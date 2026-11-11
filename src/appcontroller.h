#pragma once

#include <QColor>
#include <QObject>
#include <QStringList>

class QFileSystemWatcher;
class QLocalServer;

class AppController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList initialFiles READ initialFiles CONSTANT)
    Q_PROPERTY(QString homeDir READ homeDir CONSTANT)
    Q_PROPERTY(QString workingDir READ workingDir CONSTANT)
    Q_PROPERTY(QString cacheDir READ cacheDir CONSTANT)
    Q_PROPERTY(QString niriSocket READ niriSocket CONSTANT)
    Q_PROPERTY(qint64 pid READ pid CONSTANT)
    Q_PROPERTY(bool darkMode READ darkMode NOTIFY darkModeChanged)
    Q_PROPERTY(QString appearanceMode READ appearanceMode WRITE setAppearanceMode NOTIFY appearanceModeChanged)
    Q_PROPERTY(QColor accentColor READ accentColor NOTIFY accentColorChanged)
    Q_PROPERTY(QString systemFontFamily READ systemFontFamily CONSTANT)

public:
    explicit AppController(const QStringList &initialFiles, QObject *parent = nullptr);

    static QString serverName();

    QStringList initialFiles() const { return m_initialFiles; }
    QString homeDir() const;
    QString workingDir() const;
    QString cacheDir() const { return m_cacheDir; }
    QString niriSocket() const;
    qint64 pid() const;

    bool darkMode() const;
    QString appearanceMode() const { return m_appearanceMode; }
    void setAppearanceMode(const QString &mode);
    QColor accentColor() const { return m_accentColor; }
    QString systemFontFamily() const;

    void startServer();

    Q_INVOKABLE QString readTextFile(const QString &path) const;
    Q_INVOKABLE void runDetached(const QStringList &command) const;
    Q_INVOKABLE void copyText(const QString &text) const;
    Q_INVOKABLE QString cachePath(const QString &name) const;
    Q_INVOKABLE QString scriptPath(const QString &name) const;
    Q_INVOKABLE bool isDirectory(const QString &path) const;
    Q_INVOKABLE bool fileExists(const QString &path) const;
    Q_INVOKABLE QString uniqueOutputPath(const QString &sourcePath, const QString &tag, const QString &extension = QString()) const;
    Q_INVOKABLE QString cropImage(const QString &sourcePath, int x, int y, int width, int height, const QString &fallbackPath = QString());
    Q_INVOKABLE void startSystemMove() const;
    Q_INVOKABLE void startSystemResize(int edges) const;

signals:
    void filesReceived(const QStringList &paths);
    void darkModeChanged();
    void appearanceModeChanged();
    void accentColorChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

private:
    void handleNewConnection();
    void refreshSystemAppearance();
    void updateAccent();
    bool detectSystemDark() const;

    QStringList m_initialFiles;
    QString m_cacheDir;
    QLocalServer *m_server = nullptr;
    QFileSystemWatcher *m_watcher = nullptr;
    QString m_configPath;
    QString m_appearanceMode = QStringLiteral("system");
    bool m_systemDark = true;
    QColor m_accentColor;
};
