using System;

namespace Opgave25
{
    internal class Program
    {
        //Her er 4 konstante ushort's som virker som priser og EUR kurs
        const ushort singleRoomPrice = 765;
        const ushort doubleRoomPrice = 980;
        const ushort familyRoomPrice = 1250;
        const float eurExchangeRate = 7.45f; /*1 eur = 7.45 dkk*/

        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// Opgave25


            //Skriver 3 NYE linjer ud som text
            Console.WriteLine("Skriv værelse type ((E)nkelt, (D)obbelt, (F)amilie og antal værelser og antal dage");
            Console.WriteLine("Example: E:5:5 reserverer 5x enkelt værelser i 5 dage");
            Console.WriteLine("Format: RoomType:Quantity:Days");


            //Taget en array som input fra brugeren
            string[] input = Console.ReadLine()?.Split(' ');

            //Laver et array af typen RoomReservation
            RoomReservation[] reservations = new RoomReservation[input.Length];

            //Kører et for loop
            for (int i = 0; i < input.Length; i++)
            {
                //Splitter data mellem :
                string[] data = input[i].Split(':');

                //Checker og antallet af data længen er kortere end 3 også springer den videre
                if (data.Length < 3) { continue; }

                //Sætter værdien på varialben
                char roomType = data[0][0];

                //Prøver at konvertere data[1] til en ushort og hvis det ikke virker springer den videre
                if (!ushort.TryParse(data[1], out ushort roomQuantity)) { continue; }

                //Prøver at konvertere data[2] til en ushort og hvis det ikke virker springer den videre
                if (!ushort.TryParse(data[2], out ushort roomDays)) { continue; }

                //Laver en ny instance af RoomReservation og sætter værdien af reservations[i]
                reservations[i] = new RoomReservation(roomType, roomQuantity, roomDays);
            }

            //Laver en uint med værdien 0
            uint totalPrice = 0;

            //Skriver 2x nye linjer det føste kommer ved brug er WriteLINE og \n
            Console.WriteLine("\nListe over reservationer");

            //Kørere igennem alle reservations fra det array
            foreach (RoomReservation reservation in reservations)
            {
                //Henter prisen fra denne reservation fra methoden
                uint reservationPrice = GetReservationPrice(reservation);

                //Lægger reservationPrice oveni totalPrice
                totalPrice += reservationPrice;

                //Skriver NY linje fra variabler og metoder 
                Console.WriteLine($"For at reservere {reservation.RoomQuantity}x {GetRoomType(reservation?.RoomType)} værelser i {reservation.RoomDays} dage koster denne reservation {reservationPrice}dkk eller {reservationPrice / eurExchangeRate}eur");
            }

            //Skriver Ny linje med variabler
            Console.WriteLine($"Så den totale pris bliver {totalPrice}dkk eller {totalPrice / eurExchangeRate}eur");

            //Venter på brugeren trykker på en tast
            Console.ReadKey();
        }

        //Laver en varaible string som tager en char som input og giver navent på roomType i et mere læsbart format
        private static string GetRoomType(char? roomType) => (Char.ToUpper(roomType ?? ' ') == 'E' ? "Enkelt" : Char.ToUpper(roomType ?? ' ') == 'D' ? "Doublet" : Char.ToUpper(roomType ?? ' ') == 'F' ? "Familie" : null);

        //Laver en methode som tager RoomReservation som input argument
        private static uint GetReservationPrice(RoomReservation reservation)
        {
            //Laver en uint som finder prisen efter værelses typen 
            uint roomPrice = (uint)(Char.ToUpper(reservation?.RoomType ?? ' ') == 'E' ? singleRoomPrice : Char.ToUpper(reservation?.RoomType ?? ' ') == 'D' ? doubleRoomPrice : Char.ToUpper(reservation?.RoomType ?? ' ') == 'F' ? familyRoomPrice : 0);
            return (roomPrice * reservation.RoomQuantity) * reservation.RoomDays; /*Returnere prisen på værelset efter type antal og dage*/
        }

        //Laver en class til at holde styr på reservationer
        private sealed class RoomReservation
        {
            //Laver en readonly char varaible
            internal readonly char? RoomType;

            //Laver en readonly char varaible
            internal readonly ushort RoomQuantity;

            //Laver en readonly char varaible
            internal readonly ushort RoomDays;

            //Laver en constructor for klassen med argumenter
            internal RoomReservation(char? roomType, ushort roomQuantity, ushort roomDays)
            {
                //Checker om argumenterne passer 
                if (roomType == null || (Char.ToUpper(roomType ?? ' ') != 'E' && Char.ToUpper(roomType ?? ' ') != 'D' && Char.ToUpper(roomType ?? ' ') != 'F') || roomQuantity == default || roomDays == default)
                {
                    //Kaster en Exception
                    throw new ArgumentException("Mangler eller forkerte argumenter til at lave en reservation");
                }

                //Sætter klassens lokale varaibler til værdierne 
                this.RoomType = roomType;
                this.RoomQuantity = roomQuantity;
                this.RoomDays = roomDays;
            }
        }
    }
}