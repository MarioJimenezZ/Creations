/* 

-- Package     : API.dll
-- Script Name : Handler.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 9, 2015

*/


using System;
using System.IO;
using UnityEngine;


namespace API
{
    public class Handler : MonoBehaviour
    {
        private bool _loadedDecks;
        private bool _needUpdate;

        private void Start()
        {
            Log.Write("API.dll has been loaded");
        }

  
        private void Update()
        {
            // Updates DeckList On Start
            var myDecks = CollectionManager.Get().GetDecks();
            if (myDecks.Count > 0 && !_loadedDecks)
            {
                DeckListToJson(myDecks);
                _loadedDecks = true;
                _needUpdate = false;
            }
            // Updates Deck List After Editing Decks
            var gameMode = SceneMgr.Get().GetMode();
            switch (gameMode)
            {
                case SceneMgr.Mode.COLLECTIONMANAGER:
                    if (!_needUpdate)
                        _needUpdate = true;
                    break;
                default:
                    if (_needUpdate)
                        _loadedDecks = false;
                    break;
            }
        }

        private void DeckListToJson(Map<long, CollectionDeck> decks)
        {
            var deckListPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) +
                               "\\LogicBreakers\\Resources\\HearthStone\\deckList.json";
            using (TextWriter writer = File.CreateText(deckListPath))
            {
                writer.WriteLine("{");
                writer.WriteLine("\t\"{0}\"{1}", "deckList", ":[");
                var index = 1;
                foreach (var deck in decks)
                {
                    writer.WriteLine("\t{0}", "{");
                    writer.WriteLine("\t\t\"{0}\"{1}", "id", ": " + deck.Key + ",");
                    writer.WriteLine("\t\t\"{0}\"{1}\"{2}\"", "name", ": ",
                        CollectionManager.Get().GetDeck(deck.Key).Name);
                    writer.WriteLine("\t{0}", "}" + (decks.Count == index ? "]" : ","));
                    index += 1;
                }
                writer.WriteLine("}");
            }
        }
    }
}
