using System;
using System.Linq;

namespace Opgave42
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave42

            //Dette laver en ny instance af DrinksType som vi laver en variabel ud af der hedder drinks med start værdien 0b0000000000
            DrinksType drinks = DrinksType.None;

            //Denne variable har en værdi af alle navne i typen af DrinksType hvor værdien er større end 0
            string enumNames = String.Join("\n", Enum.GetValues(typeof(DrinksType)).Cast<DrinksType>().Where(value => (int)value > 0));

            //Skriver NY linje med menu kort over de forsklige drinks
            Console.WriteLine("Vælg nogle \"Drinks Typer\" (Skriv samme drink 2 til at fjerne)");

            //Skriver NY linje som er en streg med længden på vinduet
            Console.WriteLine(new string('-', Console.WindowWidth - 1));

            //Skriver NY linje med alle de forsklige drinks
            Console.WriteLine(enumNames);

            //Skriver NY linje som er en streg med længden på vinduet
            Console.WriteLine(new string('-', Console.WindowWidth-1));

            //Dette er et uendeligt while loop som køere intil det bliver stoppet med fx et break eller return
            while (true)
            {
                //Denne variable læser linjen som brugeren skriver
                string input = Console.ReadLine();

                //Dette IF statment checker om varaiblen input er tom eller null også stopper while loopet da så formåder vi brugeren har skrevet de drinks de ville have
                if (String.IsNullOrEmpty(input)) { break; }

                //Her bruger et klassen Enum med metoden TryParse hvor vi prøver at tage værdien fra varaiblen input og se om det kan konverteres til en værdi af DrinksType
                if (!Enum.TryParse<DrinksType>(input, true, out DrinksType drink))
                {
                    //Skriver NY linje hvis varaiblen input ikke kunne konverteres
                    Console.WriteLine($"Kunne ikke finde drink: {input}");

                    //Denne linje gør sådan loopet ikke kører vidre her fra men går tilbage til toppen og prøver igen
                    continue;
                }

                //Dette IF statment bruger bitwise til at checke om drinks IKKE har den binary værdi af drink
                if ((drinks & drink) == 0)
                {
                    //Denne bitwise opration tiløjer den binary værdi af drink til drinks
                    drinks |= drink;

                    //Skriver NY linje fortæller at drinken er blevet tilføjet 
                    Console.WriteLine($"Drink {input} tilføjet");
                }
                else if((drinks & drink) == drink) /*Denne ELSE IF statment bruger bitwise til at checke om drinks HAR den binary værdi af drink*/
                {
                    //Denne bitwise opration fjerner den binary værdi af drink fra drinks
                    drinks &= ~drink;

                    //Skriver NY linje fortæller at drinken er blevet fjernet 
                    Console.WriteLine($"Drink {input} fjernet");
                }
            }

            //Nulstiller console da vi nu er ude af det uendelige while loop
            Console.Clear();

            //Skriver NY linje med de valgte drinks i binary værdi
            Console.WriteLine($"Valgte drink(s) (Binary Value: {Convert.ToString((int)drinks, 2)})");

            //Skriver NY linje med navne på de valgte drinks
            Console.WriteLine(drinks);

            //Denne Linje bruger metoden GetDrinksPrice med drinks som argument til at få prisen på de valgte drinks
            Console.WriteLine($"Disse drink(s) koster: {GetDrinksPrice(drinks)}dkk");

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }


        //Denne metode tager DrinksType (Enum) som input argument og retunerer en ushort som pris
        private static ushort GetDrinksPrice(DrinksType drinks)
        {
            //Dette laver en ny ushort varaible med værdien 0
            ushort total = 0;

            //Dette kører et foreach loop igennen alle værdier i typen af DrinksType
            foreach (DrinksType drink in Enum.GetValues(typeof(DrinksType)))
            {
                //Dette bruger bitwise til at checke om drinks indeholder drink på bit level
                if ((drinks & drink) == drink)
                {
                    //Dette er en switch som bestemmer priserne på de forskelige drinks
                    switch (drink)
                    {
                        /*Disse cases tiløjer et tal til total varaiblen efter DrinkType*/
                        case DrinksType.Margarita:              total += 29; break;
                        case DrinksType.Cosmopolitan:           total += 34; break;
                        case DrinksType.Daiquiri:               total += 37; break;
                        case DrinksType.Gimlet:                 total += 19; break;
                        case DrinksType.Manhattan:              total += 39; break;
                        case DrinksType.Negroni:                total += 25; break;
                        case DrinksType.OldFashioned:           total += 42; break;
                        case DrinksType.EspressoMartini:        total += 24; break;
                        case DrinksType.PassionfruitMartini:    total += 14; break;
                        case DrinksType.Mimosa:                 total += 26; break;
                    }
                }
            }

            //retunerer værdien på total varaiblen
            return total;
        }


        [Flags] /*Dette er en attribute man kan godt sige at dette er metadata om kode*/
        private enum DrinksType /*Dette er en Enum (man kan vel godt sige at det er en data type man selv laver)*/
        {
            /*Her er nogle binary værdier til drinks*/
            None                = 0b0000000000,
            Margarita           = 0b0000000001,
            Cosmopolitan        = 0b0000000010,
            Daiquiri            = 0b0000000100,
            Gimlet              = 0b0000001000,
            Manhattan           = 0b0000010000,
            Negroni             = 0b0000100000,
            OldFashioned        = 0b0001000000,
            EspressoMartini     = 0b0010000000,
            PassionfruitMartini = 0b0100000000,
            Mimosa              = 0b1000000000
        }
    }
}