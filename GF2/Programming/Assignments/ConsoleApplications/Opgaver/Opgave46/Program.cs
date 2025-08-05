using System;

namespace Opgave46
{
    internal static class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave46

            //Skriver Ny linje
            Console.WriteLine("Svømmehal - Priser");

            //Skriver NY linje spørger brugeren om denne person er 
            Console.WriteLine("Er personen: Pensionist, efterlønsmodtager, arbejdsledig, borger på ledighedsydelse, dagpengemodtager eller studerende (dokumentation påkrævet) (Ja/Nej)");

            //Gemmer hvad brugeren skrev som en Boolean ved brug af min metode ToBool
            bool isSpecial = Console.ReadLine().ToBool();

            //Laver 3 nye Booleans til at gemme brugerns Ja/Nej svar
            bool isKid = false;
            bool isKidWithAudlt = false;
            bool isKidAndHoliday = false;

            //Dette IF statment checker Hvis IKKE isSpecial er true så køres denne kode block
            if (!isSpecial)
            {
                //Skriver NY linje spørger brugeren om denne person er 
                Console.WriteLine("Er personen: en voksen med barn (<7 år) (Ja/Nej)");

                //Gemmer hvad brugeren skrev som en Boolean ved brug af min metode ToBool
                isKidWithAudlt = Console.ReadLine().ToBool();

                //Dette IF statment checker Hvis IKKE isKidWithAudlt er true så køres denne kode block
                if (!isKidWithAudlt)
                {
                    //Skriver NY linje spørger brugeren om denne person er 
                    Console.WriteLine("Er personen: et barn (7-15 år) OG er det sommer/efterår/vinter (Ja/Nej)");

                    //Gemmer hvad brugeren skrev som en Boolean ved brug af min metode ToBool
                    isKidAndHoliday = Console.ReadLine().ToBool();

                    //Dette IF statment checker Hvis IKKE isKidAndHoliday er true så køres denne kode block
                    if (!isKidAndHoliday)
                    {
                        //Skriver NY linje spørger brugeren om denne person er 
                        Console.WriteLine("Er personen: et barn (7-15 år) (Ja/Nej)");

                        //Gemmer hvad brugeren skrev som en Boolean ved brug af min metode ToBool
                        isKid = Console.ReadLine().ToBool();
                    }
                }
            }

            //Hvis igen af de 4 Booleans er true så er denne person voksen
            if (!isSpecial && !isKid && !isKidWithAudlt && !isKidAndHoliday)
            {
                //Skriver en NY linje ud med text
                Console.WriteLine("Denne person er voksen");
            }

            //Skriver text med antal af biletter som skal købes
            Console.Write("Hvor mange biletter skal købes: ");

            //Prøver at konverterer inputtet fra brugeren om til data typen ushort
            if (!ushort.TryParse(Console.ReadLine(), out ushort tickets))
            {
                //Denne linje bliver skrivet ud på NY linje hvis det ikke virkede
                Console.WriteLine("Kunne ikke konvertere input");

                //Forhindrer at programmet kører vidre fra her
                return;
            }

            //Skriver NY linje med antal biletter og prisen
            Console.WriteLine($"Prisen på {tickets}x biletter med indtastede information bliver: {GetPrice(tickets, isKid, isKidWithAudlt, isKidAndHoliday, isSpecial)}dkk");

            //Venter på taste tryk
            Console.ReadKey();
        }

        //Denne metode tager en string som argument også laver den om til en Boolean
        private static bool ToBool(this string value)
        {
            //Dette ændre værdien af value til at være lowercase
            value = value.ToLower();
            return (value == "ja" || value == "j" || value == "yes" || value == "y") ? true : false; /*Dette returnerer true hvis value indeholder ja, j, yes, y Ellers returnerer den false*/
        }

        //Denne metode returnerer prisen efter antal biletter og argumenter om hvilken person der vil købe biletter
        private static ushort GetPrice(ushort tickets = 1, bool isKid = false, bool isKidWithAudlt = false, bool isKidAndHoliday = false, bool isSpecial = false)
        {
            //Dette IF statment checker om biletters antal er lig med 10
            if(tickets == 10)
            {
                if (isSpecial) { return 175; } /*hvis personen er: Pensionist, efterlønsmodtager, arbejdsledig, borger på ledighedsydelse, dagpengemodtager eller studerende*/
                if (isKidAndHoliday) { return 100; } /*hvis personen er: et barn og det er ferie*/
                if (isKid) { return 135; } /*hvis personen er: et barn og det ikke er ferie*/
                return 330; /*Ellers må denne person være voksen*/
            }
            else
            {
                if (isSpecial) { return (ushort)(23 * tickets); } /*hvis personen er: Pensionist, efterlønsmodtager, arbejdsledig, borger på ledighedsydelse, dagpengemodtager eller studerende*/
                if (isKidWithAudlt) { return (ushort)(42 * tickets); } /*denne person er voksen og har et barn med som er mindre end 7 år*/
                if (isKidAndHoliday) { return (ushort)(10 * tickets); } /*hvis personen er: et barn og det er ferie*/
                if (isKid) { return (ushort)(15 * tickets); } /*hvis personen er: et barn og det ikke er ferie*/
                return (ushort)(42 * tickets); /*Ellers må denne person være voksen*/
            }
        }
    }
}