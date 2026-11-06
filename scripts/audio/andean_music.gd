extends RefCounted

## Original loops with a pentatonic melody, plucked strings and soft percussion.
const RATE := 22050
const MELODIES := [
	[69, 72, 74, 76, 74, 72, 69, 67, 64, 67, 69, 72, 74, 72, 69, 69],
	[76, 79, 81, 79, 76, 74, 72, 74, 76, 74, 72, 69, 72, 74, 72, 69],
]
const ROOTS := [45, 43, 48, 45]

static func make_track(track: int) -> AudioStreamWAV:
	var melody: Array = MELODIES[track]
	var beat := 0.51 if track == 0 else 0.59
	var beat_samples := roundi(beat * RATE)
	var data := PackedByteArray()
	data.resize(beat_samples * melody.size() * 2)
	for note_index in melody.size():
		var flute := _frequency(melody[note_index])
		var root := _frequency(ROOTS[floori(note_index / 4.0)])
		var string_pitch := root * (2.0 if note_index % 2 == 0 else 3.0)
		for frame in beat_samples:
			var t := float(frame) / RATE
			var phrase := sin(PI * t / beat)
			var phase := TAU * flute * t + 0.12 * sin(TAU * 4.8 * t)
			var wind := (sin(phase) + 0.16 * sin(phase * 2.0)) * phrase * 0.30
			var pluck := (sin(TAU * string_pitch * t) + 0.23 * sin(TAU * string_pitch * 2.0 * t)) * exp(-12.0 * t) * 0.16
			var drum := sin(TAU * 80.0 * t) * exp(-28.0 * t) * (0.14 if note_index % 2 == 0 else 0.05)
			var edge := minf(1.0, minf(t, beat - t) * 180.0)
			data.encode_s16((note_index * beat_samples + frame) * 2, int((wind + pluck + drum) * edge * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = beat_samples * melody.size()
	return stream

static func _frequency(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)
