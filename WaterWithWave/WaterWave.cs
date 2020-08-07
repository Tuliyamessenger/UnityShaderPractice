using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterWave : MonoBehaviour
{
    [SerializeField] Vector4[] WaveCenter;
    [SerializeField] Material material;
    // Start is called before the first frame update
    void Start()
    {
        if(material == null) {
            material = GetComponent<MeshRenderer>().material;
        }
    }

    // Update is called once per frame
    void Update()
    {
        material.SetVectorArray("_WaveCenter", WaveCenter);
    }
}
