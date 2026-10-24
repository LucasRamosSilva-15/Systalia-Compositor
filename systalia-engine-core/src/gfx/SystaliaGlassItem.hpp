#pragma once

#include <QQuickItem>
#include <QVector4D>
#include <QVector2D>
#include <QSGTexture>
#include <QSGTextureProvider>
#include <QtQml/qqmlregistration.h>
#include "SystaliaSurfaceProps.hpp"

class SystaliaGlassItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVector4D radii READ radii WRITE setRadii NOTIFY radiiChanged)
    Q_PROPERTY(float slant READ slant WRITE setSlant NOTIFY slantChanged)
    Q_PROPERTY(float ior READ ior WRITE setIor NOTIFY iorChanged)
    Q_PROPERTY(float chromaticDispersion READ chromaticDispersion WRITE setChromaticDispersion NOTIFY chromaticDispersionChanged)
    Q_PROPERTY(float causticIntensity READ causticIntensity WRITE setCausticIntensity NOTIFY causticIntensityChanged)
    Q_PROPERTY(float surfaceOpacity READ surfaceOpacity WRITE setSurfaceOpacity NOTIFY surfaceOpacityChanged)
    Q_PROPERTY(QQuickItem* sourceItem READ sourceItem WRITE setSourceItem NOTIFY sourceItemChanged)
    Q_PROPERTY(float radius READ uniformRadius WRITE setUniformRadius NOTIFY uniformRadiusChanged)

public:
    explicit SystaliaGlassItem(QQuickItem *parent = nullptr);
    ~SystaliaGlassItem() override;

    QVector4D radii() const { return m_radii; }
    void setRadii(const QVector4D &radii);

    float slant() const { return m_slant; }
    void setSlant(float slant);

    float ior() const { return m_ior; }
    void setIor(float ior);

    float chromaticDispersion() const { return m_chromaticDispersion; }
    void setChromaticDispersion(float dispersion);

    float causticIntensity() const { return m_causticIntensity; }
    void setCausticIntensity(float intensity);

    float surfaceOpacity() const { return m_surfaceOpacity; }
    void setSurfaceOpacity(float opacity);

    QQuickItem *sourceItem() const { return m_sourceItem; }
    void setSourceItem(QQuickItem *item);

    float uniformRadius() const { return m_radii.x(); }
    void setUniformRadius(float r);

signals:
    void radiiChanged();
    void slantChanged();
    void iorChanged();
    void chromaticDispersionChanged();
    void causticIntensityChanged();
    void surfaceOpacityChanged();
    void sourceItemChanged();
    void uniformRadiusChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data) override;
    void releaseResources() override;

private:
    QSGTexture *ensureFallbackTexture();

    QVector4D m_radii{24.0f, 24.0f, 24.0f, 24.0f};
    float m_slant = 0.0f;
    float m_ior = 1.12f;
    float m_chromaticDispersion = 0.025f;
    float m_causticIntensity = 0.65f;
    float m_surfaceOpacity = 1.0f;

    QQuickItem *m_sourceItem = nullptr;
    QSGTextureProvider *m_connectedProvider = nullptr;
    QSGTexture *m_fallbackTexture = nullptr;
};
