using System;

namespace Opgave60
{
    internal class Program
    {
        static void Main(string[] args)
        {
            //Denne block prøver at kører
            try
            {
                //Her laver en vi en int varaible med maks værdien
                int maxValue = int.MaxValue;

                //Her laver vi en ny  int varaible med maks værdien +1 
                int result = checked(maxValue + 1);

                //Så prøver vi at skrive den MEN da vi bruger checked vil dette give en Overflow Exception 
                Console.WriteLine("Result: " + result);
            }
            catch (OverflowException ex) /*Så derfor bliver denne kode block kørt*/
            {

                //Skriver NY Linje ud med fejlen
                Console.WriteLine("Overflow Exception: " + ex.Message);
            }
        }
    }
}