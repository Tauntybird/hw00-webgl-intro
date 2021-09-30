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

uniform vec3 u_CamPos;

uniform float u_FbmOffset;

uniform float u_LandWaterRatio;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out float biome;
out float tree;

//const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
//const vec4 lightPos = rotate() * vec4(3, 5, 3, 1);

const vec3 a = vec3(0.5, 0.5, 0.5);
const vec3 b = vec3(0.5, 0.5, 0.5);
const vec3 c = vec3(1.0, 1.0, 1.0);
const vec3 d = vec3(0.3, 0.2, 0.1);

vec3 colorPalette(float t) {
    return (a + b * cos(6.28 * (t * c + d))) + .5;
    //* vec3(u_Color);
}

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

mat3 rotate3dy(float _angle){
    return mat3(cos(_angle), 0, sin(_angle),
                0, 1, 0,
                -sin(_angle), 0, cos(_angle));
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

float gain(float x, float k) 
{
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

void main()
{
    tree = 0.f;
    vec4 lightPos = vec4(rotate3dy(u_Time) * vec3(20, 0, 0), 1);
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    mat3 invTranspose = mat3(u_ModelInvTr);
    // fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

    vec4 newposition_perlin_valley;
    vec4 newposition_fbm_cliffs;

    //BIOME 1: Ocean
    //if (PerlinNoise3D(vec3(vs_Pos) * 2.) < .01) {
    if (fbm(vs_Pos.x * 2.f + u_FbmOffset, vs_Pos.y * 2.f + u_FbmOffset, vs_Pos.z * 2.f + u_FbmOffset) < u_LandWaterRatio / 10. + .5) {
        
        biome = 1.;

        vec4 vs_Pos_perlin = vs_Pos + float(u_Time * .15f);
        float h = PerlinNoise3D(vec3(vs_Pos_perlin) * 7.f);
        newposition_perlin_valley = vec4(vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.f) + vs_Nor * h * .02f);

        fs_Pos = newposition_perlin_valley;

        vec4 modelposition = u_Model * newposition_perlin_valley;   // Temporarily store the transformed vertex positions for use below

        fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

        gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                                // used to render the final positions of the geometry's vertices

        vec3 tangent = cross(vec3(0, 1, 0), vec3(vs_Nor));
        vec3 bitangent = cross(vec3(vs_Nor), tangent);
        float alpha = .0001f;
        // vec3 p1 = f(vec3(vs_Pos) + alpha * tangent);
        // vec3 p2 = f(vec3(vs_Pos) + alpha * bitangent);
        // vec3 p3 = f(vec3(vs_Pos) - alpha * tangent);
        // vec3 p4 = f(vec3(vs_Pos) - alpha * bitangent);

        // vec3 p2 = PerlinNoise3D((vec3(vs_Pos) + alpha * bitangent) * 10.f);
        // vec3 p3 = PerlinNoise3D((vec3(vs_Pos) - alpha * tangent) * 10.f);
        // vec3 p4 = PerlinNoise3D((vec3(vs_Pos) - alpha * bitangent) * 10.f);
        
        vec3 p1_o = vec3(vs_Pos_perlin) + alpha * tangent;
        vec3 p1 = vec3(vec4(p1_o.x, p1_o.y, p1_o.z, 1.f) + vs_Nor * PerlinNoise3D(p1_o * 7.f) * .02f);
        vec3 p2_o = vec3(vs_Pos_perlin) + alpha * bitangent;
        vec3 p2 = vec3(vec4(p2_o.x, p2_o.y, p2_o.z, 1.f) + vs_Nor * PerlinNoise3D(p2_o * 7.f) * .02f);
        vec3 p3_o = vec3(vs_Pos_perlin) - alpha * tangent;
        vec3 p3 = vec3(vec4(p3_o.x, p3_o.y, p3_o.z, 1.f) + vs_Nor * PerlinNoise3D(p3_o * 7.f) * .02f);
        vec3 p4_o = vec3(vs_Pos_perlin) - alpha * bitangent;
        vec3 p4 = vec3(vec4(p4_o.x, p4_o.y, p4_o.z, 1.f) + vs_Nor * PerlinNoise3D(p4_o * 7.f) * .02f);
        //fs_Nor = vec4(invTranspose * cross(p2 - p4, p1 - p3), 0);
        fs_Nor = vec4(-cross(p2 - p4, p1 - p3),0.);
    }

    //BIOME 2: Brown Mountains (Land)
    else {
        
        vec4 vs_Pos_fbm = (vs_Pos + float(u_Time * .05f));
        float h = fbm(vs_Pos_fbm.x * 5.f + u_FbmOffset, vs_Pos_fbm.y * 5.f + u_FbmOffset, vs_Pos_fbm.z * 5.f + u_FbmOffset) - gain(fbm(vs_Pos.x * 2.f + u_FbmOffset, vs_Pos.y * 2.f + u_FbmOffset, vs_Pos.z * 2.f + u_FbmOffset),.9f) + .5f;
        
        vec4 newposition_fbm_cliffs = vec4(vec4(vs_Pos.x, vs_Pos.y, vs_Pos.z, 1.f) + vs_Nor * h * .25f);
        fs_Pos = newposition_fbm_cliffs;
        vec4 modelposition = u_Model * newposition_fbm_cliffs;   // Temporarily store the transformed vertex positions for use below
        fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
        gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                                // used to render the final positions of the geometry's vertices
        // fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

        //snow caps
        vec4 diffuseColor = vec4(colorPalette(length(vs_Pos)), 1.);
        float snowy = clamp(0.f, .05f, 1. - abs(.5f * pow(vs_Pos.y, 2.)));
        diffuseColor = diffuseColor + snowy * vec4(c, 1.f) / 3.;
        for (int i = 0; i < 4; i++) {
            diffuseColor[i] = clamp(0.f, 1.f, diffuseColor[i]);
        }

        //BIOME 3: Forests -------------------------------------------------------
        vec4 tree_diffuseColor = vec4(.0f, 1.f, .0f, 1.f);

        float modifier = PerlinNoise3D(vec3(vs_Pos) * 200.) + 2.5f;
        modifier = clamp(modifier, 0.f, 100.f);
        //if (modifier > .25f) {
            tree_diffuseColor = tree_diffuseColor * modifier;
            //fs_Pos = modelposition + fs_Nor * modifier * 5.f;
        //}

        // vec4 vs_Pos_new = vs_Nor * modifier * .18f;
        vec4 vs_Pos_modifier = vs_Nor * modifier * .18f;
        float tree_height = clamp((1.2f - abs(pow(vs_Pos.y, 2.))), 0.f, .5f);
        vec4 vs_Pos_new = newposition_fbm_cliffs + vs_Pos_modifier * tree_height;

        // if (length(vs_Pos_modifier) >= .5f && vs_Pos.y < 0.5 && vs_Pos.y > -0.5) {
        if (length(vs_Pos_modifier) >= .5f && length(vs_Pos_new) > length(fs_Pos)) {
            //fs_Col = vec4(0.5f, 0.f, 0.f, 1.f);
            // vs_Pos_new = vs_Pos;
            fs_Col = tree_diffuseColor;                         // Pass the vertex colors to the fragment shader for interpolation
            vec4 modelposition = u_Model * vs_Pos_new;   // Temporarily store the transformed vertex positions for use below

            fs_Pos = modelposition;

            fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

            gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                                    // used to render the final positions of the geometry's vertices
            tree = 1.f;
        }
        //---------------------------------------------------------------------
        else {
            fs_Col = diffuseColor;  
            vec3 tangent = cross(vec3(0, 1, 0), vec3(vs_Nor));
            vec3 bitangent = cross(vec3(vs_Nor), tangent);
            float alpha = .00001f;
            vec3 p1_o = vec3(vs_Pos_fbm + u_FbmOffset) + alpha * tangent;
            float p1_h = fbm(p1_o.x * 5.f, p1_o.y * 5.f, p1_o.z * 5.f) - gain(fbm(vs_Pos.x * 2.f, vs_Pos.y * 2.f, vs_Pos.z * 2.f),.9f) + .5f;
            vec3 p1 = vec3(vec4(p1_o.x, p1_o.y, p1_o.z, 1.f) + vs_Nor * p1_h * .05f);
            vec3 p2_o = vec3(vs_Pos_fbm + u_FbmOffset) + alpha * bitangent;
            float p2_h = fbm(p2_o.x * 5.f, p2_o.y * 5.f, p2_o.z * 5.f) - gain(fbm(vs_Pos.x * 2.f, vs_Pos.y * 2.f, vs_Pos.z * 2.f),.9f) + .5f;
            vec3 p2 = vec3(vec4(p2_o.x, p2_o.y, p2_o.z, 1.f) + vs_Nor * p2_h * .05f);
            vec3 p3_o = vec3(vs_Pos_fbm + u_FbmOffset) - alpha * tangent;
            float p3_h = fbm(p3_o.x * 5.f, p3_o.y * 5.f, p3_o.z * 5.f) - gain(fbm(vs_Pos.x * 2.f, vs_Pos.y * 2.f, vs_Pos.z * 2.f),.9f) + .5f;
            vec3 p3 = vec3(vec4(p3_o.x, p3_o.y, p3_o.z, 1.f) + vs_Nor * p3_h * .05f);
            vec3 p4_o = vec3(vs_Pos_fbm + u_FbmOffset) - alpha * bitangent;
            float p4_h = fbm(p4_o.x * 5.f, p4_o.y * 5.f, p4_o.z * 5.f) - gain(fbm(vs_Pos.x * 2.f, vs_Pos.y * 2.f, vs_Pos.z * 2.f),.9f) + .5f;
            vec3 p4 = vec3(vec4(p4_o.x, p4_o.y, p4_o.z, 1.f) + vs_Nor * p4_h * .05f);
            //fs_Nor = vec4(invTranspose * cross(p2 - p4, p1 - p3), 0);
            fs_Nor = vec4(-cross(p2 - p4, p1 - p3),0.);
        }
    }
    
    //BIOME 4: Sandy Cliffs
    if (biome > 0.01) {
        vec4 newposition_mix = mix(newposition_perlin_valley, vec4(0.), .5f);
        // vec4 newposition_mix = mix(newposition_perlin_valley, newposition_perlin_valley, .5f);
        fs_Pos = newposition_mix;
        vec4 modelposition = u_Model * newposition_mix;   // Temporarily store the transformed vertex positions for use below
        fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
        gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                                // used to render the final positions of the geometry's vertices
        
    }


}
