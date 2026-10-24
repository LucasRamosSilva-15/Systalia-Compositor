#include "SystaliaGlassMaterial.hpp"
#include <cstring>

QSGMaterialType SystaliaGlassMaterial::s_type;

#include <QFile>

SystaliaGlassMaterialShader::SystaliaGlassMaterialShader()
{
    setFlag(UpdatesGraphicsPipelineState, true);
    bool vertExists = QFile::exists(QStringLiteral(":/shaders/valo_optical.vert.qsb"));
    bool fragExists = QFile::exists(QStringLiteral(":/shaders/valo_optical.frag.qsb"));
    fprintf(stderr, "[SGE-DEBUG] SHADER FILES EXIST: vert=%d, frag=%d\n", vertExists, fragExists);

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
    if (!buf) {
        fprintf(stderr, "[SGE-DEBUG] updateUniformData: buf is NULL!\n");
        return false;
    }

    auto *mat = static_cast<SystaliaGlassMaterial *>(newMaterial);
    SystaliaSurfaceProps props = mat->properties();

    // ALWAYS ensure matrix has state.combinedMatrix()!
    props.matrix = state.combinedMatrix();

    if (buf->size() < static_cast<int>(sizeof(SystaliaSurfaceProps))) {
        buf->resize(sizeof(SystaliaSurfaceProps));
    }

    std::memcpy(buf->data(), &props, sizeof(SystaliaSurfaceProps));
    static int callCount = 0;
    if (callCount++ < 2) {
        const float *m = state.combinedMatrix().constData();
        fprintf(stderr, "[SGE-DEBUG] MATRIX: [%.2f, %.2f, %.2f, %.2f] [%.2f, %.2f, %.2f, %.2f] [%.2f, %.2f, %.2f, %.2f] [%.2f, %.2f, %.2f, %.2f]\n",
                m[0], m[1], m[2], m[3],
                m[4], m[5], m[6], m[7],
                m[8], m[9], m[10], m[11],
                m[12], m[13], m[14], m[15]);
        fprintf(stderr, "[SGE-DEBUG] updateUniformData CALLED! size=%d, winSize=(%f, %f), scrRes=(%f, %f)\n",
                buf->size(), props.windowSize.x(), props.windowSize.y(),
                props.screenResolution.x(), props.screenResolution.y());
    }
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
            static int texCount = 0;
            if (texCount++ < 5) {
                fprintf(stderr, "[SGE-DEBUG] updateSampledImage binding=1, tex=%p, sz=(%d, %d)\n",
                        mat->texture(),
                        mat->texture()->textureSize().width(),
                        mat->texture()->textureSize().height());
            }
        } else {
            fprintf(stderr, "[SGE-DEBUG] updateSampledImage binding=1, tex is NULL!\n");
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
    fprintf(stderr, "[SGE-DEBUG] updateGraphicsPipelineState CALLED!\n");
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
