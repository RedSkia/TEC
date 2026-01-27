#!/usr/bin/env python3

def main():
    pairs = [f"({i},{j})" for i in range(1, 7) for j in range(1, 7) if i + j == 5]
    for pair in pairs:
        print(pair)

if __name__ == "__main__":
    main()
