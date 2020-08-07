Shader "Unlit/CartoonShadow"
{
    Properties
    {
        _ThiTex("Third Texture", 2D) = "black" {}
        _SecTex("Second Texture", 2D) = "black" {}
        _MainTex ("Main Texture", 2D) = "balck" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        _ShadowTex("Shadow List", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100

        //Blend Src OneMu

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecTex;
            sampler2D _ThiTex;
            fixed4 _Color;
            sampler2D _ShadowTex;
            float _ShadowTex_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, unity_WorldToObject);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col0 = tex2D(_MainTex, i.uv);
                fixed4 col1 = tex2D(_SecTex, i.uv);
                fixed4 col2 = tex2D(_ThiTex, i.uv);

                fixed al = 1;
                al -= col2.a;
                col1.a *= al;
                al -= col1.a;
                col0.a *= al;
                al -= col0.a;

                col2.rgb *= col2.a;
                col1.rgb *= col1.a;
                col0.rgb *= col0.a;
                _Color *= al;

                fixed4 c = col2 + col1 + col0 + _Color;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed shadow = tex2D(_ShadowTex, float2(0.95 - saturate(dot(worldNormal, worldLightDir))*0.9, 0.5)).r;

                fixed3 diffuse = _LightColor0.rgb * shadow;
                
                return fixed4(c.rgb,1) * fixed4(ambient + diffuse,1);
            }
            ENDCG
        }
    }
}
