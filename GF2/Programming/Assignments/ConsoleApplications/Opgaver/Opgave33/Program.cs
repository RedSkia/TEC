using System;

namespace Opgave33
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave33

            //Laver en lokal int varaible med værdi 0
            int number = 0;

            //Kører et while loop så længe variablen number IKKE er 50
            while (number != 50)
            {
                //Nulstiller console
                Console.Clear();

                Console.WriteLine("Skriv et tal. hint hint (50)");

                //Checker om number kan konverteres til int typen
                if (!int.TryParse(Console.ReadLine(), out number))
                {
                    //Skriver Ny linje til brugeren
                    Console.WriteLine("Kunne ikke konverterer tal");

                    //Venter på taste tryk fra brugeren
                    Console.ReadKey();

                    //Springer videre til næste loop kørsel
                    continue;
                }

                //Checker om number er 50
                if (number == 50)
                {
                    //Skriver Ny linje til brugeren
                    Console.WriteLine("Tallet er præcis 50");
                }
                else /*Ellers*/
                {
                    //Skriver Ny linje til brugeren
                    Console.WriteLine("Tallet er IKKE 50 (Kør igen?)");
                }

                //Venter på taste tryk fra brugeren
                Console.ReadKey();
            }
        }
    }
}