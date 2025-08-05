using System;

namespace Opgave39
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave39

            //Laver 2 konstante string variabler med CaseSentive værdier
            const string username = "Admin";
            const string password = "LetMeIn";
            const byte maxLoginAttempts = 5;
            byte loginAttempts = 0;

            //Dette er et do-while loop dette betyder frøst køres koden inde i do blokken der efter bliver betingelsen checket
            do
            {
                //Øger værdien af varaiblen med 1
                loginAttempts++;

                //Nulstiller Console
                Console.Clear();

                //Skriver text til brugeren efter et brugernavn
                Console.Write("Bruger: ");

                //Læser input fra bugeren i typen string format
                string user = Console.ReadLine();

                //Skriver text til brugeren efter et kodeord
                Console.Write("Kode: ");

                //Sætter variablen pass til værdien retuneret af methoden ReadPassword
                string pass = ReadPassword();

                if(loginAttempts >= maxLoginAttempts)
                {
                    Console.WriteLine("Du har prøvet at logge ind ALT FOR MANGE GANGE!");

                    //Venter på taste tryk
                    Console.ReadKey();

                    //Stopper loopet
                    break;
                }

                //Checker om variablerne user, pass er præcis det samme som username, password på binært niveau
                if (String.Equals(user, username, StringComparison.Ordinal) && String.Equals(pass, password, StringComparison.Ordinal))
                {
                    //Skriver Ny linje med velkommen besked til brugeren
                    Console.WriteLine($"Login successful\n\rVelkommen {username}!");

                    //Venter på taste tryk
                    Console.ReadKey();

                    //Stopper loopet
                    break;

                }
                else //Ellers
                {
                    //Skriver Ny linje hvis login mislykket
                    Console.WriteLine("Login mislykket. check for forkerte login initialer");

                    //Skriver Ny linje hvis login mislykket med antal af login forsøg og totale forsøg
                    Console.WriteLine($"Du har brugt {loginAttempts}/{maxLoginAttempts} login forsøg!");

                    //Venter på taste tryk
                    Console.ReadKey();
                }
            }
            while (loginAttempts <= maxLoginAttempts);
        }

        //Laver en privat methode
        private static string ReadPassword()
        {
            //Laver en ny string som er instansieret
            string password = "";

            //Laver en ny instance af struct(en) ConsoleKeyInfo 
            ConsoleKeyInfo keyInfo;

            //Laver et do-while loop
            do
            {
                //Sætter værdien af keyInfo
                keyInfo = Console.ReadKey(intercept: true);

                //Checker om det man trykker IKKE ER Backspace OG Enter
                if (keyInfo.Key != ConsoleKey.Backspace && keyInfo.Key != ConsoleKey.Enter)
                {
                    //Tilføjer værdien KeyChar til password
                    password += keyInfo.KeyChar;

                    //Skriver texten ud
                    Console.Write("*");
                }
                else if (keyInfo.Key == ConsoleKey.Backspace && password.Length > 0) /*Checker om man trykker på Backspace og password længden er større end 0*/
                {
                    //forkorter værdien af password fra enden med 1
                    password = password.Substring(0, password.Length - 1);

                    //Dette er det samme som at trykke på backspace knappen "https://learn.microsoft.com/en-us/cpp/c-language/escape-sequences?view=msvc-170"
                    Console.Write("\b \b");
                }
            } while (keyInfo.Key != ConsoleKey.Enter); /*Loopet forsætter så længe man IKKE trykker på Enter*/

            //Skriver en tom linje så musen står ved starten på ny linje
            Console.Write("\n\r");

            //Returnerer værdien
            return password;
        }
    }
}