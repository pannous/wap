#!/usr/bin/env bash
# lib/png.wap reads a PNG's pixels and writes pictures as PNGs (its header names what it reads): pictures Python's PIL
# writes in each color type, red on the left half and blue on the right, and a PNG png writes, read back by PIL. Run it
# with bash test/wap/test_png.sh
source "$(dirname "$0")/compile.sh"

# a 16 × 8 PNG, its left half red and right half half-transparent blue, in a mode PIL writes it in
written() { python3 -I -c "
from PIL import Image
picture = Image.new('RGBA', (16, 8), (255, 0, 0, 255))
picture.paste((0, 0, 255, 128), (8, 0, 16, 8))
picture.convert('$2').save('$stage/$1.png')" && echo "$stage/$1.png"; }
# the picture's size and its pixels at the left and the right half's middle, as the program reads them
read_back() { ran "png_$1" "use png
use color
picture = png_picture(read_bytes(\"$2\"))
print \"\${picture.width}x\${picture.height} \${picture.pixels[4 * 16 + 3]} \${picture.pixels[4 * 16 + 12]}\""; }

check "an RGB PNG's size and colors" "$(read_back rgb "$(written rgb RGB)")" "16x8 red blue"
check "an RGBA PNG keeps its alpha" "$(read_back rgba "$(written rgba RGBA)")" "16x8 red #0000ff80"
check "a palette PNG keeps its transparency" "$(read_back palette "$(written palette P)")" "16x8 red #0000ff80"
check "a gray PNG's pixels are grays" "$(read_back gray "$(written gray L)")" "16x8 #4c4c4c #1d1d1d"
check "a gray PNG with alpha" "$(read_back gray_alpha "$(written gray_alpha LA)")" "16x8 #4c4c4c #1d1d1d80"
check "a 1-bit PNG's pixels are black and white" "$(read_back bit "$(written bit 1)")" "16x8 black black"
check "a picture written as a PNG reads back in PIL" "$(ran png_written "use png
use color
write_bytes(\"$stage/written.png\", png_bytes(Picture(2, 1, [red, with_alpha(blue, 0.5)])))" && python3 -I -c "
from PIL import Image
print(list(Image.open('$stage/written.png').getdata()))")" "[(255, 0, 0, 255), (0, 0, 255, 128)]"
exit $((failures > 0))
