using System;

namespace Opgave16
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave16

            //Skriver text på samme linje og venter på input fra brugeren
            Console.Write("Skriv radius: ");

            //Laver en tom doubble varaible
            double radius;
            //Checker om det input fra brugeren kan konverteres til double typen også sætter værdien af radius
            if (!double.TryParse(Console.ReadLine(), out radius))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter radius");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Laver nogle doubble varaibler med formel beregning ved brug af Math klassen
            double omkreds = 2 * radius * Math.PI;
            double areal = Math.PI * Math.Pow(radius, 2);

            //Skriver NY linje med formatting og bryger \n til at også lave en ny line
            Console.WriteLine("Omkredsen er: {0:N2}\nArealet er : {1:N2}", omkreds, areal);

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }
    }
}