#!/usr/bin/env python3

import sys

def summary(filename):
    """
    Reads numbers from a file and calculates their sum, average, and standard deviation.

    Args:
        filename (str): The path to the input file.

    Returns:
        tuple: A tuple containing the sum, average, and standard deviation.
    """
    numbers = []
    with open(filename, "r") as f:
        for line in f:
            try:
                # Try to convert the line to a float and add to our list
                numbers.append(float(line))
            except ValueError:
                # If conversion fails, just ignore this line
                pass

    count = len(numbers)
    if count == 0:
        return (0.0, 0.0, 0.0)

    total_sum = sum(numbers)
    average = total_sum / count

    # Standard deviation requires at least 2 numbers
    if count < 2:
        stddev = 0.0
    else:
        sum_of_squares = sum((x - average) ** 2 for x in numbers)
        stddev = (sum_of_squares / (count - 1)) ** 0.5

    return (total_sum, average, stddev)

def main():
    for filename in sys.argv[1:]:
        s, a, std = summary(filename)
        print(f"File: {filename} Sum: {s:.6f} Average: {a:.6f} Stddev: {std:.6f}")

if __name__ == "__main__":
    main()
