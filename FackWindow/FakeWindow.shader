Shader "Unlit/FakeWindow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WinTex("Other Side Window Texture", Cube) = "_Skybox" {}
        _CubeScale("Cube Scale", Range(0,10)) = 1
        _CubeOffset("Cube Offeet", Vector) = (0,0,0,0)
        _CubeRotate("Cube Rotation", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            //Cull Front
            Cull Back
            CGPROGRAM

            // Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                //float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 objectView : TEXCOORD1;
                float3 enterP : TEXCOORD2;
                //float3 exitP : TEXCOORD3;
                float4 vertex : SV_POSITION;
                //float3 normal : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _WinTex;
            float _CubeScale;
            float3 _CubeOffset;
            float3 _CubeRotate;
            float3x3 _RotationMatrix;

            float3 PointPos(float3 P0, float3 P1, float3 d, float3 n) {
                //Px、P0 为平面某点，n 为平面法线
                //平面方程为 (Px - P0)·n = 0
                //Px、P1 为线某点，d为线向量，t为常数
                //线方程为 Px = P1 + td

                // t = ((P0 - P1)·n )/ d·n
                // px = P1 + d * (((P0 - P1)·n )/ d·n)

                float dotdn = dot(d, n);
                if (dotdn == 0 ) return float3(0,0,0);
                return P1 + mul(d, (dot(P0 - P1,n)) / dotdn);
            }

            float GetDisNRoot(float3 A, float3 B) {
                float3 AB = A - B;
                return AB.x*AB.x + AB.y*AB.y + AB.z*AB.z;
            }

            float3 GetMax(float3 A, float3 B, float3 P1) {
                return GetDisNRoot(A, P1) > GetDisNRoot(B, P1) ? A : B;
            }

            float3 GetMin(float3 A, float3 B, float3 P1) {
                return GetDisNRoot(A, P1) < GetDisNRoot(B, P1) ? A : B;
            }

            float3 GetOtherSidePoint(float3 P1, float3 d) {
                float3 temp1, temp2;
                P1 /= _CubeScale;
                P1 += _CubeOffset;
                P1 = mul(_RotationMatrix, P1);
                d = mul(_RotationMatrix, d);
                P1 += d * 100;
                //X
                temp1 = PointPos(float3(0.5, 0, 0), P1, d, float3(1, 0, 0));
                temp2 = PointPos(float3(-0.5, 0, 0), P1, d, float3(-1, 0, 0));
                float3 Px = GetMax(temp1, temp2, P1);
                //Y
                temp1 = PointPos(float3(0, 0.5, 0), P1, d, float3(0, 1, 0));
                temp2 = PointPos(float3(0, -0.5, 0), P1, d, float3(0, -1, 0));
                float3 Py = GetMax(temp1, temp2, P1);
                //Z
                temp1 = PointPos(float3(0, 0, 0.5), P1, d, float3(0, 0, 1));
                temp2 = PointPos(float3(0, 0, -0.5), P1, d, float3(0, 0, -1));
                float3 Pz = GetMax(temp1, temp2, P1);

                return GetMin(Px, GetMin(Py, Pz, P1), P1);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.objectView = ObjSpaceViewDir(v.vertex);
                o.enterP = v.vertex.xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                _CubeRotate *= UNITY_PI / 180;
                float2x3 sc = float2x3(
                    sin(_CubeRotate.x), sin(_CubeRotate.y), sin(_CubeRotate.z),
                    cos(_CubeRotate.x), cos(_CubeRotate.y), cos(_CubeRotate.z));
                _RotationMatrix = float3x3(
                    sc[1].z * sc[1].y, -sc[0].z * sc[1].x + sc[1].z * sc[0].y * sc[0].x, sc[0].z * sc[0].x + sc[1].z * sc[0].y * sc[1].x,
                    sc[0].z * sc[1].y, sc[1].z * sc[1].x + sc[0].z * sc[0].y * sc[0].x, -sc[1].z * sc[0].x + sc[0].z * sc[0].y * sc[0].x,
                    -sc[0].y, sc[1].y * sc[0].x, sc[1].y * sc[1].x);
                return fixed4(texCUBE(_WinTex, GetOtherSidePoint(i.enterP, i.objectView)));
                //return fixed4(texCUBE(_WinTex, i.exitP).rgb, 1);
            }
            ENDCG
        }
    }
}
