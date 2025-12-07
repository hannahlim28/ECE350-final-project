import numpy as np
from PIL import Image

INPUT_IMAGE     = "star.png"
OUTPUT_MEM_FILE = "star.mem"

TARGET_SIZE     = (100, 100)  
WRITE_OUTPUT    = True

BINARY_MODE     = False
THRESHOLD       = 0.5           # used only if BINARY_MODE = True

img = Image.open(INPUT_IMAGE).convert("RGB")
img = img.resize(TARGET_SIZE, Image.NEAREST)
I = np.asarray(img, dtype=np.float32) / 255.0
gray = 0.299 * I[:, :, 0] + 0.587 * I[:, :, 1] + 0.114 * I[:, :, 2]

bw = 1.0 - gray

if BINARY_MODE:
    bw = (bw > THRESHOLD).astype(np.float32)

I = np.stack([bw, bw, bw], axis=2)


im = np.floor(I * 255 / 64).astype(np.uint8)  # each channel 0–3

def print2bits(x: int) -> str:
    if x == 0:
        return "00"
    elif x == 1:
        return "01"
    elif x == 2:
        return "10"
    elif x == 3:
        return "11"
    else:
        return "ERROR"


if WRITE_OUTPUT:
    print("Writing output file:", OUTPUT_MEM_FILE)

    rows, cols, _ = im.shape
    print(f"MEM image size: {cols} x {rows} pixels")

    with open(OUTPUT_MEM_FILE, "w") as fid:
        for row in range(rows):
            for col in range(cols):
                # Use the red channel (they're all the same)
                r = int(im[row, col, 0])
                fid.write(f"{print2bits(r)} ")
            fid.write("\n")

    print("Done.")
