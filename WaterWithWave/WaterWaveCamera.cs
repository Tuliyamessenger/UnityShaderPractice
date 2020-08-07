using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterWaveCamera : MonoBehaviour
{
    private void OnEnable() {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }

}
