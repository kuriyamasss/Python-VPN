# Create simple placeholder icons for the extension
# This generates a basic PNG icon using Python's built-in capabilities

import os
import struct

def create_simple_icon(filename, size, color=(76, 175, 80)):
    """Create a simple solid color PNG icon"""
    # Minimal valid PNG structure for a solid color image
    width = height = size
    
    # PNG header
    png_header = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk (image header)
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_crc = 0x90773546  # Precomputed CRC for a simple IHDR
    ihdr = b'IHDR' + ihdr_data
    
    # Simple IDAT chunk (image data) - just a solid color
    idat_data = b''
    for y in range(height):
        idat_data += b'\x00'  # Filter type: none
        for x in range(width):
            idat_data += bytes(color)  # RGB color
    
    # Compress the data
    import zlib
    compressed_idat = zlib.compress(idat_data)
    idat = b'IDAT' + compressed_idat
    
    # IEND chunk (image end)
    iend = b'IEND'
    
    # Calculate CRCs
    import binascii
    ihdr_crc = struct.pack('>I', binascii.crc32(ihdr) & 0xffffffff)
    idat_crc = struct.pack('>I', binascii.crc32(idat) & 0xffffffff)
    iend_crc = struct.pack('>I', binascii.crc32(iend) & 0xffffffff)
    
    # Build PNG
    png = png_header
    png += struct.pack('>I', len(ihdr_data)) + ihdr + ihdr_crc
    png += struct.pack('>I', len(compressed_idat)) + idat + idat_crc
    png += struct.pack('>I', 0) + iend + iend_crc
    
    with open(filename, 'wb') as f:
        f.write(png)
    print(f"Created {filename} ({size}x{size})")

if __name__ == '__main__':
    icon_dir = os.path.dirname(__file__) or '.'
    icon_dir = os.path.join(icon_dir, 'SimpleVPN')
    
    os.makedirs(icon_dir, exist_ok=True)
    
    # Create icons in required sizes
    for size in [16, 48, 128]:
        create_simple_icon(os.path.join(icon_dir, 'icon.png'), size)
