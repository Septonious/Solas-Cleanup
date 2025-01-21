//Settings//
#include "/lib/common.glsl"

#ifdef FSH

//Varyings//
in vec2 texCoord;

//Uniforms//
uniform int frameCounter;

uniform float viewWidth, viewHeight;

#ifdef BLOOM
#ifdef TAA
uniform float frameTimeCounter;
#endif

#ifdef OVERWORLD
uniform float timeBrightness;

uniform ivec2 eyeBrightnessSmooth;
#endif
#endif

uniform sampler2D colortex0, colortex2;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;

#ifdef BLOOM
uniform sampler2D colortex1;

uniform mat4 gbufferProjectionInverse;
#endif

//Optifine Constants//
const bool colortex1MipmapEnabled = true;
const bool colortex2Clear = false;

//Includes//
#include "/lib/util/bayerDithering.glsl"
#include "/lib/post/tonemap.glsl"

#ifdef FXAA
#include "/lib/antialiasing/fxaa.glsl"
#endif

#ifdef BLOOM
#include "/lib/post/getBloom.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2DLod(colortex0, texCoord, 0).rgb;

	//Preset Variables
	float z0 = texture2D(depthtex0, texCoord).r;

    float dither = texture2D(noisetex, gl_FragCoord.xy / 512.0).b;
    #ifdef TAA
          dither = fract(dither + GOLDENRATIO * mod(float(frameCounter), 3600.0));
    #endif

	vec3 temporalColor = vec3(0.0);
	#ifdef TAA
		 temporalColor = texture2D(colortex2, texCoord).gba;
	#endif

	float temporalData = 0.0;

	//Bloom
	#ifdef BLOOM
	getBloom(color, texCoord);
	#endif

	//Fast Approximate Antialiasing
	#ifdef FXAA
	color = FXAA311(color);
	#endif

	//Tonemapping
	color = Uncharted2Tonemap(color * TONEMAP_BRIGHTNESS) / Uncharted2Tonemap(vec3(TONEMAP_WHITE_THRESHOLD));

	//Film Grain
    color += vec3((dither - 0.25) / 128.0);

	/* DRAWBUFFERS:12 */
	gl_FragData[0].rgb = color;
	gl_FragData[1] = vec4(temporalData, temporalColor);
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