#include <QTest>
#include <QFile>
#include <cmath>
#include <algorithm>
#include <cstddef>

#include "gfx/SystaliaSurfaceProps.hpp"

// Protótipo para registro de recursos RCC embutidos na biblioteca systalia_engine_core
inline void initEngineResources() {
    Q_INIT_RESOURCE(systalia_engine_shaders);
}

class tst_SystaliaEngine : public QObject {
    Q_OBJECT

private:
    struct Vec2 { float x, y; };
    struct Vec4 { float x, y, z, w; };

    static float selectRadius(Vec2 p, Vec4 r) {
        if (p.x < 0.0f) {
            return (p.y < 0.0f) ? r.x : r.z;
        } else {
            return (p.y < 0.0f) ? r.y : r.w;
        }
    }

    static float sdRoundedBox4(Vec2 p, Vec2 b, Vec4 r) {
        float rad = selectRadius(p, r);
        float maxRad = std::min(b.x, b.y) - 0.5f;
        rad = std::clamp(rad, 0.0f, maxRad);
        Vec2 q = { std::abs(p.x) - b.x + rad, std::abs(p.y) - b.y + rad };
        Vec2 q_pos = { std::max(q.x, 0.0f), std::max(q.y, 0.0f) };
        float cornerDist = std::pow(std::pow(q_pos.x, 4.0f) + std::pow(q_pos.y, 4.0f), 0.25f) - rad;
        return (q.x > 0.0f && q.y > 0.0f) ? cornerDist : (std::max(q.x, q.y) - rad);
    }

    static float evaluateSurfaceSDF(Vec2 p, Vec2 halfSize, Vec4 radii, float slant) {
        Vec2 p_mod = p;
        float slantFactor = 1.0f - (p.y / std::max(halfSize.y, 1.0f)) * slant * 0.25f;
        p_mod.x /= std::max(slantFactor, 0.05f);
        float dist = sdRoundedBox4(p_mod, halfSize, radii);
        return dist * slantFactor;
    }

private slots:
    void initTestCase() {
        initEngineResources();
    }

    void testStd140MemoryLayout() {
        // Validação estrita std140 de 128 bytes e alinhamento de 16 bytes
        QCOMPARE(sizeof(SystaliaSurfaceProps), 128ULL);
        QCOMPARE(sizeof(SystaliaSurfaceProps) % 16, 0ULL);

        // Validação exata dos offsets de cada campo no UniformBlock
        QCOMPARE(offsetof(SystaliaSurfaceProps, matrix), 0ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, radii), 64ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, windowSize), 80ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, screenResolution), 88ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, slant), 96ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, ior), 100ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, chromaticDispersion), 104ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, causticIntensity), 108ULL);
        QCOMPARE(offsetof(SystaliaSurfaceProps, opacity), 112ULL);
    }

    void testShaderBytecodeAssets() {
        QVERIFY2(QFile::exists(QStringLiteral(":/shaders/valo_optical.vert.qsb")),
                 "Shader de vértice compilado não encontrado em :/shaders/valo_optical.vert.qsb");
        QVERIFY2(QFile::exists(QStringLiteral(":/shaders/valo_optical.frag.qsb")),
                 "Fragment shader compilado não encontrado em :/shaders/valo_optical.frag.qsb");
    }

    void testSdfMathematicalBounds() {
        Vec2 halfSize = { 430.0f, 290.0f };
        Vec4 radii = { 24.0f, 24.0f, 24.0f, 24.0f };
        float slant = 0.0f;

        // Ponto central (0, 0) deve ser profundamente interno
        float distCenter = evaluateSurfaceSDF({0.0f, 0.0f}, halfSize, radii, slant);
        QVERIFY(distCenter < 0.0f);
        QCOMPARE(distCenter, -290.0f);

        // Ponto interno
        float distInner = evaluateSurfaceSDF({200.0f, 150.0f}, halfSize, radii, slant);
        QVERIFY(distInner < 0.0f);

        // Ponto externo no eixo X
        float distOutsideX = evaluateSurfaceSDF({450.0f, 0.0f}, halfSize, radii, slant);
        QVERIFY(distOutsideX > 0.0f);

        // Ponto externo no eixo Y
        float distOutsideY = evaluateSurfaceSDF({0.0f, 310.0f}, halfSize, radii, slant);
        QVERIFY(distOutsideY > 0.0f);

        // Ponto na quina além do raio
        float distCornerOutside = evaluateSurfaceSDF({428.0f, 288.0f}, halfSize, radii, slant);
        QVERIFY(distCornerOutside > 0.0f);
    }
};

QTEST_MAIN(tst_SystaliaEngine)
#include "tst_SystaliaEngine.moc"
