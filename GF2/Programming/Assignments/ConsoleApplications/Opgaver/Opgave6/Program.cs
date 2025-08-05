using System;

namespace Opgave6
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 28.08.2023
            /// Opgave6

            //kører et for loop til 255
            for (int i = 0; i <= byte.MaxValue; i++)
            {
                //Skriver et special symbol fra 0 til 255 (i) som bliver casted til typen char og bruger formatting {0} index {1} symbol 
                Console.WriteLine("{0} = {1}", i, (char)i);
            }

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}
