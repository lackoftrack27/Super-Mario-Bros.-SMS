#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <binary file>"
    exit 1
fi

FILE="$1"
FILESIZE=$(wc -c < "$FILE")
COUNT=$((FILESIZE / 2))

python3 - "$FILE" "$COUNT" << 'EOF'
import sys
import struct

filename = sys.argv[1]
count = int(sys.argv[2])

with open(filename, 'rb') as f:
    values = struct.unpack('<' + 'H' * count, f.read(count * 2))

result = [(v * 0x20) + 0x8000 for v in values]

for i in range(0, len(result), 8):
    chunk = result[i:i+8]
    print('.dw ' + ', '.join(f'${v:04X}' for v in chunk))
EOF

