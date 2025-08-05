using System;

namespace Opgave44
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave44

            //Skriver 4 NYE linjer og spørger brugeren efter at vælge 1, 2 eller 3
            Console.WriteLine("Vælg en figur");
            Console.WriteLine("(1) Rektangel");
            Console.WriteLine("(2) Cirkel");
            Console.WriteLine("(3) Retvinklet trekant");

            double result = CaculateAreaByType(Console.ReadKey().Key);
            if(result == 0) { return; }
            Console.WriteLine($"Arealet er: {result}");

            Console.ReadKey();
        }


        //Laver en methode som tager en ConsoleKey som input argument
        private static double CaculateAreaByType(ConsoleKey key)
        {
            //Nulstiller console
            Console.Clear();

            //En switch
            switch (key)
            {
                //Hvis brugeren trykkede på 1
                case ConsoleKey.D1: {

                    //Skriver NY linje
                    Console.WriteLine("Skriv længde på Rektangel");

                    //Prøver at konverterer linjen brugeren skrev til int tal typen
                    if(!int.TryParse(Console.ReadLine(), out int length))
                    {
                        //Hvis dete ikke virkede skriver vi denne NYE linje
                        Console.WriteLine("Kunne ikke konverterer længde på Rektangel");

                        //Denne break block stopper switchen
                        break;
                    }

                    //Skriver NY linje
                    Console.WriteLine("Skriv bredde på Rektangel");

                    //Prøver at konverterer linjen brugeren skrev til int tal typen
                    if (!int.TryParse(Console.ReadLine(), out int width))
                    {
                        //Hvis dete ikke virkede skriver vi denne NYE linje
                        Console.WriteLine("Kunne ikke konverterer bredde på Rektangel");

                        //Denne break block stopper switchen
                        break;
                    }

                    //returnerer arealet
                    return length * width;
                }
                
                //Hvis brugeren trykkede på 2
                case ConsoleKey.D2: {

                    //Skriver NY linje
                    Console.WriteLine("Skriv radius på Cirkel");

                    //Prøver at konverterer linjen brugeren skrev til int tal typen
                    if (!int.TryParse(Console.ReadLine(), out int radius))
                    {
                        //Hvis dete ikke virkede skriver vi denne NYE linje
                        Console.WriteLine("Kunne ikke konverterer radius på Cirkel");

                        //Denne break block stopper switchen
                        break;
                    }
                    
                    //returnerer arealet
                    return Math.PI * Math.Pow(radius, 2);
                }

                //Hvis brugeren trykkede på 3
                case ConsoleKey.D3: {

                    //Skriver NY linje
                    Console.WriteLine("Skriv længde på Retvinklet trekant");

                    //Prøver at konverterer linjen brugeren skrev til int tal typen
                    if (!int.TryParse(Console.ReadLine(), out int length))
                    {
                        //Hvis dete ikke virkede skriver vi denne NYE linje
                        Console.WriteLine("Kunne ikke konverterer længde på Retvinklet trekant");

                        //Denne break block stopper switchen
                        break;
                    }

                    //Skriver NY linje
                    Console.WriteLine("Skriv bredde på Retvinklet trekant");

                    //Prøver at konverterer linjen brugeren skrev til int tal typen
                    if (!int.TryParse(Console.ReadLine(), out int height))
                    {
                        //Hvis dete ikke virkede skriver vi denne NYE linje
                        Console.WriteLine("Kunne ikke konverterer højde på Retvinklet trekant");

                        //Denne break block stopper switchen
                        break;
                    }

                    //returnerer arealet
                    return (length * height) / 2;
                };

                //Hvis ikke det brugeren trykkede matchede med en figur case type
                default:{
                    //Skriver NY linje
                    Console.WriteLine("Kunne ikke finde en figur");
                }break;
            }
            //Default retrun værdi
            return 0;
        }
    }
}