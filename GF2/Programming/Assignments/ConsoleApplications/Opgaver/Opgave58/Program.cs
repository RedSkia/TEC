using System;

namespace Opgave58
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Opgave58

            //Laver et string array med dyr
            string[] pets = new string[]
            {
                "hund", 
                "kat", 
                "fugl", 
                "fisk",
                "kanin",
                "hest",
                "gnaver",
                "krybdyr",
            };

            //Kører genne listen
            foreach (string pet in pets)
            {
                //Skriver NY linje med værdien af pet
                Console.WriteLine(pet);
            }

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}