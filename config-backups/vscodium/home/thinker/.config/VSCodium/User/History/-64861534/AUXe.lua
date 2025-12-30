-- Importing libraries
gears = require('gears')
awful = require('awful')
wibox = require('wibox')
naughty = require("naughty")
beautiful = require('beautiful')
dpi = beautiful.xresources.apply_dpi

beautiful.init('~/.config/awesome/theme/init.lua')
keys = require('keys')
help = require('help')
dashboard = require("dashboard")
sig = require('signals')
menu = require('menu')

local req = {
  'notif',
  'bar',
  'rule',
  'music',
  'client',
  'awful.autofocus',
}

for _, x in pairs(req) do
  require(x)
end

local function set_wallpaper(s)
  if beautiful.wall then
    local wall = beautiful.wall
    if type(wall) == "function" then
      wall = wall(s)
    end
    gears.wallpaper.maximized(wall, s, true)
  end
end

screen.connect_signal("property::geometry", set_wallpaper)

-- Layouts
awful.layout.layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.floating,
}

-- Virtual desktops/ Tabs
awful.screen.connect_for_each_screen(function(s)
  set_wallpaper(s)
  local tagTable = {}
  for i = 1, keys.tags do
    table.insert(tagTable, tostring(i))
  end
  awful.tag(tagTable, s, awful.layout.layouts[1])
end)

-- Center windows automatically
client.connect_signal("manage", function (c)
    -- If the window doesn't have a set position, center it
    if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.centered(c, nil)
    end
end)


client.connect_signal("manage", function(c)
    -- Only apply this logic if the client is starting and is not set to floating=false by rules
    if awesome.startup then return end
    if c.floating or awful.layout.get(c.screen) == awful.layout.suit.floating then
        local coords = mouse.coords()
        local width = math.floor(c.screen.workarea.width * 0.5)
        local height = math.floor(c.screen.workarea.height * 0.5)
        c:geometry({
            x = coords.x - width / 2,
            y = coords.y - height / 2,
            width = width,
            height = height
        })
    end
end)

-- Hook into tag switch
tag.connect_signal("property::selected", function(t)
    slide_clients_vertically(50) -- move down 50px
    gears.timer.start_new(0.05, function()
        slide_clients_vertically(-50) -- slide back up
    end)
end)

-- Autostart
awful.spawn.with_shell("xrandr -r 120")
awful.spawn.with_shell('redshift -x && redshift -O 3800K')
awful.spawn.with_shell('killall flameshot; flameshot')
awful.spawn.with_shell('killall xsettingsd; xsettingsd &')
awful.spawn.with_shell('killall mpDris2; mpDris2 &')
awful.spawn.with_shell('mpd &')
awful.spawn.with_shell('picom')

-- Garbage Collection
collectgarbage('setpause', 110)
collectgarbage('setstepmul', 1000)
