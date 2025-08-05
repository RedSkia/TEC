using System;

namespace Opgave43
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave43

            //Skriver NY linje
            Console.WriteLine("Tryk på (S)witch eller (I)f");

            //Dette er en switch
            switch (Console.ReadKey().Key)
            {
                //Hvis knappen brugeren trykkede på er S
                case ConsoleKey.S: {

                    //Nulstiller console
                    Console.Clear();
                    
                    //Skriver NY linje og beder brugeren efter et tal fra 1-5
                    Console.WriteLine("Skriv et tal fra 1-5");
                    
                    //Sætter variable input til hvad brugeren skriver
                    string input = Console.ReadLine();

                    //Dette er en switch
                    switch (input)
                    {
                        //Hvis input er 1 skriver vi NY linje med tallet er 1
                        case "1": { Console.WriteLine("Tallet er: 1"); }; break;

                        //Hvis input er 2 skriver vi NY linje med tallet er 2
                        case "2": { Console.WriteLine("Tallet er: 2"); }; break;

                        //Hvis input er 3 skriver vi NY linje med tallet er 3
                        case "3": { Console.WriteLine("Tallet er: 3"); }; break;

                        //Hvis input er 4 skriver vi NY linje med tallet er 4
                        case "4": { Console.WriteLine("Tallet er: 4"); }; break;

                        //Hvis input er 5 skriver vi NY linje med tallet er 5
                        case "5": { Console.WriteLine("Tallet er: 5"); }; break;

                        //Hvis IKKE tallet er 1-5 Skriver denne NYE linje
                        default: { Console.WriteLine("Tallet er IKKE 1-5"); } break;
                    }
                } break;

                //Hvis knappen brugeren trykkede på er I
                case ConsoleKey.I:{

                    //Nulstiller console
                    Console.Clear();

                    //Skriver NY linje og beder brugeren efter et tal fra 1-5
                    Console.WriteLine("Skriv et tal fra 1-5");

                    //Sætter variable input til hvad brugeren skriver
                    string input = Console.ReadLine();

                    //Hvis input er 1 skriver vi NY linje med tallet er 1
                    if (input == "1") { Console.WriteLine("Tallet er: 1"); }

                    //Hvis input er 2 skriver vi NY linje med tallet er 2
                    else if (input == "2") { Console.WriteLine("Tallet er: 2"); }

                    //Hvis input er 3 skriver vi NY linje med tallet er 3
                    else if (input == "3") { Console.WriteLine("Tallet er: 3"); }

                    //Hvis input er 4 skriver vi NY linje med tallet er 4
                    else if (input == "4") { Console.WriteLine("Tallet er: 4"); }

                    //Hvis input er 5 skriver vi NY linje med tallet er 5
                    else if (input == "5") { Console.WriteLine("Tallet er: 5"); }

                    //Hvis IKKE tallet er 1-5 Skriver denne NYE linje
                    else { Console.WriteLine("Tallet er IKKE 1-5"); }
                } break;

                //Hvis ikke brugeren tykkede på S eller I skriver vi denne NYE linje
                default: { Console.WriteLine("Kunne ikke udføre operation"); } break;
            }

            //Venter på taste tryk
            Console.ReadKey();
        }
    }
}