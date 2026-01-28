#!/usr/bin/env python3

import re

def red_green_blue(filename="src/rgb.txt"):
    results = []
    # This regex will capture the three numbers and the rest of the line as the name.
    # It handles the varying amounts of whitespace between the values.
    regex = r"^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.*)$"

    with open(filename, "r") as f:
        next(f)  # Skip the first irrelevant line
        for line in f:
            match = re.search(regex, line)
            if match:
                r, g, b, name = match.groups()
                # The name can have trailing whitespace, so we strip it.
                name = name.strip()
                # Format the string with tabs as separators
                results.append(f"{r}\t{g}\t{b}\t{name}")
    return results


def main():
    for line in red_green_blue()[:5]:
        print(line)

if __name__ == "__main__":
    main()
