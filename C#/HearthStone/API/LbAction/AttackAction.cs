/* 

-- Package     : API.dll
-- Script Name : AttackAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/


using System;

namespace API.LbAction
{
    internal class AttackAction : LbAction
    {
        private readonly LbCard _attacker;
        private readonly LbCard _target;

        public AttackAction(LbCard attacker, LbCard target)
        {
            _attacker = attacker;
            _target = target;
            ActionTime = 3000;
            AddTime = DateTime.Now;
        }

        public override bool CanExecute
        {
            get { return Game.IsInGame && !Game.IsGameOver && _attacker.IsAlive && _target.IsAlive && _attacker.CanAttack && _attacker.GetZone == TAG_ZONE.PLAY; }
        }

        public override void Execute()
        {
            if (Game.IsAttacking()) return;
            _attacker.Grab();
            if (!_attacker.DoReposponse) return;
            _attacker.PickUp();
            EnemyActionHandler.Get().NotifyOpponentOfTargetModeBegin(_attacker.Source);
            GameState.Get().GetGameEntity().NotifyOfBattlefieldCardClicked(_target.Source.GetEntity(), true);
            if (!_target.DoReposponse) return;
            EnemyActionHandler.Get().NotifyOpponentOfTargetEnd();
            Game.MyPlayer.FieldZone.UpdateLayout();
            ActionQueue.Remove(this);
        }

        public override bool Executed
        {
            get { return !_attacker.CanAttack; }
        }

        public override string ToString()
        {
            return "Attack - [Attacker Card: " + _attacker.Name + " Target Card: " + _target.Name + "]";
        }

        public override LbActionType ActionType
        {
            get { return LbActionType.Attack; }
        }
    }
}