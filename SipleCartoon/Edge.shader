Shader "Unlit/Edge"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthNormalsTexture;
        sampler2D _LineTex;
        fixed4 _LineColor;
        fixed _LineWide;
        fixed _NormalDifferent;
        fixed _DepthDifferent;
        //float4 _MainTex_ST;

        struct appdata{
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2fpure{
            float2 uv[9] : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        struct v2fdraw {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        v2fpure vertpure(appdata v){
            v2fpure o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            //around
            o.uv[0] = v.uv + _MainTex_TexelSize.xy * normalize(half2(-1, -1)) * _LineWide;
            o.uv[1] = v.uv + _MainTex_TexelSize.xy * half2(-_LineWide, 0);
            o.uv[2] = v.uv + _MainTex_TexelSize.xy * normalize(half2(-1, 1)) * _LineWide;
            o.uv[3] = v.uv + _MainTex_TexelSize.xy * half2(0, -_LineWide);
            o.uv[4] = v.uv + _MainTex_TexelSize.xy * half2(0, _LineWide);
            o.uv[5] = v.uv + _MainTex_TexelSize.xy * normalize(half2(1, -1)) * _LineWide;
            o.uv[6] = v.uv + _MainTex_TexelSize.xy * half2(_LineWide, 0);
            o.uv[7] = v.uv + _MainTex_TexelSize.xy * normalize(half2(1, 1)) * _LineWide;
            
            //center
            o.uv[8] = v.uv + _MainTex_TexelSize.xy * half2(0, 0);
            return o;
        }

        v2fdraw  vertdraw(appdata v) {
            v2fdraw o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        bool isEdge(v2fpure i) {
            float3 totalnormal = 0;
            float totaldepth = 0;

            fixed4 col = 0;
            for (int s = 0; s <= 7; s += 1) {
                col = tex2D(_CameraDepthNormalsTexture, i.uv[s]);
                totalnormal += DecodeViewNormalStereo(col);
                totaldepth += DecodeFloatRG(col.zw);
            }
            totalnormal /= 8;
            totaldepth /= 8;
            col = tex2D(_CameraDepthNormalsTexture, i.uv[8]);
            float3 centernormal = DecodeViewNormalStereo(col);
            float centerdepth = DecodeFloatRG(col.zw);
            return dot(totalnormal, centernormal) < _NormalDifferent || abs(totaldepth - centerdepth) * 100 > _DepthDifferent;
        }

        fixed4 fragpure(v2fpure i) : SV_Target{
            fixed4 col = fixed4(0, 0, 0, 1);
            if (isEdge(i)) {
                col = fixed4(1, 1, 1, 1);
            }
            return col;
        }

        fixed4 fragdraw(v2fdraw i) : SV_Target {
            fixed4 col = tex2D(_MainTex, i.uv);
            fixed4 colline = tex2D(_LineTex, i.uv);
            if (colline.r + colline.g + colline.b > 0) col = colline * _LineColor;
            return col;
        }

        ENDCG

        Pass{ //#0 Make Object to be Pure Color with outline.
            CGPROGRAM
            #pragma vertex vertpure
            #pragma fragment fragpure
            ENDCG
        }

        Pass{ //#1 Add outline to texture.
            CGPROGRAM
            #pragma vertex vertdraw
            #pragma fragment fragdraw
            ENDCG
        }
    }
}
