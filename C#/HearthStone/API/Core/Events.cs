/* 

-- Package     : API.dll
-- Script Name : Events.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/

using System;
using UnityEngine;

namespace API.Core
{
    public class Events : MonoBehaviour
    {
        private int _lastTurnRan;
        private bool _updateMulligan;
        private bool _updateGameOver;
        private static DateTime _eventDelayStart = DateTime.Now;
        public delegate void GameDrawHandler();
        public delegate void GameStartHandler();
        public delegate void GameTickHandler();
        public delegate void GameOverHandler();

        public delegate void MenuDrawHandler();
        public delegate void MenuStartHandler();
        public delegate void MenuTickHandler();

        public delegate void MulliganHandler();

        public delegate void TurnStartHandler();
        public delegate void TurnTickHandler();

        public static event GameDrawHandler GameDraw;
        public static event GameStartHandler GameStart;
        public static event GameTickHandler GameTick;
        public static event GameOverHandler GameOver;

        public static event MenuDrawHandler MenuDraw;
        public static event MenuStartHandler MenuStart;
        public static event MenuTickHandler MenuTick;

        public static event MulliganHandler Mulligan;
        
        public static event TurnStartHandler TurnStart;
        public static event TurnTickHandler TurnTick;

        private void Update()
        {
            if (Menu.GetCurrentMode() != ModeStatus.InGame && Menu.GetCurrentMode() != ModeStatus.GameOver)
                _updateGameOver = false;
            if ((!Game.IsInGame || Game.IsGameOver) && MenuStart != null)
                OnMenuStart();
            if ((!Game.IsInGame || Game.IsGameOver) && MenuTick != null)
                OnMenuTick();
            if (Game.IsInGame && GameStart != null)
                OnGameStart();
            if (!Game.IsGameOver && Game.IsInGame && Game.IsMulliganIsActive && Mulligan != null)
                StartCoroutine(DelayAction.Add(13.00F, OnMulligan));
            if (Game.IsInGame && GameTick != null)
                OnGameTick();
            if (Game.IsInGame && Game.IsMyTurn() && Game.IsPassMulligan && TurnTick != null)
                StartCoroutine(DelayAction.Add(5.00F, OnTurnTick));
            if (Game.IsInGame && Game.IsMyTurn() && Game.IsPassMulligan && TurnStart != null)
                StartCoroutine(DelayAction.Add(5.00F, OnTurnStart));
            if (Game.IsGameOver && GameOver != null)
                OnGameOver();
            if (Game.IsGameOver)
                _updateMulligan = false;
        }

        private void OnGUI()
        {
            if (Game.IsInGame && GameDraw != null)
                OnGameDraw();
            if (!Game.IsInGame && MenuDraw != null)
                OnMenuDraw();
        }

        protected void OnMenuStart()
        {
            MenuStart();
            MenuStart = null;
        }

        protected void OnMenuTick()
        {
            MenuTick();
        }

        protected void OnMenuDraw()
        {
            MenuDraw();
        }

        public void OnMulligan()
        {
            if (_updateMulligan) return;
            Mulligan();
            _updateMulligan = true;
        }
        protected void OnGameStart()
        {
            GameStart();
            GameStart = null;
        }

        private void OnTurnTick()
        {
            TurnTick();
        }

        protected void OnTurnStart()
        {
            if (_lastTurnRan == Game.GetTurn()) return;
            TurnStart();
            _lastTurnRan = Game.GetTurn();
        }
        protected void OnGameTick()
        {
            GameTick();
        }

        protected void OnGameDraw()
        {
            GameDraw();
        }

        protected void OnGameOver()
        {
            if (_updateGameOver) return;
            GameOver();
            _updateGameOver = true;
        }
    }
}
