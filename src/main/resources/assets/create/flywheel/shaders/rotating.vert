#define PI 3.1415926538

#use "flywheel:core/matutils.glsl"
#use "flywheel:core/diffuse.glsl"

struct Rotating {
    vec2 light;
    vec4 color;
    vec3 pos;
    float speed;
    float offset;
    vec3 axis;
};

#use "flywheel:data/modelvertex.glsl"
#use "flywheel:block.frag"

mat4 kineticRotation(float offset, float speed, vec3 axis) {
    float degrees = offset + uTime * speed * 3./10.;
    float angle = fract(degrees / 360.) * PI * 2.;

    return rotate(axis, angle);
}

#if defined(VERTEX_SHADER)
BlockFrag vertex(Vertex v, Rotating instance) {
    mat4 spin = kineticRotation(instance.offset, instance.speed, instance.axis);

    vec4 worldPos = spin * vec4(v.pos - .5, 1.);
    worldPos += vec4(instance.pos + .5, 0.);

    vec3 norm = modelToNormal(spin) * v.normal;

    FLWFinalizeWorldPos(worldPos);
    FLWFinalizeNormal(norm);

    BlockFrag b;
    b.diffuse = diffuse(norm);
    b.texCoords = v.texCoords;
    b.light = instance.light;

    #if defined(DEBUG_RAINBOW)
    b.color = instance.color;
    #elif defined(DEBUG_NORMAL)
    b.color = vec4(norm, 1.);
    #else
    b.color = vec4(1.);
    #endif

    return b;
}
#endif
