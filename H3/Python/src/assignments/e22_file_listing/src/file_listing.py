#!/usr/bin/env python3

import re


def file_listing(filename="src/listing.txt"):
    results = []
    # This regular expression is built to find and capture the specific parts
    # of each line from the file, as described in the exercise.
    regex = r"^\S+\s+\d+\s+\S+\s+\S+\s+(\d+)\s+([A-Z][a-z]{2})\s+(\d{1,2})\s+(\d{2}):(\d{2})\s+(.*)$"

    with open(filename, "r") as f:
        for line in f:
            match = re.search(regex, line)
            if match:
                # If a match is found, extract the captured groups.
                # The groups are: 1:size, 2:month, 3:day, 4:hour, 5:minute, 6:filename
                size = int(match.group(1))
                month = match.group(2)
                day = int(match.group(3))
                hour = int(match.group(4))
                minute = int(match.group(5))
                file_name = match.group(6)
                results.append((size, month, day, hour, minute, file_name))
    return results

def main():
    for item in file_listing():
        print(item)

if __name__ == "__main__":
    main()
