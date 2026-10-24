#version 450

layout(location = 0) in vec2 v_TexCoord;
layout(location = 1) in vec2 v_Position;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 u_Matrix;
    vec4 u_Radii; // (top_left, top_right, bottom_left, bottom_right)
    vec2 u_WindowSize;
    vec2 u_ScreenResolution; // Resolução física do ecrã (pixels GPU)
    float u_Slant;
    float u_Ior; // Índice de refração (ex: 1.15)
    float u_ChromaticDispersion;
    float u_CausticIntensity;
    float u_Opacity;
    float _pad0;
    float _pad1;
    float _pad2;
};

layout(binding = 1) uniform sampler2D u_BackdropTexture;

// Seleção analítica do raio de curvatura por quadrante
float selectRadius(vec2 p, vec4 r) {
    if (p.x < 0.0) {
        return (p.y < 0.0) ? r.x : r.z; // Superior esquerdo / Inferior esquerdo
    } else {
        return (p.y < 0.0) ? r.y : r.w; // Superior direito / Inferior direito
    }
}

// Signed Distance Field com 4 raios independentes e continuidade G2 (Squircle Superelipse ordem 4)
float sdRoundedBox4(vec2 p, vec2 b, vec4 r) {
    float rad = selectRadius(p, r);
    rad = clamp(rad, 0.0, min(b.x, b.y) - 0.5);
    vec2 q = abs(p) - b + vec2(rad);
    vec2 q_pos = max(q, 0.0);
    float cornerDist = pow(pow(q_pos.x, 4.0) + pow(q_pos.y, 4.0), 0.25) - rad;
    return (q.x > 0.0 && q.y > 0.0) ? cornerDist : (max(q.x, q.y) - rad);
}

// Avaliação analítica com inclinação lateral (slant / trapézio / domo)
float evaluateSurfaceSDF(vec2 p, vec2 halfSize, vec4 radii, float slant) {
    vec2 p_mod = p;
    float slantFactor = 1.0 - (p.y / max(halfSize.y, 1.0)) * slant * 0.25;
    p_mod.x /= max(slantFactor, 0.05);
    float dist = sdRoundedBox4(p_mod, halfSize, radii);
    return dist * slantFactor;
}

// Cálculo de normais analíticas através do gradiente subpixel do SDF
vec2 calculateNormal(vec2 p, vec2 halfSize, vec4 radii, float slant) {
    vec2 eps = vec2(0.5, 0.0);
    float dx = evaluateSurfaceSDF(p + eps.xy, halfSize, radii, slant) - evaluateSurfaceSDF(p - eps.xy, halfSize, radii, slant);
    float dy = evaluateSurfaceSDF(p + eps.yx, halfSize, radii, slant) - evaluateSurfaceSDF(p - eps.yx, halfSize, radii, slant);
    float len = length(vec2(dx, dy));
    return (len > 1e-5) ? vec2(dx, dy) / len : vec2(0.0, -1.0);
}

