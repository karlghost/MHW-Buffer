local utils = {}

local soundManager, battleMusicManager
local chatManager


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

-- Custom tooltip, adds a spacing before the end of window by default,
-- but by using an empty text on the top and bottom it makes it even
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


function utils.send_message(text)
    if chatManager == nil then
        chatManager = sdk.get_managed_singleton("app.ChatManager")
    end
    chatManager:addSystemLog(text)
end

function utils.mergeTables(baseTable, newTable)
    for k, v in pairs(newTable) do
        if type(v) == "table" and type(baseTable[k]) == "table" then
            utils.mergeTables(baseTable[k], v)
        else
            baseTable[k] = v
        end
    end
end


return utils
