local utils = {}

local soundManager, battleMusicManager
local chatManager

-- Check if the player is in battle from the sound manager
function utils.isInBattle()
    if soundManager == nil then
        soundManager = sdk.get_managed_singleton.GetSingleton("app.SoundMusicManager")
    end
    if soundManager == nil then return false end
    if battleMusicManager == nil then
        battleMusicManager = soundManager:get_BattleMusic()
    end
    if battleMusicManager == nil then return false end
    if battleMusicManager:get_IsBattle() then return true end
    return false
end

-- Function to get length of table
function utils.getLength(obj)
    local count = 0

    -- Count the items in the table
    for _ in pairs(obj) do count = count + 1 end
    return count
end

-- Add a tooltip to the current item
function utils.tooltip(text)
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
end

-- Split a string into an array
function utils.split(text, delim)
    -- returns an array of fields based on text and delimiter (one character only)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        delim = "%" .. delim
    end

    local pattern = "[^" .. delim .. "]+"
    for w in string.gmatch(text, pattern) do table.insert(result, w) end
    return result
end

-- Generate an enum from a type name
function utils.generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end
    local fields = t:get_fields()
    local enum = {}
    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
        end
    end
    return enum
end

-- Send a message to the player through the system log
function utils.send_message(text)
    if chatManager == nil then
        chatManager = sdk.get_managed_singleton("app.ChatManager")
    end
    chatManager:addSystemLog(text)
end

-- Merge two tables together, updating the base table with the new table
function utils.mergeTables(baseTable, newTable)
    for k, v in pairs(newTable) do
        if type(v) == "table" and type(baseTable[k]) == "table" then
            utils.mergeTables(baseTable[k], v)
        else
            baseTable[k] = v
        end
    end
end

-- Update a table with another table, only updating the values that exist in the base table
function utils.update_table_with_existing_table(baseTable, newTable)
    for key, value in pairs(baseTable) do
        if type(value) == "table" and type(newTable[key]) == "table" then
            utils.update_table_with_existing_table(value, newTable[key])
        elseif newTable[key] ~= nil then
            baseTable[key] = newTable[key]
        end
    end
end

return utils
