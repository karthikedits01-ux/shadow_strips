import struct, zlib, os, random

def png_pack(png_tag, data):
    chunk_head = png_tag + data
    return struct.pack('!I', len(data)) + chunk_head + struct.pack('!I', zlib.crc32(chunk_head) & 0xFFFFFFFF)

width, height = 256, 256
raw_data = b''
for y in range(height):
    raw_data += b'\x00'
    for x in range(width):
        v = random.randint(150, 255) # Light grey noise
        raw_data += struct.pack('B', v)

png = b'\x89PNG\r\n\x1a\n'
png += png_pack(b'IHDR', struct.pack('!2I5B', width, height, 8, 0, 0, 0, 0))
png += png_pack(b'IDAT', zlib.compress(raw_data, 9))
png += png_pack(b'IEND', b'')

os.makedirs('assets', exist_ok=True)
with open('assets/noise.png', 'wb') as f:
    f.write(png)
print('Created assets/noise.png successfully.')
