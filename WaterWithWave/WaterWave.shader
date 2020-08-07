Shader "Unlit/WaterWave"
{
    Properties
    {
        _Color("Water Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _WaveNoise("Wave Noise Texture", 2D) = "bump" {}
        _NoiseScale("Wave Noise Scale", Float) = 1
        _WaveRadius("Wave Circle Max Radius", Float) = 1
        _WaveWidth("Wave Width", Range(0.02, 0.4)) = 0.1
        _WaveHeight("Wave Height", Range(0, 2)) = 1
        _WaveSpeed("Wave Speed", Range(0, 4)) = 1
        _WaterDepth("Water Depth", Range(1, 1000)) = 100
        _ReflectFactor("Reflect Light", Range(0, 1)) = 0.5
        _RefractFactor("Refract Index", Range(0.1, 1)) = 0.5
        _asd("asdf", Float) = 0
        
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        //Cull Off
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass{"_UnderWater"}

        CGINCLUDE
        sampler2D _MainTex;
        float4 _MainTex_ST;
        sampler2D _WaveNoise;
        fixed _NoiseScale;
        sampler2D _UnderWater;
        float2 _UnderWater_TexelSize;
        float4 _WaveNoise_ST;
        fixed4 _Color;
        fixed _WaveRadius;
        fixed _WaveWidth;
        fixed _WaveHeight;
        fixed _WaveSpeed;
        fixed _ReflectFactor;
        sampler2D _ReflectTexture;
        float2 _ReflectTexture_TexelSize;
        fixed _RefractFactor;
        fixed _WaterDepth;
        float4 _WaveCenter[10];
        float _asd;

        sampler2D _CameraDepthTexture;

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float3x3 worldTexcoord : TEXCOORD1;
            float4 grabPos : TEXCOORD4;
            float4 screenPos : TEXCOORD5;
            float4 vertex : SV_POSITION;
        };

        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            //o.uv.zw = TRANSFORM_TEX(v.uv, _WaveNoise);

            //Normal
            o.worldTexcoord[0] = mul(unity_ObjectToWorld, v.normal);
            //WorldView
            o.worldTexcoord[1] = WorldSpaceViewDir(v.vertex);
            //WorldPos
            o.worldTexcoord[2] = mul(unity_ObjectToWorld, v.vertex);
            o.grabPos = ComputeGrabScreenPos(o.vertex);
            o.screenPos = ComputeScreenPos(o.vertex);
            COMPUTE_EYEDEPTH(o.screenPos.z);
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed3 worldNormal = i.worldTexcoord[0];
            fixed3 worldView = normalize(i.worldTexcoord[1]);
            fixed3 worldPos = i.worldTexcoord[2];
            //fixed3 worldRefract = i.worldTexcoord[3];
            fixed4 grabPos = i.grabPos;

            //normal change.
            worldNormal -= UnpackNormal(tex2D(_WaveNoise, i.uv * _NoiseScale + _Time.x / 2)).rgb *_WaveHeight;
            worldNormal += UnpackNormal(tex2D(_WaveNoise, -i.uv * _NoiseScale + _Time.x / 3)).rgb *_WaveHeight;
            //return fixed4(worldNormal, 1);
            for (int c = 0; c < 10; c += 1) {
                if (_WaveCenter[c].z < 1) continue;
                half d = distance(worldPos.xz, _WaveCenter[c].xy);
                if (d < _WaveRadius) {
                    worldNormal += normalize(-worldPos) * sin(-_Time.w * _WaveSpeed + d / _WaveWidth) * saturate(_WaveRadius - d) * _WaveHeight;
                }
            }
            
            worldNormal = normalize(worldNormal);
            fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

            //------------- Get Light Color ------------
            //fixed ambient = UNITY_LIGHTMODEL_AMBIENT;
            //fixed diffuse = _LightColor0 * saturate(dot(worldNormal, worldLightDir));
            fixed fresnel = _ReflectFactor + (1 - _ReflectFactor) * pow( 1 - dot(worldView, worldNormal), 5);

            //------------ Get Under Water Color ------------
            //Get the depth under water.
            float lerpUnder = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos + fixed4(worldNormal.xz * _UnderWater_TexelSize * 100, 0, 0))));
            float depthDiff = max(0, min(_WaterDepth, lerpUnder - i.screenPos.z)) / _WaterDepth;

            fixed3 under = tex2D(_UnderWater, (grabPos.xy + worldNormal.xz * _UnderWater_TexelSize * 100) / grabPos.w);
            //fixed3 under = tex2D(_UnderWater, grabPos.xy / grabPos.w);
            fixed3 upper = tex2D(_ReflectTexture, (i.screenPos + worldNormal.xz * _UnderWater_TexelSize * 100) / i.screenPos.w);

            //Get more contrast to reflection;
            if (depthDiff < 0.1) upper += (0.1 - depthDiff)*2;

            return fixed4(lerp(lerp(_Color.rgb, under, pow(1-depthDiff,5)), upper, fresnel),1);
        }
        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
