/* 

-- Package     : API.dll
-- Script Name : ActionQueue.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 13, 2015

*/

using System;
using System.Collections.Generic;
using PegasusShared;
using UnityEngine;

namespace API.LbAction
{
    public class ActionQueue : MonoBehaviour
    {
        private static readonly List<LbAction> Queue = new List<LbAction>();
        private static LbAction _lastAction;
        private static DateTime _lastExecuteTime;
        private static bool _executing;
        
        public static bool IsEmpty
        {
            get { return Queue.Count == 0; }
        }

        public static void Add(LbAction action)
        {
            Queue.Add(action);
        }

        public static void Remove(LbAction action)
        {
            Queue.Remove(action);
            _lastAction = action;
            _lastExecuteTime = DateTime.Now;
            Log.Write("Finished Action: " + action);
            _executing = false;
        }

        private void Update()
        {
            if (IsEmpty) return;
            for (var i = 1; i <= Queue.Count; i++)
            {
                var currentAction = Queue[i];
                if (!currentAction.CanExecute)
                {
                    Queue.Remove(currentAction);
                    _executing = false;
                }
                else if (!_executing && (_lastAction == null ||
                                    (DateTime.Now - _lastExecuteTime).TotalMilliseconds > _lastAction.ActionTime))
                {
                    currentAction.Execute();
                    _executing = true;
                }
                else if (_lastAction != null && (_executing && (DateTime.Now - _lastExecuteTime).TotalMilliseconds > (_lastAction.ActionTime*2)))
                    _executing = false;
            }
        }
    }
}