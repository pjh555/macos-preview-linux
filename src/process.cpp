#include "process.h"

Process::Process(QObject *parent)
    : QObject(parent) {
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        m_output += QString::fromUtf8(m_process.readAllStandardOutput());
        emit outputChanged();
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        m_error += QString::fromUtf8(m_process.readAllStandardError());
        emit errorChanged();
    });
    connect(&m_process, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus) {
        if (!m_running)
            return;
        readChannels();
        m_exitCode = exitCode;
        m_running = false;
        emit runningChanged();
        emit exitCodeChanged();
        emit finished(exitCode);
    });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart || !m_running)
            return;
        m_error = m_process.errorString();
        emit errorChanged();
        m_exitCode = -1;
        m_running = false;
        emit runningChanged();
        emit exitCodeChanged();
        emit finished(-1);
    });
}

void Process::setCommand(const QStringList &command) {
    if (m_command == command)
        return;
    m_command = command;
    emit commandChanged();
}

void Process::setRunning(bool running) {
    if (running == m_running)
        return;
    if (running)
        startProcess();
    else if (m_process.state() != QProcess::NotRunning)
        m_process.kill();
}

void Process::startProcess() {
    if (m_command.isEmpty() || m_command.first().isEmpty())
        return;

    m_output.clear();
    m_error.clear();
    m_exitCode = -1;
    emit outputChanged();
    emit errorChanged();
    emit exitCodeChanged();

    m_process.setProgram(m_command.first());
    m_process.setArguments(m_command.mid(1));
    m_running = true;
    emit runningChanged();
    m_process.start();
}

void Process::readChannels() {
    const QByteArray out = m_process.readAllStandardOutput();
    if (!out.isEmpty()) {
        m_output += QString::fromUtf8(out);
        emit outputChanged();
    }
    const QByteArray err = m_process.readAllStandardError();
    if (!err.isEmpty()) {
        m_error += QString::fromUtf8(err);
        emit errorChanged();
    }
}

void Process::finish(int exitCode) {
    m_exitCode = exitCode;
    m_running = false;
    emit runningChanged();
    emit exitCodeChanged();
    emit finished(exitCode);
}
