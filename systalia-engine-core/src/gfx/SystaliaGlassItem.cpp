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

void SystaliaGlassItem::setSourceItem(QQuickItem *item)
{
    if (m_sourceItem == item)
        return;

    m_sourceItem = item;
    emit sourceItemChanged();
    update();
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

    // Configuração dos uniforms std140
    SystaliaSurfaceProps props;
    props.radii = m_radii;
    props.windowSize = QVector2D(static_cast<float>(width()), static_cast<float>(height()));
    props.slant = m_slant;
    props.ior = m_ior;
    props.chromaticDispersion = m_chromaticDispersion;
    props.causticIntensity = m_causticIntensity;
    props.opacity = m_surfaceOpacity * static_cast<float>(opacity());
    props.padding = 0.0f;
    material->setProperties(props);

    // Vinculação da textura a partir do QQuickItem/ShaderEffectSource
    QSGTexture *tex = nullptr;
    if (m_sourceItem && m_sourceItem->isTextureProvider()) {
        QSGTextureProvider *provider = m_sourceItem->textureProvider();
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
