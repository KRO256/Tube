import struct, zlib, binascii, os
def png(w, h, fn):
    raw = b"".join(b"\x00" + b"".join(fn(x, y) for x in range(w)) for y in range(h))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", binascii.crc32(t + d) & 0xffffffff)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 0, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
R, W, B = 203, 255, 20
def launch(w, h):
    s = min(w, h) // 3
    ox, oy = (w - s) // 2, (h - s) // 2
    r = int(s * 0.22)
    A, Bc, C = (0.38, 0.30), (0.38, 0.70), (0.72, 0.50)
    def tri(fx, fy):
        d = (Bc[1] - C[1]) * (A[0] - C[0]) + (C[0] - Bc[0]) * (A[1] - C[1])
        l1 = ((Bc[1] - C[1]) * (fx - C[0]) + (C[0] - Bc[0]) * (fy - C[1])) / d
        l2 = ((C[1] - A[1]) * (fx - C[0]) + (A[0] - C[0]) * (fy - C[1])) / d
        return l1 >= 0 and l2 >= 0 and l1 + l2 <= 1
    def row(x, y):
        if ox <= x < ox + s and oy <= y < oy + s:
            lx, ly = x - ox, y - oy
            cx, cy = min(max(lx, r), s - 1 - r), min(max(ly, r), s - 1 - r)
            if (lx - cx) ** 2 + (ly - cy) ** 2 <= r * r:
                return bytes([W if tri((lx + 0.5) / s, (ly + 0.5) / s) else R])
        return bytes([B])
    return png(w, h, row)
d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Resources")
for n, w, h in [("Default.png", 320, 480), ("Default@2x.png", 640, 960), ("Default-568h@2x.png", 640, 1136),
                ("Default-667h@2x.png", 750, 1334), ("Default-736h@3x.png", 1242, 2208)]:
    open(os.path.join(d, n), "wb").write(launch(w, h))
    print(n, w, h)
