#!/usr/bin/env python3

import math


def main():
    # enter you solution here
    while True:
        shape = input("Choose a shape (triangle, rectangle, circle): ")
        match shape:
            case "":
                break
            case "triangle":
                base = float(input("Give base of the triangle: "))
                height = float(input("Give height of the triangle: "))
                print(f"The area is {0.5 * base * height:.6f}")
            case "rectangle":
                width = float(input("Give width of the rectangle: "))
                height = float(input("Give height of the rectangle: "))
                print(f"The area is {width * height:.6f}")
            case "circle":
                radius = float(input("Give radius of the circle: "))
                print(f"The area is {math.pi * radius**2:.6f}")
            case _:
                print("Unknown shape!")

if __name__ == "__main__":
    main()
