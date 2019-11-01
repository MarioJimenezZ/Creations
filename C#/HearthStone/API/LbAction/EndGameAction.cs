
/* 

-- Package     : API.dll
-- Script Name : EndGameAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 14, 2015

*/

using System;

namespace API.LbAction
{
    internal class EndGameAction : LbAction
    {
        public EndGameAction()
        {
            ActionTime = 5000;
            AddTime = DateTime.Now;
        }

        public override LbActionType ActionType
        {
            get {return LbActionType.EndGame;}
        }

        public override bool CanExecute
        {
            get { return Game.IsInGame && Game.IsGameOver && EndGameScreen.Get() != null; }
        }

        public override void Execute()
        {
            EndGameScreen.Get().m_hitbox.TriggerRelease();
            EndGameScreen.Get().ContinueEvents();
            ActionQueue.Remove(this);
        }

        public override bool Executed
        {
            get { return !Game.IsInGame; }
        }

        public override string ToString()
        {
            return "EndGame";
        }
    }
}