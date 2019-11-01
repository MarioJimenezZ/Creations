/* 

-- Package     : API.dll
-- Script Name : DelayAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

using UnityEngine;
using System.Collections;

namespace API
{
    public class DelayAction : MonoBehaviour
    {
        public delegate void Function();

        public static IEnumerator Add(float waitTime, Function func)
        {
            yield return new WaitForSeconds(waitTime);
            func();
        }
    }
}