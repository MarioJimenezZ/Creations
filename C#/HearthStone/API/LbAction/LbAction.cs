/* 

-- Package     : API.dll
-- Script Name : LbAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/


using System;

namespace API.LbAction
{
    public abstract class LbAction
    {
        public long ActionTime;
        public abstract LbActionType ActionType { get; }
        public DateTime AddTime;
        public abstract bool CanExecute { get; }
        public abstract void Execute();
        public abstract bool Executed { get; }
        public abstract override string ToString();
    }

    public enum LbActionType
    {
        PlayMinion,
        PlaySpell,
        Attack,
        EndTurn,
        EndGame
    }
}