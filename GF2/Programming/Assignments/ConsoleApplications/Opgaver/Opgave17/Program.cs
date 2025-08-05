using System;

namespace Opgave17
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave17

            //Laver 2 tomme doubble variabler
            double højde, grundlinje;

            //Skriver text på samme linje og venter på input fra brugeren
            Console.Write("Skriv højde: ");

            //Checker om det input fra brugeren kan konverteres til double typen også sætter værdien af højte
            if (!double.TryParse(Console.ReadLine(), out højde))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter højte");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Skriver text på samme linje og venter på input fra brugeren
            Console.Write("Skriv grundlinje: ");

            //Checker om det input fra brugeren kan konverteres til double typen også sætter værdien af grundlinje
            if (!double.TryParse(Console.ReadLine(), out grundlinje))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter grundlinje");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Laver nogle doubble varaibler med formel beregning ved brug af Math klassen
            double omkreds = Math.Sqrt((Math.Pow(højde, 2) + Math.Pow(grundlinje, 2)) + højde + grundlinje);

            //Skriver NY linje med string interpolation
            Console.WriteLine($"Omkredsen er: {Math.Round(omkreds, 2)}");

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }
    }
}