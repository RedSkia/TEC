using System;
using System.Linq;

namespace Opgave41
{
    internal class Program
    {
        //Laver et nyt readonly char array med værdier 0 som default også går op til 1-9
        static readonly char[] chars = new char[10]
        {
            '0', /*Default*/
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
        };

        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave41

            //Laver en ny char variable med værdi '0'
            char input = '0';

            //Kører et while loop so længe vores chars array indeholder input variables værdi
            while (chars.Contains(input))
            {
                //Skriver NY linje til brugeren efter et taste tryk på 1, 2, 3, 4, 5, 6, 7, 8 eller 9
                Console.WriteLine("\nTryk på 1, 2, 3, 4, 5, 6, 7, 8 eller 9");

                //Ændrer variables værdi til hvad brugeren trykker på
                input = Console.ReadKey().KeyChar;

                //Dette er en Switch der er et alternativ til et IF statment Men en switch er anderldes da den check på enkelte betingelser
                switch (input)
                {
                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '1': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '2': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '3': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '4': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '5': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '6': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '7': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '8': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykker på 1 bliver denne kode block kørt som Skriver NY linje med at brugeren trykkede på knappen
                    case '9': { Console.WriteLine($"\nDu trykkede på \"{input}\""); } break;

                    //Hvis brugeren trykkede på noget andet end i cases ovenfor så bliver denne kode block kørt (man kan godt lidt side at hvis de cases ovenfor er if statments så er default else)
                    default: { Console.WriteLine($"\nDu trykkede på noget andet end \"1, 2, 3, 4, 5, 6, 7, 8 eller 9\""); } break;
                }

            }

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        }
    }
}