/* 

-- Package     : API.dll
-- Script Name : LbCard.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/

using API.LbAction;

namespace API
{
    public class LbCard
    {
        public Card Source;


        public void Attack(LbCard target)
        {
            ActionQueue.Add(new AttackAction(this, target));
        }

        public void Attack(LbPlayer target)
        {
            ActionQueue.Add(new AttackAction(this, target.HeroCard));
        }

        public int AttackDamage
        {
            get { return Source.GetEntity().GetATK(); }
        }

        public bool CanAttack
        {
            get
            {
                return (!RecentlyArrive || HasCharge) && !IsAsleep && !IsExhausted && !IsFrozen &&
                       Source.GetEntity().CanAttack() && !(AttackDamage < 1);
            }
        }

        public bool CanKill(LbCard card)
        {
            return AttackDamage > card.RemainingHealth;
        }

        public bool CanPlay
        {
            get
            {
                return Game.IsMyTurn() && IsMine && RealTimeCost <= Game.MyPlayer.AvailableMana &&
                       (!IsMinion || Game.MyPlayer.MinionsInField < 7);
            }
        }

        public int Cost
        {
            get { return Source.GetEntity().GetCost(); }
        }

        public int Damage
        {
            get { return Source.GetEntity().GetDamage(); }
        }

        public bool DoReposponse
        {
            get { return InputManager.Get().DoNetworkResponse(Source.GetEntity()); }
        }

        public int Durability
        {
            get { return Source.GetEntity().GetDurability(); }
        }

        public void Drop()
        {
            GameState.Get().GetGameEntity().NotifyOfCardDropped(Source.GetEntity());
        }

        public TAG_ZONE GetZone
        {
            get { return Source.GetEntity().GetZone(); }
        }

        public int GetZonePos
        {
            get { return Source.GetEntity().GetZonePosition(); }
        }

        public void Grab()
        {
            GameState.Get().GetGameEntity().NotifyOfCardGrabbed(Source.GetEntity());
        }

        public bool HasBattleCry
        {
            get { return Source.GetEntity().HasBattlecry(); }
        }

        public bool HasCharge
        {
            get { return Source.GetEntity().HasCharge(); }
        }

        public bool HasCombo
        {
            get { return Source.GetEntity().HasCombo(); }
        }

        public bool HasDeathrattle
        {
            get { return Source.GetEntity().HasDeathrattle(); }
        }

        public bool HasDivineShield
        {
            get { return Source.GetEntity().HasDivineShield(); }
        }

        public bool HasTaunt
        {
            get { return Source.GetEntity().HasTaunt(); }
        }

        public int Health
        {
            get { return Source.GetEntity().GetHealth(); }
        }

        public bool IsAttacking
        {
            get { return Source.IsAttacking(); }
        }

        public bool IsAlive
        {
            get { return Source.GetEntity().GetZone() != TAG_ZONE.GRAVEYARD; }
        }

        public bool IsAsleep
        {
            get { return Source.GetEntity().IsAsleep(); }
        }

        public bool IsExhausted
        {
            get { return Source.GetEntity().IsExhausted(); }
        }

        public bool IsFrozen
        {
            get { return Source.GetEntity().IsFrozen(); }
        }

        public bool IsMine
        {
            get { return Source.GetEntity().IsControlledByLocalUser(); }
        }

        public bool IsMinion
        {
            get { return Source.GetEntity().IsMinion(); }
        }

        public bool IsSecret
        {
            get { return Source.GetEntity().IsSecret(); }
        }

        public bool IsSpell
        {
            get { return Source.GetEntity().IsSpell(); }
        }

        public LbCard(Card source)
        {
            Source = source;
        }

        public void LeftPlayField()
        {
            Source.NotifyLeftPlayfield();
        }

        public string Name
        {
            get { return Source.GetEntity().GetName(); }
        }

        public void PickUp()
        {
            Source.NotifyPickedUp();
        }

        public bool RecentlyArrive
        {
            get { return Source.GetEntity().IsRecentlyArrived(); }
        }

        public int RemainingHealth
        {
            get { return Source.GetEntity().GetRemainingHP(); }
        }

        public int RealTimeCost
        {
            get { return Source.GetEntity().GetRealTimeCost(); }
        }

        public int Value()
        {
            var cardValue = 0;
            cardValue += AttackDamage;
            cardValue += Health;
            cardValue += Durability;
            cardValue += Cost;
            cardValue += Damage;
            cardValue += HasDivineShield ? 1 : 0;
            cardValue += HasTaunt ? 1 : 0;
            cardValue += HasCharge ? 1 : 0;
            cardValue += HasBattleCry ? 1 : 0;
            cardValue += HasDeathrattle ? 1 : 0;
            cardValue += HasCombo ? 1 : 0;
            cardValue += IsSecret ? 1 : 0;
            cardValue += IsSpell ? 1 : 0;
            return cardValue;
        }
    }
}
