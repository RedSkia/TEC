using System;
using System.Linq;

namespace Opgave12
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave12

            //Laver en string variable ud fra et array
            var valutaTyper = String.Join(", ", typeof(ExchangeRates).GetFields(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static).Select(x => x.Name));
            
            //Skriver ny linje med en varaible
            Console.WriteLine($"Skriv en valuta ({valutaTyper})");

            //Tager input fra brugeren og laver det til CAPS
            string input = Console.ReadLine().ToUpper();

            //Tager alle fields i ExchangeRates
            var Exchange = typeof(ExchangeRates).GetField(input, System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
            
            //Laver en ny doubble variable med værdien 0
            double exchangeRate = 0;

            //Checker om værdien er tom
            if (Exchange == null)
            {
                //SKriver en NY linje
                Console.WriteLine("Invalid currency code");

                //forhindrer kæden kører vider
                return;
            }

            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af exchangeRate
            if (!double.TryParse(Exchange.GetValue(null).ToString(), out exchangeRate))
            {
                //SKriver en NY linje
                Console.WriteLine("Failed to parse currency code value");

                //forhindrer kæden kører vider
                return;
            }

            //SKriver en NY linje
            Console.WriteLine($"Skriv antal dkk");

            //Tager input fra brugeren
            string inputDKK = Console.ReadLine();

            //Laver en tom string varaible
            double dkk;

            //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af dkk
            if (!double.TryParse(inputDKK, out dkk))
            {
                Console.WriteLine("Failed to parse inputDKK");
                return;
            }

            //Laver en doubble varaible som er sat til værdien af dkk delt med exchangeRate
            double result = (double)(dkk / exchangeRate);

            //Skriver NY linje med variabler
            Console.WriteLine($"{dkk}kr kan byttes til {result}{Exchange.Name}");

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }

        /// <summary>
        /// Exchange Rates From 1x Currency To DKK
        /// </summary>

        //Laver en struct med konstante doubbles
        private struct ExchangeRates
        {
            internal const double EUR = 7.45;
            internal const double USD = 6.89;
            internal const double SEK = 0.63;
            internal const double NOK = 1.29;
            internal const double GBP = 8.69;
        }
    }
}