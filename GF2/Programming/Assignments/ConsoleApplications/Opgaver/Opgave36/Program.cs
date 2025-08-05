
//Dette er using directives og det betyder at du forklare programmert der er komponenter i dette namespace som du gerne vil bruge
using System;

//Namespace er det navn du giver koden mellem de curly brackets (sådan da)
namespace Opgave36
{
    //Dette er et objekt (class reference type) som er internal og internal er en access modifier som giver sikkerhed efter hvor fra klassen Program kan bruges/ses fra
    internal class Program
    {
        //Dette er den standard entry method for konsol applikationer Det er ligemget hvilken access modifier du smider på MEN METODEN SKAL VÆRE STATIC! Og denne metode tager et string array som input 
        //Static betyder at objektet tilhører til sig selv se det ligt som et delt objekt
        //Void er return typen og når den er void så kan ingen værdi eller object returneres man kan dog stadig bruge det keyword return til at bryde fri fx i et if statement
        static void Main(string[] args)
        {

            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave36

            //Dette er en ikke Instantieret variable af typen int det betyder værdien er sat til default 
            int tal;

            //Dette er en type af loop som hedder do-while loop
            //Dette betyder at denne type loop frøst kører koden mellem de curly brackets i do blokken der efter checker den betingelsen i while blokken
            do
            {
                //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden Write
                Console.Write("Indtast et positivt tal: ");

                //Dette kalder klassen fra Namespace system som har en class som hedder Convert med metoden ToInt32
                tal = Convert.ToInt32(Console.ReadLine());

                //Dette er en IF statment som kan bruges til at checke for en betingelse
                if (tal <= 0)
                {
                    //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden WriteLine
                    Console.WriteLine("Du skal taste et tal større end 0");

                    //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden Write
                    Console.Write("Tryk Enter");

                    //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden ReadKey
                    Console.ReadKey();
                }
            } while (tal <= 0); /*betingelsen*/

            //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden Write
            Console.Write("Inddata er godkendt");

            //Dette kalder klassen fra Namespace system som har en class som hedder Console med metoden ReadKey
            Console.ReadKey();
        }
    }
}