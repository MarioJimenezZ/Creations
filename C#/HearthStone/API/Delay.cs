/* 

-- Package     : API.dll
-- Script Name : Delay.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

using System;
using System.Timers;

namespace API
{
    public class Delay
    {
        private delegate void Function();

        public Delay(int time,Function func)
        {
            var aTimer = new System.Timers.Timer(time);
            aTimer.Elapsed += new ElapsedEventHandler((System.Timers.ElapsedEventHandler)func);
            aTimer.Enabled = true; 
        }
    }
}
