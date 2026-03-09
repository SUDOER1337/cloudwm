-- Random Pattern Mutator for Renoise
-- Randomizes notes, instruments, and velocities in selected pattern

local song = renoise.song()
local pattern = song.selected_pattern
local track_index = song.selected_track_index

if not pattern then
  renoise.app():show_status("No pattern selected.")
  return
end

math.randomseed(os.time())

for _, pattern_track in ipairs(pattern.tracks) do
  local lines = pattern_track.lines

  for line_index, line in ipairs(lines) do
    for note_column_index = 1, #line.note_columns do
      local note_column = line.note_columns[note_column_index]

      if not note_column.is_empty then

        -- Random pitch between C-3 and C-5
        local random_note = math.random(36, 60)
        note_column.note_value = random_note

        -- Random instrument (0-7)
        note_column.instrument_value = math.random(0, 7)

        -- Velocity randomization (40-100)
        note_column.volume_value = math.random(40, 100)

        -- 10% chance to insert note-off
        if math.random() < 0.1 then
          note_column.note_value = 120 -- Note-Off
        end

      end
    end
  end
end

renoise.app():show_status("Pattern mutated.")
 
