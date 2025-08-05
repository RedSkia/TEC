using System;

namespace Opgave31
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// Opgave31

            //Laver en konstant uint varaible efter hvormange gange loopet i tabalen må kører
            const uint rounds = 100;

            //Laver en konstant byte varaible efter hvilken tabel skal bruges 
            const ushort table = 4;

            //Laver en int variable
            int windowStartHeight = Console.WindowHeight - 1;

            //Kører et loop som stater på 0 og ender på 100 med mellemrum på 5
            for (int i = 0; i <= (table*rounds); i += table)
            {
                //Skriver I på NY linje
                Console.WriteLine(i);

                //Checker om i + 1 er støere end windowStartHeight
                if ((i + 1) > windowStartHeight)
                {
                    //Øger buffer height med 1 hver gang denne bliver kaldt
                    Console.BufferHeight++;
                }
            }

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}