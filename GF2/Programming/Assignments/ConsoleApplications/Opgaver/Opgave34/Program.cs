using System;

namespace Opgave34
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave34

            //Laver en konstant byte variable på værdien 100
            const byte loopIterations = 100;

            //Laver en byte variable på værdien 0
            byte eyes = 0;

            //Laver en ny instance af klassen Random
            Random rand = new Random();

            //Dette er et do-while loop dette betyder frøst køres koden inde i do blokken der efter bliver betingelsen checket
            do
            {
                //Sætter værdien af eyes til en værdi fra method next
                eyes = (byte)rand.Next(1, loopIterations);

                //Skriver NY linje med formatting
                Console.WriteLine("Terningen landede på {0}", eyes);

            } while (eyes < (loopIterations-1)); /*betingelsen*/

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }
    }
}