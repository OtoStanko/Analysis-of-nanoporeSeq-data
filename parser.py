import getopt
import sys

'''This script parses mismatched taxonomy IDs from Krona error output (input of script) and 
puts each ID into separate line of output file, which can be processed easier afterwards.'''

START = "[ WARNING ]  The following taxonomy IDs were not found in the local database and were set to root " \
        "(if they were recently added to NCBI, use updateTaxonomy.sh to update the local"

input_file, output_file = '', ''
if len(sys.argv) != 5:
    print('parser -i <inputfile> -o <outputfile>')
    sys.exit(2)

try:
    opts, args = getopt.getopt(sys.argv[1:], "hi:o:", ["input_file=", "output_file="])
except getopt.GetoptError:
    print('parser.py -i <inputfile> -o <outputfile>')
    sys.exit(2)

for opt, arg in opts:
    if opt == '-h':
        print('parser.py -i <inputfile> -o <outputfile>')
        sys.exit()
    elif opt in ("-i", "--input_file"):
        input_file = arg
    elif opt in ("-o", "--output_file"):
        output_file = arg

with open(input_file, "r") as kraken_warnings, \
        open(output_file, "w") as kraken_mismatched:
    parse = False
    for line in kraken_warnings:
        if START in line:  # Warning header found
            parse = True
            continue

        if not parse:  # while Warning header not found
            continue

        if "[ WARNING ]" in line:  # next Warning header reached
            break
        s = line.split()
        s = list(filter(lambda x: x.isnumeric(), s))
        for elem in s:  # put all mismatched IDs to file on separate line
            print(elem, file=kraken_mismatched)
