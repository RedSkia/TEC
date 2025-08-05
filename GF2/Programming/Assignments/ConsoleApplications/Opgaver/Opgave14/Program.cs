using System;

namespace Opgave14
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 29.08.2023
            /// Opgave14


            #region 14A 
            {
                //Laver 3 doubble varaibles som er tomme
                double grundlinje, højte, svar;

                //Skriver text ud
                Console.Write("Indtast trekants grundlinje: ");

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                if (!double.TryParse(Console.ReadLine(), out grundlinje))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter grundlinje");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                Console.Write("Indtast trekants højde: ");

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                if (!double.TryParse(Console.ReadLine(), out højte))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter højte");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Formel
                svar = (grundlinje * højte) / 2;

                //Skriver NY linje med varaible
                Console.WriteLine($"Arealet på trekant: {svar}");

                //Venter på brugeren trykker på en tast
                Console.ReadKey();
            }
            #endregion 14A

            //Nulstiller console vindue
            Console.Clear();


            #region 14B
            {
                //Laver 2 doubble varaibles
                double højde, bredde;

                //Skriver text ud
                Console.Write("Indtast rektangel højde: ");

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                if (!double.TryParse(Console.ReadLine(), out højde))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter grundlinje");

                    //Forhindrer at programmet kører vidrer
                    return;
                }

                //Checker om det input fra brugeren kan konverteres til int typen også sætter værdien af tal1
                Console.Write("Indtast rektangel bredde: ");
                if (!double.TryParse(Console.ReadLine(), out bredde))
                {
                    //Skriver NY linje
                    Console.WriteLine("Fejlede til at konverter højte");

                    //Forhindrer at programmet kører vidrer
                    return;
                }


                //Skriver NY linje med varaible
                Console.WriteLine($"Arealet på rektangel: {(højde * bredde)}");

                //Skriver NY linje med varaible
                Console.WriteLine($"Omkredsen på rektangel: {(højde * 2) + (bredde * 2)}");

                //Venter på brugeren trykker på en tast
                Console.ReadKey();
            }
            #endregion 14B

        }
    }
}