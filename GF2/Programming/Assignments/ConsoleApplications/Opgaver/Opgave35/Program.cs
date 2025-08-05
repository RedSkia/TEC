using System;
using System.Collections.Generic;
using System.Linq;

namespace Opgave35
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 05.09.2023
            /// Opgave35

            //Laver en konstant byte variable på værdien 100
            const ushort loopIterations = 1000;

            //Laver en ny instance af klassen Random
            Random rand = new Random();

            //Laver en ny erklæring? af klassen Dictionary dette er en smart Refreance-Type fordi det kan gemme data som Key-Valuy
            Dictionary<int, int> cachedMatches = new Dictionary<int, int>(loopIterations);

            //Kører et for loop loopIterations gange
            for (int i = 0; i < loopIterations; i++)
            {
                //Laver en ny int variable hvor værdien bliver sat af metoden next fra klassen random
                int num = rand.Next(1, loopIterations);

                //Checker hvis ikke cachedMatches indeholder nøglen num også tilføjer den
                if (!cachedMatches.ContainsKey(num)) { cachedMatches.Add(num, 1); }

                //Øger værdien med 1 på cachedMatches med nøglen num
                cachedMatches[num]++;
            }


            //Laver en int variable
            int windowStartHeight = Console.WindowHeight - 1;

            //Int varaible med værdien 0
            int index = 0;

            //Kører et foreach loop som er forskelig fra et forloop som kun giver tal et foreach loop giver et object
            foreach (var match in cachedMatches.OrderBy(m => m.Key))
            {
                //Checker om i + 1 er støere end windowStartHeight
                if ((index + 1) > windowStartHeight)
                {
                    //Øger buffer height med 1 hver gang denne bliver kaldt
                    Console.BufferHeight++;
                }

                //Skrver NY linje med hvormange gange terningen landede på siden 
                Console.WriteLine($"terningen landede på {match.Key} ({match.Value}) gange");

                //Øger index variablen med 1
                index++;
            }

            //Venter på taste tryk
            Console.ReadLine();
        }
    }
}