void main() {
    vec2 halfSize = u_WindowSize * 0.5;
    vec2 p = v_Position - halfSize;

    // Distância analítica à superfície
    float dist = evaluateSurfaceSDF(p, halfSize, u_Radii, u_Slant);

    // 1. Anti-aliasing analítico subpixel com descarte estrito fora da geometria
    // float fw = max(fwidth(dist), 0.001);
    // float alphaMask = 1.0 - smoothstep(-fw * 0.5, fw * 0.5, dist);
    // if (alphaMask <= 0.0001) {
    //     discard;
    // }

    // 2. Normais analíticas subpixel e distância à borda interna
    vec2 norm = calculateNormal(p, halfSize, u_Radii, u_Slant);
    float distFromEdge = max(-dist, 0.0);

    // 3. Menisco de borda restrito (6.0px a 8.0px) para supressão do "Rubber Ring Artifact"
    const float MENISCUS_MAX = 7.0;
    float meniscusFactor = clamp(1.0 - (distFromEdge / MENISCUS_MAX), 0.0, 1.0);
    float meniscusProfile = smoothstep(0.0, 1.0, meniscusFactor);

    // 4. Física Óptica Realista: Refração do domo da lente + menisco chanfrado de borda
    vec2 p_norm = p / max(halfSize, vec2(1.0));
    // Curvatura convexa pronunciada do corpo da lente
    vec2 bodyRefraction = p_norm * (u_Ior - 1.0) * 0.16;
    // Chanfro de borda tangencial
    vec2 meniscusRefraction = norm * (meniscusProfile * (u_Ior - 1.0) * 0.12);
    vec2 refractionOffset = bodyRefraction + meniscusRefraction;

    // 5. Coordenadas Screen-Space estritamente limitadas em [0.0, 1.0] (DPI mismatch fix)
    vec2 res = max(u_ScreenResolution, vec2(1.0));
    vec2 screenUV = clamp(gl_FragCoord.xy / res, vec2(0.0), vec2(1.0));

    // 6. Separação espectral de Cauchy para aberração cromática (canais R, G e B)
    vec2 refrUV_R = clamp(screenUV + refractionOffset * (1.0 - u_ChromaticDispersion * 2.0), vec2(0.001), vec2(0.999));
    vec2 refrUV_G = clamp(screenUV + refractionOffset, vec2(0.001), vec2(0.999));
    vec2 refrUV_B = clamp(screenUV + refractionOffset * (1.0 + u_ChromaticDispersion * 2.0), vec2(0.001), vec2(0.999));

    float colR = texture(u_BackdropTexture, refrUV_R).r;
    float colG = texture(u_BackdropTexture, refrUV_G).g;
    float colB = texture(u_BackdropTexture, refrUV_B).b;
    vec3 refractedBackdrop = vec3(colR, colG, colB);

    // 7. Reflexo de borda (specular rim highlight) refinado de 1.0px a 1.2px
    // Orientado estritamente para o zénite (-norm.y > 0.0) com clamp estrito
    float zenith = max(-norm.y, 0.0);
    float rimLine = exp(-pow((distFromEdge - 0.6) / 0.45, 2.0));
    float specularRim = clamp(rimLine * zenith, 0.0, 1.0);
    vec3 rimSpecularColor = clamp(vec3(1.0) * (specularRim * 0.95) + vec3(0.0, 0.898, 1.0) * (specularRim * 0.25), vec3(0.0), vec3(1.0));

    // 8. Feixe cáustico a 45°: Modulação diagonal contida sem estourar luz branca
    float diagCoord = clamp(dot(v_TexCoord, vec2(0.707106, 0.707106)), 0.0, 1.414);
    float causticBand = exp(-pow((diagCoord - 0.45) / 0.22, 2.0));
    vec3 causticTint = mix(vec3(0.0, 0.898, 1.0), vec3(1.0, 1.0, 1.0), 0.72);
    vec3 causticContribution = clamp(causticTint * (causticBand * u_CausticIntensity * 0.35), vec3(0.0), vec3(0.5));

    // 9. Base translúcida abissal VALO Glass (rgba(12, 28, 48))
    vec3 glassBase = vec3(0.047, 0.110, 0.188);
    vec3 finalColor = vec3(1.0, 0.0, 0.0); // mix(refractedBackdrop, glassBase, clamp(0.22 * u_Opacity, 0.0, 1.0));
    finalColor += causticContribution;
    finalColor += rimSpecularColor;
    finalColor = clamp(finalColor, vec3(0.0), vec3(1.0));

    // 10. Prova de Fogo da Refração: Saída 100% opaca (alpha = 1.0) no interior da máscara.
    // O fundo DEVE ser visível e sofrer deformação unicamente através do refractedBackdrop!
    fragColor = vec4(finalColor, 1.0);
}
