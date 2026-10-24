#pragma once

#include <QSGMaterial>
#include <QSGMaterialShader>
#include <QSGTexture>
#include "SystaliaSurfaceProps.hpp"

class SystaliaGlassMaterialShader : public QSGMaterialShader
{
public:
    SystaliaGlassMaterialShader();

    // Atualização de buffers de uniforms std140 para o shader SPIR-V
    bool updateUniformData(RenderState &state,
                           QSGMaterial *newMaterial,
                           QSGMaterial *oldMaterial) override;

    // Vinculação de textura de fundo amostrada (binding = 1, u_BackdropTexture)
    void updateSampledImage(RenderState &state,
                            int binding,
                            QSGTexture **texture,
                            QSGMaterial *newMaterial,
                            QSGMaterial *oldMaterial) override;

    // Configuração do estado de pipeline Vulkan (alpha blending)
    bool updateGraphicsPipelineState(RenderState &state,
                                    GraphicsPipelineState *ps,
                                    QSGMaterial *newMaterial,
                                    QSGMaterial *oldMaterial) override;

    // Alias semântico para atualização de buffers
    void updateUniformBuffer(RenderState &state, QSGMaterial *newMaterial, QSGMaterial *oldMaterial) {
        updateUniformData(state, newMaterial, oldMaterial);
    }
};

class SystaliaGlassMaterial : public QSGMaterial
{
public:
    SystaliaGlassMaterial();
    ~SystaliaGlassMaterial() override = default;

    QSGMaterialType *type() const override;
    QSGMaterialShader *createShader(QSGRendererInterface::RenderMode renderMode) const override;
    int compare(const QSGMaterial *other) const override;

    void setProperties(const SystaliaSurfaceProps &props) { m_props = props; }
    const SystaliaSurfaceProps &properties() const { return m_props; }

    void setTexture(QSGTexture *texture) { m_texture = texture; }
    QSGTexture *texture() const { return m_texture; }

private:
    SystaliaSurfaceProps m_props;
    QSGTexture *m_texture = nullptr;
    static QSGMaterialType s_type;
};
