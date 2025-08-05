using System;

namespace WhileLoop
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// WhileLoop

            //Laver en lokal varaible af typen string som er instansieret som blank
            string password = "";

            //Dette er en do-while loop dette betyder at frøst bliver blokken do kørt derefter bliver betingelsen checket
            do
            {
                //Skriver Ny linje og spøgerger brugeren efter et kodeord som er mindst 5 tegn langt
                Console.WriteLine("Skriv et kodeord som mindst er 5 tegn langt");

                //Sætter værdien af password til hvad brugeren skriver
                password = Console.ReadLine();
            }
            while (password.Length < 5); /*Forsætter loopet HVIS antallet af tegn i password er mindre end 5 tegn*/

            //Skriver ny linje og takker brugeren for at godt kodeord
            Console.WriteLine("Kodeord godkendt TAK");

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}