#!/usr/bin/env python3

def merge(L1, L2):
    result = []
    i = 0  # Pointer for L1
    j = 0  # Pointer for L2

    # Loop while both lists have elements
    while i < len(L1) and j < len(L2):
        if L1[i] < L2[j]:
            result.append(L1[i])
            i += 1
        else:
            result.append(L2[j])
            j += 1

    # Append remaining elements from L1 (if any)
    result.extend(L1[i:])
    # Append remaining elements from L2 (if any)
    result.extend(L2[j:])
    return result

def main():
    print(merge([1, 5, 9, 12], [2, 6, 10]))
    print(merge([1, 2, 3], [4, 5, 6]))
    print(merge([], [1, 2, 3]))
