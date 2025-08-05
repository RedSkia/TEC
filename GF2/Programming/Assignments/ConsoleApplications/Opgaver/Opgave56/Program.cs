using System;

namespace Opgave56
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Opgave56

            //Laver en ny Tuple med 7 elementer
            (string, double)[] temperaturesOverTheWeek = new(string, double)[7]
            {
                ("Mandag", 27.3),
                ("Tirsdag", 21.5),
                ("Onsdag", 23.9),
                ("Torsdag", 28.1),
                ("Fredag", 31.4),
                ("Lørdag", 19.6),
                ("Søndag", 18.0)
            };


            //Bruger denne double variable til at beregne gennesnit temp
            double averageTemperature = 0;

            //Et for loop som kører antal gange efter længden på temperaturesOverTheWeek
            for (int i = 0; i < temperaturesOverTheWeek.Length; i++)
            {
                //Skriver NY linje med Temperatur for dagen og hvad den var
                Console.WriteLine($"Temperatur for {temperaturesOverTheWeek[i].Item1} var {temperaturesOverTheWeek[i].Item2}");

                //Øger averageTemperature med værdien fra Item2
                averageTemperature += temperaturesOverTheWeek[i].Item2;
            }

            //Skriver NY linje med averageTemperature
            Console.WriteLine("Gennemsnit temperaturen var: {0:N1}", averageTemperature / temperaturesOverTheWeek.Length);

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}