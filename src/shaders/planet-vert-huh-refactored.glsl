#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out float biome;

//const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
//const vec4 lightPos = rotate() * vec4(3, 5, 3, 1);

float random3( vec3 p ) {
    return fract(sin(dot(p,vec3(127.1, 321.7, 653.2)))
    //return fract(sin(dot(p,vec3(u_Color.x * 127.1 + 23.5, u_Color.y * 321.7 + 83.9, u_Color.z * 653.2 + 39.4)))
                 *438.5453);
                 //*u_Time / 5. + u_Time * .1);
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

mat3 rotate3dx(float _angle){
    return mat3(cos(_angle),-sin(_angle), 0,
                sin(_angle),cos(_angle), 0,
                0, 0, 1);
}

vec3 random3perlin( vec3 p ) {
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                          dot(p, vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
                 //*iTime * .1);
}

float surflet(vec3 p, vec3 gridPoint) {
    vec3 t2 = abs(p - vec3(gridPoint));
    vec3 t = vec3(1.f) - 6.f * vec3(pow(t2.x, 5.f), pow(t2.y, 5.f), pow(t2.z, 5.f)) + 15.f * vec3(pow(t2.x, 4.f), pow(t2.y, 4.f), pow(t2.z, 4.f)) - 10.f * vec3(pow(t2.x, 3.f), pow(t2.y, 3.f), pow(t2.z, 3.f));
    vec3 gradient = random3perlin(vec3(gridPoint)) * 2. - vec3(1.,1.,1.);
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
    //SETUP

    //Universal stuff
    vec4 lightPos = vec4(rotate3dx(u_Time) * vec3(20, 0, 0), 1);
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

    //BIOME 1: Perlin Valley
    if (PerlinNoise3D(vec3(vs_Pos) * 2.) < .01) {    
        biome = 1.;
    }
    
    vec4 vs_Pos_perlin = vs_Pos + float(u_Time * .25f);
    float h = PerlinNoise3D(vec3(vs_Pos_perlin) * 2.f);
    vec4 newposition_perlin_valley = vec4(vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.f) + vs_Nor * h * .9f);

    //BIOME 2: FBM Cliffs
    vec4 vs_Pos_fbm = vs_Pos + float(u_Time * .15f);
    float g = fbm(vs_Pos_fbm.x * 2.f, vs_Pos_fbm.y * 2.f, vs_Pos_fbm.z * 2.f);

    vec4 newposition_fbm_cliffs = vec4(vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.f) + vs_Nor * g * .5f);

    //RENDER
    //Universal stuff
    vec4 newposition = newposition_fbm_cliffs;
    if (PerlinNoise3D(vec3(vs_Pos) * 2.) < .01) {
        biome = 1.;
        newposition = mix(newposition_perlin_valley, newposition_fbm_cliffs, .5f);
    }
    fs_Pos = newposition;
    vec4 modelposition = u_Model * newposition;   // Temporarily store the transformed vertex positions for use below
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                                // used to render the final positions of the geometry's vertices


}
