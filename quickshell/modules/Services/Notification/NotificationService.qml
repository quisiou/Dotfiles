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
    }

    function removeHistory(time) {
        root.history = root.history.filter(e => e.time !== time);
        logFile.setText(JSON.stringify(root.history.slice().reverse(), null, 2));
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
                icon:   root.resolveLogIcon(notif),
                urgency: notif.urgency ?? 1,
                category: notif.hints["category"] ?? "",
                _notif:  notif
            });

            // Show only if showNotifications is true and is not on IgnoreList
            if (root.showNotifications && !root._ignoredApps.includes(notif.appName)) {
                root.notifications = [entry, ...root.notifications];
            }

            // Always log to file
            root._appendLog(notif.appName, notif.summary, notif.body, root.resolveLogIcon(notif));
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
            property int    urgency:    1
            property string category:   ""
            property var    _notif:     null

            function dismiss() {
                root.notifications = root.notifications.filter(n => n !== this);
                if (_notif) try { _notif.dismiss(); } catch(e) {}
                destroy();
            }
        }
    }
}
