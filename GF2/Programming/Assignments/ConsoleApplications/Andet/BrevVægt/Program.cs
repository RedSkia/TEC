using System;

namespace BrevVægt
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// BrevVægt

            Console.Write("Skriv vægten på brevet i gram: ");

            //Prøver at konverterer input til float
            if (!float.TryParse(Console.ReadLine(), out float weight))
            {
                //Skriver Ny linje
                Console.WriteLine("Kunne ikke konverterer dit input til en float");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om weight er mindre eller lig med 0.00
            if (weight <= 0.00f)
            {
                //Skriver Ny linje
                Console.WriteLine("Det er et meget let brev du har (Prøv igen)");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om weight er mindre eller lig med 20.00
            if (weight <= 20.00f)
            {
                //Skriver Ny linje
                Console.WriteLine("Portoen er 5,50 Kr.");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om weight er mindre eller lig med 100.00
            if (weight <= 100.00f)
            {
                //Skriver Ny linje
                Console.WriteLine("Portoen er 11,50 Kr.");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om weight er mindre eller lig med 250.00
            if (weight <= 250.00f)
            {
                //Skriver Ny linje
                Console.WriteLine("Portoen er 23,40 Kr.");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Skriver Ny linje
            Console.WriteLine("Dette er ikke et brev men en pakke");

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }
    }
}