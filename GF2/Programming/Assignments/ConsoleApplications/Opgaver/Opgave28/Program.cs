using System;

namespace Opgave28
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// Opgave28

            //Laver en int variable
            int windowStartHeight = Console.WindowHeight - 1;

            //Kører et loop som stater på 1 og ender på 100
            for (int i = 1; i <= 100; i++)
            {
                //Skriver I på NY linje
                Console.WriteLine(i);

                //Checker om i + 1 er støere end windowStartHeight
                if (i+1 > windowStartHeight)
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