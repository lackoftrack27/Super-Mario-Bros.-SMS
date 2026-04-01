#!/usr/bin/env python3
"""
MIDI to Note Sequence Converter
Outputs note/rest sequences for MIDI channels 11-14 in the format:
  nD4, $10, nRst, $08, $10
  (note, duration_hex, rest, rest_duration_hex, next_note_duration_hex, ...)
"""

import struct
import sys
import os
from collections import defaultdict


# ---------------------------------------------------------------------------
# MIDI note number → name (e.g. 60 → "C4")
# ---------------------------------------------------------------------------
NOTE_NAMES = ['C', 'Cs', 'D', 'Eb', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'Bb', 'B']

def note_number_to_name(n):
    """Convert MIDI note number to name like nC4, nEb3, etc."""
    octave = (n // 12) - 1 - 2
    name = NOTE_NAMES[n % 12]
    return f"n{name}{octave}"

RST_BYTE = "nRst"


# ---------------------------------------------------------------------------
# Variable-length quantity (VLQ) reader used in MIDI
# ---------------------------------------------------------------------------
def read_vlq(data, pos):
    value = 0
    while True:
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 0x7F)
        if not (byte & 0x80):
            break
    return value, pos


# ---------------------------------------------------------------------------
# Raw MIDI parser (no external libs)
# ---------------------------------------------------------------------------
def parse_midi(filepath):
    """
    Returns:
        ticks_per_beat (int)
        tracks: list of lists of (absolute_tick, channel, type, note, velocity)
                type is 'note_on' or 'note_off'
    """
    with open(filepath, 'rb') as f:
        data = f.read()

    pos = 0

    # --- Header chunk ---
    if data[pos:pos+4] != b'MThd':
        raise ValueError("Not a valid MIDI file (missing MThd)")
    pos += 4
    header_len = struct.unpack('>I', data[pos:pos+4])[0]
    pos += 4
    fmt       = struct.unpack('>H', data[pos:pos+2])[0]
    num_tracks= struct.unpack('>H', data[pos+2:pos+4])[0]
    tpb       = struct.unpack('>H', data[pos+4:pos+6])[0]
    pos += header_len

    tracks = []

    # --- Track chunks ---
    for _ in range(num_tracks):
        if pos >= len(data):
            break
        if data[pos:pos+4] != b'MTrk':
            # skip unknown chunk
            pos += 4
            chunk_len = struct.unpack('>I', data[pos:pos+4])[0]
            pos += 4 + chunk_len
            continue
        pos += 4
        track_len = struct.unpack('>I', data[pos:pos+4])[0]
        pos += 4
        track_end = pos + track_len

        events = []
        abs_tick = 0
        running_status = None

        while pos < track_end:
            # delta time
            delta, pos = read_vlq(data, pos)
            abs_tick += delta

            # status byte
            byte = data[pos]

            if byte & 0x80:
                status = byte
                pos += 1
                running_status = status
            else:
                status = running_status  # running status

            msg_type = (status & 0xF0) >> 4
            channel  = (status & 0x0F)  # 0-indexed

            if msg_type == 0x9:  # note_on
                note = data[pos]; vel = data[pos+1]; pos += 2
                if vel == 0:
                    events.append((abs_tick, channel, 'note_off', note, 0))
                else:
                    events.append((abs_tick, channel, 'note_on', note, vel))

            elif msg_type == 0x8:  # note_off
                note = data[pos]; vel = data[pos+1]; pos += 2
                events.append((abs_tick, channel, 'note_off', note, vel))

            elif msg_type == 0xA:  # aftertouch
                pos += 2
            elif msg_type == 0xB:  # control change
                ctrl = data[pos]; val = data[pos+1]; pos += 2
                if ctrl == 64:  # CC64 sustain pedal
                    events.append((abs_tick, channel, 'cc64', ctrl, val))
            elif msg_type == 0xC:  # program change
                pos += 1
            elif msg_type == 0xD:  # channel pressure
                pos += 1
            elif msg_type == 0xE:  # pitch bend
                pos += 2
            elif msg_type == 0xF:  # sysex / meta
                if status == 0xFF:  # meta event
                    meta_type = data[pos]; pos += 1
                    meta_len, pos = read_vlq(data, pos)
                    pos += meta_len
                elif status == 0xF0 or status == 0xF7:  # sysex
                    sysex_len, pos = read_vlq(data, pos)
                    pos += sysex_len
                else:
                    pos += 1  # unknown, skip
            else:
                pos += 1  # skip unknown

        tracks.append(events)

    return tpb, tracks


