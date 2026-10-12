#!/usr/bin/env python3
"""Package exported icon PNGs without changing their pixels. No third-party modules."""
import argparse
from pathlib import Path
import struct


def package(source):
    entries = [
        ('icp4', 16, 1), ('ic11', 16, 2), ('icp5', 32, 1), ('ic12', 32, 2),
        ('ic07', 128, 1), ('ic13', 128, 2), ('ic08', 256, 1), ('ic14', 256, 2),
        ('ic09', 512, 1), ('ic10', 512, 2),
    ]
    chunks = []
    for kind, points, scale in entries:
        suffix = '@2x' if scale == 2 else ''
        name = f'icon_{points}x{points}{suffix}.png'
        data = (source / name).read_bytes()
        if (len(data) < 33 or data[:8] != b'\x89PNG\r\n\x1a\n' or
                data[12:16] != b'IHDR' or
                struct.unpack('>II', data[16:24]) != (points * scale, points * scale)):
            raise ValueError(f'Invalid PNG or dimensions: {name}')
        offset = 8
        while offset < len(data):
            if offset + 12 > len(data):
                raise ValueError(f'Truncated PNG: {name}')
            length = struct.unpack('>I', data[offset:offset + 4])[0]
            tag = data[offset + 4:offset + 8]
            if tag in {b'tEXt', b'iTXt', b'zTXt', b'eXIf'}:
                raise ValueError(f'Remove text/EXIF metadata before packaging: {name}')
            offset += length + 12
            if offset > len(data):
                raise ValueError(f'Truncated PNG: {name}')
        chunks.append(kind.encode('ascii') + struct.pack('>I', len(data) + 8) + data)
    payload = b''.join(chunks)
    return b'icns' + struct.pack('>I', len(payload) + 8) + payload


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('iconset', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.output.suffix.lower() != '.icns':
        parser.error('Output must have the .icns extension.')
    try:
        data = package(args.iconset)
        args.output.write_bytes(data)
    except (OSError, ValueError) as error:
        parser.exit(1, f'Icon packaging failed: {error}\n')
    print('Wrote 10 PNG icon representations. Inspect the result before publication.')


if __name__ == '__main__':
    main()
