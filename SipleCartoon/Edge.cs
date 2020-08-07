using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Edge : PostEffectsBase
{
    [SerializeField] Color LineColor = new Vector4(0,0,0,1);
    [SerializeField, Range(0, 5)] float LineWide = 2;
    [SerializeField, Range(0, 1f)] float NormalDifferent = 0.9f;
    [SerializeField, Range(0, 1f)] float DepthDifferent = 0.1f;
    [SerializeField] RenderTexture pureColorTex;
    [SerializeField] Camera secCamera;

    private void OnEnable() {
        secCamera.depthTextureMode = DepthTextureMode.DepthNormals;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (material != null) {
            RenderTexture buffer1 = RenderTexture.GetTemporary(source.width, source.height, 0);
            //RenderTexture buffer2 = RenderTexture.GetTemporary(source.width, source.height, 0);
            material.SetColor("_LineColor", LineColor);
            material.SetFloat("_LineWide", LineWide);
            material.SetFloat("_NormalDifferent", NormalDifferent);
            material.SetFloat("_DepthDifferent", DepthDifferent);

            Graphics.Blit(pureColorTex, buffer1, material, 0);
            
            //buffer1 = RenderTexture.GetTemporary(source.width, source.height, 0);
            material.SetTexture("_LineTex", buffer1);
            
            //Graphics.Blit(buffer1, destination);
            Graphics.Blit(source, destination, material, 1);
            RenderTexture.ReleaseTemporary(buffer1);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }
}
