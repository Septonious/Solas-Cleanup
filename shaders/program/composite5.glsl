//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform sampler2D colortex0;


void main() {
	vec3 color = texture2D(colortex0, texCoord).rgb;

	/* DRAWBUFFERS:0 */
	gl_FragData[0].rgb = pow(color.rgb, vec3(2.2));
}

#endif

/////////////////////////////////////////////////////////////////////////////////////

#ifdef VSH

//Varyings//
out vec2 texCoord;

void main() {
	//Coords
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	//Position
	gl_Position = ftransform();
}

#endif