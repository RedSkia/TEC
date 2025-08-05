using System;

namespace PositiveNumbers
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// PositiveNumbers

            //Laver en int type variable
            int number;


            //Dette er et do-while loop dette betyder frøst køres koden inde i do blokken der efter bliver betingelsen checket
            do
            {
                //Skriver text og spørger brugeren efter et positivt tal
                Console.Write("Skriv en positivt tal: ");

                //Prøver at konvaterer brugerens input til int data typen
                if(!int.TryParse(Console.ReadLine(), out number))
                {
                    //Skriver NY linje hvis det mislykkedes
                    Console.WriteLine("Kunne ikke konvertere (Prøv igen)");

                    //Venter på taste tryk
                    Console.ReadKey();

                    //Springer videre i loopet
                    continue;
                }

                //Checker om number er mindre eller lig med 0
                if(number <= 0)
                {
                    //Skriver NY linje hvis tallet ikke er positivt 
                    Console.WriteLine($"Tallet {number} er ikke et positivt tal (Prøv igen)");

                    //Venter på taste tryk
                    Console.ReadKey();
                }
            }
            while (number <= 0); /*betingelsen*/


            //Skriver NY linje takker brugeren for et godt tal
            Console.WriteLine("Tallet er godkendt TAK");

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}