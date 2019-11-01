/* 

-- Package     : API.dll
-- Script Name : Log.cs
-- Script Ver. : 1.0
-- Author      : Mario Jimenez
-- Date        : April 8, 2015

*/

using System;
using System.IO;

namespace API
{
    public class Log
    {
        private static readonly string LogsPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) +
                                          @"\LogicBreakers\Logs\";

        public static void Write(string msg)
        {
            var logPath = LogsPath + @"\Log.txt";
            var newContent = "[" + DateTime.Now + "] : " + msg + "\r\n";
            if (File.Exists(logPath))
            {
                var currentContent = File.ReadAllText(logPath);
                if (currentContent.Length > 5000)
                    currentContent = String.Empty;
                File.WriteAllText(logPath, newContent + currentContent);
            }
            else
            {
                File.Create(logPath);
                Write(msg);
            }
        }
    }
}
