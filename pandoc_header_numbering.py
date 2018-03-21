"""
Pandoc filter for numbering headers
"""

from pandocfilters import toJSONFilters, Header, Str

import re
import sys

def header_numbering(key, value, format, meta):

    # Only headers
    if key == 'Header':

        [level, desc, content] = value

        try:
            # Look for headers starting with ("Question -")
            if ((content[0]['t'] == 'Str' and content[0]['c'] == 'Question')
                    and (content[1]['t'] == 'Space')
                    and (content[2]['t'] == 'Str' and content[2]['c'] == '-')):

                # Change the '-' string into the actual number
                content[2] = Str(str(header_numbering.count))

                header_numbering.count += 1
        except:
            pass

        return Header(level, desc, content)

def main():
    # Starts the numbering at 1
    header_numbering.count = 1
    toJSONFilters([header_numbering])

if __name__ == '__main__':
    main()
