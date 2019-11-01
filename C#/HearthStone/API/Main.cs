/* 

-- Package     : API.dll
-- Script Name : Main.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/

using API.Core;
using API.LbAction;
using UnityEngine;


namespace LogicBreakers
{
    public class Entry : MonoBehaviour
    {
        public static void Init()
        {
            SceneMgr.Get().gameObject.AddComponent<API.Handler>();
            SceneMgr.Get().gameObject.AddComponent<Events>();
            SceneMgr.Get().gameObject.AddComponent<ActionQueue>();
        }
    }
}
