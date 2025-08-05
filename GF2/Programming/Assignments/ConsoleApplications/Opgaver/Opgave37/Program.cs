
//Laver en definition til hvis man vil snyde
//#define CHEAT

using System;

namespace Opgave37
{
    internal class Program
    {
        //Laver et array af typen string med byer på Fyn
        private static readonly string[] cities = new string[]
        {
            "Odense",
            "Svendborg",
            "Nyborg",
            "Middelfart",
            "Faaborg",
            "Assens",
            "Kerteminde",
            "Ringe",
            "Munkebo",
            "Otterup",
            "Bellinge",
            "Strib",
            "Langeskov",
            "Bogense",
            "Årslev",
            "Glamsbjerg",
            "Vissenbjerg",
            "Søndersø",
            "Nørre Aaby",
            "Aarup"
        };
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave37

            //Laver en ny instance af klassen Random
            Random rand = new Random();

            //Laver en string varaible med navent på en by fra det array og laver navent til lowercase
            string city = cities[rand.Next(0, cities.Length)].ToLower();

            //Laver en tom variable af typen string til at huske brugerens gæt
            string guess;

            //Laver en varaible til at huske antalet af gæt brugeren skulle bruge
            int guessCounter = 0;

            //Dette er et do-while loop dette betyder frøst køres koden inde i do blokken der efter bliver betingelsen checket
            do
            {
                //Nulstiller Console
                Console.Clear();
//Dette er et definition check
#if CHEAT
                //Skriver Ny Linje
                Console.WriteLine($"Byens navn er: {city}");
#endif

                //Skriver NU linje spørger efter et by navn fra brugeren
                Console.WriteLine("Skriv dit gæt på en by på Fyn (Små bogstaver)");

                //Sætter variablen til brugerens gæt
                guess = Console.ReadLine().ToLower();

                //Checker om brugerns gæt på by navn ikke er korrekt
                if(guess != city)
                {
                    //Skriver Ny Linje
                    Console.WriteLine("Tæt på men ikke helt korrekt (Prøv igen)");

                    //Venter på taste tryk
                    Console.ReadKey();
                }

                //Øger med 1
                guessCounter++;
            }
            while (guess != city); /*Loop Betingelse*/

            //Skriver Ny Linje med varaible at nu har brugeren gættet den rigite by
            Console.WriteLine($"Tilykke du gættede det!\nMed kun {guessCounter} forsøg");

            //Venter på taste tryk
            Console.ReadLine();
        }
    }
}