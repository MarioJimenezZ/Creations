/* 

-- Package     : API.dll
-- Script Name : Game.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

using API.LbAction;

namespace API
{
    public static class Game
    {
        public static void EndMulligan()
        {
            MulliganManager.Get().EndMulligan();
        }

        public static void EndGame()
        {
            ActionQueue.Add(new EndGameAction());
        }

        public static void EndTurn()
        {
            ActionQueue.Add(new EndTurnAction());
        }

        public static LbPlayer EnemyPlayer
        {
            get { return new LbPlayer(GameState.Get().GetFirstOpponentPlayer(MyPlayer.Source)); }
        }

        public static LbCard GetLowestEnemyTaunt()
        {
            LbCard lowestTaunt = null;
            foreach (var card in EnemyPlayer.CardsInField())
            {
                if (!card.HasTaunt)
                    continue;
                if (lowestTaunt == null || (card.RemainingHealth < lowestTaunt.RemainingHealth))
                    lowestTaunt = card;
                else if (lowestTaunt.RemainingHealth == card.RemainingHealth &&
                         lowestTaunt.AttackDamage < card.AttackDamage)
                    lowestTaunt = card;
            }
            return lowestTaunt;
        }

        public static int GetTurn()
        {
            return GameState.Get().GetTurn();
        }

        public static bool HasTheCoinSpawned
        {
            get { return GameState.Get().HasTheCoinBeenSpawned(); }
        }

        public static bool IsAttacking()
        {
            foreach (var card in EnemyPlayer.CardsInField())
            {
                if (card.IsAttacking)
                    return true;
            }
            return false;
        }

        public static bool IsGameOver
        {
            get { return GameState.Get() != null && GameState.Get().IsGameOver(); }
        }

        public static bool IsInGame
        {
            get { return SceneMgr.Get().IsInGame(); }
        }

        public static bool IsMulliganIsActive
        {
            get
            {
                return (MulliganManager.Get() != null) && GameState.Get().IsMulliganPhase() &&
                       GameState.Get().IsMulliganManagerActive() && MulliganManager.Get().GetMulliganButton();
            }
        }

        public static bool IsMyTurn()
        {
            return GameState.Get().IsFriendlySidePlayerTurn();
        }

        public static bool IsPassMulligan
        {
            get { return GameState.Get().IsPastBeginPhase(); }
        }

        public static LbPlayer MyPlayer
        {
            get { return new LbPlayer(GameState.Get().GetCurrentPlayer()); }
        }

        public static void NukeEnemy()
        {
            foreach (var card in MyPlayer.CardsInField())
            {
                if(!card.CanAttack) continue;
                card.Attack(EnemyPlayer);
            }
        }

        public static void PlayCard(LbCard card)
        {
            if (!card.CanPlay) return;
            ActionQueue.Add(new PlayCardAction(card));
        }

        public static void PlayCards()
        {
            var cardsInHand = MyPlayer.CardsInHand();
            foreach (var card in cardsInHand)
            {
                if (!card.IsMinion)
                    continue;
                PlayCard(card);
            }
        }

        public static void ReplaceCards()
        {

            var cards = MyPlayer.CardsInHand();
            foreach (var card in cards)
            {
                if (card.Cost >= 3)
                    MulliganManager.Get().ToggleHoldState(card.Source);
            }
            MulliganManager.Get().GetMulliganButton().TriggerRelease();
        }
    }
}
