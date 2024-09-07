local previous_brightness
local brightness_raised = false
local file_loaded = false

-- Function to get current brightness
local function get_current_brightness()
    local handle = io.popen([[powershell.exe -WindowStyle Hidden -Command "(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightness).CurrentBrightness"]])
    local result = handle:read("*a")
    handle:close()
    return tonumber(result:match("%d+"))
end

-- Function to set brightness
local function set_brightness(level)
    os.execute(string.format([[powershell.exe -WindowStyle Hidden -Command "Start-Process powershell -ArgumentList '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,%d)' -WindowStyle Hidden"]], level))
end

-- Store the current brightness when MPV starts
mp.register_event("start-file", function()
    file_loaded = true
    if not brightness_raised then
        -- Store the current brightness
        -- previous_brightness = get_current_brightness() or 70
        previous_brightness = get_current_brightness()
        set_brightness(100)
        brightness_raised = true
    end
end)

-- Restore the previous brightness when MPV quits
mp.register_event("shutdown", function()
    if previous_brightness then
        set_brightness(previous_brightness)
        brightness_raised = false
    end
end)

-- Function to check focus and adjust brightness
local function check_focus()
    if file_loaded then
        if mp.get_property_native('focused') then
            -- MPV is focused; raise brightness
            if not brightness_raised then
                set_brightness(100)
                brightness_raised = true
            end
        else
            -- MPV is not focused; restore previous brightness
            if brightness_raised then
                set_brightness(previous_brightness)
                brightness_raised = false
            end
        end
    end
end

-- Set a timer to check focus periodically

-- mp.add_periodic_timer(0.5, check_focus)
-- this causes mpv to crash after skipping through a few files in playlist. stutter might also be increased.
