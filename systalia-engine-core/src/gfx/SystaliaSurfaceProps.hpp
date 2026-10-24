#pragma once

#include <QMatrix4x4>
#include <QVector4D>
#include <QVector2D>

// Encapsulamento de matriz 4x4 em 64 bytes (16 floats) para alinhamento estrito std140.
struct alignas(16) Matrix4x4_std140 {
    float data[16] = {
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    };

    Matrix4x4_std140() = default;
    Matrix4x4_std140(const QMatrix4x4 &m) { m.copyDataTo(data); }
    Matrix4x4_std140 &operator=(const QMatrix4x4 &m) {
        m.copyDataTo(data);
        return *this;
    }
    operator QMatrix4x4() const { return QMatrix4x4(data); }
};
static_assert(sizeof(Matrix4x4_std140) == 64, "Matrix4x4_std140 deve ter exatamente 64 bytes");

// Estrutura de Uniforms com alinhamento estrito std140 (16-byte aligned, 128 bytes totais)
struct alignas(16) SystaliaSurfaceProps {
    Matrix4x4_std140 matrix;            // 64 bytes (offset 0..64)
    QVector4D radii;                    // 16 bytes (offset 64..80) -> (r_tl, r_tr, r_bl, r_br)
    QVector2D windowSize;               // 8 bytes  (offset 80..88)
    QVector2D screenResolution;         // 8 bytes  (offset 88..96)
    float slant = 0.0f;                 // 4 bytes  (offset 96..100)
    float ior = 1.12f;                  // 4 bytes  (offset 100..104)
    float chromaticDispersion = 0.025f; // 4 bytes  (offset 104..108)
    float causticIntensity = 0.65f;     // 4 bytes  (offset 108..112)
    float opacity = 1.0f;               // 4 bytes  (offset 112..116)
    float padding[3] = {0.0f, 0.0f, 0.0f}; // 12 bytes (offset 116..128)
};

static_assert(sizeof(SystaliaSurfaceProps) == 128, "SystaliaSurfaceProps deve ter exatamente 128 bytes para std140");
static_assert(sizeof(SystaliaSurfaceProps) % 16 == 0, "SystaliaSurfaceProps deve ter alinhamento de 16 bytes");
