using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Opgave45
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave45

            //Sætter console size og buffer size
            Console.SetWindowSize(80, 33);
            Console.SetBufferSize(80, 33);

            //Kører et while loop uendeligt intil det bliver stoppet
            while (true)
            {

                //Denne er et do wile loop
                do
                {
                    //Kalder metoden med argument 1
                    DrawMenu(1);

                    //Dette er en swtich som læser hvad brugeren trykker på
                    switch (Console.ReadKey().Key)
                    {
                        //Hvis brugeren trykker på 1
                        case ConsoleKey.D1: { SeatType = 1; } break;

                        //Hvis brugeren trykker på 2
                        case ConsoleKey.D2: { SeatType = 2; } break;

                        //Hvis brugeren trykker på 3
                        case ConsoleKey.D3: { SeatType = 3; } break;

                        //Hvis brugeren trykker på 4
                        case ConsoleKey.D4: { SeatType = 4; } break;

                        //ELLERS
                        default: SeatType = 0; break;
                    }

                    //Hvis variablen er mindre end 1 
                    if (SeatType < 1)
                    {
                        //Kald metoden med argument 1
                        DrawMenu(0);

                        //kalder metoden
                        AddTopMargin();

                        //kalder metoden med en string som input
                        WriteCenterAligned("Den valgte sæde type kunne ikke findes (Vil du prøve igen?)");

                        //Venter på taste tryk
                        Console.ReadKey();
                        
                        
                        //Springer vidre til næste kørsel af loopet
                        continue;
                    }

                } while (SeatType < 1); /*betingelsen*/

                //Kald metoden med argument 2
                DrawMenu(2);

                //Venter på taste tryk
                Console.ReadKey();
            }


        }

        //Dette er en readonly array med lidt fancy ASCII text
        private readonly static string[] Banner = new string[]
        {
            @"  _____ _      _              ",
            @" / ____(_)    | |             ",
            @"| |     _ _ __| | ___   _ ___ ",
            @"| |    | | '__| |/ / | | / __|",
            @"| |____| | |  |   <| |_| \__ \",
            @" \_____|_|_|  |_|\_\\__,_|___/"

        };

        //Dette er en variable som finder ud af højten mellem menu elementerne
        private static int menuHeight = (Console.WindowHeight - (Banner.Length + 12)) / 4;

        //Denne er en metode som giver lidt mellemrum på Y aksen
        private static void AddTopMargin()
        {
            //Dette er et for loop som kører antal gange på hvad værdien af menuHeight er
            for (int y = 0; y < menuHeight; y++)
            {
                //Dette skriver tvinger ny linje og cursor reset til at blive gjort 
                Console.Write("\n\r");
            }
        }

        //Denne metode tager en byte som input
        private static void DrawMenu(byte screen)
        {
            //Nulstiller console
            Console.Clear();

            //Slår console cursor fra
            Console.CursorVisible = false;

            //Skriver text linje med længden på vindue
            Console.Write(new string('=', Console.WindowWidth));

            //Kører et for loop efter længden på det Banner array
            for (int i = 0; i < Banner.Length; i++)
            {
                //Kalder metoden med nuværende element fra array'et Banner 
                WriteCenterAligned(Banner[i]);
            }

            //Skriver text linje med længden på vindue med doubblet NY linje
            Console.WriteLine("\n"+new string('=', Console.WindowWidth));

            //Sætter cursor position
            Console.SetCursorPosition(0, Console.CursorTop-1);

            //Checker om variable screen er 1
            if (screen == 1)
            {
                //Kalder metoden GetFields og får FieldInfo[] værdi tilbage
                FieldInfo[] fields = CircusSeats.GetFields();

                //Kører loop på længden af fields
                for (int i = 0; i < fields.Length; i++)
                {

                    //nuværende element fra fields
                    FieldInfo field = fields[i];

                    //Kalder metoden og får data fra GetRank som er af typen SeatRankAttribute
                    SeatRankAttribute seatRank = CircusSeats.GetRank((byte)(i + 1));

                    //Kalder metoden
                    AddTopMargin();

                    //sætter console text farven
                    Console.ForegroundColor = seatRank.color;

                    //Kalder metoden 2 gange med string som argument med varaibler
                    WriteCenterAligned($"Køb {seatRank.name} pladser {field.GetValue(null)} tilbage");
                    WriteCenterAligned($"Tryk ({seatRank.rank}) for at købe {seatRank.name}");
                }


            }

            //Nulstiller console farver
            Console.ResetColor();

            //Checker om screen er 2
            if (screen == 2)
            {
                //Får data fra metoden GetRank fra input SeatType
                SeatRankAttribute seatRank = CircusSeats.GetRank(SeatType);

                //Kalder metoden
                AddTopMargin();

                //Sætter text farven
                Console.ForegroundColor = seatRank.color;

                //Kalder metoden 2 gange med string argument med variabler
                WriteCenterAligned($"Valgte sæde type er: {seatRank.name}");
                WriteCenterAligned("Skriv antallet af sæder du ønsker at købe");

                //Nulstiller console farver
                Console.ResetColor();

                //Kalder metoden
                SetCursorCenter();

                //Checker om input fra brugeren kan laves om til ushort
                if (!ushort.TryParse(Console.ReadLine(), out ushort seatsToBuy))
                {
                    //Kalder metoden hvis det ikke virkede
                    WriteCenterAligned("Kunne ikke konverterer input til antal sæder");

                    //Retunerer og forhinder kørsel
                    return;
                }

                //Får data fra metoden GetFields af typen FieldInfo[]
                FieldInfo[] fields = CircusSeats.GetFields();

                //En byte variable med værdi 0
                byte availableType = 0;

                //For loop med længte på fields
                for (int i = 0; i < fields.Length; i++)
                {
                    //Hvis sæde type ikke havde nok pladser forsæt
                    if (seatsToBuy > (ushort)fields[i].GetValue(null)) { continue; }

                    //øger med +1
                    availableType = (byte)(i + 1);

                    //Stopper loopet
                    break;
                }

                //Checker om availableType er 0
                if (availableType == 0)
                {
                    //Kalder metoden 2x gange med string argument med variable
                    WriteCenterAligned($"Ingen sæde typer kunne passe til behov for {seatsToBuy}x sæder");
                    WriteCenterAligned($"Prøv at justerer til behov da vi har begrænset antal sæder");

                    //forhindre vidre kørsel
                    return;
                }


                //Hvis SeatType ikke er lig med availableType
                if (SeatType != availableType)
                {
                    //Kalder metoden 2x gange med string argument med variable og metoder
                    WriteCenterAligned($"Der er kun {CircusSeats.GetRemaningSeats(SeatType)} {CircusSeats.GetRank(SeatType).name} tilgængelige/tilbage så du kan ikke købe {seatsToBuy}x");
                    WriteCenterAligned($"Må vi anbefale de næst bedste sæder? {CircusSeats.GetRank(availableType).name} Vi har {CircusSeats.GetRemaningSeats(availableType)}x tilgængelige/tilbage");
                }


                //Kalder metoden 2x gange med string argument med variable og metoder
                WriteCenterAligned($"Prisen på {seatsToBuy}x {CircusSeats.GetRank(availableType).name} sæder bliver {CircusSeats.GetRank(availableType).price * seatsToBuy}dkk");
                WriteCenterAligned($"Tryk på en ENTER knap for at købe");

                //Hvis ikke brugeren tykker ENTER forhindre vædre kørsel
                if (Console.ReadKey().Key != ConsoleKey.Enter) { return; }

                //Prøver at købe biletter
                if (!CircusSeats.BuySeats(availableType, seatsToBuy))
                {
                    //Kalder metoden med string argument
                    WriteCenterAligned($"Købet fejlede");

                    //forhindre vidre kørsel
                    return;
                }

                //Kalder metoden med string argument
                WriteCenterAligned($"Købet success");
            }
        }


        //Denne metode tager string argument som vi kalder text
        //Også skriver NY linje ud med x mellemrum så texten bliver centret ved at tage længden af vindue - text længden og dele med 2
        private static void WriteCenterAligned(string text) => Console.WriteLine($"{new string(' ', (Console.WindowWidth - text.Length) / 2)}{text}");

        //Denne metode sætter cursor til havldelen af vindue width
        private static void SetCursorCenter() =>  Console.CursorLeft = Console.WindowWidth / 2;

        //Dette er en variable med værdien 0 som vi bruger til at checke hvilken sæde type det blev valgt
        private static byte SeatType = 0;

        //Dette er en struct som vi kalder CircusSeats
        private struct CircusSeats
        {
            //Denne metode tager alle fælter i CircusSeats som er ikke public (access modifier) og som er static
            internal static FieldInfo[] GetFields() => typeof(CircusSeats).GetFields(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);

            //Denne metoder bruger GetFields og bygger vidre så den tager alle hvor de har (Attribute) SeatRankAttribute på sig
            internal static IEnumerable<SeatRankAttribute> GetAttrs() => GetFields().SelectMany(field => field.GetCustomAttributes<SeatRankAttribute>());

            //Denne metode finder hvor SeatRankAttribute har samme rank som seatType
            internal static SeatRankAttribute GetRank(byte seatType) => GetAttrs().Where(attr => attr.rank == ((seatType > 4) ? 4 : (seatType < 1) ? 1 : seatType)).FirstOrDefault();

            //Denne metode retunerer værdien af varible efter input seatRank
            internal static ushort GetRemaningSeats(byte seatRank)
            {
                //Dette er en switch
                switch (seatRank)
                {
                    //Hvis 1 giv værdi af Pink
                    case 1: return Pink;

                    //Hvis 1 giv værdi af Gold
                    case 2: return Gold;

                    //Hvis 1 giv værdi af Red
                    case 3: return Red;

                    //Hvis 1 giv værdi af Blue
                    case 4: return Blue;

                    //ELLERS giv værdi 0
                    default: return 0;
                }
            }

            //Prøver at købe sæder efter type og antal
            internal static bool BuySeats(byte seatRank, ushort quantity)
            {
                //Dette er en switch
                switch (seatRank)
                {
                    //HVIS 1 Prøver at købe pink
                    case 1: { 
                        if(quantity > Pink) { return false; }
                        Pink -= quantity;
                        return true;
                    };

                    //HVIS 2 Prøver at købe guld
                    case 2: {
                        if (quantity > Gold) { return false; }
                        Gold -= quantity;
                        return true;
                    };

                    //HVIS 3 Prøver at købe rød
                    case 3: {
                        if (quantity > Red) { return false; }
                        else { Red -= quantity; }
                        return true;
                    };

                    //HVIS 4 Prøver at købe blå
                    case 4: {
                        if (quantity > Blue) { return false; }
                        Blue -= quantity;
                        return true;
                    };

                    //ELLERS
                    default: return false;
                }
            }

            //Dette er de forseklige typer af pladser med et Attribute på
            [SeatRank(1, "Pink", ConsoleColor.Magenta, 320)]
            internal static ushort Pink = 20;

            [SeatRank(2, "Guld", ConsoleColor.Yellow, 280)]
            internal static ushort Gold = 40;

            [SeatRank(3, "Rød", ConsoleColor.Red, 250)]
            internal static ushort Red = 60;

            [SeatRank(4, "Blå", ConsoleColor.Cyan, 190)]
            internal static ushort Blue = 80;
        }

        //Dette er en Attribute klasse som brugeres til at give hver plads et rank, navn, farve og pris
        [AttributeUsage(AttributeTargets.Field, Inherited = false, AllowMultiple = false)]
        internal sealed class SeatRankAttribute : Attribute
        {
            //Dette er en byte get property som kun kan sættets af objecket selv
            internal byte rank { get; }

            //Dette er en string get property som kun kan sættets af objecket selv
            internal string name { get; }

            //Dette er en ConsoleColor get property som kun kan sættets af objecket selv
            internal ConsoleColor color { get; }

            //Dette er en ushort get property som kun kan sættets af objecket selv
            internal ushort price { get; }

            //Dette er en constructor som sætter Get værdierne
            internal SeatRankAttribute(byte rank, string name, ConsoleColor color, ushort price)
            {
                this.rank = rank; /*Sætter rank væriden*/
                this.name = name; /*Sætter name væriden*/
                this.color = color; /*Sætter color væriden*/
                this.price = price;/*Sætter price væriden*/
            }
        }
    }
}