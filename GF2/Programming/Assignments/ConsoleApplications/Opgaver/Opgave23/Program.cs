using System;

namespace Opgave23
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave23

            //Her er 5 konstante bytes med værdier
            const byte smallPrice = 120;
            const byte mediumPrice = 160;
            const byte largePrice = 185;
            const byte bulkQuantity = 10;
            const byte bulkDiscountPercentage = 5;

            //Laver en type string som vi kalder size
            string size = "";

            //Laver en type byte som vi kalder antal
            byte antal = 0;

            //Skriver Ny linje og skriver input til brugeren efter S M eller F
            Console.WriteLine("Skriv størelse på TShirt (S, M, F)");

            //En siwtch som venter på knap tryk
            switch (Console.ReadKey().Key)
            {
                //Hvis S sætter vi string variablen til S
                case ConsoleKey.S: size = "S"; break;

                //Hvis M sætter vi string variablen til M
                case ConsoleKey.M: size = "M"; break;

                //Hvis F sætter vi string variablen til F
                case ConsoleKey.F: size = "F"; break;

                //Hvis ikke nogle af de korrkte knapper blev trykket kør koden her
                default: {
                    //SKriver ny Linje
                    Console.WriteLine("Størelse ikke fundet");
                    
                    //Forhindere at koden forsætter her fra
                    return;
                }
            }

            //SKriver 2x Ny Linje 
            Console.WriteLine("\nSkriv antal:");

            //Sikerer mod overflow
            unchecked
            {
                //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien af antal
                if (!byte.TryParse(Console.ReadLine(), out antal))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter antal");

                    //Forhindrer at programmet kører vidrer
                    return;
                }
            }

            //Giver prisen på det antal og størelse af TShirts man vil have
            ushort pris = (ushort)((size == "S" ? smallPrice : size == "M" ? mediumPrice : size == "F" ? largePrice : 0) * antal);
            
            //SKriver NY linje med pris antal og størelse
            Console.WriteLine($"Prisen på {antal}x {(size == "S" ? "Små" : size == "M" ? "Mellem" : size == "F" ? "Store" : "")} TShirts koster {pris}kr");

            //CHecker om antal er størere end bulk antal
            if (antal > bulkQuantity)
            {
                //Giver pisten med discount%
                ushort discountPrice = (ushort)(pris - (pris * bulkDiscountPercentage) / 100);

                //Skriver NY linje med antal og nye pris
                Console.WriteLine($"Men da du køber {antal} TShits får du {bulkDiscountPercentage}% rabat så nu koster det kun {discountPrice}kr");
            }

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}