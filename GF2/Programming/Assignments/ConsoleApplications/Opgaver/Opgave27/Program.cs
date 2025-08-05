using System;

namespace Opgave27
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// Opgave27

            //Laver 2 konstante varaibler
            const ushort discountPriceCap = 1000;
            const byte discountPercentage = 5;

            //Spørger brugeren efter hvor mange kr de ønsker at købe for
            Console.WriteLine("Hvor mange dkk vil du købe for?");

            //Prøver at konverterer brugerens input til unit
            if (!uint.TryParse(Console.ReadLine(), out uint money))
            {
                //Skriver Ny linje
                Console.WriteLine("Dit input kunne ikke konverteres");

                //Forhindrer programmet kører vidre
                return;
            }

            //Checker om money er større end discountPriceCap
            if (money > discountPriceCap)
            {
                //Skriver Nye linjer med beregninger
                Console.WriteLine($"Da du køber for over {discountPriceCap}dkk får du {discountPercentage}% rabat");
                Console.WriteLine($"Så nu skal du kun betale {money - (money * discountPercentage / 100)}dkk");
            }
            else /*Ellers*/
            {
                //Skriver Nye linjer med beregninger
                Console.WriteLine($"Ingen rabat til dig :(");
                Console.WriteLine($"Du skal købe for mere end {discountPriceCap} for at få {discountPercentage}% rabat\n\rDu mangler at købe for {Math.Abs(discountPriceCap - money)}dkk");
            }

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }
    }
}