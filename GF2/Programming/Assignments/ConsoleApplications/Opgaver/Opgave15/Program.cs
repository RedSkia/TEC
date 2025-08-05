using System;

namespace Opgave15
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave15

            //SKriver linje ud efter svar
            Console.Write("SKriv temperatur i Fahrenheit: ");

            //Laver en tom doubble varaible
            double fahrenheit;
            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
            if (!double.TryParse(Console.ReadLine(), out fahrenheit))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter fahrenheit");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Laver en tom doubble varaible som beregner fahrenheit til celsius
            double celsius = (fahrenheit - 32) * 5 / 9;

            //SKriver NY linje med variabler
            Console.WriteLine($"{fahrenheit} Fahrenheit er det samme som {celsius} Celsius");

            //Venter på tast tryk
            Console.ReadKey();
        }
    }
}