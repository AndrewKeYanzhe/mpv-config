-- original code obtained from https://github.com/zenyd/mpv-scripts/blob/master/delete_file.lua


-- ctrl + DEL	mark/unmark file to be deleted
-- alt + DEL	show the list of files marked for deletion
-- ctrl + shift + DEL	clear the list of marked files


-- bugs and TODOs. * mean priority
-- 1. on exfat, windows recycle bin doesnt work. this script automatically permanently deletes instead of send to recycle bin
-- TODO: add warning ***
-- TODO: move files instead of delete
-- 2. TODO print delete list on multiple lines


local utils = require "mp.utils"

require 'mp.options'

options = {}
options.MoveToFolder = false

if package.config:sub(1,1) == "/" then
   options.DeletedFilesPath = utils.join_path(os.getenv("HOME"), "delete_file")
   ops = "unix"
else
   options.DeletedFilesPath = utils.join_path(os.getenv("USERPROFILE"), "delete_file")
   ops = "win"
end

read_options(options)


del_list = {}


function move_to_recycle_bin(path)
   local command = string.format([[powershell -command "& {Add-Type -AssemblyName 'Microsoft.VisualBasic'; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile('%s', 'OnlyErrorDialogs', 'SendToRecycleBin') }"]], path)
   os.execute(command)
end

function moveToTrash(filePath)
   -- move to trash works on macOS. 
   
   -- When using an NTFS disk via Paragon NTFS for Mac, "move to trash" and "put back using finder" works. However, there will be no "date deleted" attribute of the file in trash which can be inconvenient. This is the same behaviour when deleting manually in finder, so the lack of "date deleted" In the trash is due to the paragon NTFS implementation.

   --no terminal window will appear momentarily, so the Apple script implementation is better than the Power shell command line implementation for windows



   -- Escape the file path for use in AppleScript
   local escapedPath = filePath:gsub('"', '\\"')

   -- AppleScript command to move the file to the Trash
   local appleScriptCommand = string.format([[osascript -e 'tell application "Finder" to move POSIX file "%s" to trash']], escapedPath)
   

   -- Execute the AppleScript command
   os.execute(appleScriptCommand)
end


function createDirectory()
   if not utils.file_info(options.DeletedFilesPath) then
      if not os.execute(string.format('mkdir "%s"', options.DeletedFilesPath)) then
         print("failed to create folder")
      end
   end
end

function contains_item(l, i)
   for k, v in pairs(l) do
      if v == i then
         mp.osd_message("current file is removed from deletion list")
         l[k] = nil
         return true
      end
   end
   mp.osd_message("IMPORTANT: Current file is marked for deletion!"
)
   return false
end

function mark_delete()
   local work_dir = mp.get_property_native("working-directory")
   local file_path = mp.get_property_native("path")
   local s = file_path:find(work_dir, 0, true)
   local final_path
   if s and s == 0 then
      final_path = file_path
   else
      final_path = utils.join_path(work_dir, file_path)
   end
   if not contains_item(del_list, final_path) then
      table.insert(del_list, final_path)
   end
end

function delete()
   if options.MoveToFolder then
      --create folder if not exists
      createDirectory()
   end

   for i, v in pairs(del_list) do
      if options.MoveToFolder then
         print("moving: "..v)
         local _, file_name = utils.split_path(v)
         --this loop will add a number to the file name if it already exists in the directory
         --But limit the number of iterations
         for i = 1,100 do
            if i > 1 then
               if file_name:find("[.].+$") then
                  file_name = file_name:gsub("([.].+)$", string.format("_%d%%1", i))
               else
                  file_name = string.format("%s_%d", file_name, i)
               end
            end
            
            local movedPath = utils.join_path(options.DeletedFilesPath, file_name)
            local fileInfo = utils.file_info(movedPath)
            if not fileInfo then
               os.rename(v, movedPath)
               break
            end
         end
      else
         print("deleting: "..v)
         -- os.remove(v)
         moveToTrash(v)
      end
   end

   -- del_list = {}
   mp.command("script-reload")
end

function showList()
   local delString = "Delete Marks:\n"
   for _,v in pairs(del_list) do
      local dFile = v:gsub("/","\\")
      delString = delString..dFile:match("\\*([^\\]*)$").."; "
   end
   if delString:find(";") then
      mp.osd_message(delString)
      return delString
   elseif showListTimer then
      showListTimer:kill()
   end
end
showListTimer = mp.add_periodic_timer(1,showList)
showListTimer:kill()
function list_marks()
   if showListTimer:is_enabled() then
      showListTimer:kill()
      mp.osd_message("",0)
   else
      local delString = showList()
      if delString and delString:find(";") then
         showListTimer:resume()
         print(delString)
      else
         showListTimer:kill()
      end
   end
end

-- mp.add_key_binding("ctrl+DEL", "delete_file", mark_delete)
-- mp.add_key_binding("alt+DEL", "list_marks", list_marks)
-- mp.add_key_binding("ctrl+shift+DEL", "clear_list", function() mp.osd_message("Undelete all"); del_list = {}; end)
-- mp.register_event("shutdown", delete)


-- https://github.com/mpv-player/mpv/blob/master/etc/input.conf

mp.remove_key_binding("BS")
mp.add_key_binding("BS", "delete_file", mark_delete)
mp.add_key_binding("alt+BS", "list_marks", list_marks)
mp.add_key_binding("alt+shift+BS", "clear_list", function() mp.osd_message("Undelete all"); del_list = {}; end)

-- this refers to the control key on macOS
mp.add_key_binding("ctrl+BS", delete) 

