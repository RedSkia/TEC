using System;
using System.Windows;

namespace Opgave47
{
    internal class Program
    {

        [STAThread] /*Denne attribute laver applkaction single-threaded da det kræver Clipboard klassen til at virke i dette tilfælde*/
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 07.09.2023
            /// Opgave47

            //Skriver Ny line
            Console.WriteLine("Kopier tekst1");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text1 til værdien fra klassen Clipboard fra metoden GetText
            string text1 = Clipboard.GetText();


            //Skriver Ny line
            Console.WriteLine("Kopier tekst2");

            //Vent på taste tryk
            Console.ReadKey();

            //Sæt string variablen text2 til værdien fra klassen Clipboard fra metoden GetText
            string text2 = Clipboard.GetText();

            //Laver en string varaible med ternary operator checks som giver et bruges til at give en string værdi efter betingelserne
            string longestText = (text1.Length == text2.Length) ? "Teksterne er samme længde" : (text1.Length >= text2.Length) ? "Den første tekst var længst" : "Den anden tekst var længst";

            //Skriver varaiblen longestText ud på NY line
            Console.WriteLine(longestText);
            
            //Vent på taste tryk
            Console.ReadKey();
        }
    }
}