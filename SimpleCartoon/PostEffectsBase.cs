using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode] [RequireComponent(typeof(Camera))]
public class PostEffectsBase : MonoBehaviour {

    [SerializeField] protected Shader shader;
    protected Material shaderMaterial;

    protected Material material {
        get {
            shaderMaterial = CheckShaderAndCreateMaterial(shader, shaderMaterial);
            return shaderMaterial;
        }
    }

    protected void CheckResources() {
        bool isSupported = CheckSupport();
        if (isSupported == false) {
            NotSupported();
        }
    }
    
    protected bool CheckSupport() {
        //if(!SystemInfo.supportsImageEffects || !SystemInfo.supportsRenderTextures) {
        //    return false;
        //}
        return true;
    }

    protected void NotSupported() {
        enabled = false;
    }

    protected void Start() {
        CheckResources();
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
        if (shader == null) return null;
        if (shader.isSupported && material && material.shader == shader) return material;
        if (!shader.isSupported) return null;
        else {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material) return material;
            else return null;
        }
    }
}
