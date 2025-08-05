using System;

namespace Opgave24
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// Opgave24

            //Her er 4 konstante ushort's som virker som priser og EUR kurs
            const ushort singleRoom = 765;
            const ushort doubleRoom = 980;
            const ushort familyRoom = 1250;
            const float eurExchangeRate = 7.45f; /*1 eur = 7.45 dkk*/


            //Laver en type string som vi kalder roomType som bruges til værelse typen
            string roomType = "";

            //Laver en type byte som vi kalder roomQuantity som bruges til værelse antal
            byte roomQuantity = 0;

            //Laver en type byte som vi kalder roomRentDays som bruges til antal af dage værelset skal lejes
            byte roomRentDays = 0;

            //Skriver Ny linje og skriver input til brugeren efter S D eller F
            Console.WriteLine("Skriv størelse på Hotel værelse størrelse ((E)nkelt, (D)obbelt, (F)amilie");

            //En siwtch som venter på knap tryk
            switch (Console.ReadKey().Key)
            {
                //Hvis S sætter vi string variablen til S
                case ConsoleKey.E: roomType = "E"; break;

                //Hvis M sætter vi string variablen til M
                case ConsoleKey.D: roomType = "D"; break;

                //Hvis F sætter vi string variablen til F
                case ConsoleKey.F: roomType = "F"; break;

                //Hvis ikke nogle af de korrkte knapper blev trykket kør koden her
                default: {
                    //SKriver ny Linje
                    Console.WriteLine("Værelse type ikke fundet");

                    //Forhindere at koden forsætter her fra
                    return;
                }
            }

            //SKriver text og Ny Linje ved brug af \n
            Console.Write("\nSkriv antal værelser til reservation: ");

            //Sikerer mod overflow
            unchecked
            {
                //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien
                if (!byte.TryParse(Console.ReadLine(), out roomQuantity))
                {
                    //Skriver NY linje
                    Console.WriteLine("Forkert input type! eller overflow");

                    //Forhindrer at programmet kører vidrer
                    return;
                }
            }


            //SKriver text og Ny Linje ved brug af \n
            Console.Write("\nSkriv antal dage til reservation: ");

            //Sikerer mod overflow
            unchecked
            {
                //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien
                if (!byte.TryParse(Console.ReadLine(), out roomRentDays))
                {
                    //Skriver NY linje
                    Console.WriteLine("Forkert input type! eller overflow");

                    //Forhindrer at programmet kører vidrer
                    return;
                }
            }


            //Giver prisen på det antal og størelse af værelser man vil have
            uint pris = (uint)((roomType == "E" ? singleRoom : roomType == "D" ? doubleRoom : roomType == "F" ? familyRoom : 0) * roomQuantity) * roomRentDays;

            //SKriver NY linje med pris antal og størelse
            Console.WriteLine($"Prisen på {roomQuantity}x {(roomType == "E" ? "Enkeltværelse(r)" : roomType == "D" ? "Dobbeltværelse(r)" : roomType == "F" ? "Familieværelse(r)" : "")} i {roomRentDays} dage koster\n{pris}kr eller {pris/eurExchangeRate}eur");

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }
    }
}