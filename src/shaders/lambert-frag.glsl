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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
                 //*iTime * .1);
}

float surflet(vec3 p, vec3 gridPoint) {
    vec3 t2 = abs(p - vec3(gridPoint));
    vec3 t = vec3(1.f) - 6.f * vec3(pow(t2.x, 5.f), pow(t2.y, 5.f), pow(t2.z, 5.f)) + 15.f * vec3(pow(t2.x, 4.f), pow(t2.y, 4.f), pow(t2.z, 4.f)) - 10.f * vec3(pow(t2.x, 3.f), pow(t2.y, 3.f), pow(t2.z, 3.f));
    vec3 gradient = random3(vec3(gridPoint)) * 2. - vec3(1.,1.,1.);
    vec3 diff = p - vec3(gridPoint);
    float height = dot(diff, gradient);
    return height * t.x * t.y * t.z;
    return 0.f;
}

float PerlinNoise3D(vec3 p) {
    //p = p + vec3(0., u_Time * .5, 0.);
    p = p + vec3(0., .5, 0.);
    float surfletSum = 0.f;
    vec3 floored = vec3(floor(p.x), floor(p.y), floor(p.z));
	for(int dx = 0; dx <= 1; ++dx) {
	    for(int dy = 0; dy <= 1; ++dy) {
            for(int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet(p, floored + vec3(dx, dy, dz));
			}
		}
	}
	return surfletSum;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = fs_Col;
        //vec4 diffuseColor = u_Color;
        // float modifier = PerlinNoise3D(vec3(fs_Pos) * 20.);
        // if (modifier > .25f) {
        //     diffuseColor = diffuseColor * modifier;
        // }

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
