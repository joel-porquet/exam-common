"""
Pandoc filter for adding LaTeX environement on specific div
"""

from pandocfilters import toJSONFilters, RawBlock, stringify

import re
import sys

def environment(key, value, format, meta):
    # Is it a div and the right format?
    if key == 'Div' and format == 'latex':

        # Get the attributes
        [[id, classes, properties], content] = value

        currentClasses = set(classes)

        for environment, definedClasses in getDefined(meta).items():
            # Is the classes correct?
            if currentClasses >= definedClasses:
                if id != '':
                    label = ' \\label{' + id + '}'
                else:
                    label = ''

                option = ''
                arguments = ''
                for key, value in properties:
                    if key == 'option':
                        if option == '':
                            option = '[' + value + ']'
                        else:
                            sys.stderr.write("Warning: ignoring option '{}'".
                                    format(value))
                    elif key == 'argument':
                        arguments += '{' + value + '}'

                return [RawBlock('tex', '\\begin{' + environment + '}' + option + arguments + label)] + content + [RawBlock('tex', '\\end{' + environment + '}')]

def getDefined(meta):
    # Return the latex-environment defined in the meta
    if not hasattr(getDefined, 'value'):
        getDefined.value = {}
        if 'pandoc-latex-environment' in meta and meta['pandoc-latex-environment']['t'] == 'MetaMap':
            for environment, classes in meta['pandoc-latex-environment']['c'].items():
                if classes['t'] == 'MetaList':
                    getDefined.value[environment] = []
                    for klass in classes['c']:
                        string = stringify(klass)
                        if re.match('^[a-zA-Z][\w.:-]*$', string):
                            getDefined.value[environment].append(string)
                    getDefined.value[environment] = set(getDefined.value[environment])
    return getDefined.value

def main():
    toJSONFilters([environment])

if __name__ == '__main__':
    main()
