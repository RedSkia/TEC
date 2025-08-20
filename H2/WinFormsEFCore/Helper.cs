using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Text;
using System.Threading.Tasks;

namespace WinFormsEFCore;

public static class Helper
{
    public static string RandomWord(int length = -1)
    {
        var random = new Random();
        const string vowels = "aeiou";
        const string consonants = "bcdfghjklmnpqrstvwxyz";

        // If length not specified, choose 3–8 letters (more realistic)
        if (length == -1) length = random.Next(3, 9);

        var word = new char[length];

        // Alternate consonant and vowel for a more "word-like" structure
        bool startWithConsonant = random.Next(2) == 0;
        for (int i = 0; i < length; i++)
        {
            if ((i % 2 == 0 && startWithConsonant) || (i % 2 == 1 && !startWithConsonant))
                word[i] = consonants[random.Next(consonants.Length)];
            else
                word[i] = vowels[random.Next(vowels.Length)];
        }

        // Capitalize first letter
        word[0] = char.ToUpper(word[0]);
        return new string(word);
    }

    public static void Generate(int count, Func<object>[] generators, Action<object[]>[]? processors = null, Action<object[]>? finalizer = null)
    {
        var length = generators.Length;
        var buffer = new object[length];

        for (int i = 0; i < count; i++)
        {
            // Create
            for (int j = 0; j < length; j++)
                buffer[j] = generators[j]();

            // Process
            if (processors is not null)
            {
                foreach (var process in processors)
                    process(buffer);
            }

            // Finalize
            finalizer?.Invoke(buffer);
        }
    }
}
