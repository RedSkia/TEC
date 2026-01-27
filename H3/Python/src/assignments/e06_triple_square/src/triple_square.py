#!/usr/bin/env python3

def triple(x):
    """
    Multiplies its parameter by three.
    """
    return x * 3

def square(x):
    """
    Raises its parameter to the power of two.
    """
    return x ** 2

def main():
    for i in range(1, 11):
        if square(i) > triple(i):
            break
        print(f"triple({i})=={triple(i)} square({i})=={square(i)}")

if __name__ == "__main__":
    main()
