//Grundforløb 2 programmerings opgave 2024
//Lavet af Lukas, Marcus, My og Susanne fra klassen D06


//Her fortæller vi programmet at vi bruger værktøjer fra "System" "namespace"
using System;

//Her laver vi et "namespace" det kan sammenlignes lidt med et projekt navn
namespace ConsoleApp
{
    //Her laver vi en "class" ved navn "Program" som fortæller at dette er vores indgangspunkt til koden (Dette er ude over pensum)
    internal sealed class Program
    {
        //Her laver vi en variabel af typen "string" som er tekst og har værdien Ab12345 som tekst vi bruger til at sammenligne kodeord med (Denne variabel er konstant og kan IKKE ændres mens programmet kører)
        private const string password = "Ab12345";

        //Her laver vi en variabel af typen "bool" denne variabel kan være til eller fra (true eller false)
        private static bool isPasswordEnabled = false;

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" (Denne variabel er markeret "readonly" det betyder at efter dens værdi er sat mens programmet kører kan den ikke ændres)
        private static readonly string[] informationOptions = new string[3]
        {
            "Tilmelding af nyhedsbrev",
            "Søg efter bruger",
            "Vis alle brugere",
        };

        //Her laver vi en variabel af typen "string" som er tekst og har værdien Nyhedsbrev informationsstander som tekst vi bruger til at sætte titlen på vores program (Denne variabel er konstant og kan IKKE ændres mens programmet kører)
        private const string defaultTitle = "Nyhedsbrev informationsstander";

        //Her laver vi en variabel af typen "byte" som er et helt tal mellem 0 og 255 og har værdien 12 som et tal vi bruger til at begrænse antal af brugere der vises af gangen (Denne variabel er konstant og kan IKKE ændres mens programmet kører)
        private const byte maxDisplayItems = 12;

        //Her laver vi en variabel af typen "string" som er tekst og har værdien {0,-20}{1,-20}{2,-20}{3,-20}{4,-50}{5,-20}{6,-30}{7,-20} som tekst vi bruger til at formatere visningen af bruger data (Denne variabel er konstant og kan IKKE ændres mens programmet kører)
        private const string displayTableFormat = "{0,-20}{1,-20}{2,-20}{3,-20}{4,-50}{5,-20}{6,-30}{7,-20}";

