using System;

namespace Arrays
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Arrays

            //Laver et double på 10
            double[] peopleHeight = new double[10];

            //Kører et for loop med længde på peopleHeight
            for (int i = 0; i < peopleHeight.Length; i++)
            {
                //Skriver NY linje beder brugeren om at intaste højte
                Console.WriteLine($"Skriv højte på person nr. {i + 1}");

                //Prøver at konverterer input til double og hvis det fejler springer den videre
                if (!double.TryParse(Console.ReadLine(), out peopleHeight[i])) { continue; }
            }

            //Nulstilelr console
            Console.Clear();

            //Skriver NY LInje
            Console.WriteLine("Liste af højten på personer");

            //Kører et for loop med længde på peopleHeight
            for (int i = 0; i < peopleHeight.Length; i++)
            {
                //Skriver NY linje med person nummer (index i) og højte
                Console.WriteLine($"Højte på person nr. {i+1} er {peopleHeight[i]}");
            }

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}