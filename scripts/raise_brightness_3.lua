local previous_brightness
local brightness_raised = false

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
    if not brightness_raised then
        -- Store the current brightness
        -- previous_brightness = get_current_brightness() or 70
        previous_brightness = get_current_brightness()

        -- Set the brightness to 100
        set_brightness(100)
        brightness_raised = true  -- Set the flag to true after raising brightness
    end
end)

-- Restore the previous brightness when MPV quits
mp.register_event("shutdown", function()
    if previous_brightness then
        set_brightness(previous_brightness)
        brightness_raised = false  -- Reset the flag when quitting
    end
end)
