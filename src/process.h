#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

// Small QML-friendly wrapper around QProcess: command, running, output,
// error, exitCode and a finished(exitCode) signal.
class Process : public QObject {
    Q_OBJECT
    Q_PROPERTY(QStringList command READ command WRITE setCommand NOTIFY commandChanged)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(QString output READ output NOTIFY outputChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int exitCode READ exitCode NOTIFY exitCodeChanged)

public:
    explicit Process(QObject *parent = nullptr);

    QStringList command() const { return m_command; }
    void setCommand(const QStringList &command);

    bool running() const { return m_running; }
    void setRunning(bool running);

    QString output() const { return m_output; }
    QString error() const { return m_error; }
    int exitCode() const { return m_exitCode; }

signals:
    void commandChanged();
    void runningChanged();
    void outputChanged();
    void errorChanged();
    void exitCodeChanged();
    void finished(int exitCode);

private:
    void startProcess();
    void finish(int exitCode);
    void readChannels();

    QProcess m_process;
    QStringList m_command;
    bool m_running = false;
    QString m_output;
    QString m_error;
    int m_exitCode = -1;
};
