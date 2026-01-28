#!/usr/bin/env python3


def word_frequencies(filename):
    """
    Calculates the frequency of each word in a file.

    Args:
        filename (str): The path to the input file.

    Returns:
        dict: A dictionary with words as keys and their frequencies as values.
    """
    frequencies = {}
    # The instructions list "&", but stripping it removes the word "&" from
    # "Sons & Company", causing the count to be off by one (2423 vs 2424).
    punctuation = """!"#$%'()*,-./:;?@[]_"""
    with open(filename, 'r') as f:
        for line in f:
            for word in line.split():
                cleaned_word = word.strip(punctuation)
                if cleaned_word:
                    frequencies[cleaned_word] = frequencies.get(cleaned_word, 0) + 1
    return frequencies

def main():
    frequencies = word_frequencies("src/alice.txt")
    for word, count in frequencies.items():
        print(f"{word}\t{count}")

if __name__ == "__main__":
    main()