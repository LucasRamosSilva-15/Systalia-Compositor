#include "SystaliaGlassItem.hpp"
#include "SystaliaGlassMaterial.hpp"
#include <QSGGeometryNode>
#include <QSGGeometry>
#include <QQuickWindow>
#include <QImage>

SystaliaGlassItem::SystaliaGlassItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

SystaliaGlassItem::~SystaliaGlassItem()
{
    releaseResources();
}

void SystaliaGlassItem::setRadii(const QVector4D &radii)
{
    if (m_radii != radii) {
        m_radii = radii;
        emit radiiChanged();
        update();
    }
}

void SystaliaGlassItem::setUniformRadius(float r)
{
    setRadii(QVector4D(r, r, r, r));
    emit uniformRadiusChanged();
}

void SystaliaGlassItem::setSlant(float slant)
{
    if (!qFuzzyCompare(m_slant, slant)) {
        m_slant = slant;
        emit slantChanged();
        update();
    }
}

void SystaliaGlassItem::setIor(float ior)
{
    if (!qFuzzyCompare(m_ior, ior)) {
        m_ior = ior;
        emit iorChanged();
        update();
    }
}

void SystaliaGlassItem::setChromaticDispersion(float dispersion)
{
    if (!qFuzzyCompare(m_chromaticDispersion, dispersion)) {
        m_chromaticDispersion = dispersion;
        emit chromaticDispersionChanged();
        update();
    }
}

void SystaliaGlassItem::setCausticIntensity(float intensity)
{
    if (!qFuzzyCompare(m_causticIntensity, intensity)) {
        m_causticIntensity = intensity;
        emit causticIntensityChanged();
        update();
    }
}

void SystaliaGlassItem::setSurfaceOpacity(float opacity)
{
    if (!qFuzzyCompare(m_surfaceOpacity, opacity)) {
        m_surfaceOpacity = opacity;
        emit surfaceOpacityChanged();
        update();
    }
}

void SystaliaGlassItem::setBackdropSource(QQuickItem *item)
{
    if (m_backdropSource == item)
        return;

    if (m_connectedProvider) {
        disconnect(m_connectedProvider, &QSGTextureProvider::textureChanged,
                   this, &QQuickItem::update);
        m_connectedProvider = nullptr;
    }

    m_backdropSource = item;
    emit backdropSourceChanged();
    update();
}

void SystaliaGlassItem::setScreenResolution(const QVector2D &res)
{
    if (m_screenResolution != res) {
        m_screenResolution = res;
        emit screenResolutionChanged();
        update();
    }
}

QSGTexture *SystaliaGlassItem::ensureFallbackTexture()
{
    if (!m_fallbackTexture && window()) {
        QImage fallback(4, 4, QImage::Format_RGBA8888);
        fallback.fill(QColor(12, 28, 48, 255));
        m_fallbackTexture = window()->createTextureFromImage(fallback, QQuickWindow::TextureIsOpaque);
    }
    return m_fallbackTexture;
}

QSGNode *SystaliaGlassItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *data)
{
    Q_UNUSED(data);
    auto *node = static_cast<QSGGeometryNode *>(oldNode);

    if (width() <= 0 || height() <= 0) {
        delete node;
        return nullptr;
    }

    if (!node) {
        node = new QSGGeometryNode();
        auto *geometry = new QSGGeometry(QSGGeometry::defaultAttributes_TexturedPoint2D(), 4);
        geometry->setDrawingMode(QSGGeometry::DrawTriangleStrip);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        auto *material = new SystaliaGlassMaterial();
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    // Geometria do quad local do item
    QSGGeometry::updateTexturedRectGeometry(node->geometry(),
                                            QRectF(0, 0, width(), height()),
                                            QRectF(0, 0, 1, 1));
    node->markDirty(QSGNode::DirtyGeometry);

    auto *material = static_cast<SystaliaGlassMaterial *>(node->material());

    // Configuração dos uniforms std140 (128 bytes)
    SystaliaSurfaceProps props;
    props.radii = m_radii;
    props.windowSize = QVector2D(static_cast<float>(width()), static_cast<float>(height()));

    // Resolução de ecrã para Screen-Space normalizado com suporte a High-DPI
    QVector2D res = m_screenResolution;
    if (res.x() <= 0.0f || res.y() <= 0.0f) {
        if (window()) {
            res = QVector2D(window()->width(), window()->height());
        } else {
            res = props.windowSize;
        }
    }
    const float dpr = window() ? static_cast<float>(window()->devicePixelRatio()) : 1.0f;
    props.screenResolution = QVector2D(res.x() * dpr, res.y() * dpr);

    props.slant = m_slant;
    props.ior = m_ior;
    props.chromaticDispersion = m_chromaticDispersion;
    props.causticIntensity = m_causticIntensity;
    props.opacity = m_surfaceOpacity;
    props.padding[0] = 0.0f;
    props.padding[1] = 0.0f;
    props.padding[2] = 0.0f;
    material->setProperties(props);

    // Extração ativa da textura do backdropSource via textureProvider()
    QSGTexture *tex = nullptr;
    if (m_backdropSource && m_backdropSource->isTextureProvider()) {
        QSGTextureProvider *provider = m_backdropSource->textureProvider();
        if (provider) {
            if (m_connectedProvider != provider) {
                if (m_connectedProvider) {
                    disconnect(m_connectedProvider, &QSGTextureProvider::textureChanged,
                               this, &QQuickItem::update);
                }
                m_connectedProvider = provider;
                connect(m_connectedProvider, &QSGTextureProvider::textureChanged,
                        this, &QQuickItem::update, Qt::UniqueConnection);
            }
            tex = provider->texture();
        }
    }

    if (!tex) {
        tex = ensureFallbackTexture();
    }

    material->setTexture(tex);
    node->markDirty(QSGNode::DirtyMaterial);

    return node;
}

void SystaliaGlassItem::releaseResources()
{
    if (m_connectedProvider) {
        disconnect(m_connectedProvider, &QSGTextureProvider::textureChanged,
                   this, &QQuickItem::update);
        m_connectedProvider = nullptr;
    }
    delete m_fallbackTexture;
    m_fallbackTexture = nullptr;
}
