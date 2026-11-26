#!/usr/bin/env bash
# The drawing libraries that need a window or the GPU compile with their words called (wiki/graphics.md); compiled
# only, never run, so nothing opens. Run it with bash test/wap/test_drawing.sh
source "$(dirname "$0")/compile.sh"

# what the compiler says of a program calling a library's words, then "written" when the module is written
compiled() {
	printf '%s\n' "$2" >"$stage/$1.wap"
	$wap "$compiler" "$stage/$1.wap" "$stage/$1.wasm" 2>&1
	[ -f "$stage/$1.wasm" ] && echo written
}
check "display's words compile" "$(compiled calls_display 'use display
use units
print display.width
print (3cm * display.dpi)
print display.diagonal()')" "written"
check "frames's words compile" "$(compiled calls_frames 'use frames
on frame { print "frame" }
on exit { print "done" }
finished()')" "written"
check "gpu_passes's words compile" "$(compiled calls_gpu_passes 'use gpu_passes
blur = Pass("blur", "fn main() {}")
paint([blur], 64, 48)
print field(64, 8, 8).width')" "written"
check "pga_draw's words compile" "$(compiled calls_pga_draw 'use pga
use pga_draw
use color
use draw
canvas(200, 200)
orbit(0.3, 0.2)
zoom(40.0)
p = point(1.0, 2.0, 3.0)
sketch(p, red)
sketch(plane(0.0, 0.0, 1.0, 0.0), blue)
sketch(join(p, point(0.0, 0.0, 0.0)), green)
sketch(Sphere(p, 1.0), red)
print grade(p)')" "written"
check "splats's words compile" "$(compiled calls_splats 'use splats
scene = splats("scene.ply")
save(scene, "out.ply")
frame = splat_frame("scene.ply")
print frame.count
print #view_order(frame.centres, [0.0, 0.0, 0.0], [0.0, 0.0, 1.0], 0.1)')" "written"
exit $((failures > 0))
