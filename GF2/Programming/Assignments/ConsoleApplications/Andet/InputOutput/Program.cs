using System;

namespace InputOutput
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// InputOutput

            #region InputOutput String 
            {
                //Skriver text ud beder brugen om noget text;
                Console.Write("Indtast dit navn: ");

                //Laver en varaible som venter på et linje input fra brugeren
                string navn = Console.ReadLine();

                //Skriver en NY linje ud med variablen navn
                Console.WriteLine($"Hej med dig: {navn}");

                //Venter på brugeren trykker på en tast
                Console.ReadKey();
            }
            #endregion InputOutput String

            #region InputOutput Int 
            {
                //Laver flere typer af int variabler
                int tal1, tal2, resultat;

                //Skriver en NY linje
                Console.WriteLine("Skriv et tal");

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                if (!int.TryParse(Console.ReadLine(), out tal1))
                {
                    //Skriver en NY linje ud
                    Console.WriteLine("Fejlede til at konverter tal1");
                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Skriver en NY linje
                Console.WriteLine("Skriv andet tal");
                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal2
                if (!int.TryParse(Console.ReadLine(), out tal2))
                {
                    //Skriver en NY linje ud
                    Console.WriteLine("Fejlede til at konverter tal2");
                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Sætter varaiblen resultat til værdien af tal1 + tal2
                resultat = tal1 + tal2;

                //Skriver en NY linje ud med varaiblen resultat
                Console.WriteLine($"Resultat bliver = {resultat}");

                //Venter på brugeren trykker på en tast
                Console.ReadKey();
            }
            #endregion InputOutput Int
        }
    }
}