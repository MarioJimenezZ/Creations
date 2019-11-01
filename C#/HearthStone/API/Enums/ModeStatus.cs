/* 

-- Package     : API.dll
-- Script Name : ModeStatus.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/


namespace API
{
    public enum ModeStatus
    {
        Unknown = -1,
        Login = 0,
        MainMenu = 1,
        Adventure = 2,
        Play = 3,
        InGame = 4,
        GameOver = 5
    }
}