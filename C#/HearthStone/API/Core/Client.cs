/* 

-- Package     : API.dll
-- Script Name : Client.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/

using System;
using System.IO;
using System.Xml;

namespace API.Core
{
    public class Client
    {
        public static long GetSelectedDeckId()
        {
            var config = new XmlDocument();
            var fs =
                new FileStream(
                    (Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) +
                     "\\LogicBreakers\\Resources\\HearthStone\\config.xml"), FileMode.Open, FileAccess.Read);
            config.Load(fs);
            var list = config.GetElementsByTagName("selectedDeck");
            var xmlNode = list[0].ChildNodes.Item(0);
            if (xmlNode == null) return DeckPickerTrayDisplay.Get().GetSelectedDeckID();
            var name = xmlNode.InnerText.Trim();
            fs.Close();
            using (var enumerator = CollectionManager.Get().GetDecks().Values.GetEnumerator())
            {
                while (enumerator.MoveNext())
                {
                    var current = enumerator.Current;
                    if (name == current.Name)
                        return current.ID;
                }
            }
            return DeckPickerTrayDisplay.Get().GetSelectedDeckID();
        }

        public static int GetSelectedGameMode()
        {
            var config = new XmlDocument();
            var fs =
                new FileStream(
                    (Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) +
                     "\\LogicBreakers\\Resources\\HearthStone\\config.xml"), FileMode.Open, FileAccess.Read);
            config.Load(fs);
            var list = config.GetElementsByTagName("selectedMode");
            var xmlNode = list[0].ChildNodes.Item(0);
            if (xmlNode == null) return 0;
            var id = xmlNode.InnerText.Trim();
            fs.Close();
            return Int32.Parse(id);
        }

        public static GameType GetSelectedGameType()
        {
            var selectedMode = GetSelectedGameMode();
            switch (selectedMode)
            {
                case 0:
                    return GameType.VsAi;
                case 1:
                    return GameType.VsAi;
                case 2:
                    return GameType.Unranked;
                case 3:
                    return GameType.Ranked;
                default:
                    return GameType.VsAi;
            }
        }

        public static MissionIds GetSelectedMission()
        {
            var selectedMode = GetSelectedGameMode();
            switch (selectedMode)
            {
                case 0:
                    return Menu.RandomMission(false);
                case 1:
                    return Menu.RandomMission(true);
                case 2:
                    return MissionIds.Multiplayer_1V1;
                case 3:
                    return MissionIds.Multiplayer_1V1;
                default:
                    return Menu.RandomMission(false);
            }
        }

        public static void SetSelectedMode()
        {
            SceneMgr.Mode nextMode;
            var selected = GetSelectedGameMode();
            switch (selected)
            {
                case 0:
                    nextMode = SceneMgr.Mode.ADVENTURE;
                    break;
                case 1:
                    nextMode = SceneMgr.Mode.ADVENTURE;
                    break;
                case 2:
                    nextMode = SceneMgr.Mode.TOURNAMENT;
                    break;
                case 3:
                    nextMode = SceneMgr.Mode.TOURNAMENT;
                    break;
                default:
                    nextMode = SceneMgr.Mode.ADVENTURE;
                    break;
            }
            SceneMgr.Get().SetNextMode(nextMode);
        }
    }
}
