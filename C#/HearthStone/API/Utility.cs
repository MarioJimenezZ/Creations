/* 

-- Package     : API.dll
-- Script Name : Utility.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

namespace API
{
    public static class Utility
    {
        public static bool IsTransitioning()
        {
            if (GameUtils.IsAnyTransitionActive())
                return true;
            if (GameMgr.Get().IsFindingGame() || Network.Get().IsFindingGame())
                return true;
            switch (GameMgr.Get().GetFindGameState())
            {
                case FindGameState.CLIENT_STARTED:
                case FindGameState.CLIENT_CANCELED:
                case FindGameState.CLIENT_ERROR:
                case FindGameState.BNET_QUEUE_CANCELED:
                case FindGameState.BNET_ERROR:
                case FindGameState.SERVER_GAME_CONNECTING:
                case FindGameState.SERVER_GAME_STARTED:
                case FindGameState.SERVER_GAME_CANCELED:
                    return true;
                default:
                    return false;
            }
        }
    }
}
