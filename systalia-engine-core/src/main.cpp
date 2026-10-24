#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQuickStyle>
#include <QSGRendererInterface>
#include <QDebug>
#include "gfx/SystaliaGlassItem.hpp"

int main(int argc, char *argv[])
{
    // Forçar o backend Vulkan via Qt RHI conforme especificado
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Vulkan);
    qputenv("QSG_RHI_BACKEND", "vulkan");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("Systalia Glass Engine - Core"));
    app.setOrganizationName(QStringLiteral("Systalia Systems"));
    app.setOrganizationDomain(QStringLiteral("systalia.systems"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // Registo do componente de vidro analítico na engine QML
    qmlRegisterType<SystaliaGlassItem>("Systalia.Engine", 1, 0, "SystaliaGlassItem");

    QQmlApplicationEngine engine;

    // Conexão de verificação de criação de objetos raiz
    const QUrl primaryUrl(QStringLiteral("qrc:/qt/qml/Systalia/Engine/src/qml/main.qml"));
    const QUrl fallbackUrl(QStringLiteral("qrc:/src/qml/main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    engine.load(primaryUrl);
    if (engine.rootObjects().isEmpty()) {
        engine.load(fallbackUrl);
    }

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Falha crítica ao carregar interface QML do Systalia Glass Engine!";
        return -1;
    }

    return app.exec();
}
