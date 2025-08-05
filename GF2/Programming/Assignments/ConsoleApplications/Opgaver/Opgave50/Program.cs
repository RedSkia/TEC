using System;
using System.Windows;

namespace Opgave50
{
    internal class Program
    {

        [STAThread] /*Denne attribute laver applkaction single-threaded da det kræver Clipboard klassen til at virke i dette tilfælde*/
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave50

            //Skriver Ny line
            Console.WriteLine("Kopier tekst1");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text1 til værdien fra klassen Clipboard fra metoden GetText
            string text1 = Clipboard.GetText();

            //Skriver Ny line
            Console.WriteLine("Kopier tekst2 som bruges til at søge i tekst1");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text2 til værdien fra klassen Clipboard fra metoden GetText
            string text2 = Clipboard.GetText();

            //Laver en string varaible med ternary operator checks som giver et bruges til at give en string værdi efter betingelserne
            string contains = text1.Contains(text2) ? "tekst1 indeholder tekst2" : "tekst1 indeholder IKKE tekst2";

            //Skriver varaiblen ud på NY line
            Console.WriteLine(contains);

            //Vent på taste tryk
            Console.ReadKey();
        }
    }
}