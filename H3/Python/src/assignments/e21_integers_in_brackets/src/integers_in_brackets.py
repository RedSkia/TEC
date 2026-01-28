#!/usr/bin/env python3


def integers_in_brackets(s):
    results = []
    # Split the string by the opening bracket '['
    parts = s.split('[')

    # We iterate through the parts that came after an opening bracket
    for part in parts[1:]:
        # Find the content before the first closing bracket ']'
        if ']' in part:
            content_part = part.split(']')[0]
            # Remove any leading/trailing whitespace
            cleaned_content = content_part.strip()
            # Try to convert the cleaned content to an integer
            try:
                number = int(cleaned_content)
                results.append(number)
            except ValueError:
                # If conversion fails, it's not a valid integer, so we ignore it.
                pass
    return results

def main():
    print(integers_in_brackets(" afd [asd] [12 ] [a34] [ -43 ]tt [+12]xxx"))

if __name__ == "__main__":
    main()
