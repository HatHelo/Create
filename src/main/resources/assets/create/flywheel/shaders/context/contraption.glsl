#use "flywheel:context/fog.glsl"

uniform sampler3D uLightVolume;

uniform sampler2D uBlockAtlas;
uniform sampler2D uLightMap;

uniform vec3 uLightBoxSize;
uniform vec3 uLightBoxMin;
uniform mat4 uModel;

uniform float uTime;
uniform mat4 uViewProjection;
uniform vec3 uCameraPos;

void FLWFinalizeNormal(inout vec3 normal) {
    mat3 m;
    m[0] = uModel[0].xyz;
    m[1] = uModel[1].xyz;
    m[2] = uModel[2].xyz;
    normal = m * normal;
}

#if defined(VERTEX_SHADER)

out vec3 BoxCoord;

void FLWFinalizeWorldPos(inout vec4 worldPos) {
    worldPos = uModel * worldPos;

    BoxCoord = (worldPos.xyz - uLightBoxMin) / uLightBoxSize;

    FragDistance = max(length(worldPos.xz), abs(worldPos.y)); // cylindrical fog

    gl_Position = uViewProjection * worldPos;
}

#elif defined(FRAGMENT_SHADER)
#use "flywheel:core/lightutil.glsl"

#define ALPHA_DISCARD 0.1
// optimize discard usage
#if defined(ALPHA_DISCARD)
#if defined(GL_ARB_conservative_depth)
layout (depth_greater) out float gl_FragDepth;
#endif
#endif

in vec3 BoxCoord;

out vec4 FragColor;

vec4 FLWBlockTexture(vec2 texCoords) {
    return texture(uBlockAtlas, texCoords);
}

void FLWFinalizeColor(vec4 color) {
    float a = color.a;
    float fog = clamp(FLWFogFactor(), 0., 1.);

    color = mix(uFogColor, color, fog);
    color.a = a;

    #if defined(ALPHA_DISCARD)
    if (color.a < ALPHA_DISCARD) {
        discard;
    }
    #endif

    FragColor = color;
}

vec4 FLWLight(vec2 lightCoords) {
    lightCoords = max(lightCoords, texture(uLightVolume, BoxCoord).rg);

    return texture(uLightMap, shiftLight(lightCoords));
}

#endif
