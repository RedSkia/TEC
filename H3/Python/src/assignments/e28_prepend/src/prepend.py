#!/usr/bin/env python3

class Prepend(object):
    """
    A class that prepends a start string to another string when writing.
    """
    def __init__(self, start):
        """
        Initializes the Prepend object with a start string.
        """
        self.start = start

    def write(self, s):
        """
        Prints the string 's' prepended with the start string.
        """
        print(f"{self.start}{s}")

def main():
    p = Prepend("+++ ")
    p.write("Hello")

if __name__ == "__main__":
    main()
