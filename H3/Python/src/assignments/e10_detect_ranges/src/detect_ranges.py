#!/usr/bin/env python3

def detect_ranges(L):
    if not L:
        return []

    sorted_L = sorted(L)
    result = []
    i = 0
    n = len(sorted_L)

    while i < n:
        start = sorted_L[i]
        j = i
        while j + 1 < n and sorted_L[j+1] == sorted_L[j] + 1:
            j += 1

        if i == j:
            result.append(start)
            i += 1
        else:
            result.append((start, sorted_L[j] + 1))
            i = j + 1
    return result

def main():
    L = [2, 5, 4, 8, 12, 6, 7, 10, 13]
    result = detect_ranges(L)
    print(L)
    print(result)

if __name__ == "__main__":
    main()
