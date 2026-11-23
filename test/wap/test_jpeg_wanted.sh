#!/usr/bin/env bash
# what lib/jpeg.wap does not build yet, each red line a to-do (the reader takes no if as an argument and no `not in`):
# it reads a baseline JPEG's pixels (its header names what it reads): pictures Python's PIL writes, gray and
# YCbCr at 4:4:4 and 4:2:0, red on the left half, blue on the right, read back as libjpeg reads them (PIL: #fe0000 and
# #0000fe). Run it with bash test/wap/test_jpeg_wanted.sh
source "$(dirname "$0")/compile.sh"

# a 16 × 8 JPEG, its left half red and right half blue, in a mode and subsampling PIL writes it with
written() { python3 -I -c "
from PIL import Image
picture = Image.new('RGB', (16, 8), (255, 0, 0))
picture.paste((0, 0, 255), (8, 0, 16, 8))
picture.convert('$2').save('$stage/$1.jpg', quality=100, subsampling=$3)" && echo "$stage/$1.jpg"; }
# the picture's size and its pixels at the left and the right half's middle, as the program reads them
read_back() { ran "jpeg_$1" "use jpeg
picture = jpeg_picture(read_bytes(\"$2\"))
print \"\${picture.width}x\${picture.height} \${picture.pixels[4 * 16 + 3]} \${picture.pixels[4 * 16 + 12]}\""; }

check "a YCbCr JPEG's size and colors" "$(read_back color "$(written color RGB 0)")" "16x8 #fe0000 #0000fe"
check "a JPEG sampled 4:2:0 reads each half's color" "$(read_back halved "$(written halved RGB 2)")" "16x8 #fe0000 #0000fe"
check "a gray JPEG's pixels are grays" "$(read_back gray "$(written gray L 0)")" "16x8 #4c4c4c #1d1d1d"
exit $((failures > 0))
