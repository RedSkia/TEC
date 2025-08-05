using System;

namespace Opgave19
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave19

            //Skriver NY linje med text
            Console.WriteLine("Skriv din alder for at oprette en købsaftale");

            //Sikerer mod overflow
            unchecked
            {
                //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien af age
                if (!byte.TryParse(Console.ReadLine(), out byte age))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter højte");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Checker om age er mindere end 18
                if (age < 18)
                {
                    //Skriver NY linje
                    Console.WriteLine("Du er IKKE gammel nok!");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Checker om age er støre end 128
                if (age >= byte.MaxValue/2)
                {
                    //Skriver NY linje
                    Console.WriteLine("Du er FOR gammel");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Skriver NY linje
                Console.WriteLine("Købsaftale oprettet!");
            }


            //Venter på tryk tast
            Console.ReadKey();
        }
    }
}