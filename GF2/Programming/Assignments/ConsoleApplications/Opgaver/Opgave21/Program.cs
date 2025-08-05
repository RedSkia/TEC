using System;

namespace Opgave21
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave21

            //SKriver text og venter på input fra brugeren
            Console.WriteLine("Er du insat i virksomheden (J/N)");

            //En switch er lidt ligesom IF statments bare nemmere at læse syndes jeg
            switch (Console.ReadKey().Key)
            {
                //CHekcer om brugeren trykker på J
                case ConsoleKey.J: {
                    //Skriver NY linje med text
                    Console.WriteLine("\nDu får 10% rabat Tilykke!");
                } break;

                //CHekcer om brugeren trykker på N
                case ConsoleKey.N: {
                    //Skriver NY linje med text
                    Console.WriteLine("\nIngen rabat til dig Bare surt!");
                } break;

                //CHecker om brugeren trykker på andet en J eller N
                default: {
                    //Skriver NY linje med text
                     Console.WriteLine("\nForkert kanp!");
                } break;
            }
        }
    }
}