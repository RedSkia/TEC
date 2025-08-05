using System;
using System.Threading;

namespace Opgave9
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave9

            //Sætter farven på text til rød
            Console.ForegroundColor = ConsoleColor.Red;

            //Sætter farven på baggrunden til gul
            Console.BackgroundColor = ConsoleColor.Yellow;

            //Nulstiller konsollens vindue
            Console.Clear();

            //Udskriver noget text i konsollen
            Console.Write("udskriver en tekst på skærmen");

            //Spøger brugen om de er klar til næste skridt
            Console.WriteLine("Klar til beep?");

            //Venter på brugeren trykker på en tast
            Console.ReadLine();

            //Sætter en variable som bruges til at kontrollerer hastiheden på for loopet
            ushort durationMS = 50;

            //Kører et forloop fra 37 til 32767
            for (int i = 37; i < 32767; i++)
            {
                //Laver en beep lyd med frekvensen i som varar i halvdelen af durationMS i ms
                Console.Beep(i, durationMS / 2);

                //Pauser den nuværende thread i halvdelen af durationMS i ms inden loopet forsætter
                Thread.Sleep(durationMS / 2);
            }
        }
    }
}