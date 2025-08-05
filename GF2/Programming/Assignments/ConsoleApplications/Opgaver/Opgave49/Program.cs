using System;
using System.Linq;
using System.Windows;

namespace Opgave49
{
    internal class Program
    {
        [STAThread] /*Denne attribute laver applkaction single-threaded da det kræver Clipboard klassen til at virke i dette tilfælde*/
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Opgave49

            //Skriver Ny line
            Console.WriteLine("Kopier noget tekst");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text til værdien fra klassen Clipboard fra metoden GetText og laver den omvendt
            string text = new string(Clipboard.GetText().Reverse().ToArray());

            //Skriv NY linje med teksten uden mellemrum
            Console.WriteLine(text);

            //Vent på taste tryk
            Console.ReadKey();
        }
    }
}