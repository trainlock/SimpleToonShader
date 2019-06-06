// Toon Shader Tutorial: https://roystan.net/articles/toon-shader.html
// Followed tutorial from start to end

Shader "Roystan/Toon"{
	Properties{
		_Color("Color", Color) = (0.5, 0.65, 1, 1)
		_MainTex("Main Texture", 2D) = "white" {}	
        [HDR]   // Attribute that allows the color to have values beyond regular RGB
        _AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
        _Glossiness("Glossiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
	}
	SubShader{
		Pass{
            Tags{
                "LightMode" = "ForwardBase"         // Require some data to pass into shader
                "PassFlags" = "OnlyDirectional"     // Restrict data to only main directional light
            }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_fwdbase       // Set up shader to handle two different lighting cases
			
			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            // Use Blinn-Phong shading

			struct appdata{
				float4 vertex : POSITION;				
				float4 uv : TEXCOORD0;
                float3 normal : NORMAL;         // Automatically populated, surface normal
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 worldNormal : NORMAL;    // Manually populated in the vertex shader
                float3 viewDir : TEXCOORD1;     // Enable view dependant reflection
                SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

            // Vertex Shader
			v2f vert (appdata v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                TRANSFER_SHADOW(o)

				return o;
			}
			
			float4 _Color;
            
            // Add Ambient light
            float4 _AmbientColor;

            // Add Specular light
            float _Glossiness;
            float4 _SpecularColor;

            // Rim light
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

            // Fragment Shader
			float4 frag (v2f i) : SV_Target{
                float3 viewDir = normalize(i.viewDir);
                float4 sample = tex2D(_MainTex, i.uv);
                float3 normal = normalize(i.worldNormal);
               
                // Calcylate light intensity
                float NdotL = dot(_WorldSpaceLightPos0, normal);

                // Divide light into two bands (light and dark) to create a toon-like effect 
                // with a smooth border, smoothstep(lower bound, upper bound, value)
                float shadow = SHADOW_ATTENUATION(i);
                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
                float4 light = lightIntensity * _LightColor0;

                // Make view dependant
                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir); // Vector between viewing direction and light source
                float NdotH = dot(normal, halfVector);

                // Calculate specular light intensity
                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float specular = specularIntensitySmooth * _SpecularColor;

                // Rim lightning
                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float rim = rimIntensity * _RimColor;

                // Add ambient light to the scene as well as toon-shading
				return _Color * sample * (_AmbientColor + light + specular + rim);
			}
            //!/ End o www
			ENDCG
		}
        // Add pass that is used by Unity during the shadow casting step of the rendering process
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}