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

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.
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
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    //vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    //fs_Pos = modelposition;

    //fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    //gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    vec4 diffuseColor = vec4(.5f, 1.f, .5f, 1.f);
    float modifier = PerlinNoise3D(vec3(vs_Pos) * 500.) + 2.5f;
    //if (modifier > .25f) {
        diffuseColor = diffuseColor * modifier;
        //fs_Pos = modelposition + fs_Nor * modifier * 5.f;
    //}
    fs_Col = diffuseColor;                         // Pass the vertex colors to the fragment shader for interpolation

    vec4 vs_Pos_new = vs_Pos + vs_Nor * modifier * .18f;

    if (length(vs_Pos_new) < 2.7f) {
        fs_Col = vec4(0.5f, 0.f, 0.f, 1.f);
        // vs_Pos_new = vs_Pos;
    }

    vec4 modelposition = u_Model * vs_Pos_new;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

}
