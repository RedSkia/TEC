#!/usr/bin/env python3

def distinct_characters(L):
    result = {}
    for s in L:
        result[s] = len(set(s))
    return result

def main():
    print(distinct_characters(["check", "look", "try", "pop"]))

if __name__ == "__main__":
    main()
