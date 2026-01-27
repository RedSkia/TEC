#!/usr/bin/env python3

def main():
    # Enter your solution here
    while True:
        try:
            num1 = int(input("Enter the first number: "))
            num2 = int(input("Enter the second number: "))
            result = num1 * num2
            print(f"{num1} multiplied by {num2} is {result}")
            break
        except ValueError:
            print("Please enter valid integers.")
    pass

if __name__ == "__main__":
    main()
