using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace IfElse
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 04.09.2023
            /// IfElse


            //Skriver text til brugeren efter et tal
            Console.Write("Skriv et tal");


            //Prøver at konverterer input fra brugeren til typen int
            if (!int.TryParse(Console.ReadLine(), out int number))
            {
                //Skriver NY linje med text
                Console.WriteLine("Kunne ikke konvertere input til int");

                //forhindrer programmeet kørere videre fra her
                return;
            }

            //Checker om tallet er større end 4 
            if (number > 4)
            {
                //Skriver NY linje med text
                Console.WriteLine("Tallet er større end 4");
            }
            else /*Ellers*/
            {
                //Skriver NY linje med text
                Console.WriteLine("Tallet er mindre end 4");
            }

            //Venter på taste tryk fra brugeren
            Console.ReadKey();
        } 
    }
}