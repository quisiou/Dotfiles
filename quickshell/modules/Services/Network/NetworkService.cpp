/* quickshell/modules/Services/Network/NetworkService.cpp */


#include "NetworkService.hpp"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDebug>

// ── D-Bus constants ────────────────────────────────────────────────────────

static const QString NM_SERVICE         = "org.freedesktop.NetworkManager";
static const QString NM_PATH            = "/org/freedesktop/NetworkManager";
static const QString NM_IFACE           = "org.freedesktop.NetworkManager";
static const QString NM_WIRELESS_IFACE  = "org.freedesktop.NetworkManager.Device.Wireless";
static const QString NM_AP_IFACE        = "org.freedesktop.NetworkManager.AccessPoint";
static const QString PROPS_IFACE        = "org.freedesktop.DBus.Properties";

// ── Helpers ────────────────────────────────────────────────────────────────

static QVariant getProp(const QString& path, const QString& iface, const QString& prop) {
    QDBusInterface pi(NM_SERVICE, path, PROPS_IFACE, QDBusConnection::systemBus());
    QDBusReply<QVariant> r = pi.call("Get", iface, prop);
    if (!r.isValid()) {
        qWarning() << "NetworkService: Get" << prop << "failed:" << r.error().message();
        return {};
    }
    return r.value();
}

// ── Connection type ────────────────────────────────────────────────────────

QString NetworkService::resolveConnectionType() const {
    QDBusInterface nm(NM_SERVICE, NM_PATH, NM_IFACE, QDBusConnection::systemBus());
    QDBusReply<QList<QDBusObjectPath>> reply = nm.call("GetDevices");
    if (!reply.isValid()) return "none";

    for (const QDBusObjectPath& p : reply.value()) {
        const QString path = p.path();
        QVariant state = getProp(path, "org.freedesktop.NetworkManager.Device", "State");
        if (state.toUInt() != 100) continue; // 100 = ACTIVATED

        QVariant type = getProp(path, "org.freedesktop.NetworkManager.Device", "DeviceType");
        switch (type.toUInt()) {
            case 1: return "ethernet";
            case 2: return "wifi";
            default: break;
        }
    }
    return "none";
}

// ── Constructor ────────────────────────────────────────────────────────────

NetworkService::NetworkService(QObject* parent) : QObject(parent) {
    fetchInitialState();

    QDBusConnection::systemBus().connect(
        NM_SERVICE, NM_PATH, PROPS_IFACE, "PropertiesChanged",
        this, SLOT(onNmPropertiesChanged(QString, QVariantMap, QStringList))
    );
}

// ── Property readers ───────────────────────────────────────────────────────

bool    NetworkService::enabled()           const { return m_enabled; }
int     NetworkService::strength()          const { return m_strength; }
int     NetworkService::bitrate()           const { return m_bitrate;  }
QString NetworkService::ssid()              const { return m_ssid; }
QString NetworkService::connectionType()    const { return m_connectionType; }

// ── Setter ─────────────────────────────────────────────────────────────────

void NetworkService::setEnabled(bool on) {
    if (m_enabled == on) return;
    if (m_connectionType == "ethernet") return;

    QDBusInterface nm(NM_SERVICE, NM_PATH, PROPS_IFACE, QDBusConnection::systemBus());
    nm.asyncCall("Set", NM_IFACE, QString("WirelessEnabled"),
                 QVariant::fromValue(QDBusVariant(on)));
    // State will update reactively via PropertiesChanged
}

// ── Initial state ──────────────────────────────────────────────────────────

void NetworkService::fetchInitialState() {
    // WirelessEnabled
    QVariant en = getProp(NM_PATH, NM_IFACE, "WirelessEnabled");
    if (en.isValid()) m_enabled = en.toBool();

    m_connectionType = resolveConnectionType();

    if (m_connectionType == "wifi") {
        // Find active wireless device and its current AP
        const QString devPath = activeWirelessDevicePath();
        if (!devPath.isEmpty()) {
            connectToDevice(QDBusObjectPath(devPath));
            const QString apPath = activeAccessPointPath(devPath);
            if (!apPath.isEmpty())
                connectToAccessPoint(QDBusObjectPath(apPath));
        }
    }
}

// ── Device wiring ──────────────────────────────────────────────────────────

// Returns the object path of the first active wireless device, or "".
QString NetworkService::activeWirelessDevicePath() const {
    // NM exposes all devices; filter for wireless ones with an active AP.
    QDBusInterface nm(NM_SERVICE, NM_PATH, NM_IFACE, QDBusConnection::systemBus());
    QDBusReply<QList<QDBusObjectPath>> reply = nm.call("GetDevices");
    if (!reply.isValid()) return {};

    for (const QDBusObjectPath& p : reply.value()) {
        const QString path = p.path();
        // DeviceType 2 = NM_DEVICE_TYPE_WIFI
        QVariant type = getProp(path, "org.freedesktop.NetworkManager.Device", "DeviceType");
        if (type.toUInt() == 2) return path;
    }
    return {};
}

// Returns the ActiveAccessPoint path for a wireless device, or "".
QString NetworkService::activeAccessPointPath(const QString& devicePath) const {
    QVariant ap = getProp(devicePath, NM_WIRELESS_IFACE, "ActiveAccessPoint");
    if (!ap.isValid()) return {};
    const QString path = ap.value<QDBusObjectPath>().path();
    return (path == "/") ? QString() : path;
}

