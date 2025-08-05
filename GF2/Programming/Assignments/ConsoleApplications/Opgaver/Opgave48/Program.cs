using System;
using System.Windows;

namespace Opgave48
{
    internal class Program
    {
        [STAThread] /*Denne attribute laver applkaction single-threaded da det kræver Clipboard klassen til at virke i dette tilfælde*/
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave48

            //Skriver Ny line
            Console.WriteLine("Kopier noget tekst");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text til værdien fra klassen Clipboard fra metoden GetText og erstat alle mellemrum
            string text = Clipboard.GetText().Replace(" ", "");

            //Skriv NY linje med teksten uden mellemrum
            Console.WriteLine(text);

            //Vent på taste tryk
            Console.ReadKey();
        }
    }
}