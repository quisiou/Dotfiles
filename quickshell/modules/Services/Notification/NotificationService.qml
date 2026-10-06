/* quickshell/modules/Services/Notification/NotificationService.qml */


pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property list<var> notifications:   []
    property int _seq:                  0
    property bool showNotifications:    true
    property list<string> _ignoredApps: []
    property list<var> history:         []
    property var _live: ({})          // logTime -> Notification
    property var _liveOrder: []       // logTimes, oldest first
    readonly property int _maxLive: 30

    // ── Apps to ignore ─────────────────────────────────────────────────────

    FileView {
        id: ignoreFile
        path: Quickshell.env("HOME") + "/.config/quickshell/ignoreNotifications.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            var text = ignoreFile.text()
            if (text === "") return []
            try {
                var data = JSON.parse(text)
                root._ignoredApps = Array.isArray(data) ? data : []
            } catch (e) {
                console.warn("ignoreNotifications.json: parse failed", e)
                root._ignoredApps = []
            }
        }
    }

    // ── JSON log ───────────────────────────────────────────────────────────

    readonly property string _logPath: Quickshell.cacheDir + "/notifications.json"
    readonly property string avatarDir: Quickshell.cacheDir + "/notification-avatars"

    Process {
        command: ["mkdir", "-p", root.avatarDir]
        running: true
    }

    Process {
        id: clearAvatars
        command: ["sh", "-c", "rm -f \"$1\"/*", "sh", root.avatarDir]
    }

    FileView {
        id: logFile
        path: ""
        onLoaded: {
            try {
                const arr = JSON.parse(logFile.text());
                root.history = Array.isArray(arr) ? arr.slice().reverse() : [];
            } catch (e) {
                root.history = [];
            }
        }
    }

    // Ensure log file exists
    Process {
    id: initProc
        command: [Quickshell.shellDir + "/scripts/init_notif_log.sh", root._logPath]
        running: true
        // qmllint disable signal-handler-parameters
        onExited: function(exitCode) {
            if (exitCode === 0) {
                logFile.path = root._logPath;
            } else {
                console.warn("NotificationService: failed to initialise log file (exit", exitCode, ")");
            }
        }
        // qmllint enable signal-handler-parameters
    }

    function _dropLive(time, close) {
        const n = root._live[time]
        delete root._live[time]
        root._liveOrder = root._liveOrder.filter(t => t !== time)
        if (close && n) try { n.dismiss() } catch (e) {}
    }

    function _keepLive(time, notif) {
        root._live[time] = notif
        root._liveOrder.push(time)
        notif.closed.connect(() => root._dropLive(time, false))

        // Past the cap, close the oldest ones
        while (root._liveOrder.length > root._maxLive)
            root._dropLive(root._liveOrder[0], true)
    }

    function invokeDefault(time) {
        const n = root._live[time]
        if (!n) return false
        const def = (n.actions ?? []).find(a => a.identifier === "default")
        if (!def) return false
        def.invoke()
        return true
    }

    function _appendLog(appName, summary, body, icon) {
        const entry = {
            time:    new Date().toISOString(),
            app:     appName || "unknown",
            summary: summary || "",
            body:    body    || "",
            icon:    icon    || ""
        };
        root.history = [entry, ...root.history];
        logFile.setText(JSON.stringify(root.history.slice().reverse(), null, 2));
        return entry.time;
    }

    function removeHistory(time) {
        root._dropLive(time, true);
        root.history = root.history.filter(e => e.time !== time);
        logFile.setText(JSON.stringify(root.history.slice().reverse(), null, 2));
    }

    function setHistoryIcon(time, icon) {
        root.history = root.history.map(e => e.time === time ? Object.assign({}, e, { icon: icon }) : e);
        logFile.setText(JSON.stringify(root.history.slice().reverse(), null, 2));
    }

    function clearHistory() {
        for (const t of root._liveOrder.slice())
            root._dropLive(t, true);

        root.history = [];
        logFile.setText("[]");
        clearAvatars.running = true;
    }

    // ── App icon retrieval ─────────────────────────────────────────────────

    readonly property string _fallbackIcon: Quickshell.shellDir + "/assets/icons/notification-bell.svg"

    function resolveLogIcon(notif) {
        if (notif.appIcon && notif.appIcon !== "") {
            const p = Quickshell.iconPath(notif.appIcon, 32);
            if (p && p !== "") return p;
        }
        return root._fallbackIcon;
    }

    // ── Notification daemon ────────────────────────────────────────────────

    NotificationServer {
        id: server
        actionsSupported:       true
        bodySupported:          true
        bodyMarkupSupported:    false
        imageSupported:         true
        keepOnReload:           false

        onNotification: function(notif) {
            if (!notif.appName && !notif.summary && !notif.body) return;

            notif.tracked = true;

            const avatar  = notif.image || "";
            const appIcon = root.resolveLogIcon(notif);

            // Replace if same protocol id (app is updating an existing notif)
            const idStr = String(notif.id || "");
            if (idStr !== "") {
                const existing = root.notifications.find(n => n._pid === idStr);
                if (existing) {
                    root.notifications = root.notifications.filter(n => n !== existing);
                    existing.destroy();
                }
            }

            const entry = _entryComp.createObject(root, {
                seqId:   root._seq++,
                _pid:    idStr,
                appName: notif.appName || "",
                summary: notif.summary || "",
                body:    notif.body    || "",
                icon:    avatar !== "" ? avatar : appIcon,
                avatar:  avatar,
                logTime: "",
                urgency: notif.urgency ?? 1,
                category: notif.hints["category"] ?? "",
                _notif:  notif
            });

            // Show only if showNotifications is true and is not on IgnoreList
            if (root.showNotifications && !root._ignoredApps.includes(notif.appName)) {
                root.notifications = [entry, ...root.notifications];
            }

            // Always log to file
            entry.logTime = root._appendLog(notif.appName, notif.summary, notif.body, appIcon);

            // Keep alive
            root._keepLive(entry.logTime, notif);
        }
    }

    // ── Entry ──────────────────────────────────────────────────────────────

    Component {
        id: _entryComp

        QtObject {
            property int    seqId:      0
            property string _pid:       ""
            property string appName:    ""
            property string summary:    ""
            property string body:       ""
            property string icon:       ""
            property string avatar:     ""
            property string logTime:    ""
            property int    urgency:    1
            property string category:   ""
            property var    _notif:     null

            function dismiss() {
                root.notifications = root.notifications.filter(n => n !== this);
                destroy();
            }
        }
    }
}
