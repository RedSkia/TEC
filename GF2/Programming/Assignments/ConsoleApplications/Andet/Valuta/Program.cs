using System;

namespace Valuta
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Valuta

            //Laver 3 doubble varaibler
            double euro, kurs, kroner;

            //Skriver text ud
            Console.Write("Indtast antal kroner: ");

            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
            if (!double.TryParse(Console.ReadLine(), out kroner))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter kroner");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
            Console.Write("Indtast kursen på eur til dkk: ");
            if (!double.TryParse(Console.ReadLine(), out kurs))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter kurs");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Formal
            euro = (double)(kroner / kurs);

            //Skriver NY linje med formatting argumenter
            Console.WriteLine("Når kursen er {0:N2}, får du {1:N2} euro, når du veksler {2:N2} danske kroner", kurs, euro, kroner);

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}