#!/usr/bin/env python3


def main():
    input_range1 = int(input("Range 1: "))
    input_range2 = int(input("Range 2: "))
    for i in range(1, input_range1+1):
        for j in range(1, input_range2+1):
            print(f"{i*j:4}", end="")
        print()

if __name__ == "__main__":
    main()
