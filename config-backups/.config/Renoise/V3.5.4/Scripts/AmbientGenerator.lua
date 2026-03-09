-- Ambient Generator for Renoise

local song = renoise.song()
local track_index = song.selected_track_index
local instrument_index = song.selected_instrument_index

math.randomseed(os.time())

-- SETTINGS
local pattern_length = 64
local chord_density = 0.9 
local note_length = 16 -- long notes
local root_note = 48 -- C-4
local scale = {0, 2, 3, 7, 10} -- Minor Pentatonic (safe ambient)

-- Create new pattern
local seq_index = song.selected_sequence_index + 1
song.sequencer:insert_new_pattern_at(seq_index)
local pattern = song.patterns[song.sequencer.pattern_sequence[seq_index]]
pattern.number_of_lines = pattern_length 

for line_index = 1, pattern_length, 8 do

  if math.random() < chord_density then

    local line = pattern.tracks[track_index].lines[line_index]

    -- Create 3 note chord
    for col_index = 1, 3 do
      local note_column = line.note_columns[col_index]
      
      local scale_note = scale[math.random(1, #scale)]
      local octave_shift = math.random(0, 1) * 12
      
      note_column.note_value = root_note + scale_note + octave_shift
      note_column.instrument_value = instrument_index - 1
      note_column.volume_value = math.random(50, 90)
    end

    -- Note offs
    local off_line_index = math.min(line_index + note_length, pattern_length)
    local off_line = pattern.tracks[track_index].lines[off_line_index]

    for col_index = 1, 3 do
      off_line.note_columns[col_index].note_value = 120 -- OFF
    end

  end
end

renoise.app():show_status("Ambient pattern generated.")

