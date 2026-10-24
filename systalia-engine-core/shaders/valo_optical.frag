#version 450

layout(location = 0) in vec2 v_TexCoord;
layout(location = 1) in vec2 v_Position;

layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 u_Matrix;
    vec4 u_Radii;            // (top_left, top_right, bottom_left, bottom_right)
    vec2 u_WindowSize;
    vec2 u_ScreenResolution; // Resolução física do ecrã (pixels GPU)
    float u_Slant;
    float u_Ior;             // Índice de refração (ex: 1.00 a 1.50)
    float u_ChromaticDispersion;
    float u_CausticIntensity;
    float u_Opacity;
    float _pad0;
    float _pad1;
    float _pad2;
};

layout(binding = 1) uniform sampler2D u_BackdropTexture;

float selectRadius(vec2 p, vec4 r) {
    if (p.x < 0.0) {
        return (p.y < 0.0) ? r.x : r.z;
    } else {
        return (p.y < 0.0) ? r.y : r.w;
    }
}

// SDF Squircle G2 de 4ª ordem
float sdRoundedBox4(vec2 p, vec2 b, vec4 r) {
    float rad = selectRadius(p, r);
    rad = clamp(rad, 0.0, min(b.x, b.y) - 0.5);
    vec2 q = abs(p) - b + vec2(rad);
    vec2 q_pos = max(q, 0.0);
    float cornerDist = pow(pow(q_pos.x, 4.0) + pow(q_pos.y, 4.0), 0.25) - rad;
    return (q.x > 0.0 && q.y > 0.0) ? cornerDist : (max(q.x, q.y) - rad);
}

float evaluateSurfaceSDF(vec2 p, vec2 halfSize, vec4 radii, float slant) {
    vec2 p_mod = p;
    float slantFactor = 1.0 - (p.y / max(halfSize.y, 1.0)) * slant * 0.25;
    p_mod.x /= max(slantFactor, 0.05);
    float dist = sdRoundedBox4(p_mod, halfSize, radii);
    return dist * slantFactor;
}

vec2 calculateNormal(vec2 p, vec2 halfSize, vec4 radii, float slant) {
    vec2 eps = vec2(0.5, 0.0);
    float dx = evaluateSurfaceSDF(p + eps.xy, halfSize, radii, slant) - evaluateSurfaceSDF(p - eps.xy, halfSize, radii, slant);
    float dy = evaluateSurfaceSDF(p + eps.yx, halfSize, radii, slant) - evaluateSurfaceSDF(p - eps.yx, halfSize, radii, slant);
    float len = length(vec2(dx, dy));
    return (len > 1e-5) ? vec2(dx, dy) / len : vec2(0.0, -1.0);
}

// Amostrador com filtro óptico de 9-taps (Dual-Ring Blur) para dispersão acetinada do vidro
vec3 sampleBlurredChromatic(vec2 baseUV, vec2 refrOffset, float dispersion, vec2 texelSize) {
    vec2 uvR = clamp(baseUV + refrOffset * (1.0 - dispersion * 3.5), vec2(0.002), vec2(0.998));
    vec2 uvG = clamp(baseUV + refrOffset,                           vec2(0.002), vec2(0.998));
    vec2 uvB = clamp(baseUV + refrOffset * (1.0 + dispersion * 3.5), vec2(0.002), vec2(0.998));

    const vec2 offsets[9] = vec2[9](
        vec2( 0.0,  0.0),
        vec2(-1.5, -1.5), vec2( 1.5, -1.5),
        vec2(-1.5,  1.5), vec2( 1.5,  1.5),
        vec2( 0.0, -2.5), vec2( 0.0,  2.5),
        vec2(-2.5,  0.0), vec2( 2.5,  0.0)
    );
    const float weights[9] = float[9](
        0.24,
        0.11, 0.11, 0.11, 0.11,
        0.08, 0.08, 0.08, 0.08
    );

    vec3 accum = vec3(0.0);
    for (int i = 0; i < 9; ++i) {
        vec2 delta = offsets[i] * texelSize * 2.2;
        float r = texture(u_BackdropTexture, clamp(uvR + delta, vec2(0.001), vec2(0.999))).r;
        float g = texture(u_BackdropTexture, clamp(uvG + delta, vec2(0.001), vec2(0.999))).g;
        float b = texture(u_BackdropTexture, clamp(uvB + delta, vec2(0.001), vec2(0.999))).b;
        accum += vec3(r, g, b) * weights[i];
    }
    return accum;
}

