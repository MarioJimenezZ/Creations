/* 

-- Package     : API.dll
-- Script Name : Menu.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/

using System;
using System.Collections.ObjectModel;
using API.Core;

namespace API
{
    public static class Menu
    {
        public static void FindGame(GameType gameType, MissionIds missionId, long deckId = 0, long aiDeckId = 0)
        {
            if (!Utility.IsTransitioning() && !Game.IsInGame)
                GameMgr.Get().FindGame((PegasusShared.GameType) gameType, (int) missionId, deckId, aiDeckId);
            GameMgr.Get().UpdatePresence();

        }

        public static void FindGame()
        {
            var status = GetCurrentMode();
            switch (status)
            {
                case ModeStatus.Adventure:
                    AdventureConfig.Get()
                        .ChangeSubScene(AdventureConfig.GetSubSceneFromMode(AdventureDbId.PRACTICE,
                            AdventureModeDbId.NORMAL));
                    break; 
            }
            var selectedDeck = Client.GetSelectedDeckId();
            var selectedGameType = Client.GetSelectedGameType();
            var selectedMission = Client.GetSelectedMission();
            FindGame(selectedGameType, selectedMission, selectedDeck);
        }

        public static ModeStatus GetCurrentMode()
        {
            var gameMode = SceneMgr.Get().GetMode();
            if (Game.IsGameOver) return ModeStatus.GameOver;
            switch (gameMode)
            {
                case SceneMgr.Mode.LOGIN:
                    return ModeStatus.Login;
                case SceneMgr.Mode.HUB:
                    return ModeStatus.MainMenu;
                case SceneMgr.Mode.ADVENTURE:
                    return ModeStatus.Adventure;
                case SceneMgr.Mode.TOURNAMENT:
                    return ModeStatus.Play;
                case SceneMgr.Mode.GAMEPLAY:
                    return ModeStatus.InGame;
                default:
                    return ModeStatus.Unknown;
            }
        }

        public static MissionIds RandomMission(bool expert)
        {
            var random = new Random();
            var aiNormal =
                new ReadOnlyCollection<MissionIds>(new[]
                {
                    MissionIds.PracticeNormalMage, MissionIds.PracticeNormalWarlock,
                    MissionIds.PracticeNormalHunter, MissionIds.PracticeNormalRogue,
                    MissionIds.PracticeNormalPriest, MissionIds.PracticeNormalWarrior,
                    MissionIds.PracticeNormalDruid, MissionIds.PracticeNormalPaladin,
                    MissionIds.PracticeNormalShaman
                });

            var aiExpert =
                new ReadOnlyCollection<MissionIds>(new[]
                {
                    MissionIds.PracticeExpertMage, MissionIds.PracticeExpertWarlock,
                    MissionIds.PracticeExpertHunter, MissionIds.PracticeExpertRogue,
                    MissionIds.PracticeExpertPriest, MissionIds.PracticeExpertWarrior,
                    MissionIds.PracticeExpertDruid, MissionIds.PracticeExpertPaladin,
                    MissionIds.PracticeExpertShaman
                });
            var aiSelected = (expert) ? aiExpert : aiNormal;
            var index = random.Next(aiSelected.Count);
            return aiSelected[index];
        }

        public static void ReleaseQuests()
        {
            if (WelcomeQuests.Get() != null)
                WelcomeQuests.Get().m_clickCatcher.TriggerRelease();
        }
    }
}
