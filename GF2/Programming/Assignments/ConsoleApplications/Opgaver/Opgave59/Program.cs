using System;

namespace Opgave59
{
    internal class Program
    {
        static void Main(string[] args)
        {
            /// Marcus Wahlstrøm
            /// 08.09.2023
            /// Opgave59


            /*Her er Dokumentationen på hvordan jeg lavede en hjemmelavet snippet:
             https://learn.microsoft.com/en-us/visualstudio/ide/walkthrough-creating-a-code-snippet?view=vs-2022
            */

            /*
             <?xml version="1.0" encoding="utf-8"?>
             <CodeSnippets xmlns="http://schemas.microsoft.com/VisualStudio/2005/CodeSnippet">
                 <CodeSnippet Format="1.0.0">
                     <Header>
                         <Title>MySnippet</Title>
                         <Author>Marcus</Author>
                         <Description>Sætter up Console.WriteLine med tekst og Console.ReadKey</Description>
                         <Shortcut>snap</Shortcut>
                     </Header>
                     <Snippet>
                         <Code Language="CSharp">
                             <![CDATA[
                             Console.WriteLine("Hjemmelavet snippet!");
                             Console.ReadKey();
                             ]]>
                         </Code>
                     </Snippet>
                 </CodeSnippet>
             </CodeSnippets>
             */


            //Fra min snippet
            Console.WriteLine("Hjemmelavet snippet!");
            Console.ReadKey();
        }
    }
}