#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const vec3 a = vec3(0.5, 0.5, 0.5);
const vec3 b = vec3(0.5, 0.5, 0.5);
const vec3 c = vec3(1.0, 1.0, 1.0);
const vec3 d = vec3(0.3, 0.2, 0.1);

vec3 colorPalette(float t) {
    return (a + b * cos(6.28 * (t * c + d))) + .5 * vec3(u_Color);
}

float random3( vec3 p ) {
    //return fract(sin(dot(p,vec3(127.1, 321.7, 653.2)))
    return fract(sin(dot(p,vec3(u_Color.x * 127.1 + 23.5, u_Color.y * 321.7 + 83.9, u_Color.z * 653.2 + 39.4)))
                 //*438.5453);
                 *u_Time / 5. + u_Time * .1);
}

float interpNoise3D(float x, float y, float z) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = random3(vec3(intX, intY, intZ));
    float v2 = random3(vec3(intX + 1, intY, intZ));
    float v3 = random3(vec3(intX, intY + 1, intZ));
    float v4 = random3(vec3(intX + 1, intY + 1, intZ));
    float v5 = random3(vec3(intX, intY, intZ + 1));
    float v6 = random3(vec3(intX + 1, intY, intZ + 1));
    float v7 = random3(vec3(intX, intY + 1, intZ + 1));
    float v8 = random3(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i12 = mix(i1, i2, fractY);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);
    float i34 = mix(i3, i4, fractY);
    return mix(i12, i34, fractZ);
}

float fbm(float x, float y, float z) {
    float total = 0.;
    float persistence = 0.5;
    int octaves = 4;

    for(int i = 0; i <= octaves; i++) {
        float fi = float(i);
        float freq = pow(2., fi);
        float amp = pow(persistence, fi);

        total += interpNoise3D(x * freq,
                               y * freq,
                               z * freq) * amp;
    }
    return total;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        //NOISE
        diffuseColor = vec4(colorPalette(fbm(fs_Pos.x * 2. - u_Time, fs_Pos.y * 2. - u_Time, fs_Pos.z * 2. - u_Time)),1.);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
