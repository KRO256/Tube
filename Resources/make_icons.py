import struct, zlib, binascii
def png(w, h, px):
    raw = b"".join(b"\x00" + bytes(c for t in px[y * w:(y + 1) * w] for c in t) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", binascii.crc32(t + d) & 0xffffffff)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
def icon(s):
    R, W = (203, 32, 39), (255, 255, 255)
    r = int(s * 0.22)
    A, B, C = (s * 0.38, s * 0.30), (s * 0.38, s * 0.70), (s * 0.72, s * 0.50)
    def tri(x, y):
        d = (B[1] - C[1]) * (A[0] - C[0]) + (C[0] - B[0]) * (A[1] - C[1])
        l1 = ((B[1] - C[1]) * (x - C[0]) + (C[0] - B[0]) * (y - C[1])) / d
        l2 = ((C[1] - A[1]) * (x - C[0]) + (A[0] - C[0]) * (y - C[1])) / d
        return l1 >= 0 and l2 >= 0 and l1 + l2 <= 1
    px = []
    for y in range(s):
        for x in range(s):
            cx, cy = min(max(x, r), s - 1 - r), min(max(y, r), s - 1 - r)
            px.append(W if (x - cx) ** 2 + (y - cy) ** 2 <= r * r and tri(x + 0.5, y + 0.5) else R)
    return png(s, s, px)
import os
d = os.path.join(os.path.dirname(os.path.abspath(__file__)))
for n, s in [("Icon-Small.png", 29), ("Icon-Small@2x.png", 58), ("Icon.png", 57), ("Icon@2x.png", 114), ("Icon-60@2x.png", 120)]:
    open(os.path.join(d, n), "wb").write(icon(s))
    print(n, s)
