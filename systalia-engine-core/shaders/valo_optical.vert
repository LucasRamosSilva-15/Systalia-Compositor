#version 450

layout(location = 0) in vec4 aVertex;
layout(location = 1) in vec2 aTexCoord;

layout(location = 0) out vec2 v_TexCoord;
layout(location = 1) out vec2 v_Position;

layout(std140, binding = 0) uniform buf {
    mat4 u_Matrix;
    vec4 u_Radii; // (top_left, top_right, bottom_left, bottom_right)
    vec2 u_WindowSize;
    vec2 u_ScreenResolution;
    float u_Slant;
    float u_Ior;
    float u_ChromaticDispersion;
    float u_CausticIntensity;
    float u_Opacity;
    float _pad0;
    float _pad1;
    float _pad2;
};

void main() {
    v_TexCoord = aTexCoord;
    v_Position = aVertex.xy;
    gl_Position = u_Matrix * aVertex;
}
