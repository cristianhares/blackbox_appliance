#!/bin/python3
#
# The reason behind this script is that 
# awk/sed do not handle well hash special characters
# and perl is not a standard linux library which is more complex to handle
#
import re, crypt
from sys import argv

with open(argv[1], 'rt') as infile:
    with open(argv[2], 'wt') as outfile:
        for line in infile:
            if line.startswith("rootpw"):
                new_line1 = re.sub(r'\$6.*', crypt.crypt(argv[3], crypt.mksalt(crypt.METHOD_SHA512)), line)
                outfile.write(new_line1)
            elif line.startswith("user --name=sysadmin"):
                new_line2 = re.sub(r'\$6.*', crypt.crypt(argv[4], crypt.mksalt(crypt.METHOD_SHA512)), line)
                outfile.write(new_line2)
            elif line.startswith("user --name=netadmin"):
                new_line3 = re.sub(r'\$6.*', crypt.crypt(argv[5], crypt.mksalt(crypt.METHOD_SHA512)), line)
                outfile.write(new_line3)
            else:
                outfile.write(line)
        outfile.close()
    infile.close()
