#!/usr/bin/env python3

def extract_numbers(s):
    """
    Extracts all integers and floats from a string and returns them in a list.
    """
    found_numbers = []
    for word in s.split():
        try:
            # First, try to convert the word to an integer.
            found_numbers.append(int(word))
        except ValueError:
            # If that fails, it's not an integer. Let's try converting to a float.
            try:
                found_numbers.append(float(word))
            except ValueError:
                # If it's not a float either, we ignore it and continue.
                continue
    return found_numbers

def main():
    print(extract_numbers("abd 123 1.2 test 13.2 -1"))

if __name__ == "__main__":
    main()
