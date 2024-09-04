-- mp.register_event("start-file", function()
--     os.execute([[powershell.exe -Command "Start-Process powershell -ArgumentList '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1,100)' -WindowStyle Hidden"]])
-- end)

-- -- terminal still appears for a split second