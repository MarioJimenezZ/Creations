/* 

-- Package     : API.dll
-- Script Name : PlayCardAction.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/


using System;

namespace API.LbAction
{
    internal class PlayCardAction : LbAction
    {
        private readonly LbCard _source;

        public PlayCardAction(LbCard source)
        {
            _source = source;
            ActionTime = 3000;
            AddTime = DateTime.Now;
        }

        public override LbActionType ActionType
        {
            get { return LbActionType.PlayMinion; }
        }

        public override string ToString()
        {
            return "PlayCard - [Card: " + _source.Name + "]";
        }

        public override bool CanExecute
        {
            get { return Game.IsInGame && !Game.IsGameOver && (_source.GetZone == TAG_ZONE.HAND) && _source.CanPlay && _source.IsMinion; }
        }

        public override bool Executed
        {
            get { return _source.GetZone != TAG_ZONE.HAND; }
        }

        public override void Execute()
        {
            var slot = Game.MyPlayer.FieldZone.GetCards().Count + 1;
            _source.PickUp();
            _source.Drop();
            if (!_source.DoReposponse) return;
            ZoneMgr.Get().AddLocalZoneChange(_source.Source, Game.MyPlayer.FieldZone, slot);
            Game.MyPlayer.UpdateMana(_source.RealTimeCost);
            Game.MyPlayer.HandZone.UpdateLayout(-1, true);
            Game.MyPlayer.FieldZone.SortWithSpotForHeldCard(-1);
            if (GameState.Get().GetResponseMode() == GameState.ResponseMode.SUB_OPTION) return;
            EnemyActionHandler.Get().NotifyOpponentOfCardDropped();
            ActionQueue.Remove(this);
        }
    }
}