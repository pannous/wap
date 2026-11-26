#!/usr/bin/env bash
# The sound words that play compile, beep to the MIDI words, each typed with the host words under it (wiki/sound.md).
# Compiled only, never run, so nothing sounds. Run it with bash test/wap/test_sound.sh
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
exit $((failures > 0))
