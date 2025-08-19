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
        const string chars = "abcdefghijklmnopqrstuvwxyz";
        var random = new Random();

        if (length == -1) length = random.Next(1, chars.Length + 1);

        var word = new char[length];
        for (int i = 0; i < length; i++)
            word[i] = chars[random.Next(chars.Length)];

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
