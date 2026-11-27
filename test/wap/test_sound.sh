#!/usr/bin/env bash
# The sound words that play compile, beep to the MIDI words, each typed with the host words under it (wiki/sound.md).
# Compiled, then run muted (wiki/sound.md "muted"): nothing sounds and nothing waits, and what played is still
# rendered, saved and read back. Run it with bash test/wap/test_sound.sh
source "$(dirname "$0")/compile.sh"

# a program of every playing word, compiled: the compiler says nothing and the module is written
printf '%s\n' 'use sound' 'use units' \
	'beep()' \
	'play(440Hz, 0.5s)' \
	'play(C4)' \
	'play([C4, D4, E4], 200ms)' \
	'tone(220Hz, 300ms, "square")' \
	'melody([C4, E4], each: 100ms)' \
	'play("c3 ~ [c3 c3] <~ c3?>")' \
	'chord_sound = play(C4 + E4 + G4, 1s)' \
	'fade(chord_sound, 0.0, 500ms)' \
	'fade(sound(), 0.0, 2)' \
	'stop(sound())' \
	'room = delay(bus(), 0.3, 0.5, 1.0)' \
	'print #room.chain' \
	'out(osc(A4, 0.1s), room)' \
	'play(C4, 1s, bus: room)' \
	'siren(t: float): float := 0.3 * sin(2.0 * pi * 440.0 * t)' \
	'play(siren, 4s)' \
	'stereo(left: list<float>, right: list<float>, t: float) := { left[0] = 0.1; right[0] = 0.1 }' \
	'play(stereo, 3s)' \
	'at 2.0 { play(C4) }' \
	'rest(1s)' \
	'wait(sound())' \
	'save(sound(), "song.wav")' \
	'kick = sample("kick.wav")' \
	'play(kick, 2.0)' \
	'loop = sample_looped(kick, 4s, 0.5s, 1s)' \
	'midi_on(C4)' \
	'midi_off(C4)' \
	'midi_note(C4, 0.5)' \
	'print midi_outputs()' \
	>"$stage/playing.wap"
check "every playing word compiles" "$($wap "$compiler" "$stage/playing.wap" "$stage/playing.wasm" 2>&1; [ -f "$stage/playing.wasm" ] && echo written)" "written"
# muted runs of the native wap: a tone played is rendered all the same, so a saved file holds its samples
muted() { printf '%s\n' "$2" >"$stage/$1.wap" && (cd "$stage" && $wap --mute --no-window "$1.wap" 2>&1); }
check "a tone played muted is saved: half a second at 22050 Hz, mono, 16-bit" "$(muted saving 'use sound
use units
play(440Hz, 0.5s)
save(sound(), "tone.wav")' >/dev/null; wc -c <"$stage/tone.wav" | tr -d ' ')" "22094"
check "a saved sound reads back as a sample of its rate, channels and frames" "$(muted reading 'use sound
tone = sample("tone.wav")
print "${tone.rate} ${tone.channels} ${#tone.frames}"')" "22050 1 11025"
check "the MIDI outputs are listed, none sounding" "$(muted ports 'use sound
print #midi_outputs() >= 0')" "yes"
check "--muted is --mute, said" "$(cd "$stage" && $wap --muted --no-window ports.wap 2>&1)" "got it: --muted is --mute
yes"
exit $((failures > 0))
