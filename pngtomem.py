import numpy as np
from PIL import Image

# ------------------------------------------------------------------------------
# sprite_strip_to_mem -- converts images to .mem file for FPGAs
# Direct translation of your Matlab script, except forced to black/white.
# ------------------------------------------------------------------------------

# read in image
I = Image.open(r"plant.png").convert("RGB")
I = np.asarray(I, dtype=np.float32) / 255.0   # im2double equivalent

# ---- FORCE BLACK & WHITE (only change vs Matlab) ----
# grayscale
gray = 0.299 * I[:, :, 0] + 0.587 * I[:, :, 1] + 0.114 * I[:, :, 2]

# threshold to pure B/W (0 or 1)
bw = 1.0 - gray        # black=1, white=0, gray stays ~0.5
I = np.stack([bw, bw, bw], axis=2)

# replicate into 3 channels so rest of script is identical
I = np.stack([bw, bw, bw], axis=2)
# -----------------------------------------------------

# 1/0 for whether to write output .mem file
write_output_file = 1

# output filename
if write_output_file == 1:
    fid = open("plant.mem", "w")

# create image with only RED content
R_orig = I.copy()
R_orig[:, :, 1] = 0
R_orig[:, :, 2] = 0

# create image with only GREEN content
G_orig = I.copy()
G_orig[:, :, 0] = 0
G_orig[:, :, 2] = 0

# create image with only BLUE content
B_orig = I.copy()
B_orig[:, :, 0] = 0
B_orig[:, :, 1] = 0

# Reduce to 6 bits/pixel, 2 for each color
R_64 = np.floor(R_orig * 255 / 64).astype(np.uint8)
G_64 = np.floor(G_orig * 255 / 64).astype(np.uint8)
B_64 = np.floor(B_orig * 255 / 64).astype(np.uint8)

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

    for row in range(rows):
        for col in range(cols):
            r = int(im[row, col, 0])
            g = int(im[row, col, 1])
            b = int(im[row, col, 2])

            fid.write(
                f"{print2bits(r)}{print2bits(g)}{print2bits(b)} "
            )

        fid.write("\n")

    fid.close()
    print("Done.")
