using System;

namespace Opgave40
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave40

            //Skriver NY linje til brugeren efter et taste tryk på 1, 2 eller 3
            Console.WriteLine("Tryk på 1, 2 eller 3");

            //Dette er en Switch der er et alternativ til et IF statment Men en switch er anderldes da den check på enkelte betingelser
            switch (Console.ReadKey().Key)
            {
                //Hvis brugeren trykker på 1 så køre denne kode block som skriver NY linje ud med text at brugeren trykkede på 1
                case ConsoleKey.D1: { Console.WriteLine($"\nDu trykkede på \"1\""); } break;

                //Hvis brugeren trykker på 2 så køre denne kode block som skriver NY linje ud med text at brugeren trykkede på 1
                case ConsoleKey.D2: { Console.WriteLine($"\nDu trykkede på \"2\""); } break;

                //Hvis brugeren trykker på 3 så køre denne kode block som skriver NY linje ud med text at brugeren trykkede på 1
                case ConsoleKey.D3: { Console.WriteLine($"\nDu trykkede på \"3\""); } break;

                //Hvis brugeren trykkede på noget andet end i cases ovenfor så bliver denne kode block kørt (man kan godt lidt side at hvis de cases ovenfor er if statments så er default else)
                default: { Console.WriteLine($"\nDu trykkede på noget andet end \"1, 2 eller 3\""); } break;
            }

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }
    }
}