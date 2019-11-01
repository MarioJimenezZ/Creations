/* 

-- Package     : API.dll
-- Script Name : LBPlayer.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/


using System.Collections.Generic;

namespace API
{
    public class LbPlayer
    {
        public Player Source;

        public int AvailableMana
        {
            get { return Source.GetNumAvailableResources(); }
        }

        public List<LbCard> CardsInHand()
        {
            var cards = new List<LbCard>();
            foreach (var card in Source.GetHandZone().GetCards())
                cards.Add(new LbCard(card));
            return cards;
        }

        public List<LbCard> CardsInField()
        {
            var cards = new List<LbCard>();
            foreach (var card in Source.GetBattlefieldZone().GetCards())
                cards.Add(new LbCard(card));
            return cards;
        }

        public ZonePlay FieldZone
        {
            get { return Source.GetBattlefieldZone(); }
        }

        public bool HasLethal()
        {
            var enemy = new LbPlayer(GameState.Get().GetFirstOpponentPlayer(Source));
            var cards = CardsInField();
            int totalDamage = 0;
            foreach (var card in cards)
            {
                if (!card.CanAttack) continue;
                totalDamage += card.AttackDamage;
            }
            return totalDamage >= enemy.RemainingHealth;
        }

        public ZoneHand HandZone
        {
            get { return Source.GetHandZone(); }
        }

        public LbCard HeroCard
        {
            get { return new LbCard(Source.GetHeroCard()); }
        }

        public bool HasTauntMinion
        {
            get { return Source.HasATauntMinion(); }
        }

        public LbPlayer(Player source)
        {
            Source = source;
        }

        public int MinionsInField
        {
            get { return Source.GetNumMinionsInPlay(); }
        }

        public int MinionsThatCanAttack()
        {
            int count = 0;
            foreach (var card in CardsInField())
                if (card.CanAttack)
                    count += 1;
            return count;

        }

        public int PlayableMinions()
        {
            int count = 0;
            foreach (var card in CardsInHand())
                if (card.CanPlay && card.IsMinion)
                    count += 1;
            return count;

        }

        public int RemainingHealth
        {
            get { return Source.GetHero().GetRealTimeRemainingHP(); }
        }

        public void UpdateMana(int amount)
        {
            Source.NotifyOfSpentMana(amount);
            Source.UpdateManaCounter();
            ManaCrystalMgr.Get().UpdateSpentMana(amount);
        }
    }
}
