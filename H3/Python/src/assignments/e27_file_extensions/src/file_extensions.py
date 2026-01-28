#!/usr/bin/env python3

import sys

def file_extensions(filename):
    """
    Reads a file containing filenames and categorizes them by their extension.

    Args:
        filename (str): The path to the input file.

    Returns:
        tuple: A pair containing:
               - A list of filenames with no extension.
               - A dictionary with extensions as keys and lists of filenames as values.
    """
    no_extension_files = []
    extensions_dict = {}

    with open(filename, 'r') as f:
        for line in f:
            fn = line.strip()
            if not fn:
                continue

            last_dot_pos = fn.rfind('.')

            # A file has no extension if there is no dot or if the dot is the first character.
            if last_dot_pos <= 0:
                no_extension_files.append(fn)
            else:
                ext = fn[last_dot_pos + 1:]
                if ext not in extensions_dict:
                    extensions_dict[ext] = []
                extensions_dict[ext].append(fn)
    
    return (no_extension_files, extensions_dict)

def main():
    """
    Calls file_extensions and prints the summary.
    """
    no_ext_list, ext_dict = file_extensions("src/filenames.txt")
    print(f"{len(no_ext_list)} files with no extension")
    for ext in sorted(ext_dict):
        print(f"{ext} {len(ext_dict[ext])}")

if __name__ == "__main__":
    main()