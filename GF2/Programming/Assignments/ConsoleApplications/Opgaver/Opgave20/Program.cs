using System;

namespace Opgave20
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave20

            //Skriver på samme linje med text
            Console.Write("Skriv et tal: ");

            //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien
            if (!int.TryParse(Console.ReadLine(), out int num1))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Skriver på samme linje med text
            Console.Write("Skriv et tal mere ");

            //Checker om det input fra brugeren kan konverteres til byte typen også sætter værdien
            if (!int.TryParse(Console.ReadLine(), out int num2))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Skriver NY linje
            Console.WriteLine($"Det højeste tal er {GetHighestNumber(num1, num2)}");

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }

        //Laver en private static metode som retunerer int
        private static int GetHighestNumber(params int[] nums)
        {
            //Laver en ny int varaible med værdien 1
            int num = 0;

            //Kører et foreach loop gennem alle værdier i nums
            foreach (int n in nums)
            {
                //CHecker om index værdien N er størere end num
                if (n > num) { num = n; }
            }

            //retunerer num
            return num;
        }
    }
}