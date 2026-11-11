#include "appcontroller.h"
#include "process.h"

#include <QGuiApplication>
#include <QIcon>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml/qqml.h>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);

    QCoreApplication::setApplicationName(QStringLiteral("preview"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0"));
    QCoreApplication::setOrganizationName(QStringLiteral("org.clavis"));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.clavis.Preview"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/Preview/assets/icon.svg")));

    QStringList arguments = QCoreApplication::arguments();
    if (!arguments.isEmpty())
        arguments.removeFirst();

    // A second invocation forwards its paths to the existing viewer and exits.
    QLocalSocket probe;
    probe.connectToServer(AppController::serverName());
    if (probe.waitForConnected(250)) {
        probe.write(arguments.join('\n').toUtf8());
        probe.waitForBytesWritten(500);
        probe.disconnectFromServer();
        return 0;
    }

    AppController controller(arguments);
    controller.startServer();

    qmlRegisterType<Process>("Preview", 1, 0, "Process");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("app"), &controller);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(1);
    }, Qt::QueuedConnection);

    engine.loadFromModule("Preview", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;

    return app.exec();
}