// Subscribe to property changes on the wireless device and read initial
// Bitrate. ActiveAccessPoint changes here tell us when to re-wire the AP.
void NetworkService::connectToDevice(const QDBusObjectPath& devicePath) {
    const QString path = devicePath.path();
    if (path == m_devicePath) return;

    if (!m_devicePath.isEmpty()) {
        QDBusConnection::systemBus().disconnect(
            NM_SERVICE, m_devicePath, PROPS_IFACE, "PropertiesChanged",
            this, SLOT(onDevicePropertiesChanged(QString, QVariantMap, QStringList)));
        QDBusConnection::systemBus().disconnect(
            NM_SERVICE, m_devicePath,
            "org.freedesktop.NetworkManager.Device", "StateChanged",
            this, SLOT(onDeviceStateChanged(uint, uint, uint)));
    }

    m_devicePath = path;

    QDBusConnection::systemBus().connect(
        NM_SERVICE, path, PROPS_IFACE, "PropertiesChanged",
        this, SLOT(onDevicePropertiesChanged(QString, QVariantMap, QStringList)));
    QDBusConnection::systemBus().connect(
        NM_SERVICE, path,
        "org.freedesktop.NetworkManager.Device", "StateChanged",
        this, SLOT(onDeviceStateChanged(uint, uint, uint)));

    QVariant br = getProp(path, NM_WIRELESS_IFACE, "Bitrate");
    const int newBr = br.isValid() ? (int)br.toUInt() : 0;
    if (m_bitrate != newBr) { m_bitrate = newBr; emit bitrateChanged(); }
}

// Subscribe to property changes on the access point and read initial Strength.
void NetworkService::connectToAccessPoint(const QDBusObjectPath& apPath) {
    const QString path = apPath.path();
    if (path == m_apPath) return;

    if (!m_apPath.isEmpty())
        QDBusConnection::systemBus().disconnect(
            NM_SERVICE, m_apPath, PROPS_IFACE, "PropertiesChanged",
            this, SLOT(onApPropertiesChanged(QString, QVariantMap, QStringList)));

    m_apPath = path;

    QDBusConnection::systemBus().connect(
        NM_SERVICE, path, PROPS_IFACE, "PropertiesChanged",
        this, SLOT(onApPropertiesChanged(QString, QVariantMap, QStringList)));

    // Initial strength (0-100)
    QVariant st = getProp(path, NM_AP_IFACE, "Strength");
    const int newSt = st.isValid() ? (int)st.value<uchar>() : 0;
    if (m_strength != newSt) { m_strength = newSt; emit strengthChanged(); }

    // Network's SSID
    QVariant ss = getProp(path, NM_AP_IFACE, "Ssid");
    const QString newSsid = ss.isValid()
        ? QString::fromUtf8(ss.toByteArray())
        : QString();
    if (m_ssid != newSsid) { m_ssid = newSsid; emit ssidChanged(); }
}

// ── Slot: Network device's state changed ──────────────────────────────────

void NetworkService::onDeviceStateChanged(uint newState, uint oldState, uint reason) {
    Q_UNUSED(oldState); Q_UNUSED(reason);

    const QString ct = resolveConnectionType();
    if (m_connectionType != ct) { m_connectionType = ct; emit connectionTypeChanged(); }

    if (newState == 100) {
        const QString apPath = activeAccessPointPath(m_devicePath);
        if (!apPath.isEmpty())
            connectToAccessPoint(QDBusObjectPath(apPath));
    } else {
        m_apPath = "";
        if (m_strength != 0) { m_strength = 0; emit strengthChanged(); }
        if (!m_ssid.isEmpty()) { m_ssid = ""; emit ssidChanged(); }
        if (m_bitrate != 0) { m_bitrate = 0; emit bitrateChanged(); }
    }
}

// ── Slot: NM root PropertiesChanged ───────────────────────────────────────

void NetworkService::onNmPropertiesChanged(const QString& interface,
                                         const QVariantMap& changed,
                                         const QStringList&)
{
    if (interface != NM_IFACE) return;

    if (changed.contains("WirelessEnabled")) {
        const bool v = changed["WirelessEnabled"].toBool();
        if (m_enabled != v) { m_enabled = v; emit enabledChanged(); }

        const QString ct = resolveConnectionType();
        if (m_connectionType != ct) { m_connectionType = ct; emit connectionTypeChanged(); }
    }

    if (changed.contains("ActiveConnections")) {
        const QString devPath = activeWirelessDevicePath();
        if (!devPath.isEmpty())
            connectToDevice(QDBusObjectPath(devPath));
    }
}

// ── Slot: wireless device PropertiesChanged ────────────────────────────────

void NetworkService::onDevicePropertiesChanged(const QString& interface,
                                             const QVariantMap& changed,
                                             const QStringList&)
{
    if (interface != NM_WIRELESS_IFACE) return;

    if (changed.contains("Bitrate")) {
        const int v = (int)changed["Bitrate"].toUInt();
        if (m_bitrate != v) { m_bitrate = v; emit bitrateChanged(); }
    }

    // Active AP changed (roamed, reconnected, etc.)
    if (changed.contains("ActiveAccessPoint")) {
        const QString apPath = changed["ActiveAccessPoint"]
                                   .value<QDBusObjectPath>().path();
        if (!apPath.isEmpty() && apPath != "/")
            connectToAccessPoint(QDBusObjectPath(apPath));
        else {
            m_apPath = "";
            if (m_strength != 0) { m_strength = 0; emit strengthChanged(); }
            if (!m_ssid.isEmpty()) { m_ssid = ""; emit ssidChanged(); }
        }
    }
}

// ── Slot: access point PropertiesChanged ──────────────────────────────────

void NetworkService::onApPropertiesChanged(const QString& interface,
                                         const QVariantMap& changed,
                                         const QStringList&)
{
    if (interface != NM_AP_IFACE) return;

    if (changed.contains("Strength")) {
        const int v = (int)changed["Strength"].value<uchar>();
        if (m_strength != v) { m_strength = v; emit strengthChanged(); }
    }
}
