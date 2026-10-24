#include "SystaliaGlassMaterial.hpp"
#include <cstring>

QSGMaterialType SystaliaGlassMaterial::s_type;

SystaliaGlassMaterialShader::SystaliaGlassMaterialShader()
{
    setFlag(UpdatesGraphicsPipelineState, true);
    // Carregamento dos shaders SPIR-V compilados via qsb
    setShaderFileName(VertexStage, QStringLiteral(":/shaders/valo_optical.vert.qsb"));
    setShaderFileName(FragmentStage, QStringLiteral(":/shaders/valo_optical.frag.qsb"));
}

bool SystaliaGlassMaterialShader::updateUniformData(RenderState &state,
                                                   QSGMaterial *newMaterial,
                                                   QSGMaterial *oldMaterial)
{
    Q_UNUSED(oldMaterial);
    QByteArray *buf = state.uniformData();
    if (!buf)
        return false;

    auto *mat = static_cast<SystaliaGlassMaterial *>(newMaterial);
    SystaliaSurfaceProps props = mat->properties();

    if (state.isMatrixDirty()) {
        props.matrix = state.combinedMatrix();
    }

    if (buf->size() < static_cast<int>(sizeof(SystaliaSurfaceProps))) {
        buf->resize(sizeof(SystaliaSurfaceProps));
    }

    std::memcpy(buf->data(), &props, sizeof(SystaliaSurfaceProps));
    return true;
}

void SystaliaGlassMaterialShader::updateSampledImage(RenderState &state,
                                                    int binding,
                                                    QSGTexture **texture,
                                                    QSGMaterial *newMaterial,
                                                    QSGMaterial *oldMaterial)
{
    Q_UNUSED(state);
    Q_UNUSED(oldMaterial);
    // binding 1 = u_BackdropTexture
    if (binding == 1) {
        auto *mat = static_cast<SystaliaGlassMaterial *>(newMaterial);
        if (mat && mat->texture()) {
            *texture = mat->texture();
        }
    }
}

bool SystaliaGlassMaterialShader::updateGraphicsPipelineState(RenderState &state,
                                                             GraphicsPipelineState *ps,
                                                             QSGMaterial *newMaterial,
                                                             QSGMaterial *oldMaterial)
{
    Q_UNUSED(state);
    Q_UNUSED(newMaterial);
    Q_UNUSED(oldMaterial);
    ps->blendEnable = true;
    ps->srcColor = GraphicsPipelineState::SrcAlpha;
    ps->dstColor = GraphicsPipelineState::OneMinusSrcAlpha;
    return true;
}

SystaliaGlassMaterial::SystaliaGlassMaterial()
{
    setFlag(Blending, true);
    setFlag(RequiresFullMatrixExceptTranslate, true);
}

QSGMaterialType *SystaliaGlassMaterial::type() const
{
    return &s_type;
}

QSGMaterialShader *SystaliaGlassMaterial::createShader(QSGRendererInterface::RenderMode renderMode) const
{
    Q_UNUSED(renderMode);
    return new SystaliaGlassMaterialShader();
}

int SystaliaGlassMaterial::compare(const QSGMaterial *other) const
{
    auto *o = static_cast<const SystaliaGlassMaterial *>(other);
    if (m_texture != o->m_texture)
        return m_texture < o->m_texture ? -1 : 1;
    return std::memcmp(&m_props, &o->m_props, sizeof(SystaliaSurfaceProps));
}
