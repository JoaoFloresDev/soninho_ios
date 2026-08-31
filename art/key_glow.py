"""Keys a Gemini hero rendered on black into a transparent PNG.

The art carries a baked halo, so a hard cut leaves a dark ring against the app's
background. Alpha is taken from luminance instead: the lit blob stays opaque and
the glow fades out exactly as bright as it is, which is what makes it blend.
"""
import sys
from PIL import Image

INNER, BLEND, OUTER = 0.48, 0.62, 1.02   # radius stops, normalised to the inscribed circle
GAIN = 1.45                              # how strongly luminance drives the outer alpha


def key(src_path, out_path, size=1024):
    im = Image.open(src_path).convert("RGB")
    if im.size != (size, size):
        side = min(im.size)
        left = (im.width - side) // 2
        top = (im.height - side) // 2
        im = im.crop((left, top, left + side, top + side)).resize((size, size), Image.LANCZOS)

    px = im.load()
    out = Image.new("RGBA", (size, size))
    op = out.load()
    half = size / 2

    for y in range(size):
        dy = (y - half) / half
        for x in range(size):
            r, g, b = px[x, y]
            dx = (x - half) / half
            radius = (dx * dx + dy * dy) ** 0.5

            if radius >= OUTER:
                alpha = 0
            else:
                luma = max(r, g, b)
                glow = min(255, int(luma * GAIN))
                if radius <= INNER:
                    alpha = 255
                elif radius >= BLEND:
                    alpha = glow
                else:
                    t = (radius - INNER) / (BLEND - INNER)
                    alpha = int(255 * (1 - t) + glow * t)
            op[x, y] = (r, g, b, alpha)

    out.save(out_path, "PNG")
    return out


if __name__ == "__main__":
    key(sys.argv[1], sys.argv[2])
    print("keyed ->", sys.argv[2])
