using System;

namespace Opgave10
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave10

            //Skriver en NY linje ud i console
            Console.WriteLine("Vælg et flag...");

            //Skriver en NY linje ud i console
            Console.WriteLine("(dk) dansk");

            //Skriver en NY linje ud i console
            Console.WriteLine("(se) svensk\r\n");

            //Får input fra brugeren og laver texten lille
            string input = Console.ReadLine().ToLower();

            //En switch er lidt ligesom IF statments jeg syndes bare dette er mere løsbart
            switch (input)
            {
                //Checker om det input er "dk" eller "dansk"
                case "dk":
                case "dansk": {
                    //Kalder metoden
                    DrawCrossFlag(backColor: ConsoleColor.Red, crossColor: ConsoleColor.White);
                } break;

                //Checker om det input er "se" eller "svensk"
                case "se":
                case "svensk": {
                    //Kalder metoden
                    DrawCrossFlag(backColor: ConsoleColor.Blue, crossColor: ConsoleColor.Yellow);
                } break;
            }

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }

        //Deklarerer en methode
        private static void DrawCrossFlag(ushort flagWidth = 50, ushort flagHeight = default, ConsoleColor backColor = ConsoleColor.Red, ConsoleColor crossColor = ConsoleColor.White)
        {
            //Checker om flagHeight er standard værdien
            if (flagHeight.Equals(default))
            {
                //Auto sætter højten på flagHeight til at passe med flagWidth
                flagHeight = (ushort)(flagWidth / 4);
            }
            //Kører et loop efter flagets højte
            for (int i = 0; i < flagHeight; i++)
            {
                //Sætter baggrundsfarve til backColor
                Console.BackgroundColor = backColor;

                //Laver en string varaible med en masse mellemum efter flagWidth
                string space = new string(' ', flagWidth);

                //Sætter cursor lokation
                Console.SetCursorPosition(0, i);

                //Ændre flagHeight efter om værdien er lige eller ulige
                flagHeight = (ushort)((flagHeight % 2 == 0) ? flagHeight + 1 : flagHeight);

                //Checker om I er = halvdelen af flagHeight
                if (i == (flagHeight / 2))
                {
                    //Sætter baggrundsfarve til crossColor
                    Console.BackgroundColor = crossColor;
                }
                //Skriver X text
                Console.Write(space);

                //Sætter baggrundsfarve til crossColor
                Console.BackgroundColor = crossColor;

                //Sætter cursor lokation
                Console.SetCursorPosition(flagWidth / 3, i);

                //Skriver Y text
                Console.Write(new string(' ', 2));
            }
        }
    }
}