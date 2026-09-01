/* quickshell/modules/Services/Network/NetworkService.hpp */


#ifndef NETWORK_SERVICE_H
#define NETWORK_SERVICE_H

#include <QObject>
#include <QString>
#include <QDBusObjectPath>
#include <qqmlintegration.h>

class NetworkService : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool     enabled         READ enabled    WRITE   setEnabled  NOTIFY enabledChanged)

    // 0-100
    Q_PROPERTY(int      strength        READ strength                       NOTIFY  strengthChanged)

    // kbit/s
    Q_PROPERTY(int      bitrate         READ bitrate                        NOTIFY  bitrateChanged)

    Q_PROPERTY(QString  ssid            READ ssid                           NOTIFY  ssidChanged)

    // "wifi", "ethernet", or "none"
    Q_PROPERTY(QString  connectionType  READ connectionType                 NOTIFY connectionTypeChanged)


public:
    explicit NetworkService(QObject* parent = nullptr);

    bool    enabled()           const;
    int     strength()          const;
    int     bitrate()           const;
    QString ssid()              const;
    QString connectionType()    const;

    void setEnabled(bool on);

signals:
    void enabledChanged();
    void strengthChanged();
    void bitrateChanged();
    void ssidChanged();
    void connectionTypeChanged();

private slots:
    void onDeviceStateChanged(uint newState, uint oldState, uint reason);

    void onNmPropertiesChanged(const QString& interface,
                               const QVariantMap& changed,
                               const QStringList& invalidated);

    void onDevicePropertiesChanged(const QString& interface,
                                   const QVariantMap& changed,
                                   const QStringList& invalidated);

    void onApPropertiesChanged(const QString& interface,
                               const QVariantMap& changed,
                               const QStringList& invalidated);

private:
    QString resolveConnectionType() const;
    void    fetchInitialState();
    void    connectToDevice(const QDBusObjectPath& devicePath);
    void    connectToAccessPoint(const QDBusObjectPath& apPath);
    QString activeWirelessDevicePath() const;
    QString activeAccessPointPath(const QString& devicePath) const;

    bool    m_enabled = false;
    int     m_strength = 0;
    int     m_bitrate  = 0;

    QString m_devicePath;
    QString m_apPath;
    QString m_ssid;
    QString m_connectionType = "none";
};

#endif /* NETWORK_SERVICE_H */
