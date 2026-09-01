/* quickshell/modules/Services/Bluetooth/BluetoothService.hpp */


#ifndef BLUETOOTH_SERVICE_H
#define BLUETOOTH_SERVICE_H

#include <QtCore/QAbstractListModel>
#include <QDBusContext>
#include <QDBusObjectPath>
#include <QObject>
#include <QString>
#include <QList>
#include <qqmlintegration.h>

struct BluetoothDevice {
    QString path;
    QString name;
    QString alias;
    QString icon;
    QString address;
    bool connected;
    bool paired;
};

class BluetoothDeviceModel : public QAbstractListModel, protected QDBusContext {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int connectedCount READ connectedCount NOTIFY layoutChanged)
    Q_PROPERTY(bool anyConnected READ anyConnected NOTIFY layoutChanged)
    Q_PROPERTY(QStringList connectedNames READ connectedNames NOTIFY connectedNamesChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        AliasRole,
        IconRole,
        AddressRole,
        ConnectedRole,
        PairedRole,
        PathRole
    };

    explicit BluetoothDeviceModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int connectedCount() const;
    bool anyConnected() const;
    QStringList connectedNames() const;

    Q_INVOKABLE void toggle(const QString& path);
    Q_INVOKABLE void connectDevice(const QString& path);
    Q_INVOKABLE void disconnectDevice(const QString& path);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantList deviceList() const;

signals:
    void connectedNamesChanged();


private slots:
    void onPropertiesChanged(const QString& interface,
                             const QVariantMap& changed,
                             const QStringList& invalidated);

private:
    void loadDevices();
    int indexForPath(const QString& path) const;

    QList<BluetoothDevice> m_devices;
};

#endif /* BLUETOOTH_SERVICE_H */
