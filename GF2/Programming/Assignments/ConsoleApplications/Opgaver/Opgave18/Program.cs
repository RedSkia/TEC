using System;
using System.Text;
using System.Threading;

namespace Opgave18
{
    internal class Program
    {

        //Laver en konstant variable af typen int ude af Main scope med værdien 4
        const int minuimValue = 4;

        static void Main(string[] args)
        {

            /// Marcus Wahlstrøm
            /// 31.08.2023
            /// Opgave18


            //Skriver text på samme linje og venter på input fra brugeren
            Console.Write("Skriv værdi: ");

            //Checker om det input fra brugeren kan konverteres til double typen også sætter værdien af value
            if (!double.TryParse(Console.ReadLine(), out double value))
            {
                //Skriver NY linje
                Console.WriteLine("Fejlede til at konverter højte");

                //Forhindrer at programmet kører vidrer
                return;
            }

            //Checker om value er størerer end minuimValue
            if (value > minuimValue)
            {
                //Kalder methoden StartPartyMode
                StartPartyMode();
            }
            //Ellers går den her ind
            else
            {
                //SKriver NY linje med varaibler
                Console.WriteLine($"Tallet {value} er IKKE størrere end {minuimValue}");
            }

            //Venter på tryk tast fra brugeren
            Console.ReadKey();
        }

        //thread lock Låser en tread til single threading
        private static object _lock = new object();

        //Laver en private static methode
        private static void StartPartyMode()
        {
            Console.OutputEncoding = Encoding.UTF8;

            //thread lock
            lock (_lock)
            {
                //Laver en ny instance af Random klassen
                Random rand = new Random();

                //Et loop som bare forsætter
                while (true)
                {
                    //thread lock
                    lock (_lock)
                    {
                        //Nulstiller console så farverne fylder hele bagruden
                        Console.Clear();

                        //Skriver NY linje med text og viaralber
                        Console.WriteLine($"Tallet er størrere end {minuimValue} 🎉🎉🎉");

                        //Sætter text farven til en random værdi som bliver casted til enum typen ConsoleColor
                        Console.ForegroundColor = (ConsoleColor)rand.Next(0, 16);

                        //Sætter text farven til en random værdi som bliver casted til enum typen ConsoleColor
                        Console.BackgroundColor = (ConsoleColor)rand.Next(0, 16);

                        //Sover for 1000ms
                        Thread.Sleep(1000);
                    }
                }
            }
        }
    }
}