void main() {
    vec2 halfSize = u_WindowSize * 0.5;
    vec2 p = v_Position - halfSize;

    // 1. Recorte Analítico SDF G2 e Anti-Aliasing Subpixel
    float dist = evaluateSurfaceSDF(p, halfSize, u_Radii, u_Slant);
    float fw = max(fwidth(dist), 0.75);
    float alphaMask = 1.0 - smoothstep(-fw * 0.5, fw * 0.5, dist);
    if (alphaMask <= 0.001) {
        discard;
    }

    // 2. Normais Analíticas e Menisco de Borda (14px para efeito lente visível sem Rubber Ring)
    vec2 norm = calculateNormal(p, halfSize, u_Radii, u_Slant);
    float distFromEdge = max(-dist, 0.0);

    const float MENISCUS_WIDTH = 14.0;
    float edgeFactor = clamp(1.0 - (distFromEdge / MENISCUS_WIDTH), 0.0, 1.0);
    float meniscusCurve = pow(edgeFactor, 2.0);

    // 3. Deflexão de Lente (Corpo Convexo + Menisco de Borda Snelliano)
    vec2 p_norm = p / max(halfSize, vec2(1.0));
    float iorDelta = (u_Ior - 1.0);
    vec2 bodyRefraction = -p_norm * iorDelta * 0.12;
    vec2 edgeRefraction = -norm * (meniscusCurve * iorDelta * 0.085);
    vec2 refractionOffset = bodyRefraction + edgeRefraction;

    // 4. Coordenadas Screen-Space Reais
    vec2 res = max(u_ScreenResolution, vec2(1.0));
    vec2 screenUV = clamp(gl_FragCoord.xy / res, vec2(0.0), vec2(1.0));
    vec2 texelSize = 1.0 / res;

    // 5. Amostragem Refratada com Dispersão de Cauchy + Difusão Óptica
    vec3 refractedBackdrop = sampleBlurredChromatic(screenUV, refractionOffset, u_ChromaticDispersion, texelSize);

    // Boost de Saturação Rec.709 (135%) para manter cores vibrantes através do cristal
    float luma = dot(refractedBackdrop, vec3(0.2126, 0.7152, 0.0722));
    refractedBackdrop = clamp(mix(vec3(luma), refractedBackdrop, 1.35), vec3(0.0), vec3(1.0));

    // 6. Substrato Abissal VALO Glass
    vec3 glassBase = mix(vec3(0.035, 0.095, 0.175), vec3(0.055, 0.145, 0.255), v_TexCoord.y);
    vec3 composite = mix(refractedBackdrop, glassBase, clamp(u_Opacity, 0.05, 0.90));

    // 7. Feixe Cáustico Planar a 45° com Decomposição Espectral Suave
    float diag = (v_TexCoord.x * 0.7071 + (1.0 - v_TexCoord.y) * 0.7071);
    float beam = exp(-pow((diag - 0.65) / 0.20, 2.0)) * u_CausticIntensity;
    vec3 causticSpectral = mix(vec3(0.0, 0.898, 1.0), vec3(0.85, 0.96, 1.0), smoothstep(0.45, 0.85, diag));
    composite += causticSpectral * beam * 0.28;

    // 8. Specular Rim Light Zenital Fino (1.2px no topo e quinas superiores)
    float zenith = clamp(-norm.y * 0.85 + 0.15, 0.0, 1.0);
    float rimMask = exp(-pow((distFromEdge - 0.8) / 0.65, 2.0));
    float specularRim = rimMask * zenith * 0.90;
    composite += mix(vec3(1.0), vec3(0.0, 0.898, 1.0), 0.25) * specularRim;

    // Oclusão de contato sutil na borda inferior
    float bottomOcc = clamp(norm.y, 0.0, 1.0) * rimMask * 0.25;
    composite -= vec3(bottomOcc);

    fragColor = vec4(clamp(composite, vec3(0.0), vec3(1.0)), alphaMask);
}