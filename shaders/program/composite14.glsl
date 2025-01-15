//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;

//Optifine Constants//
const bool colortex1MipmapEnabled = true;

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

//Program//
void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	vec3 curr = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS);

	color = pow(curr / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD)), vec3(1.0 / 2.2));

	/* DRAWBUFFERS:1 */
	gl_FragData[0].rgb = color;
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

#include "/lib/wmark/s0las_shader.glsl"

//Varyings//
out vec2 texCoord;

//Program//
void main() {
	//Coord
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy * float(chval == 0.1984);

	//Position
	gl_Position = ftransform();
}

#endif