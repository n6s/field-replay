local mp = require 'mp'

local buffer_seconds = 2

local function live_minus()
    local dur = mp.get_property_number("duration")
    if not dur or dur <= 0 then
        mp.osd_message("No usable duration yet")
        return
    end

    local target = dur - buffer_seconds
    if target < 0 then
        target = 0
    end

    mp.commandv("seek", tostring(target), "absolute", "exact")
    mp.osd_message(string.format("Live-%ds", buffer_seconds))
end

mp.register_script_message("live-minus", live_minus)
