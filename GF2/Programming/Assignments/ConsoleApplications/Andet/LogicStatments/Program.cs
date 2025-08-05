using System;

namespace LogicStatments
{
    internal class Program
    {
        static void Main(string[] args)
        {

            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// LogicStatments

            //Skriver text på samme linje og venter på input fra brugeren
            Console.Write("Skriv et tal mellem 10-40: ");

            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af value
            if (!int.TryParse(Console.ReadLine(), out int value))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter værdi");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om værdien er mellem 10 og 40
            if (value < 10 || value > 40)
            {
                //Skriver NY linje med text
                Console.WriteLine("Tallet SKAL VÆRE MELLEM 10 OG 40!");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Skriver NY linje med text
            Console.WriteLine("Tallet passer (Nice Job!)");

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }
    }
}