# ---------------------------------------------------------------------------
# Build per-channel event timeline
# ---------------------------------------------------------------------------
def build_channel_timeline(tracks, target_channels_1indexed):
    """
    Merge all tracks, keep only target channels (1-indexed, e.g. 11-14).
    Returns dict: channel_0idx → sorted list of (abs_tick, type, note, vel)
    """
    # Convert to 0-indexed
    target_0 = {ch - 1 for ch in target_channels_1indexed}

    channel_events = defaultdict(list)
    for track in tracks:
        for (tick, ch, etype, note, vel) in track:
            if ch in target_0:
                channel_events[ch].append((tick, etype, note, vel))

    for ch in channel_events:
        channel_events[ch].sort(key=lambda e: e[0])

    return channel_events


# ---------------------------------------------------------------------------
# Convert channel events → list of (note_name_or_rest, duration_ticks)
# ---------------------------------------------------------------------------
def events_to_sequence(events):
    """
    Given sorted (tick, type, note, vel) events for one channel,
    produce a list of ('nXY' or 'nRst', duration_in_ticks).

    CC64 sustain pedal handling:
      While the pedal is held (CC64 >= 64), note_off events are ignored
      entirely. A note's duration stretches until the next note_on for that
      same pitch arrives (which implicitly closes the previous one), or until
      the end of the track. Pedal release has no effect on open notes.
    """
    if not events:
        return []

    active = {}        # note → start_tick
    notes = []         # (start_tick, end_tick, note)
    pedal_down = False

    for (tick, etype, note, vel) in events:
        if etype == 'cc64':
            pedal_down = (vel >= 64)

        elif etype == 'note_on':
            if pedal_down:
                # Pedal held: any new note_on closes ALL currently active
                # pedal-sustained notes (monophonic sustain behaviour)
                for held_note, start in list(active.items()):
                    notes.append((start, tick, held_note))
                active.clear()
            elif note in active:
                # No pedal: only close the same pitch if retriggered
                notes.append((active.pop(note), tick, note))
            active[note] = tick

        elif etype == 'note_off':
            if pedal_down:
                pass  # pedal held — ignore note_off completely
            elif note in active:
                notes.append((active.pop(note), tick, note))

    # Close anything still open at the last event tick
    last_tick = events[-1][0]
    for note, start in active.items():
        notes.append((start, last_tick, note))

    if not notes:
        return []

    notes.sort(key=lambda x: x[0])

    sequence = []
    cursor = 0  # start from tick 0 so leading rests are captured

    for (start, end, note) in notes:
        # Rest before this note?
        if start > cursor:
            sequence.append((RST_BYTE, start - cursor))
        note_dur = end - start
        if note_dur > 0:
            sequence.append((note_number_to_name(note), note_dur))
        cursor = end

    return sequence


