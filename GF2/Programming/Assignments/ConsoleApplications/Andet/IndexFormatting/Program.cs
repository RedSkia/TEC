using System;

namespace IndexFormatting
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 28.08.2023
            /// IndexFormatting

            //SKriver ny linje med index formatting {0} {1} {2}
            Console.WriteLine("Jeg er {0} år og har {1} børn. Jeg har {2} kroner i banken", 50, 3, 5);


            //SKriver ny linje med index formatting {0} {1} {2}
            Console.WriteLine("Jeg hedder {0} og har {1:N14} børn. Jeg har {2} kroner i banken", "Bob", Math.PI, Int64.MinValue);

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}
