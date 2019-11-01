
/* 

-- Package     : API.dll
-- Script Name : EndTurnAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 14, 2015

*/

using System;

namespace API.LbAction
{
    internal class EndTurnAction : LbAction
    {
        public EndTurnAction()
        {
            ActionTime = 2000;
            AddTime = DateTime.Now;
        }

        public override LbActionType ActionType
        {
            get {return LbActionType.EndTurn;}
        }

        public override bool Executed
        {
            get { return !Game.IsMyTurn(); }
        }

        public override bool CanExecute
        {
            get { return Game.IsInGame && !Game.IsGameOver && !EndTurnButton.Get().IsInWaitingState(); }
        }

        public override void Execute()
        {
            InputManager.Get().DoEndTurnButton();
            ActionQueue.Remove(this);
        }

        public override string ToString()
        {
            return "EndTurn";
        }
    }
}