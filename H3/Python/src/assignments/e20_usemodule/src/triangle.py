"""
This module provides functions for right-angled triangle calculations.
"""

__version__ = "1.0"
__author__ = "RedSkia"

import math

def hypothenuse(a, b):
    """
    Returns the length of the hypothenuse when given the lengths of two other sides of a right-angled triangle.
    """
    return math.sqrt(a**2 + b**2)

def area(a, b):
    """
    Returns the area of the right-angled triangle, when two sides, perpendicular to each other, are given as parameters.
    """
    return 0.5 * a * b
