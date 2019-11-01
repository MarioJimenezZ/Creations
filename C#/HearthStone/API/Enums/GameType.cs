/* 

-- Package     : API.dll
-- Script Name : GameType.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/

namespace API
{
    public enum GameType
    {
        Unknown = 0,
        VsAi = 1,
        VsFriend = 2,
        Tutorial = 4,
        Arena = 5,
        Test = 6,
        Ranked = 7,
        Unranked = 8,
        Last = 14,
    }
}