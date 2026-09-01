/* quickshell/modules/Services/Bluetooth/BluetoothService.cpp */


#include "BluetoothService.hpp"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusArgument>
#include <QDebug>
#include <QIcon>
#include <algorithm>

static const QString BLUEZ_SERVICE    = "org.bluez";
static const QString DEVICE_IFACE     = "org.bluez.Device1";
static const QString PROPS_IFACE      = "org.freedesktop.DBus.Properties";
static const QString OBJMANAGER_IFACE = "org.freedesktop.DBus.ObjectManager";

BluetoothDeviceModel::BluetoothDeviceModel(QObject* parent)
    : QAbstractListModel(parent)
{

    QIcon::setThemeName("Adwaita");
    QIcon::setFallbackThemeName("hicolor");

    loadDevices();

    QDBusConnection::systemBus().connect(
        BLUEZ_SERVICE,
        QString(),
        PROPS_IFACE,
        "PropertiesChanged",
        this,
        SLOT(onPropertiesChanged(QString, QVariantMap, QStringList))
    );
}

void BluetoothDeviceModel::loadDevices() {
    beginResetModel();
    m_devices.clear();

    QDBusInterface manager(BLUEZ_SERVICE, "/",
                           OBJMANAGER_IFACE,
                           QDBusConnection::systemBus());

    QDBusMessage reply = manager.call("GetManagedObjects");
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qWarning() << "BluetoothService: GetManagedObjects failed:" << reply.errorMessage();
        endResetModel();
        return;
    }

    const QDBusArgument arg = reply.arguments().at(0).value<QDBusArgument>();
    QMap<QDBusObjectPath, QMap<QString, QVariantMap>> objects;
    arg >> objects;

    for (auto it = objects.cbegin(); it != objects.cend(); ++it) {
        const QString path = it.key().path();
        const auto& interfaces = it.value();
        if (!interfaces.contains(DEVICE_IFACE)) continue;

        const QVariantMap& props = interfaces[DEVICE_IFACE];
        if (!props.value("Paired", false).toBool()) continue;

        BluetoothDevice dev;
        dev.path      = path;
        dev.name      = props.value("Name").toString();
        dev.alias     = props.value("Alias").toString();
        dev.icon      = props.value("Icon").toString();
        dev.address   = props.value("Address").toString();
        dev.connected = props.value("Connected", false).toBool();
        dev.paired    = true;
        m_devices.append(dev);
    }

    endResetModel();
    emit connectedNamesChanged();
}

void BluetoothDeviceModel::onPropertiesChanged(const QString& interface,
                                                const QVariantMap& changed,
                                                const QStringList&)
{
    if (interface != DEVICE_IFACE) return;

    const QString path = message().path();
    int idx = indexForPath(path);
    if (idx < 0) return;

    bool dirty = false;
    if (changed.contains("Connected")) {
        m_devices[idx].connected = changed["Connected"].toBool();
        dirty = true;
    }
    if (changed.contains("Name")) {
        m_devices[idx].name = changed["Name"].toString();
        dirty = true;
    }
    if (changed.contains("Alias")) {
        m_devices[idx].alias = changed["Alias"].toString();
        dirty = true;
    }

    if (dirty) {
        const QModelIndex mi = index(idx);
        emit dataChanged(mi, mi);
        emit connectedNamesChanged();
    }
}

void BluetoothDeviceModel::toggle(const QString& path) {
    int idx = indexForPath(path);
    if (idx < 0) return;
    if (m_devices[idx].connected) disconnectDevice(path);
    else connectDevice(path);
}

void BluetoothDeviceModel::connectDevice(const QString& path) {
    QDBusInterface dev(BLUEZ_SERVICE, path, DEVICE_IFACE,
                       QDBusConnection::systemBus());
    dev.asyncCall("Connect");
}

void BluetoothDeviceModel::disconnectDevice(const QString& path) {
    QDBusInterface dev(BLUEZ_SERVICE, path, DEVICE_IFACE,
                       QDBusConnection::systemBus());
    dev.asyncCall("Disconnect");
}

void BluetoothDeviceModel::refresh() { loadDevices(); }

QVariantList BluetoothDeviceModel::deviceList() const {
    QVariantList result;
    for (const auto& dev : m_devices) {
        QVariantMap map;
        map["path"]      = dev.path;
        map["name"]      = dev.name;
        map["alias"]     = dev.alias;
        map["icon"]      = dev.icon;
        map["address"]   = dev.address;
        map["connected"] = dev.connected;
        map["paired"]    = dev.paired;
        result.append(map);
    }
    return result;
}

int BluetoothDeviceModel::connectedCount() const {
    return std::count_if(m_devices.cbegin(), m_devices.cend(),
        [](const BluetoothDevice& d) { return d.connected; });
}

bool BluetoothDeviceModel::anyConnected() const {
    return connectedCount() > 0;
}

QStringList BluetoothDeviceModel::connectedNames() const {
    QStringList names;
    for (const auto& dev : m_devices) {
        if (dev.connected) {
            const QString label = dev.alias.isEmpty() ? dev.name : dev.alias;
            if (!label.isEmpty())
                names.append(label);
        }
    }
    return names;
}

int BluetoothDeviceModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_devices.size();
}

QVariant BluetoothDeviceModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_devices.size()) return {};
    const auto& dev = m_devices[index.row()];
    switch (role) {
        case NameRole:      return dev.name;
        case AliasRole:     return dev.alias;
        case IconRole:      return dev.icon;
        case AddressRole:   return dev.address;
        case ConnectedRole: return dev.connected;
        case PairedRole:    return dev.paired;
        case PathRole:      return dev.path;
        default:            return {};
    }
}

QHash<int, QByteArray> BluetoothDeviceModel::roleNames() const {
    return {
        { NameRole,      "name"      },
        { AliasRole,     "alias"     },
        { IconRole,      "icon"      },
        { AddressRole,   "address"   },
        { ConnectedRole, "connected" },
        { PairedRole,    "paired"    },
        { PathRole,      "path"      },
    };
}

int BluetoothDeviceModel::indexForPath(const QString& path) const {
    for (int i = 0; i < m_devices.size(); i++)
        if (m_devices[i].path == path) return i;
    return -1;
}