# ---------------------------------------------------------------------------
# Format sequence as the target string
# ---------------------------------------------------------------------------
def format_sequence(sequence, ticks_per_beat, quantize=True):
    """
    Format list of (name, ticks) into the output string.
    Durations are expressed as hex values prefixed with $.
    
    If quantize=True, durations are rounded to nearest common note value
    (in ticks) for cleaner output.
    """
    if not sequence:
        return "(empty)"

    def split_duration(ticks):
        """
        Split a duration into bytes each <= $7F (127).
        e.g. 200 ticks → [$7F, $49]  (127 + 73 = 200)
        """
        chunks = []
        while ticks > 0x7F:
            chunks.append("$7F")
            ticks -= 0x7F
        if ticks > 0:
            chunks.append(f"${ticks:02X}")
        return chunks

    # --- Pass 1: build full byte stream, omitting repeated note bytes only ---
    parts = []
    last_note = None
    for note_byte, ticks in sequence:
        # Omit note byte if same pitch as previous (not for rests).
        if note_byte == last_note and note_byte != RST_BYTE:
            pass
        else:
            parts.append(note_byte)
            last_note = note_byte
        parts.extend(split_duration(ticks))

    # --- Pass 2: remove redundant duration bytes ---
    # A duration byte at index i is redundant if:
    #   - the byte before it is a note byte (>= $80) — player peeks after note
    #   - the byte after it is also a note byte (>= $80) — player sets SetDur=false
    #   - it equals the most recently established duration
    # When the next byte is a duration, the player consumes it as the current
    # note's duration rather than treating it as a separate play — so we must
    # keep it in that case.
    def is_note_byte(s):
        return s.startswith('n')  # note names start with 'n' (nC4, nRst, etc.)

    optimized = []
    last_dur = None
    i = 0
    while i < len(parts):
        byte = parts[i]
        if (not is_note_byte(byte) and          # it's a duration byte
                last_dur is not None and         # we have a prior duration
                byte == last_dur and             # it matches — candidate to omit
                i > 0 and is_note_byte(parts[i - 1]) and   # preceded by note byte
                (i + 1 >= len(parts) or is_note_byte(parts[i + 1]))):  # followed by note or end of stream
            pass  # omit this redundant duration byte
        else:
            optimized.append(byte)
            if not is_note_byte(byte):
                last_dur = byte
        i += 1
    parts = optimized

    # Format as .db lines with 16 values per line
    lines = []
    for i in range(0, len(parts), 16):
        chunk = parts[i:i+16]
        lines.append(".db " + ", ".join(chunk))

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def midi_to_note_sequences(filepath, channels=(11, 12, 13, 14), output_file=None):
    tpb, tracks = parse_midi(filepath)

    lines = []
    lines.append(f"File       : {os.path.basename(filepath)}")
    lines.append(f"Ticks/beat : {tpb}")
    lines.append(f"Tracks     : {len(tracks)}")
    lines.append(f"Channels   : {list(channels)}")
    lines.append("")

    channel_events = build_channel_timeline(tracks, channels)

    results = {}
    for ch_1idx in sorted(channels):
        ch_0idx = ch_1idx - 1
        events = channel_events.get(ch_0idx, [])
        seq = events_to_sequence(events)
        formatted = format_sequence(seq, tpb)
        results[ch_1idx] = formatted

        lines.append(f"--- Channel {ch_1idx} ---")
        lines.append(formatted if seq else "(no events)")
        lines.append("")

    output = "\n".join(lines)
    print(output)

    if output_file:
        with open(output_file, 'w') as f:
            f.write(output)
        print(f"Output written to: {output_file}")

    return results


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python midi_to_notes.py <file.mid> [-o output.txt] [ch1 ch2 ...]")
        print("Default channels: 11 12 13 14")
        print()
        print("Options:")
        print("  -o <file>   Write output to a file (default: <midi_name>_notes.txt)")
        print()
        print("Output format example:")
        print("  nD4, $10, nRst, $08, $10")
        sys.exit(0)

    args = sys.argv[1:]
    midi_path = args[0]

    if not os.path.isfile(midi_path):
        print(f"Error: file not found: {midi_path}")
        sys.exit(1)

    remaining = args[1:]
    output_file = None
    channel_args = []

    i = 0
    while i < len(remaining):
        if remaining[i] == '-o':
            if i + 1 >= len(remaining):
                print("Error: -o requires a filename")
                sys.exit(1)
            output_file = remaining[i + 1]
            i += 2
        else:
            channel_args.append(remaining[i])
            i += 1

    if channel_args:
        try:
            channels = tuple(int(x) for x in channel_args)
        except ValueError:
            print("Error: channel numbers must be integers")
            sys.exit(1)
    else:
        channels = (11, 12, 13, 14)

    if output_file is None:
        base = os.path.splitext(midi_path)[0]
        output_file = base + "_notes.txt"

    midi_to_note_sequences(midi_path, channels, output_file)