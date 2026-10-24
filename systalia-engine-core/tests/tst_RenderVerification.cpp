#include <QTest>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQuickRenderControl>
#include <QOffscreenSurface>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QQuickItemGrabResult>
#include <QImage>
#include <QColor>
#include <QSignalSpy>

#include "gfx/SystaliaGlassItem.hpp"

// Protótipo para registro dos recursos da engine
inline void initEngineResources() {
    Q_INIT_RESOURCE(systalia_engine_shaders);
}

class CustomRenderControl : public QQuickRenderControl {
public:
    CustomRenderControl() = default;

    QWindow *renderWindow(QPoint *offset) override {
        if (offset) {
            *offset = QPoint(0, 0);
        }
        return m_window;
    }

    QWindow *m_window = nullptr;
};

class tst_RenderVerification : public QObject {
    Q_OBJECT

private:
    CustomRenderControl *m_renderControl = nullptr;
    QQuickWindow *m_quickWindow = nullptr;
    QOffscreenSurface *m_offscreenSurface = nullptr;
    QQmlEngine *m_engine = nullptr;
    QQuickItem *m_rootItem = nullptr;
    QImage m_capturedFrame;

private slots:
    void initTestCase() {
        initEngineResources();

        qmlRegisterType<SystaliaGlassItem>("Systalia.Engine", 1, 0, "SystaliaGlassItem");

        m_renderControl = new CustomRenderControl();
        m_quickWindow = new QQuickWindow();
        m_renderControl->m_window = m_quickWindow;

        m_quickWindow->setGeometry(0, 0, 800, 600);
        m_quickWindow->contentItem()->setSize(QSizeF(800, 600));

        m_offscreenSurface = new QOffscreenSurface();
        m_offscreenSurface->setFormat(m_quickWindow->requestedFormat());
        m_offscreenSurface->create();

        m_renderControl->initialize();

        m_engine = new QQmlEngine(this);

        // Cena sintética: Viewport 800x600, Fundo bipartido (vermelho à esquerda, preto à direita)
        // e SystaliaGlassItem centralizado de 400x300 em (200, 150)
        const QByteArray qmlCode = R"QML(
            import QtQuick 2.15
            import Systalia.Engine 1.0

            Item {
                id: root
                width: 800
                height: 600

                Item {
                    id: bgScene
                    anchors.fill: parent

                    Rectangle {
                        id: leftHalf
                        x: 0; y: 0; width: 400; height: 600
                        color: "#ff0000"
                    }
                    Rectangle {
                        id: rightHalf
                        x: 400; y: 0; width: 400; height: 600
                        color: "#000000"
                    }
                }

                ShaderEffectSource {
                    id: backdropGrab
                    anchors.fill: bgScene
                    sourceItem: bgScene
                    textureSize: Qt.size(800, 600)
                    live: true
                    hideSource: false
                    format: ShaderEffectSource.RGBA8
                }

                SystaliaGlassItem {
                    id: glass
                    x: 395; y: 150
                    width: 400; height: 300
                    backdropSource: backdropGrab
                    screenResolution: Qt.vector2d(800, 600)
                    radii: Qt.vector4d(32, 32, 32, 32)
                    slant: 0.0
                    ior: 1.25
                    chromaticDispersion: 0.04
                    causticIntensity: 0.5
                    surfaceOpacity: 0.8
                }
            }
        )QML";

        QQmlComponent component(m_engine);
        component.setData(qmlCode, QUrl());

        QObject *obj = component.create();
        if (!obj) {
            qCritical() << "Erro ao criar componente QML de teste:" << component.errorString();
        }
        QVERIFY(obj != nullptr);

        m_rootItem = qobject_cast<QQuickItem*>(obj);
        QVERIFY(m_rootItem != nullptr);

        m_rootItem->setParentItem(m_quickWindow->contentItem());

        m_quickWindow->show();

