using System;
using System.Threading;

namespace Opgave5
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 28.08.2023
            /// Opgave5

            //Slår den blinkende cursor fra
            Console.CursorVisible = false;

            //Laver en variable text som ikke kan ændres
            const string text = "I AM CENTERED";

            //thread lock Låser en tread til single threading
            object _lock = new object();

            //Et loop som bare forsætter
            while (true)
            {
                //thread lock
                lock (_lock)
                {
                    //Nulstiller konsollen
                    Console.Clear();

                    //Center X koordinat
                    int x = (Console.WindowWidth / 2) - (text.Length / 2);
                    //Center Y koordinat
                    int y = Console.WindowHeight / 2;

                    //Sætter cursor lokation
                    Console.SetCursorPosition(x, y);

                    //Skriver varaible text der hvor cursor lokation er sat
                    Console.Write(text);

                    //Pauser den nuværende thread i 10 ms inden loopet forsætter
                    Thread.Sleep(10);
                }
            }
        }
    }
}