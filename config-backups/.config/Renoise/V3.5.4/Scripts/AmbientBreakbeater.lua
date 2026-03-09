-- Atmospheric DnB Filler Generator

local song = renoise.song()
math.randomseed(os.time())

local seq_index = song.selected_sequence_index + 1
song.sequencer:insert_new_pattern_at(seq_index)
local pattern = song.patterns[song.sequencer.pattern_sequence[seq_index]]
pattern.number_of_lines = 64

--------------------------------------------------
-- BREAKBEAT RANDOMIZER (Track 1)
--------------------------------------------------

local break_track = pattern.tracks[1]
local break_inst = 1
local slice_count = #song.instruments[break_inst].samples[1].slice_markers

for line = 1, 64 do
  if math.random() < 0.6 then
    local col = break_track.lines[line].note_columns[1]
    local slice = math.random(0, slice_count - 1)
    col.note_value = 36 + slice
    col.instrument_value = break_inst - 1
    col.volume_value = math.random(70, 120)

    -- 20% retrigger glitch
    if math.random() < 0.2 then
      col.effect_number_string = "0R"
      col.effect_amount_value = math.random(2,6)
    end
  end
end

--------------------------------------------------
-- ATMOSPHERIC PAD (Track 2)
--------------------------------------------------

local pad_track = pattern.tracks[2]
local pad_inst = 2

for line = 1, 64, 16 do
  local col = pad_track.lines[line].note_columns[1]
  col.note_value = 48 + math.random(0,12)
  col.instrument_value = pad_inst - 1
  col.volume_value = 60

  -- note off
  local off_line = math.min(line + 12, 64)
  pad_track.lines[off_line].note_columns[1].note_value = 120
end

--------------------------------------------------
-- WOBBLE BASS (Track 3)
--------------------------------------------------

local bass_track = pattern.tracks[3]
local bass_inst = 3

-- Root note
bass_track.lines[1].note_columns[1].note_value = 36
bass_track.lines[1].note_columns[1].instrument_value = bass_inst - 1
bass_track.lines[1].note_columns[1].volume_value = 100

-- Note off at end
bass_track.lines[64].note_columns[1].note_value = 120

-- Automation wobble (Device 1, Parameter 1 assumed filter cutoff)
local device = song.tracks[3].devices[2] -- usually first VST after mixer
local param = device.parameters[1]

local automation = song.patterns[song.sequencer.pattern_sequence[seq_index]]
  :track(3)
  :create_automation(param)

for line = 1, 64 do
  if line % 4 == 0 then
    automation:add_point_at(line-1, math.random())
  end
end

renoise.app():show_status("Atmospheric DnB filler generated.")
 