        // Aguardar múltiplos ciclos para que o ShaderEffectSource grave o FBO e o SystaliaGlassItem refrate
        for (int i = 0; i < 6; ++i) {
            m_quickWindow->requestUpdate();
            QTest::qWait(50);
        }

        m_capturedFrame = m_quickWindow->grabWindow();

        m_capturedFrame.save("/tmp/render_verification_test.png");
        qDebug() << "Captured frame format:" << m_capturedFrame.format()
                 << "size:" << m_capturedFrame.size();
    }

    void cleanupTestCase() {
        delete m_rootItem;
        delete m_engine;
        delete m_quickWindow;
        delete m_renderControl;
        delete m_offscreenSurface;
    }

    // =========================================================================
    // Teste 1 — A Janela Principal Está Renderizando?
    // =========================================================================
    void testMainWindowIsRendering() {
        QVERIFY2(!m_capturedFrame.isNull(), "O framebuffer capturado não pode ser nulo.");
        QCOMPARE(m_capturedFrame.size(), QSize(800, 600));

        // Amostrar pixel sob a janela principal (ex: x=401, y=300 sob a placa)
        QColor bodyColor = m_capturedFrame.pixelColor(401, 300);

        // Valida que o pixel não é transparente e que foi efetivamente composto
        QVERIFY2(bodyColor.alpha() > 200, "Pixel da janela deve ser opaco/composto.");
        QVERIFY2(bodyColor.red() > 0 || bodyColor.green() > 0 || bodyColor.blue() > 0,
                 "O conteúdo da janela de cristal deve estar ativo.");
    }

    // =========================================================================
    // Teste 2 — A Refração Está Ativa?
    // =========================================================================
    void testOpticalRefractionActive() {
        QVERIFY(!m_capturedFrame.isNull());

        // A borda contrastante do fundo divide em x=400 (vermelho à esquerda, preto à direita).
        // A janela de vidro começa em x=395, posicionando o menisco perimetral entre x=395 e x=402.
        // O ponto x=401 fica no lado direito da borda (onde sem refração seria preto puro, red=0).
        // Sob a ação da refração do menisco (IOR=1.25), a luz vermelha da esquerda é desviada para a direita.
        QColor refractedPixel = m_capturedFrame.pixelColor(401, 300);

        QVERIFY2(refractedPixel.red() > 0,
                 "Luz vermelha deve refratar para a direita da borda sob o menisco do vidro.");
    }

    // =========================================================================
    // Teste 3 — Anti-Aliasing e Recorte Analítico SDF G2 (Zero Blur Bleed)
    // =========================================================================
    void testSdfContinuousAntiAliasing() {
        QVERIFY(!m_capturedFrame.isNull());

        // Ponto bem fora da janela à esquerda (x=100, y=100) deve ser vermelho puro do fundo
        QColor bgFarLeft = m_capturedFrame.pixelColor(100, 100);
        QVERIFY2(bgFarLeft.red() > 240 && bgFarLeft.green() < 15 && bgFarLeft.blue() < 15,
                 "Fundo à esquerda fora da janela deve manter vermelho puro.");

        // Ponto bem fora da janela acima (x=450, y=50) na metade preta
        QColor bgFarRight = m_capturedFrame.pixelColor(450, 50);
        QVERIFY2(bgFarRight.red() < 15 && bgFarRight.green() < 15 && bgFarRight.blue() < 15,
                 "Fundo fora da janela na metade preta deve manter preto puro.");

        // Ponto imediatamente antes da borda externa da janela (x=390, y=300):
        // Fora do vidro (que começa em 395), o fundo vermelho não deve sofrer blur bleed
        QColor outsideGlass = m_capturedFrame.pixelColor(390, 300);
        QVERIFY2(outsideGlass.red() > 240,
                 "O fundo fora da janela analítica SDF deve preservar sua cor nativa sem blur bleed.");
    }
};

QTEST_MAIN(tst_RenderVerification)
#include "tst_RenderVerification.moc"
