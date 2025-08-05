using System;

namespace Position
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 28.08.2023
            /// Position

            //Sætter cursoren i konsollen på x1, y1
            Console.SetCursorPosition(1, 1);
            //Skriver text "x1, y1" ud på linjen hvor cursoren er sat
            Console.Write("x1, y1");

            //Sætter cursoren i konsollen på x20, y1
            Console.SetCursorPosition(20, 1);
            //Skriver text "x20, y1" ud på linjen hvor cursoren er sat
            Console.Write("x20, y1");

            //Sætter cursoren i konsollen på x1, y15
            Console.SetCursorPosition(1, 15);
            //Skriver text "x1, y15" ud på linjen hvor cursoren er sat
            Console.Write("x1, y15");

            //Sætter cursoren i konsollen på x20, y15
            Console.SetCursorPosition(20, 15);
            //Skriver text "x20, y15" ud på linjen hvor cursoren er sat
            Console.Write("x20, y15");

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}
