/* 

-- Package     : API.dll
-- Script Name : Graphics.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

using UnityEngine;

namespace API
{
    public class Graphics
    {
        public static void DrawText(string sText, int iSize, int iX, int iY, Color color)
        {
            var s = new GUIStyle {normal = {textColor = color}, fontSize = iSize};
            GUI.Label(new Rect(iX, iY, 200, 200), sText, s);
        }

        public static void AddInfoMsg(string msg)
        {
            UIStatus.Get().AddInfo(msg);
        }

        public static void AddErrorMsg(string msg)
        {
            UIStatus.Get().AddError(msg);
        }
    }
}