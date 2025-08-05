using System;

namespace SofticeShop
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// SofticeShop

            //Skriver Ny linje til brugeren
            Console.WriteLine("Vil du købe en (stor) eller (lille) softice");

            //Laver en swtich som tager input fra brugeren og laver det til små letters
            switch (Console.ReadLine().ToLower())
            {
                //Hvis stor kør denne kode
                case "stor": {
                    //SKriver NY linje
                    Console.WriteLine("En stor softice koster 5kr");
                } break;

                //Hvis lille kør denne kode
                case "lille": {
                    //SKriver NY linje
                    Console.WriteLine("En stor softice koster 8kr");
                } break;
                
                default: {
                    //SKriver NY linje
                    Console.WriteLine("Denne softice størelse findes ikke");
                } break;
            }

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }
    }
}