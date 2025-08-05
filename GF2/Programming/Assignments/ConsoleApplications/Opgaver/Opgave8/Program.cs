using System;

namespace Opgave8
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave8

            //Skriver linjen ud i konsollen
            Console.WriteLine("Kære alle. Velkommen til fest.");

            //Skriver linjen ud i konsollen med formatting {0} til {10}
            Console.WriteLine("\r\n{0} medbringer {1}. \r\n{2} medbringer {3} {4}, \r\n{5} medbringer {6} {7} og \r\n{8} medbringer {9} {10}.",
                "Allan", "brød", "Per", 3, "tomater", "Lise", 5, "æbler", "Kim", 2, "bananer");

            //Venter på brugeren trykker på en tast
            Console.ReadLine();
        }
    }
}
