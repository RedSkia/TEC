using System;

namespace Opgave22
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave22

            //Skriver NY linje med text
            Console.WriteLine("Skriv din alder for at købe en billet");

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
                    Console.WriteLine("Prisen er 45kr");

                    //Forhindrer at programmet kører vidrer
                    return;
                }


                //Checker om age er mellem 18 og 65
                if (age <= 65 && age >= 18)
                {
                    //Skriver NY linje
                    Console.WriteLine("Prisen er 75kr");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Checker om age er størerer end 65
                if (age > 65)
                {
                    //Skriver NY linje
                    Console.WriteLine("Prisen er 35kr");

                    //Forhindrer at programmet kører vidrer
                    return;
                }
            }

            //Venter på tryk tast
            Console.ReadKey();
        }
    }
}