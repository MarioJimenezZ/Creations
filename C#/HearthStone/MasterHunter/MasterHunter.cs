/* 
-- Package     : MasterHunter
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : Sept 8, 2015 */

using API;

namespace MasterHunter
{
    // Class necessary to be recognized by the client
    public class Entry
    {
        public static void Init()
        {
            // Runs & Adds the HunterBot class to the main handler 
            Handler.GameObject.AddComponent<HunterBot>();
        }
    }
}