        //Her laver vi en "region" ved navn "Data" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
        #region Data
        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive telefonnumre
        private static string[] phoneNumbers = new string[]
        {
            "1234-5678",
            "5678-1234",
            "8765-4321",
            "4321-8765",
            "7890-1234",
            "3210-9876",
            "2345-6789",
            "8901-2345",
            "4567-8901",
            "6789-0123",
            "2109-8765",
            "5432-1098",
            "9876-5432",
            "3210-8765",
            "6789-2109",
            "1098-7654",
            "2345-6789",
            "8765-4321",
            "5432-1098",
            "2109-8765"
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive fornavne
        private static string[] firstNames = new string[]
        {
            "Emma",
            "Olivia",
            "Ava",
            "Amelia",
            "Johan",
            "Isabella",
            "Charlotte",
            "Mia",
            "Evelyn",
            "Harper",
            "Layla",
            "Zoey",
            "Noah",
            "Liam",
            "William",
            "Elijah",
            "James",
            "Benjamin",
            "Alexander",
            "Mason"
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive efternavne
        private static string[] lastNames = new string[]
        {
            "Johnson",
            "Williams",
            "Brown",
            "Davis",
            "Miller",
            "Wilson",
            "Anderson",
            "Jones",
            "Taylor",
            "Thomas",
            "Hernandez",
            "Martinez",
            "Garcia",
            "Rodriguez",
            "Lopez",
            "Smith",
            "White",
            "Thompson",
            "Moore",
            "Lee"
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "byte" som indeholder 20 fiktive aldre
        private static byte[] ages = new byte[]
        {
            7,
            28,
            56,
            19,
            82,
            43,
            31,
            65,
            23,
            91,
            52,
            15,
            80,
            45,
            34,
            62,
            21,
            90,
            53,
            17
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive telefonnumre
        private static string[] addresses = new string[]
        {
            "1234 Elm Street, Springfield, FA",
            "5678 Maple Avenue, Rivertown, TX",
            "9876 Oak Lane, Meadowville, CA",
            "4321 Pine Court, Lakeside, NY",
            "8765 Birch Road, Hilltop, AZ",
            "2345 Cedar Drive, Harbor City, WA",
            "6789 Redwood Lane, Mountain View, CO",
            "3456 Sycamore Circle, Lakeshore, GA",
            "7890 Aspen Boulevard, Summitville, NV",
            "2109 Willow Lane, Sunset Hills, FL",
            "6543 Juniper Street, Highland Park, OR",
            "8901 Magnolia Avenue, Riverside, UT",
            "1098 Birchwood Court, Greenfield, NM",
            "5432 Pinecrest Road, Woodland, OH",
            "8765 Cypress Drive, Maplewood, KY",
            "3210 Oakwood Lane, Lakeside, IA",
            "7654 Walnut Avenue, Springfield, IL",
            "2345 Cedarwood Drive, Riverdale, TX",
            "6789 Elmwood Court, Hillcrest, NC",
            "1234 Redwood Street, Meadowview, MI"
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "ushort" som er et helt tal mellem 0 og 65535 og indeholder 20 fiktive postnumre
        private static ushort[] postageNumbers = new ushort[]
        {
            1234,
            6789,
            5432,
            8765,
            3456,
            5432,
            1098,
            9876,
            8912,
            5678,
            2109,
            7654,
            5432,
            1098,
            6789,
            1098,
            5432,
            7654,
            1098,
            5432
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive byer
        private static string[] cities = new string[]
        {
            "Springfield, FA",
            "Rivertown, TX",
            "Meadowville, CA",
            "Lakeside, NY",
            "Hilltop, AZ",
            "Harbor City, WA",
            "Mountain View, CO",
            "Lakeshore, GA",
            "Summitville, NV",
            "Sunset Hills, FL",
            "Highland Park, OR",
            "Riverside, UT",
            "Greenfield, NM",
            "Woodland, OH",
            "Maplewood, KY",
            "Lakeside, IA",
            "Springfield, IL",
            "Riverdale, TX",
            "Hillcrest, NC",
            "Meadowview, MI"
        };

        //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "string" som indeholder 20 fiktive mail adresser
        private static string[] mails = new string[]
        {
            "emma-johnson@email.com",
            "olivia-williams@email.com",
            "ava-brown@email.com",
            "amelia-davis@email.com",
            "johan-miller@email.com",
            "isabella-wilson@email.com",
            "charlotte-anderson@email.com",
            "mia-jones@email.com",
            "evelyn-taylor@email.com",
            "harper-thomas@email.com",
            "layla-hernandez@email.com",
            "zoey-martinez@email.com",
            "noah-garcia@email.com",
            "liam-rodriguez@email.com",
            "william-lopez@email.com",
            "elijah-smith@email.com",
            "james-white@email.com",
            "benjamin-thompson@email.com",
            "alexander-moore@email.com",
            "mason-lee@email.com"
        };
        #endregion Data
        //Her stopper vi en "endregion" ved navn "Data" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

        //Her laver vi en "method/function" ved navn "Main" som fortæller at dette er vores direkte indgangspunkt til koden (Dette er ude over pensum)
        static void Main()
        {
            //Her sætter vi titlen på vores "Console" program til værdien af "defaultTitle" som har værdien "Nyhedsbrev informationsstander"
            Console.Title = defaultTitle;

            //Her laver vi et "while" loop som forsætter uendeligt indtil vi bruger nøgleordet "break" eller "return" som stopper eller returnere i loopet
            while (true)
            {
                //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                Console.Clear();

                //Her sætter vi musposition til øverst til venstre
                Console.SetCursorPosition(0, 0);

                //Her skriver vi en NY linje ud i "Console" vinduet
                Console.WriteLine("Velkommen til denne informationsstander");

                //Her skriver vi en NY linje ud i "Console" vinduet og i enden af vores tekst rykker vi musmarkøren helt tilbage og laver ny linje
                Console.WriteLine("Venligst vælg en af mulighederne\r\n");

                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "informationOptions"
                for (int i = 0; i < informationOptions.Length; i++)
                {
                    //Her skriver vi en NY linje ud i "Console" vinduet med teksten fra informationOptions med index "i" som er et helt tal
                    Console.WriteLine($"{informationOptions[i]} (Tryk {i + 1})");
                }

                //Her bruger vi "Console" hvor vi læser hvilken knap brugeren trykker på
                ConsoleKey inputKey = Console.ReadKey(true).Key;

                //Her laver vi et "if" check hvor vi checker på om vores "bool" "isPasswordEnabled" er "false" og knappen brugeren trykkede på er 2 eller 3
                if (isPasswordEnabled == false && (inputKey == ConsoleKey.D2 || inputKey == ConsoleKey.D3 || inputKey == ConsoleKey.NumPad2 || inputKey == ConsoleKey.NumPad3))
                {
                    //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                    Console.Clear();

                    //Her skriver vi tekst og spørger brugeren efter et kodeord
                    Console.Write("Skriv kodeord (og tryk på \"Enter\"): ");

                    //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputPassword"
                    string inputPassword = Console.ReadLine();

                    //Her laver vi et "if" check hvor vi checker på om vores "string" "inputPassword" tekst indhold er tomt ELLER vores "string" "inputPassword" tekst indhold IKKE er det samme som vores vores "string" "password"
                    if (String.IsNullOrWhiteSpace(inputPassword) || String.Equals(inputPassword, password, StringComparison.Ordinal) == false)
                    {
                        //Her skriver vi en NY linje ud i "Console" vinduet at kodeordet brugeren skrev er forkert og ikke passer med vores konstante variabel "password"
                        Console.WriteLine("Tomt eller forkert kodeord");

                        //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                        Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                        //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                        Console.ReadKey(true);

                        //Her springer vi tilbage til starten af vores "while" loop
                        continue;
                    }

                    //Vi kan kun komme her til HVIS det kodeord brugeren skrev passede sammen med vores konstante variabel "password" også skriver vi til brugeren kodeordet er korrekt
                    Console.WriteLine("Kodeord godkendt");

                    //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                    Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                    //Her ændre vi vores "bool" variabel "isPasswordEnabled" til "ture" som betyder at nu er kodeordet arktiveret
                    isPasswordEnabled = true;

                    //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                    Console.ReadKey(true);

                    //Her springer vi tilbage til starten af vores "while" loop
                    continue;
                }

                //Her laver vi et "if" check hvor vi checker på om den knap brugeren trykke på er "Escape" og vores "bool" "isPasswordEnabled" er "true"
                if (inputKey == ConsoleKey.Escape && isPasswordEnabled)
                {
                    //Her ændre vi vores "bool" variabel "isPasswordEnabled" til "false" som betyder at nu er kodeordet deaktiveret
                    isPasswordEnabled = false;

                    //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                    Console.Clear();

                    //Her skriver vi en NY linje ud i "Console" vinduet at "isPasswordEnabled" er nu slået fra
                    Console.WriteLine("Kodeord privilegium deaktiveret");

                    //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                    Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                    //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                    Console.ReadKey(true);

                    //Her springer vi tilbage til starten af vores "while" loop
                    continue;
                }

                //Her laver vi en "Switch" det er næsten det samme som vores "if" checks bare lidt anden opstilling
                switch (inputKey) /*I denne "switch" checker vi på hvilken knap brugeren trykkede på*/
                {
                    //Hvis brugeren trykkede på numpad 1 ELLER talrækken 1
                    case ConsoleKey.NumPad1:
                    case ConsoleKey.D1:
                        {
                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter telefonnummer

                            //Her skriver vi tekst og spørger brugeren efter deres telefonnummer
                            Console.Write("Skriv dit telefonnummer (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputPhoneNumber"
                            string inputPhoneNumber = Console.ReadLine();

                            //Her laver vi et "if" check hvor vi checker på om vores "string" "inputPhoneNumber" tekst indhold er tomt
                            if (String.IsNullOrWhiteSpace(inputPhoneNumber))
                            {
                                //Hvis teksten i inputPhoneNumber er tom skriver vi NY linje til brugeren og fortæller dem det
                                Console.WriteLine($"Det indtastede telefonnummer er tomt eller ugyldigt");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }

                            //Her laver vi en "bool" til at angive om det indtastede telefonnummer allerede findes
                            bool isPhoneNumberFound = false;

                            //Her kører vi et "foreach" som er anderledes end et "for" loop da denne type loop kører ingemmen alle værdier i vores "array" "phoneNumbers"
                            foreach (string phoneNumber in phoneNumbers)
                            {
                                //Her laver vi et "if" check som checker hvis vores telefonnummer som brugeren skrev "string" "inputPhoneNumber" er det samme som nuværende element i vores "foreach" loop "phoneNumber"
                                if (inputPhoneNumber == phoneNumber)
                                {
                                    //Her vi sætter også vores "bool" variabel "isPhoneNumberFound" til "true" da det indtastede telefonnummer allerede findes
                                    isPhoneNumberFound = true;

                                    //Hvis det telefonnummer som brugeren skrev passer med en af telefonnummerne i vores telefonnummer "array" så findes det allerede og vi skriver NY linje til brugeren
                                    Console.WriteLine("Telefonnummeret er allerede registreret!");

                                    //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                    Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                    //Her venter vi lige på brugeren trykker på en knap så de får en chance til at læse linjen ovenover
                                    Console.ReadKey(true);

                                    //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                    break;
                                }
                            }

                            //Her laver vi et "if" check hvor vi checker på om vores "bool" "isPhoneNumberFound" er "true"
                            if (isPhoneNumberFound == true)
                            {
                                //Hvis det indtastede telefonnummer allerede findes ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter telefonnummer
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter fornavn

                            //Her skriver vi tekst og spørger brugeren efter deres fornavn
                            Console.Write("Skriv dit fornavn (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputFirstName"
                            string inputFirstName = Console.ReadLine();

                            //Her laver vi et "if" check hvor vi checker på om vores "string" "inputFirstName" tekst indhold er tomt
                            if (String.IsNullOrWhiteSpace(inputFirstName))
                            {
                                //Her skriver vi NY linje til brugeren at det indtastede fornavn er tomt
                                Console.WriteLine($"Det indtastede fornavn er tomt eller ugyldigt");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter fornavn
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter efternavn

                            //Her skriver vi tekst og spørger efter efternavn
                            Console.Write("Skriv dit efternavn (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputLastName"
                            string inputLastName = Console.ReadLine();

                            //Her laver vi et "if" check hvor vi checker på om vores "string" "inputLastName" tekst indhold er tomt
                            if (String.IsNullOrWhiteSpace(inputLastName))
                            {
                                //Her skriver vi NY linje til brugeren at det indtastede efternavn er tomt
                                Console.WriteLine($"Det indtastede efternavn er tomt eller ugyldigt");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter efternavn
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter alder

                            //Her skriver vi tekst og spørger brugeren efter deres alder
                            Console.Write("Skriv din alder (og tryk på \"Enter\"): ");

                            //Her laver vi et "if" check som tager den alder som brugeren skrev og PRØVER at konverterer brugeres "string" input til en "byte" og checker hvis det ikke virkede
                            if (byte.TryParse(Console.ReadLine(), out byte inputAge) == false)
                            {
                                //Hvis det ikke virkede med at konverterer brugeres input til "byte" skriver vi NY line og fortæller hvilke værdier er acceptable
                                Console.WriteLine($"Den indtastede alder er ikke mellem: {byte.MinValue} og {byte.MaxValue}");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter alder
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter adresse


                            //Her skriver vi tekst og spørger efter adresse
                            Console.Write("Skriv din adresse (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputAddress"
                            string inputAddress = Console.ReadLine();

                            //Her laver vi et "if" check hvor vi checker på om vores "string" "inputAddress" tekst indhold er tomt
                            if (String.IsNullOrWhiteSpace(inputAddress))
                            {
                                //Her skriver vi NY linje til brugeren at det indtastede adresse er tomt
                                Console.WriteLine($"Den indtastede adresse er tom eller ugyldig");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter adresse
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter postnummer

                            //Her skriver vi tekst og spørger brugeren efter deres postnummer
                            Console.Write("Skriv dit postnummer (og tryk på \"Enter\"): ");

                            //Her laver vi et "if" check som tager den postnummer som brugeren skrev og PRØVER at konverterer brugeres "string" input til en "ushort" og checker hvis det ikke virkede
                            if (ushort.TryParse(Console.ReadLine(), out ushort inputPostageNumber) == false)
                            {
                                //Hvis det ikke virkede med at konverterer brugeres input til "ushort" skriver vi NY line og fortæller hvilke værdier er acceptable
                                Console.WriteLine($"Det indtastede postnummer passer ikke mellem: {ushort.MinValue} og {ushort.MaxValue}");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter postnummer
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter by

                            //Her skriver vi tekst og spørger efter by
                            Console.Write("Skriv din by (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputCity"
                            string inputCity = Console.ReadLine();

                            //Her laver vi et "if" check hvor vi checker på om vores "string" "inputCity" tekst indhold er tomt
                            if (String.IsNullOrWhiteSpace(inputCity))
                            {
                                //Her skriver vi NY linje til brugeren at den indtastede by er tom
                                Console.WriteLine($"Den indtastede by er tom eller ugyldig");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter by
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Spørger brugeren efter mail

                            //Her skriver vi tekst og spørger efter mail
                            Console.Write("Skriv din mail (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputMail"
                            string inputMail = Console.ReadLine();
                            if (String.IsNullOrWhiteSpace(inputMail))
                            {
                                //Her skriver vi NY linje til brugeren at det indtastede mail er tomt
                                Console.WriteLine($"Den indtastede mail er tom eller ugyldig");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }
                            #endregion Spørger brugeren efter mail
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her skriver vi NY linje med brug at formatting {0} {1} som estatter {0} med variablens "inputFirstName" indhold og {0} med variablens "inputLastName" indhold
                            Console.WriteLine("Tak for din registrering, {0} {1}", inputFirstName, inputLastName);

                            //Her skriver vi en NY linje ud i "Console" vinduet at brugeren er nu tilmeldt nyhedsbrevet
                            Console.WriteLine("Vi vil nu sende nyhedsbreve:");

                            //Skriver NY linje en masse lighedstegn ======= med længden på "Console" vinduet
                            Console.WriteLine("".PadLeft(Console.WindowWidth, '='));

                            //Skriver NY linje med tekst og intastet alder
                            Console.WriteLine($"Som er relevante for din alder: {inputAge}");

                            //Skriver NY linje med tekst og intastede adresse postnummer og by
                            Console.WriteLine($"Til din adresse: {inputAddress} ({inputPostageNumber}) i {inputCity}");

                            //Skriver NY linje med tekst og intastede mail
                            Console.WriteLine($"Derudover sender vi også til din mail: {inputMail}");

                            //Skriver NY linje en masse lighedsegn ======= med længden på "Console" vinduet
                            Console.WriteLine("".PadLeft(Console.WindowWidth, '='));

                            //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                            Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                            //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                            Console.ReadKey(true);

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af telefonnummer til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "phoneNumbers" med 1 mere
                                string[] newArray = new string[phoneNumbers.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "phoneNumbers"
                                for (int i = 0; i < phoneNumbers.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i phoneNumbers (Vi kopierer det egentlig bare)
                                    newArray[i] = phoneNumbers[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede telefonnummer
                                newArray[newArray.Length - 1] = inputPhoneNumber;

                                //Her overskriver vi vores phoneNumbers med alle elementerne i vores newArray
                                phoneNumbers = newArray;
                            }
                            #endregion Tilføjelse af telefonnummer til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af fornavn til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "firstNames" med 1 mere
                                string[] newArray = new string[firstNames.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "firstNames"
                                for (int i = 0; i < firstNames.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i firstNames (Vi kopierer det egentlig bare)
                                    newArray[i] = firstNames[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede fornavn
                                newArray[newArray.Length - 1] = inputFirstName;

                                //Her overskriver vi vores firstNames med alle elementerne i vores newArray
                                firstNames = newArray;
                            }
                            #endregion Tilføjelse af fornavn til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af efternavn til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "lastNames" med 1 mere
                                string[] newArray = new string[lastNames.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "lastNames"
                                for (int i = 0; i < lastNames.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i lastNames (Vi kopierer det egentlig bare)
                                    newArray[i] = lastNames[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede efternavn
                                newArray[newArray.Length - 1] = inputLastName;

                                //Her overskriver vi vores lastNames med alle elementerne i vores newArray
                                lastNames = newArray;
                            }
                            #endregion Tilføjelse af efternavn til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af alder til array
                            {
                                //Her laver vi et "byte" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "ages" med 1 mere
                                byte[] newArray = new byte[ages.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "ages"
                                for (int i = 0; i < ages.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i ages (Vi kopierer det egentlig bare)
                                    newArray[i] = ages[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede alder
                                newArray[newArray.Length - 1] = inputAge;

                                //Her overskriver vi vores ages med alle elementerne i vores newArray
                                ages = newArray;
                            }
                            #endregion Tilføjelse af alder til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af adresse til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "addresses" med 1 mere
                                string[] newArray = new string[addresses.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "addresses"
                                for (int i = 0; i < addresses.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i addresses (Vi kopierer det egentlig bare)
                                    newArray[i] = addresses[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede adresse
                                newArray[newArray.Length - 1] = inputAddress;

                                //Her overskriver vi vores addresses med alle elementerne i vores newArray
                                addresses = newArray;
                            }
                            #endregion Tilføjelse af adresse til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af postnummer til array
                            {
                                //Her laver vi et "ushort" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "postageNumbers" med 1 mere
                                ushort[] newArray = new ushort[postageNumbers.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "postageNumbers"
                                for (int i = 0; i < postageNumbers.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i postageNumbers (Vi kopierer det egentlig bare)
                                    newArray[i] = postageNumbers[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede postnummer
                                newArray[newArray.Length - 1] = inputPostageNumber;

                                //Her overskriver vi vores postageNumbers med alle elementerne i vores newArray
                                postageNumbers = newArray;
                            }
                            #endregion Tilføjelse af postnummer til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af by til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "cities" med 1 mere
                                string[] newArray = new string[cities.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "cities"
                                for (int i = 0; i < cities.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i cities (Vi kopierer det egentlig bare)
                                    newArray[i] = cities[i];
                                }

                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede by
                                newArray[newArray.Length - 1] = inputCity;

                                //Her overskriver vi vores addresser med alle elementerne i vores newArray
                                cities = newArray;
                            }
                            #endregion Tilføjelse af by til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Tilføjelse af mail til array
                            {
                                //Her laver vi et "string" "array" ved navn newArray hvor der er plads til det samme antal elementer som i "mails" med 1 mere
                                string[] newArray = new string[mails.Length + 1];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "mails"
                                for (int i = 0; i < mails.Length; i++)
                                {
                                    //Her sætter vi værdien i vores newArray til samme værdi som i mails (Vi kopierer det egentlig bare)
                                    newArray[i] = mails[i];
                                }
                                //Her sætter vi den sidste plads i vores newArray til værdien af det indtastede mail
                                newArray[newArray.Length - 1] = inputMail;

                                //Her overskriver vi vores addresses med alle elementerne i vores newArray
                                mails = newArray;
                            }
                            #endregion Tilføjelse af mail til array
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                        }
                        break;
                    //Her stopper koden Hvis brugeren trykkede på numpad 1 ELLER talrækken 1

                    //Hvis brugeren trykkede på numpad 2 ELLER talrækken 2
                    case ConsoleKey.NumPad2:
                    case ConsoleKey.D2:
                        {
                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Søge muligheder tekst
                            //Skriver NY linje med søgemuligheder
                            Console.WriteLine("Søg i data");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (1) for at søge efter telefonnumre");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (2) for at søge efter fornavne");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (3) for at søge efter efternavne");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (4) for at søge efter aldre");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (5) for at søge efter adresser");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (6) for at søge efter postnumre");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (7) for at søge efter byer");

                            //Her skriver vi en NY linje ud i "Console" vinduet
                            Console.WriteLine("Tryk (8) for at søge efter mails");
                            #endregion Søge muligheder tekst
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                            Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                            //Her bruger vi "Console" hvor vi læser hvilken knap brugeren trykker på
                            ConsoleKey inputSearchKey = Console.ReadKey(true).Key;

                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her skriver vi tekst og spørger brugeren efter et søgeord
                            Console.Write("Skriv søgeord (og tryk på \"Enter\"): ");

                            //Her læser vi HELE linjen brugeren skrev og gemmer det tekst i vores "string" til variablen "inputSearch"
                            string inputSearch = Console.ReadLine();

                            //Her laver vi en "region" som kan sammenlignes lidt med et afsnit (Dette er ude over pensum)
                            #region Søge system

                            //Her laver vi et "array" som kan sammenlignes lidt med en bog hvor hver side er et element i vores "array" er en samling af typen "bool" som bruges til at holde styr på elementer der indeholder teksten brugeren har søgt efter
                            bool[] searchMatches = new bool[] { };

                            //Her laver vi en "bool" til at angive om et resultat blev fundet efter hvad brugeren søgte efter
                            bool searchMatchFound = false;

                            //Her laver vi et "if" check hvor vi checker om brugeren trykkede på numpad 1 ELLER talrækken 1
                            if (inputSearchKey == ConsoleKey.D1 || inputSearchKey == ConsoleKey.NumPad1)
                            {
                                //Hvis brugeren trykkede på numpad 1 ELLER talrækken 1 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "phoneNumbers"
                                searchMatches = new bool[phoneNumbers.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "phoneNumbers"
                                for (int i = 0; i < phoneNumbers.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "phoneNumbers" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch"
                                    if (phoneNumbers[i].Contains(inputSearch))
                                    {
                                        //Hvis vores "array" "phoneNumbers" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 2 ELLER talrækken 2 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D2 || inputSearchKey == ConsoleKey.NumPad2)
                            {
                                //Hvis brugeren trykkede på numpad 2 ELLER talrækken 2 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "firstNames"
                                searchMatches = new bool[firstNames.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "firstNames"
                                for (int i = 0; i < firstNames.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "firstNames" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (firstNames[i].ToLower().Contains(inputSearch.ToLower()))
                                    {
                                        //Hvis vores "array" "firstNames" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 3 ELLER talrækken 3 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D3 || inputSearchKey == ConsoleKey.NumPad3)
                            {
                                //Hvis brugeren trykkede på numpad 3 ELLER talrækken 3 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "lastNames"
                                searchMatches = new bool[lastNames.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "lastNames"
                                for (int i = 0; i < lastNames.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "lastNames" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (lastNames[i].ToLower().Contains(inputSearch.ToLower()))
                                    {
                                        //Hvis vores "array" "lastNames" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 4 ELLER talrækken 4 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D4 || inputSearchKey == ConsoleKey.NumPad4)
                            {
                                //Hvis brugeren trykkede på numpad 4 ELLER talrækken 4 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "ages"
                                searchMatches = new bool[ages.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "ages"
                                for (int i = 0; i < ages.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "ages" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch"
                                    if (ages[i].ToString().Contains(inputSearch))
                                    {
                                        //Hvis vores "array" "ages" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 5 ELLER talrækken 5 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D5 || inputSearchKey == ConsoleKey.NumPad5)
                            {
                                //Hvis brugeren trykkede på numpad 5 ELLER talrækken 5 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "addresses"
                                searchMatches = new bool[addresses.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "addresses"
                                for (int i = 0; i < addresses.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "addresses" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (addresses[i].ToLower().Contains(inputSearch.ToLower()))
                                    {
                                        //Hvis vores "array" "addresses" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 6 ELLER talrækken 6 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D6 || inputSearchKey == ConsoleKey.NumPad6)
                            {
                                //Hvis brugeren trykkede på numpad 6 ELLER talrækken 6 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "postageNumbers"
                                searchMatches = new bool[postageNumbers.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "postageNumbers"
                                for (int i = 0; i < postageNumbers.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "postageNumbers" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (postageNumbers[i].ToString().Contains(inputSearch))
                                    {
                                        //Hvis vores "array" "postageNumbers" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 7 ELLER talrækken 7 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D7 || inputSearchKey == ConsoleKey.NumPad7)
                            {
                                //Hvis brugeren trykkede på numpad 7 ELLER talrækken 7 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "cities"
                                searchMatches = new bool[cities.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "cities"
                                for (int i = 0; i < cities.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "cities" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (cities[i].ToLower().Contains(inputSearch.ToLower()))
                                    {
                                        //Hvis vores "array" "cities" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }

                            //Her laver vi et "else-if" hvor vi checker om brugeren trykkede på numpad 8 ELLER talrækken 8 som bliver checket hvis ikke det ovenstående check er opfyldt
                            else if (inputSearchKey == ConsoleKey.D8 || inputSearchKey == ConsoleKey.NumPad8)
                            {
                                //Hvis brugeren trykkede på numpad 8 ELLER talrækken 8 så ændre vi vores "array" "searchMatches" til at have samme antal pladser til data som længden på vores "array" "mails"
                                searchMatches = new bool[mails.Length];

                                //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "mails"
                                for (int i = 0; i < mails.Length; i++)
                                {
                                    //Her laver vi et "if" check hvor vi checker om vores "array" "mails" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" lavet om til små bogstaver
                                    if (mails[i].ToLower().Contains(inputSearch.ToLower()))
                                    {
                                        //Hvis vores "array" "mails" med index "i" som er et helt tal indeholder lidt eller det hele af vores "string" "inputSearch" så sætter vi værdien "true" i vores "array" "searchMatches" med positionen af "i"
                                        searchMatches[i] = true;

                                        //Og vi sætter også vores "bool" variabel "searchMatchFound" til "true" da vi har fundet mindst 1 resultat
                                        searchMatchFound = true;
                                    }
                                }
                            }
                            #endregion Søge system
                            //Her stopper vi en "endregion" som kan sammenlignes lidt med en slutning af et afsnit (Dette er ude over pensum)

                            //Her laver vi et "if" check som checker om vores "bool" "searchMatchFound" variabel har værdien "false"
                            if (searchMatchFound == false)
                            {
                                //Hvis vores "bool" "searchMatchFound" variabel har værdien "false" skriver vi NY linje til brugeren at ingen resultater er fundet med det tekst brugen indskrev
                                Console.WriteLine($"Ingen resultater fundet med søgeord: {inputSearch}");

                                //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                                Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                                //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                                Console.ReadKey(true);

                                //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }

                            //Her laver vi en "int" variabel som er et helt tal og vores variabel har værdien 0 (Vi bruger denne variabl til at holde styr på tomme søge resultater)
                            int emptyMatches = 0;

                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her laver vi en "string" variabel hvor vi bruger "String.Format" til at formaterer Telefonnummer, Fornavn, Efternavn, Alder, Adresse, Postnummer, By, Mail efter vores konstante formaternings variabel "displayTableFormat"
                            string formattedTitle = String.Format(displayTableFormat, "[Telefonnummer]", "[Fornavn]", "[Efternavn]", "[Alder]", "[Adresse]", "[Postnummer]", "[By]", "[Mail]");

                            //Her skriver vi NY line ud med indholdet fra vores "string" variabel "formattedTitle" som laver en fin tabel med rækkerne ovenfor
                            Console.WriteLine(formattedTitle);

                            //Her laver vi en "bool" variabel som vi bruger til at checke om brugeren trykkede på andet end "SpaceBar" (som standard giver vi den værdien "false")
                            bool keyIsNotSpaceBar = false;

                            //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "searchMatches"
                            for (int i = 0; i < searchMatches.Length; i++)
                            {
                                //Her laver vi et "if" check hvor vi checker om vores "array" "searchMatches" med index "i" som er et helt tal har værdien "false"
                                if (searchMatches[i] == false)
                                {
                                    //Hvis vi kommer her til så blev resultatet med index "i" ikke fundet og derfor tæller vi vores "int" "emptyMatches" variabel op med 1
                                    emptyMatches++;

                                    //Her hopper vi til næste kørsel i vores "for" loop som kører efter antal elementer i vores "array" "searchMatches"
                                    continue;
                                }

                                //Her laver vi et "if" check som checker om index "i" minus "int" værdien på vores variabel "emptyMatches" er størrere end 0
                                //OG index "i" minus "int" værdien på vores variabel "emptyMatches" ER LIG MED (Modulus som er tegnet % og betyder "divisionsrest")
                                //HVOR vi så checker om "Modulus" så er LIGMED 0
                                //DETTE IF CHECK OPDELER BARE KOLONNER I DELE AF 12 ELLER HVAD VÆRDIEN AF "maxDisplayItems" HAR
                                if ((i - emptyMatches) > 0 && (i - emptyMatches) % maxDisplayItems == 0)
                                {
                                    //Skriver NY linje og beder brugeren om at trykke på "SpaceBar" for at se de næste kolonner
                                    Console.WriteLine("Tryk på \"SpaceBar\" for at se næste side");

                                    //Her bruger vi "Console" hvor vi læser hvilken knap brugeren trykker på
                                    ConsoleKey nextPageKey = Console.ReadKey(true).Key;

                                    //Her laver vi et "if" check hvor vi checker på og knappen brugeren IKKE trykkede "SpaceBar"
                                    if (nextPageKey != ConsoleKey.Spacebar)
                                    {
                                        //Hvis brugeren ikke trykkede på sætter vi vores "bool" variabel "keyIsNotSpaceBar" til værdien "true"
                                        keyIsNotSpaceBar = true;

                                        //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                        break;
                                    }

                                    //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                                    Console.Clear();

                                    //Her skriver vi NY line ud med indholdet fra vores "string" variabel "formattedTitle" som laver en fin tabel med rækkerne ovenfor
                                    Console.WriteLine(formattedTitle);
                                }

                                //Her laver vi en "string" variabel hvor vi bruger "String.Format" til at formaterer Telefonnummer med index "i", Fornavn med index "i", Efternavn med index "i", Alder med index "i", Adresse med index "i", Postnummer med index "i", By med index "i", Mail med index "i" efter vores konstante formaterningsvariabel "displayTableFormat"
                                string formattedLine = String.Format(displayTableFormat, phoneNumbers[i], firstNames[i], lastNames[i], $"{ages[i]}år", addresses[i], postageNumbers[i], cities[i], mails[i]);

                                //Her skriver vi en NY linje med indholdet fra vores "string" variabel "formattedLine"
                                Console.WriteLine(formattedLine);
                            }

                            //Her laver vi et "if" check som checker om vores "bool" variabel "keyIsNotSpaceBar" har værdien "true"
                            if (keyIsNotSpaceBar == true)
                            {
                                //Hvis vores "bool" variabel "keyIsNotSpaceBar" har værdien "true" så ødelægger vi vores "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }

                            //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                            Console.WriteLine("\r\nTryk på en \"Enter\" for at fortsætte...");

                            //Her venter vi lige på brugeren trykker på en vilkårlig knap, inden vi afslutter vores "switch" check
                            Console.ReadKey(true);
                        }
                        break;
                    //Her stopper koden Hvis brugeren trykkede på numpad 2 ELLER talrækken 2

                    //Hvis brugeren trykkede på numpad 3 ELLER talrækken 3
                    case ConsoleKey.NumPad3:
                    case ConsoleKey.D3:
                        {
                            //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                            Console.Clear();

                            //Her laver vi en "string" variabel hvor vi bruger "String.Format" til at formaterer Telefonnummer, Fornavn, Efternavn, Alder, Adresse, Postnummer, By, Mail efter vores konstante formaternings variabel "displayTableFormat"
                            string formattedTitle = String.Format(displayTableFormat, "[Telefonnummer]", "[Fornavn]", "[Efternavn]", "[Alder]", "[Adresse]", "[Postnummer]", "[By]", "[Mail]");

                            //Her skriver vi NY line ud med indholdet fra vores "string" variabel "formattedTitle" som laver en fin tabel med rækkerne ovenfor
                            Console.WriteLine(formattedTitle);

                            //Her laver vi en "bool" variabel som vi bruger til at checke om brugeren trykkede på andet end "SpaceBar" (som standard giver vi den værdien "false")
                            bool keyIsNotSpaceBar = false;

                            //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "phoneNumbers"
                            for (int i = 0; i < phoneNumbers.Length; i++)
                            {
                                //Her laver vi et "if" check som checker om index "i" er større end 0
                                //OG index "i" ER LIG MED (Modulus som er tegnet % og det betyder "divisionsrest")
                                //HVOR vi så checker om "Modulus" så er LIGMED 0
                                //DETTE IF CHECK OPDELER BARE KOLONNER I DELE AF 12 ELLER HVAD VÆRDIEN AF "maxDisplayItems" HAR
                                if (i > 0 && i % maxDisplayItems == 0)
                                {
                                    //Skriver NY linje og beder brugeren om at trykke på "SpaceBar" for at se de næste kolonner
                                    Console.WriteLine("Tryk på \"SpaceBar\" for at se næste side");

                                    //Her bruger vi "Console" hvor vi læser hvilken knap brugeren trykker på
                                    ConsoleKey nextPageKey = Console.ReadKey(true).Key;

                                    //Her laver vi et "if" check hvor vi checker på og knappen brugeren IKKE trykkede "SpaceBar"
                                    if (nextPageKey != ConsoleKey.Spacebar)
                                    {
                                        //Hvis brugeren ikke trykkede på sætter vi vores "bool" variabel "keyIsNotSpaceBar" til værdien "true"
                                        keyIsNotSpaceBar = true;

                                        //Her ødelægger vi "switch" så vi kommer ud at den og tilbage til starten igen
                                        break;
                                    }

                                    //Her nulstiller vi "Console" vinduet så den er tilbage til standarden
                                    Console.Clear();

                                    //Her skriver vi NY line ud med indholdet fra vores "string" variabel "formattedTitle" som laver en fin tabel med rækkerne ovenfor
                                    Console.WriteLine(formattedTitle);
                                }

                                //Her laver vi en "string" variabel hvor vi bruger "String.Format" til at formatterer Telefonnummer med index "i", Fornavn med index "i", Efternavn med index "i", Alder med index "i", Adresse med index "i", Postnummer med index "i", By med index "i", Mail med index "i" efter vores konstante formatterningsvariabel "displayTableFormat"
                                string formattedLine = String.Format(displayTableFormat, phoneNumbers[i], firstNames[i], lastNames[i], $"{ages[i]}år", addresses[i], postageNumbers[i], cities[i], mails[i]);

                                //Her skriver vi en NY linje med indholdet fra vores "string" variabel "formattedLine"
                                Console.WriteLine(formattedLine);
                            }

                            //Her laver vi et "if" check som checker om vores "bool" variabel "keyIsNotSpaceBar" har værdien "true"
                            if (keyIsNotSpaceBar == true)
                            {
                                //Hvis vores "bool" variabel "keyIsNotSpaceBar" har værdien "true" så ødelægger vi vores "switch" så vi kommer ud at den og tilbage til starten igen
                                break;
                            }

                            //Her laver vi en "int" variabel til at beregne gennemsnitsalderen i vores data
                            int ageSum = 0;

                            //Her laver vi et "for" loop som kører det antal gange af elementer i "array" "ages"
                            for (int i = 0; i < ages.Length; i++)
                            {
                                //Her lægger vi værdien af index "i" i vores "array" "ages" oveni værdien på vores "ageSum" variabel
                                ageSum += ages[i];
                            }

                            //Her skriver vi en NY linje ud i "Console" vinduet og i starten af vores tekst rykker vi mus markøren helt tilbage og laver ny linje også skriver ud hvad gennemsnitsalderen er på ved at dividerer "ageSum" med antal elementer i vores "array" "ages"
                            Console.WriteLine($"\r\nGennemsnitsalderen: {(float)(ageSum / ages.Length)}år");

                            //Her skriver vi en NY linje ud i "Console" vinduet at brugeren skal trykke på en knap for at fortsætte
                            Console.WriteLine("Tryk på en \"Enter\" for at fortsætte...");

                            //Her venter vi lige på brugeren trykker på en knap så de for en chance til at læse linjen ovenover
                            Console.ReadKey(true);
                        }
                        break;
                        //Her stopper koden Hvis brugeren trykkede på numpad 3 ELLER talrækken 3
                }
            }
        }
    }
}