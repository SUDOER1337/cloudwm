-- Breakbeat Auto Arrange + Mutate
-- Requires: Instrument 00 with sliced sample

local song = renoise.song()
local instrument_index = 1 -- Renoise is 1-based
local instrument = song.instruments[instrument_index]

if not instrument or #instrument.samples == 0 then
  renoise.app():show_status("Instrument 00 has no samples.")
  return
end

local sample = instrument.samples[1]
local num_slices = #sample.slice_markers

if num_slices == 0 then
  renoise.app():show_status("Sample is not sliced.")
  return
end
 
math.randomseed(os.time())

local track_index = song.selected_track_index
local pattern_length = num_slices

-- Create two new patterns
local pattern_index_original = song.sequencer:insert_new_pattern_at(song.selected_sequence_index + 1) 
local pattern_index_mutated = song.sequencer:insert_new_pattern_at(song.selected_sequence_index + 2)

local pattern_original = song.patterns[song.sequencer.pattern_sequence[pattern_index_original]]
local pattern_mutated = song.patterns[song.sequencer.pattern_sequence[pattern_index_mutated]]

pattern_original.number_of_lines = pattern_length
pattern_mutated.number_of_lines = pattern_length

-- Fill ORIGINAL pattern (ordered slices)
for i = 1, num_slices do
  local line = pattern_original.tracks[track_index].lines[i]
  local col = line.note_columns[1]

  col.note_value = 36 + (i - 1) -- Each slice maps chromatically
  col.instrument_value = instrument_index - 1
  col.volume_value = 80
end

-- Fill MUTATED pattern (random slice order)
for i = 1, num_slices do
  local line = pattern_mutated.tracks[track_index].lines[i]
  local col = line.note_columns[1]

  local random_slice = math.random(0, num_slices - 1)

  col.note_value = 36 + random_slice
  col.instrument_value = instrument_index - 1
  col.volume_value = math.random(60, 110)

  -- 20% chance to retrigger effect
  if math.random() < 0.2 then
    col.effect_number_string = "0R"
    col.effect_amount_value = math.random(2, 8)
  end
end

renoise.app():show_status("Breakbeat arranged + mutated.")

