#!/usr/bin/env python3

def gcd(a, b):
    """
    Computes the greatest common divisor of two integers using the Euclidean algorithm.
    """
    while b:
        a, b = b, a % b
    return a

class Rational(object):
    def __init__(self, num, den):
        if den == 0:
            raise ZeroDivisionError("Denominator cannot be zero")
        
        common = gcd(num, den)
        self.num = num // common
        self.den = den // common

        # Ensure the sign is always on the numerator
        if self.den < 0:
            self.num = -self.num
            self.den = -self.den

    def __str__(self):
        return f"{self.num}/{self.den}"

    def __add__(self, other):
        new_num = self.num * other.den + other.num * self.den
        new_den = self.den * other.den
        return Rational(new_num, new_den)

    def __sub__(self, other):
        new_num = self.num * other.den - other.num * self.den
        new_den = self.den * other.den
        return Rational(new_num, new_den)

    def __mul__(self, other):
        new_num = self.num * other.num
        new_den = self.den * other.den
        return Rational(new_num, new_den)

    def __truediv__(self, other):
        new_num = self.num * other.den
        new_den = self.den * other.num
        return Rational(new_num, new_den)

    def __eq__(self, other):
        # Fractions are always simplified, so direct comparison works.
        return self.num == other.num and self.den == other.den

    def __lt__(self, other):
        # Compare a/b < c/d by checking if ad < bc
        return self.num * other.den < other.num * self.den

    def __gt__(self, other):
        # Compare a/b > c/d by checking if ad > bc
        return self.num * other.den > other.num * self.den

def main():
    r1=Rational(1,4)
    r2=Rational(2,3)
    print(r1)
    print(r2)
    print(r1*r2)
    print(r1/r2)
    print(r1+r2)
    print(r1-r2)
    print(Rational(1,2) == Rational(2,4))
    print(Rational(1,2) > Rational(2,4))
    print(Rational(1,2) < Rational(2,4))

if __name__ == "__main__":
    main()
