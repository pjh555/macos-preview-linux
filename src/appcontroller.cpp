#include "appcontroller.h"

#include <QClipboard>
#include <QCoreApplication>
#include <QDir>
#include <QEvent>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QFileSystemWatcher>
#include <QFontDatabase>
#include <QImage>
#include <QImageReader>
#include <QImageWriter>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QPalette>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QStyleHints>
#include <QWindow>
#include <QtGlobal>

#include <unistd.h>

AppController::AppController(const QStringList &initialFiles, QObject *parent)
    : QObject(parent)
    , m_initialFiles(initialFiles) {
    m_cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(m_cacheDir);

    QSettings settings;
    const QString savedMode = settings.value(QStringLiteral("appearance/mode"), QStringLiteral("system")).toString();
    if (savedMode == QStringLiteral("light") || savedMode == QStringLiteral("dark") || savedMode == QStringLiteral("system"))
        m_appearanceMode = savedMode;

    m_configPath = QDir::homePath() + QStringLiteral("/.config/clavis/config.json");
    m_systemDark = detectSystemDark();
    updateAccent();

    m_watcher = new QFileSystemWatcher(this);
    const QString configDir = QFileInfo(m_configPath).absolutePath();
    if (QFileInfo::exists(m_configPath))
        m_watcher->addPath(m_configPath);
    if (QDir(configDir).exists())
        m_watcher->addPath(configDir);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this]() {
        if (QFileInfo::exists(m_configPath) && !m_watcher->files().contains(m_configPath))
            m_watcher->addPath(m_configPath);
        refreshSystemAppearance();
    });
    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, [this]() {
        if (QFileInfo::exists(m_configPath) && !m_watcher->files().contains(m_configPath))
            m_watcher->addPath(m_configPath);
        refreshSystemAppearance();
    });

    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this](Qt::ColorScheme) {
        refreshSystemAppearance();
    });
    qApp->installEventFilter(this);
}

bool AppController::darkMode() const {
    if (m_appearanceMode == QStringLiteral("light"))
        return false;
    if (m_appearanceMode == QStringLiteral("dark"))
        return true;
    return m_systemDark;
}

void AppController::setAppearanceMode(const QString &mode) {
    const QString next = mode.toLower();
    if (next != QStringLiteral("system") && next != QStringLiteral("light") && next != QStringLiteral("dark"))
        return;
    if (next == m_appearanceMode)
        return;
    m_appearanceMode = next;
    QSettings settings;
    settings.setValue(QStringLiteral("appearance/mode"), next);
    emit appearanceModeChanged();
    emit darkModeChanged();
}

QString AppController::systemFontFamily() const {
    return QFontDatabase::systemFont(QFontDatabase::GeneralFont).family();
}

bool AppController::detectSystemDark() const {
    QFile config(m_configPath);
    if (config.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(config.readAll(), &error);
        if (error.error == QJsonParseError::NoError) {
            const QString mode = document.object().value(QStringLiteral("theme")).toObject().value(QStringLiteral("mode")).toString();
            if (mode == QStringLiteral("light"))
                return false;
            if (mode == QStringLiteral("dark"))
                return true;
        }
    }

    const Qt::ColorScheme scheme = QGuiApplication::styleHints()->colorScheme();
    if (scheme == Qt::ColorScheme::Dark)
        return true;
    if (scheme == Qt::ColorScheme::Light)
        return false;
    return QGuiApplication::palette().color(QPalette::Window).lightness() < 128;
}

void AppController::refreshSystemAppearance() {
    const bool next = detectSystemDark();
    if (next != m_systemDark) {
        m_systemDark = next;
        emit darkModeChanged();
    }
    updateAccent();
}

void AppController::updateAccent() {
    const QPalette palette = QGuiApplication::palette();
    QColor accent;
#if QT_VERSION >= QT_VERSION_CHECK(6, 6, 0)
    accent = palette.color(QPalette::Accent);
#endif
    if (!accent.isValid() || accent.alpha() == 0)
        accent = palette.color(QPalette::Highlight);
    if (!accent.isValid() || accent.alpha() == 0 || accent.saturation() < 35 || accent.lightness() < 30 || accent.lightness() > 230)
        accent = QColor(0, 0, 0, 0);
    if (accent != m_accentColor) {
        m_accentColor = accent;
        emit accentColorChanged();
    }
}

bool AppController::eventFilter(QObject *watched, QEvent *event) {
    if (event->type() == QEvent::ApplicationPaletteChange)
        refreshSystemAppearance();
    return QObject::eventFilter(watched, event);
}

QString AppController::serverName() {
    return QStringLiteral("org.clavis.Preview-%1").arg(static_cast<qulonglong>(::getuid()));
}

QString AppController::homeDir() const {
    return QDir::homePath();
}

QString AppController::workingDir() const {
    return QDir::currentPath();
}

