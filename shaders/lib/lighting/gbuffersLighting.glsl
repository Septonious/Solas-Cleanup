void gbuffersLighting(inout vec4 albedo, in vec3 screenPos, in vec3 viewPos, in vec3 worldPos, in vec3 normal, inout vec3 shadow, in vec2 lightmap, 
                    in float NoU, in float NoL, in float NoE,
                    in float subsurface, in float smoothness, in float emission, in float parallaxShadow) {
    //Variables
    float originalNoL = NoL;
    float lViewPos = length(viewPos.xz);
    float ao = color.a * color.a;
    vec3 worldNormal = normalize(ToWorld(normal * 1000000.0));

    //Vanilla Directional Lighting
    float vanillaDiffuse = (0.25 * NoU + 0.75) + (0.667 - abs(NoE)) * (1.0 - abs(NoU)) * 0.15;
          vanillaDiffuse *= vanillaDiffuse;
    #ifdef OVERWORLD
          vanillaDiffuse = mix(1.0, vanillaDiffuse, lightmap.y);
    #endif

    //Block Lighting
    float blockLightMap = pow6(lightmap.x * lightmap.x) * 3.0 + max(lightmap.x - 0.05, 0.0);
         blockLightMap *= blockLightMap * 0.5;

    vec3 blockLighting = blockLightCol * blockLightMap * (1.0 - min(emission, 1.0));

    //Shadow Calculation
    //Some code made by Emin and gri573
    float shadowLightingFade = maxOf(abs(worldPos) / (vec3(shadowDistance, shadowDistance + 128.0, shadowDistance)));
          shadowLightingFade = clamp(shadowLightingFade, 0.0, 1.0);
          shadowLightingFade = 1.0 - shadowLightingFade * shadowLightingFade;

    //Subsurface Scattering
    float sss = 0.0;

    if (shadowLightingFade > 0.0) {
        #if defined OVERWORLD && defined GBUFFERS_TERRAIN
        if (subsurface > 0.0 && lightmap.y > 0.0) {
            float VoL = clamp(dot(normalize(viewPos), lightVec), 0.0, 1.0);
            sss = pow8(VoL) * shadowFade * (1.0 - wetness * 0.5);
            if (subsurface > 0.49 && subsurface < 0.51) { //Leaves
                NoL += 0.5 * shadowLightingFade * (0.75 + sss * 0.75);
            } else { //Foliage
                NoL += shadowLightingFade * (0.35 + sss) * (1.0 - float(subsurface > 0.29 && subsurface < 0.31) * 0.5);
            }
        }
        #endif

        float lightmapS = lightmap.y * lightmap.y * (3.0 - 2.0 * lightmap.y);

        vec3 worldPosM = worldPos;

        #ifdef GBUFFERS_TEXTURED
            vec3 centerWorldPos = floor(worldPos + cameraPosition) - cameraPosition + 0.5;
            worldPosM = mix(centerWorldPos, worldPosM + vec3(0.0, 0.02, 0.0), lightmapS);
        #else
            //Shadow bias without peter-panning
            float distanceBias = pow(dot(worldPos, worldPos), 0.75);
                  distanceBias = 0.12 + 0.0008 * distanceBias;
            vec3 bias = worldNormal * distanceBias * (2.0 - 0.95 * max(NoL, 0.0));

            //Fix light leaking in caves
            if (lightmapS < 0.999) {
                #ifdef GBUFFERS_HAND
                    worldPosM = mix(vec3(0.0), worldPosM, 0.2 + 0.8 * lightmapS);
                #else
                    vec3 edgeFactor = 0.2 * (0.5 - fract(worldPosM + cameraPosition + worldNormal * 0.01));

                    #ifdef GBUFFERS_WATER
                        bias *= 0.7;
                        worldPosM += (1.0 - lightmapS) * edgeFactor;
                    #endif

                    worldPosM += (1.0 - pow2(pow2(max(color.a, lightmapS)))) * edgeFactor;
                #endif
            }

            worldPosM += bias;
        #endif
        
        vec3 shadowPos = ToShadow(worldPosM);

        float offset = 0.001;
        float viewDistance = 1.0 - clamp(lViewPos * 0.01, 0.0, 1.0);
        
        shadow = computeShadow(shadowPos, offset, lightmap.y, subsurface, viewDistance);
    }

    vec3 fakeShadow = getFakeShadow(lightmap.y);

    shadow = mix(fakeShadow, shadow, vec3(shadowLightingFade));

    #if defined PBR && defined GBUFFERS_TERRAIN
    shadow *= parallaxShadow;
    #endif

    shadow *= clamp(NoL * 1.01 - 0.01, 0.0, 1.0);

    //Main Lighting
    #ifdef OVERWORLD
    float rainFactor = 1.0 - wetness * 0.75;
    vec3 sceneLighting = mix(ambientCol * pow4(lightmap.y), lightCol, shadow * rainFactor * shadowFade);
         sceneLighting *= 1.0 + sss * shadow;
    #elif defined END
    vec3 sceneLighting = mix(endAmbientCol, endLightCol, shadow) * 0.25;
    #elif defined NETHER
    vec3 sceneLighting = pow(netherColSqrt, vec3(0.75)) * 0.03;
    #endif

    //Minimal Lighting
    #if defined OVERWORLD || defined END
    sceneLighting += minLightCol * (1.0 - lightmap.y);
    #endif

    //Night vision
    sceneLighting += nightVision * vec3(0.1, 0.15, 0.1);

    //Vanilla AO
    #ifdef VANILLA_AO
    float aoMixer = (1.0 - ao) * (1.0 - pow6(lightmap.x));
    albedo.rgb = mix(albedo.rgb, albedo.rgb * ao * ao, aoMixer * AO_STRENGTH);
    #endif

    albedo.rgb = pow(albedo.rgb, vec3(2.2));
    albedo.rgb *= sceneLighting * vanillaDiffuse + blockLighting + emission;
    albedo.rgb = pow(albedo.rgb, vec3(1.0 / 2.2));
}