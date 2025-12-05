import numpy as np
from PIL import Image

TARGET_SIZE = (500, 500)   # (width, height)

img = Image.open("mountian.png").convert("RGB")
img = img.resize(TARGET_SIZE, Image.BICUBIC)   # resize 

I = np.asarray(img, dtype=np.float32) / 255.0   
gray = 0.299 * I[:, :, 0] + 0.587 * I[:, :, 1] + 0.114 * I[:, :, 2]

bw = 1.0 - gray
I = np.stack([bw, bw, bw], axis=2)

write_output_file = 1

if write_output_file == 1:
    fid = open("mountian.mem", "w")

# create image with only RED content
R_orig = I.copy()
R_orig[:, :, 1] = 0
R_orig[:, :, 2] = 0


# Reduce to 6 bits/pixel, 2 for each color
R_64 = np.floor(R_orig * 255 / 64).astype(np.uint8)

I_64 = np.floor(I * 255 / 64).astype(np.uint8)

im = I_64

def print2bits(x):
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

if write_output_file == 1:
    print("Writing output file.")

    rows, cols, _ = im.shape
    # sanity check: should be 200 x 200
    print(f"MEM image size: {cols} x {rows} pixels")

    for row in range(rows):
        for col in range(cols):
            r = int(im[row, col, 0])
            fid.write(f"{print2bits(r)} ")

        fid.write("\n")
    fid.close()
    print("Done")
