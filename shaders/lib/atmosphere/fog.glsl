//1.19 Darkness Fog
#if MC_VERSION >= 11900
void getDarknessFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (darknessFactor * 0.01);
		  fog = (1.0 - exp(-fog)) * darknessFactor;

	color = mix(color, vec3(0.0), fog);
}
#endif

//Blindness Fog
void getBlindFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (blindFactor * 0.1);
		  fog = (1.0 - exp(-4.0 * pow3(fog))) * blindFactor;

	color = mix(color, vec3(0.0), fog);
}

//Powder Snow / Lava Fog
vec3 densefogCol[2] = vec3[2](
	vec3(1.0, 0.18, 0.02),
	vec3(0.05, 0.07, 0.12)
);

void getDenseFog(inout vec3 color, float lViewPos) {
	float fog = lViewPos * (0.15 + float(isEyeInWater == 3) * 0.5);
		  fog = 1.0 - exp(-2.0 * pow2(fog));

	color = mix(color, densefogCol[isEyeInWater - 2], fog);
}

//Normal Fog
#ifndef END
void getNormalFog(inout vec3 color, in vec3 worldPos, in vec3 atmosphereColor, in float lViewPos, in float lWorldPos) {
    #if defined DISTANT_HORIZONS && (defined DEFERRED || defined DH_WATER || defined GBUFFERS_WATER)
    float farPlane = dhFarPlane;
    #else
    float farPlane = far;
    #endif

	//Overworld Fog
	#ifdef OVERWORLD
    float fogDistanceFactor = mix(65.0, FOG_DISTANCE * (0.7 + timeBrightness * 0.3), caveFactor);
	float fogDistance = min(192.0 / farPlane, 1.0) * (100.0 / fogDistanceFactor);
	float fogAltitudeFactor = clamp(exp2(-max(cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogAltitude = clamp(exp2(-max(worldPos.y + cameraPosition.y - FOG_HEIGHT, 0.0) / exp2(FOG_HEIGHT_FALLOFF)), 0.0, 1.0);
	float fogDensity = FOG_DENSITY * (2.0 - caveFactor) * (1.0 - pow(eBS, 0.1) * timeBrightness * 0.5);

	#ifdef DISTANT_HORIZONS
	fogDensity *= 3.0;
	#endif

	#if MC_VERSION >= 12104
	fogDensity = mix(fogDensity, 6.0, isPaleGarden);
	fogDistance *= 1.0 - isPaleGarden * 0.75;
	#endif

    float fog = 1.0 - exp(-(0.0075 + wetness * caveFactor * 0.0025) * lViewPos * fogDistance);
		  fog = clamp(fog * fogDensity * fogAltitude, 0.0, 1.0);

	vec3 fogCol = mix(caveMinLightCol * atmosphereColor, atmosphereColor, caveFactor);

	//Distant Fade
	#ifdef DISTANT_FADE
	if (isEyeInWater < 0.5) {
		#if MC_VERSION >= 11800
		const float fogOffset = 0.0;
		#else
		const float fogOffset = 12.0;
		#endif

		#if DISTANT_FADE_STYLE == 0
		float fogFactor = lWorldPos;
		#else
		float fogFactor = lViewPos;
		#endif

		float vanillaFog = 1.0 - (farPlane - (fogFactor + fogOffset)) * 8.0 / (4.0 * farPlane);
			  vanillaFog = clamp(vanillaFog * vanillaFog * vanillaFog, 0.0, 1.0) * caveFactor;
	
		if (vanillaFog > 0.0){
			fogCol *= fog;
			fog = mix(fog, 1.0, vanillaFog);

			if (fog > 0.0) fogCol = mix(fogCol, atmosphereColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	//Nether Fog
	#ifdef NETHER
	float fog = lViewPos * 0.004;
	#ifdef DISTANT_FADE
	      fog += 6.0 * pow4(lWorldPos / farPlane);
	#endif
	      fog = 1.0 - exp(-fog);

	vec3 fogCol = netherColSqrt.rgb * 0.25;
	#endif

    //Mixing Colors
	#if !defined NETHER && defined DEFERRED
    #if defined DISTANT_HORIZONS && (defined DEFERRED || defined DH_WATER || defined GBUFFERS_WATER)
    float zMixer = float(texture2D(dhDepthTex0, texCoord).r < 1.0);
    #else
    float zMixer = float(texture2D(depthtex1, texCoord).r < 1.0);
    #endif

	#if MC_VERSION >= 12104
		  zMixer = mix(zMixer, 1.0, isPaleGarden);
	#endif
	      zMixer = clamp(zMixer, 0.0, 1.0);

	fog *= zMixer;
	#endif

	color = mix(color, fogCol, fog);
}
#endif

void Fog(inout vec3 color, in vec3 viewPos, in vec3 worldPos, in vec3 atmosphereColor) {
    float lViewPos = length(viewPos);
    float lWorldPos = length(worldPos.xz);

	if (isEyeInWater < 1) {
		#ifndef END
        getNormalFog(color, worldPos, atmosphereColor, lViewPos, lWorldPos);
		#endif
    } else if (isEyeInWater > 1) {
        getDenseFog(color, lViewPos);
    }
	if (blindFactor > 0) getBlindFog(color, lViewPos);

	#if MC_VERSION >= 11900
	if (darknessFactor > 0) getDarknessFog(color, lViewPos);
	#endif
}