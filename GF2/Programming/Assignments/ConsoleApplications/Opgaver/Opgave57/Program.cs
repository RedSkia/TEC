using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace Opgave57
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Opgave57

            //Dette er et ReadOnlyDictionary som ikke kan ændres og bruges til at holde styr på godkendte karaktere
            ReadOnlyDictionary<string, sbyte> approvedGrades = new ReadOnlyDictionary<string, sbyte>(new Dictionary<string, sbyte>
            {
                { "12",  12 },
                { "10",  10 },
                { "7",   7 },
                { "4",   4 },
                { "02",  2 },
                { "00",  0 },
                { "-3", -3 },
            });

            //En liste til at huske karakterer til sum beregning
            List<int> totalGrades = new List<int>();

            //Skriver Nye linjer til brugeren 
            Console.WriteLine("Skriv karakterer du ønsker at finde gennemsnittet på");
            Console.WriteLine($"Godkendte karaktere ({String.Join(", ", approvedGrades.Keys)})");

            //Uendelig while loop indtil det bliver stopped
            while (true)
            {
                //Laver en string varaible med input fra brugeren
                string grade = Console.ReadLine();

                //Hvis input er tomt stop loopet da så antager vi brugeren er færdig med at skrive sine karakterer
                if (String.IsNullOrEmpty(grade)) { break; }

                //Cehcker om den karakter brugeren skrev er en af de godkendte 
                if (!approvedGrades.ContainsKey(grade))
                {
                    //Hvis ikke vi skriver denne line
                    Console.WriteLine($"Karakterer {grade} ikke fundet (Prøv igen)");

                    //Og hopper vidre til næste loop kørsel
                    continue;
                }

                //Ellers tilføjer vi den karakter til listen
                totalGrades.Add(approvedGrades[grade]);
            }

            //Denne varaible beregner Gennemsnittet på de indtastede karakterer
            double Average = totalGrades.Count < 1 ? 0 : (totalGrades.Sum() / (double)totalGrades.Count);

            //Skriver NY linje ud med beregningen
            Console.WriteLine("Gennemsnittet på indtastede karakterer er: {0:N1}", Average);

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}