QString AppController::niriSocket() const {
    return qEnvironmentVariable("NIRI_SOCKET");
}

qint64 AppController::pid() const {
    return QCoreApplication::applicationPid();
}

void AppController::startServer() {
    m_server = new QLocalServer(this);
    QLocalServer::removeServer(serverName());
    if (!m_server->listen(serverName()))
        qWarning("Preview: could not listen on %s: %s", qPrintable(serverName()), qPrintable(m_server->errorString()));
    connect(m_server, &QLocalServer::newConnection, this, &AppController::handleNewConnection);
}

void AppController::handleNewConnection() {
    while (QLocalSocket *socket = m_server->nextPendingConnection()) {
        auto *buffer = new QByteArray;
        connect(socket, &QLocalSocket::readyRead, socket, [socket, buffer]() {
            buffer->append(socket->readAll());
        });
        connect(socket, &QLocalSocket::disconnected, socket, [this, socket, buffer]() {
            const QStringList paths = QString::fromUtf8(*buffer).split('\n', Qt::SkipEmptyParts);
            delete buffer;
            emit filesReceived(paths);
            socket->deleteLater();
        });
    }
}

QString AppController::readTextFile(const QString &path) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll());
}

void AppController::runDetached(const QStringList &command) const {
    if (command.isEmpty() || command.first().isEmpty())
        return;
    QProcess::startDetached(command.first(), command.mid(1));
}

void AppController::copyText(const QString &text) const {
    QGuiApplication::clipboard()->setText(text);
}

QString AppController::cachePath(const QString &name) const {
    return QDir(m_cacheDir).filePath(name);
}

QString AppController::scriptPath(const QString &name) const {
    QStringList candidates;
    candidates << QCoreApplication::applicationDirPath() + "/scripts/" + name;
    candidates << QCoreApplication::applicationDirPath() + "/../scripts/" + name;
#ifdef PREVIEW_SOURCE_DIR
    candidates << QStringLiteral(PREVIEW_SOURCE_DIR) + "/scripts/" + name;
#endif
    for (const QString &candidate : candidates) {
        if (QFileInfo::exists(candidate))
            return QDir::cleanPath(candidate);
    }
    return QDir::cleanPath(candidates.first());
}

bool AppController::isDirectory(const QString &path) const {
    return QFileInfo(path).isDir();
}

bool AppController::fileExists(const QString &path) const {
    return QFileInfo::exists(path);
}

QString AppController::uniqueOutputPath(const QString &sourcePath, const QString &tag, const QString &extension) const {
    const QFileInfo info(sourcePath);
    const QString dir = info.absolutePath();
    const QString base = info.completeBaseName();
    QString ext = extension;
    if (ext.isEmpty())
        ext = info.suffix();
    ext = ext.toLower();

    auto makeName = [&](int index) {
        QString name = base + "-" + tag;
        if (index > 1)
            name += "-" + QString::number(index);
        if (!ext.isEmpty())
            name += "." + ext;
        return QDir(dir).filePath(name);
    };

    QString candidate = makeName(1);
    int index = 2;
    while (QFileInfo::exists(candidate))
        candidate = makeName(index++);
    return candidate;
}

QString AppController::cropImage(const QString &sourcePath, int x, int y, int width, int height, const QString &fallbackPath) {
    QImage image;
    QImageReader reader(sourcePath);
    reader.setAutoTransform(true);
    image = reader.read();
    if (image.isNull() && !fallbackPath.isEmpty())
        image = QImage(fallbackPath);
    if (image.isNull())
        return "ERROR:" + reader.errorString();

    const QRect wanted(x, y, width, height);
    const QRect bounds = wanted.intersected(image.rect());
    if (bounds.width() < 1 || bounds.height() < 1)
        return "ERROR:Invalid crop rectangle";

    const QImage cropped = image.copy(bounds);
    const QString sourceSuffix = QFileInfo(sourcePath).suffix().toLower();
    QString extension = (sourceSuffix == "png" || sourceSuffix == "jpg" || sourceSuffix == "jpeg") ? sourceSuffix : "png";
    QString output = uniqueOutputPath(sourcePath, "cropped", extension);
    QImageWriter writer(output);
    writer.setQuality(95);
    if (!writer.write(cropped)) {
        if (extension == "png")
            return "ERROR:" + writer.errorString();
        extension = "png";
        output = uniqueOutputPath(sourcePath, "cropped", extension);
        QImageWriter pngWriter(output);
        if (!pngWriter.write(cropped))
            return "ERROR:" + pngWriter.errorString();
    }
    return output;
}

void AppController::startSystemMove() const {
    if (QWindow *window = QGuiApplication::focusWindow())
        window->startSystemMove();
}

void AppController::startSystemResize(int edges) const {
    if (QWindow *window = QGuiApplication::focusWindow())
        window->startSystemResize(static_cast<Qt::Edges>(edges));
}
