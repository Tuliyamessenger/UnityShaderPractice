using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterWaveReflectCamera : MonoBehaviour
{
    [SerializeField] Transform targetCamera;
    [SerializeField] Transform targetWater;
    Material material;

    RenderTexture renderTexture;

    private void Awake() {
        //Flip Camera
        GetComponent<Camera>().projectionMatrix *= Matrix4x4.Scale(new Vector3(-1, 1, 1));
    }

    //When flip the camera, the cull also inverted. Therefore, incert the culling and invert again befor effect other cameras. 
    void OnPreRender() {
        GL.invertCulling = true;
    }

    void OnPostRender() {
        GL.invertCulling = false;
    }

    // Start is called before the first frame update
    void Start()
    {
        renderTexture = RenderTexture.GetTemporary(Screen.width, Screen.height, 0);
        material = targetWater.GetComponent<MeshRenderer>().material;
        GetComponent<Camera>().targetTexture = renderTexture;
    }

    // Update is called once per frame
    void Update()
    {
        material.SetTexture("_ReflectTexture", renderTexture);
        float toY = targetWater.position.y - targetCamera.position.y;
        transform.position = new Vector3(targetCamera.position.x, toY, targetCamera.position.z);
        transform.rotation = targetCamera.rotation;
        transform.Rotate(-targetCamera.rotation.eulerAngles.x * 2,0,180);
    }
}
