local utils = require("Buffer.Misc.Utils")
local language

local file_path = "Buffer/Bindings.json"

local pad_manager, main_pad
local mouse_keyboard_manager, main_mouse_keyboard
local key_bindings, btn_bindings
local modules = {}

local bindings = {
    btns = {},
    keys = {}
}

local popup = {}

-- Init the bindings module
function bindings.init(module_list)
    modules = module_list

    language = require("Buffer.Misc.Language")

    bindings.load_from_file()

    key_bindings = utils.generate_enum("ace.ACE_MKB_KEY.INDEX")
    btn_bindings = utils.generate_enum("ace.ACE_PAD_KEY.BITS")

    -- Testing
    -- bindings.add(1, {8192, 1024}, "miscellaneous.data.ammo_and_coatings.unlimited_ammo", true) -- R3 + R1
    -- bindings.add(1, {4096}, "great_sword.data.charge_level", 3) -- R3

    -- bindings.add(2, {8, 80}, "miscellaneous.data.ammo_and_coatings.unlimited_ammo", true) -- BACKSPACE + P
end

-- Add a new binding
-- If device is gamepad(1)
-- If device is a keyboard(2)
function bindings.add(device, input, path, on)
    local binding_table = nil
    if device == 1 then
        binding_table = bindings.btns
        if binding_table then
            table.insert(binding_table, {
                ["input"] = bindings.get_button_code(input),
                ["data"] = {
                    path = path,
                    on = on
                }
            })
        end
    elseif device == 2 then
        binding_table = bindings.keys
        table.insert(binding_table, {
            ["input"] = bindings.get_key_codes_from_code_with_name(input),
            ["data"] = {
                path = path,
                on = on
            }
        })
    end

    bindings.save_to_file()
end

-- Remove a binding from the device's table (Sometimes doesn't work... will need to debug)
function bindings.remove(device, index)
    local binding_table = nil
    if device == 1 then
        binding_table = bindings.btns
    elseif device == 2 then
        binding_table = bindings.keys
    end
    if binding_table then
        table.remove(binding_table, index)
        bindings.save_to_file()
    end
end

-- ======== File Stuff ===========
function bindings.load_from_file()
    local file = json.load_file(file_path)
    if file then
        bindings.btns = file.btns or {}
        bindings.keys = file.keys or {}
    end
end

-- Save the bindings to a file
function bindings.save_to_file()
    json.dump_file(file_path, {
        ['keys'] = bindings.keys,
        ['btns'] = bindings.btns
    })
end
-- ======= Misc ===========
function bindings.get_formatted_title(path)
    path = string.gsub(path, "data%.", "")
    path = utils.split(path, ".")
    local currentPath = path[1]
    local title = language.get(currentPath .. ".title")
    for i = 2, #path, 1 do
        currentPath = currentPath .. "." .. path[i]
        if i == #path then
            title = title .. "/" .. language.get(currentPath)
        else
            title = title .. "/" .. language.get(currentPath .. ".title")
        end
    end
    return title
end
-- ======= Gamepad ==========


local current_buttons = nil
local current_buttons_last_check = nil
local previous_buttons = 0
local triggered_buttons = {}

-- Check if the controller is being used
function bindings.is_controller()
    return bindings.get_current_button_code() > 0
end

-- Get the previous buttons
function bindings.get_previous_button_code()
    return previous_buttons
end
-- Get current buttons pressed
function bindings.get_current_button_code()
    if pad_manager == nil then
        pad_manager = sdk.get_managed_singleton("ace.PadManager")
    end
    if main_pad == nil then
        main_pad = pad_manager:get_MainPad()
    end

    -- Cache the buttons for 0.1 seconds - allows for easier setting/reading of binds
    if current_buttons ~= nil and current_buttons_last_check ~= nil and current_buttons_last_check + 0.1 > os.clock() then
        return current_buttons
    end

    local current = main_pad:get_KeyOn()

    if current == 0 then
        current = -1
    end

    current_buttons = current
    current_buttons_last_check = os.clock()
    return current
end

-- Get current buttons as a list of array {name, code}
function bindings.get_current_buttons()
    return bindings.get_button_names(bindings.get_current_button_code())
end

-- Convert the list of buttons back to a code
function bindings.get_button_code(arr_btns)
    local code = 0
    for _, btn in pairs(arr_btns) do
        code = code + btn.code
    end
    return code
end

-- Is the code being triggered
function bindings.is_button_code_triggered(code)
    local current = bindings.get_current_button_code()
    local previous = bindings.get_previous_button_code()
    return current ~= previous and current == code
end

-- Is the buttons being triggered
function bindings.is_buttons_triggered(arr_btns)
    local current = bindings.get_current_button_code()
    local previous = bindings.get_previous_button_code()

    -- if current has all buttons needed, and old has all but one, then return true
    local matches = 0
    for _, required_code in pairs(arr_btns) do
        local found = false
        for _, current_code in pairs(current) do
            if current_code == required_code then
                found = true
            end
        end
        for _, previous_code in pairs(previous) do
            if previous_code == required_code then
                found = true
                matches = matches + 1
            end
        end
        if not found then
            return false
        end
    end

    return matches + 1 == #arr_btns
end

-- Is the button being pressed
function bindings.is_button_down(code)
    local current = bindings.get_current_buttons()
    for _, btn in pairs(current) do
        if btn.code == code then
            return true
        end
    end
    return false
end

-- This function will return an array of {name, code} for each button
function bindings.get_button_names(code)
    local init_code = code

    -- If the code is a single btn
    local btns = {}
    while code > 0 do
        local largest = {
            code = 0
        }

        for btn_name, btn_code in pairs(btn_bindings) do
            if btn_code <= code and btn_code > largest.code then
                largest = {
                    name = btn_name,
                    code = btn_code
                }
            end
        end

        -- If we couldn't find a bigger code, then we must have all the possible ones
        if largest.code == 0 then
            break
        end

        -- Remove the largest and add it to the list of btns
        code = code - largest.code
        table.insert(btns, {
            name = largest.name,
            code = largest.code
        })
    end
    if #btns > 0 then
        return btns
    elseif code ~= 0 and code ~= -1 then
        table.insert(btns, {
            name = "Unknown",
            code = init_code
        })
        return btns
    else
        return btns
    end
end

-- ======= Keyboard ==========

-- Keys currently being pressed
local current_keys = nil
local current_keys_last_check = nil
local previous_keys = {}

-- Check if the keyboard is being used
function bindings.is_keyboard()
    return #bindings.get_current_keys() > 0
end

-- Get the previous keys
function bindings.get_previous_keys()
    return previous_keys
end

-- Get current keys as an array of {name, code}
function bindings.get_current_keys_with_name()
    if mouse_keyboard_manager == nil then
        mouse_keyboard_manager = sdk.get_managed_singleton("ace.MouseKeyboardManager")
    end
    if main_mouse_keyboard == nil then
        main_mouse_keyboard = mouse_keyboard_manager:get_MainMouseKeyboard()
    end

    -- Cache the keys for 0.1 seconds - allows for easier setting/reading of binds
    if current_keys ~= nil and current_keys_last_check ~= nil and current_keys_last_check + 0.1 > os.clock() then
        return current_keys
    end

    local key_list = main_mouse_keyboard:get_field("_Keys")
    local keys = {}
    for key_name, key_code in pairs(key_bindings) do
        key_list:get_Item(key_code)
        if key_list:get_Item(key_code):get_field("_On") then
            if not string.match(key_name, "CLICK") then
                table.insert(keys, {
                    name = key_name,
                    code = key_code
                })
            end
        end
    end

    current_keys = keys
    current_keys_last_check = os.clock()
    return keys
end

-- Get current keys as an array of code
function bindings.get_current_keys()

    local keys = bindings.get_current_keys_with_name()
    local key_codes = {}
    for _, key in pairs(keys) do
        table.insert(key_codes, key.code)
    end
    return key_codes
end

-- Is the keys being triggered
function bindings.is_key_codes_triggered(arr_key)
    local current = bindings.get_current_keys()
    local previous = bindings.get_previous_keys()

    -- Check if in current all keys are pressed, and in previous either none or all but one
    local matches = 0
    local previous_matches = 0
    for _, key in pairs(arr_key) do
        for _, current_key in pairs(current) do
            if current_key == key then
                matches = matches + 1
            end
        end
        for _, previous_key in pairs(previous) do
            if previous_key == key then
                previous_matches = previous_matches + 1
            end
        end
    end

    -- If not all current keys match the trigger
    if matches ~= #arr_key then
        return false
    end

    -- If no previous keys were found
    if #previous_keys == 0 then
        return true
    end

    -- If all but one key is the same
    return previous_matches + 1 == #arr_key
   
end
function bindings.is_key_code_triggered(code)
    local keys = {}
    table.insert(keys, code)
    return bindings.is_key_codes_triggered(keys)
end

-- Get the key names
function bindings.get_keys_with_name(arr_key)
    local keys = {}
    for _, key in pairs(arr_key) do
        table.insert(keys, {
            name = bindings.get_key_name(key),
            code = key
        })
    end
    return keys
end

-- Is the key being pressed
function bindings.is_key_down(code)
    local current = bindings.get_current_keys()
    for _, key in pairs(current) do
        if key == code then
            return true
        end
    end
    return false
end

-- This function will return an array of {name, code} for each key
function bindings.get_key_name(code)
    for key_name, key_code in pairs(key_bindings) do
        if key_code == code then
            return key_name
        end
    end
    return "Unknown"
end

-- Get an array of key codes
function bindings.get_key_codes_from_code_with_name(keys)
    local key_codes = {}
    for _, key in pairs(keys) do
        table.insert(key_codes, key.code)
    end
    return key_codes
end

-- =========================================

-- Checks the bindings
function bindings.update()
    if bindings.is_controller() then
        for _, input_data in pairs(bindings.btns) do
            if bindings.is_button_code_triggered(input_data.input) and not triggered_buttons[input_data.input] then
                bindings.perform(input_data.data)
                triggered_buttons[input_data.input] = true
            end
        end
    end

    if bindings.is_keyboard() then
        for _, input_data in pairs(bindings.keys) do
            if bindings.is_key_codes_triggered(input_data.input) then
                bindings.perform(input_data.data)
            end
        end
    end

    bindings.popup_update()

    if not bindings.is_controller() then
        triggered_buttons = {}
    else
        for code, _ in pairs(triggered_buttons) do
            local btns_in_trigger = bindings.get_button_names(code)
            local found_unpressed = false
            for _, btn in pairs(btns_in_trigger) do
                if not bindings.is_button_down(btn.code) then
                    found_unpressed = true
                end
            end
            if found_unpressed then
                triggered_buttons[code] = nil
            end
        end
    end
    
    -- Update previous data
    previous_buttons = bindings.get_current_button_code()
    previous_keys = bindings.get_current_keys()
end

-- Draw anything the bindings need
function bindings.draw()
    bindings.popup_draw()
end

-- Perform the changes
function bindings.perform(data)
    local path = utils.split(data.path, ".")
    local on_value = data.on
    local enabled_text = "<COL YEL>" .. language.get("window.bindings.enabled") .. "</COL>"
    local disabled_text = "<COL RED>" .. language.get("window.bindings.disabled") .. "</COL>"
    if type(on_value) == "number" then
        enabled_text = "<COL YEL>" .. string.gsub(language.get("window.bindings.set_to"), "%%d", on_value) .. "</COL>"
    end

    -- Find module
    local module_index
    for key, value in pairs(modules) do
        if modules[key].title == path[1] then
            module_index = key
        end
    end
    table.remove(path, 1) -- Remove Module name
    table.remove(path, 1) -- Remove "data" from path

    local function toggle_boolean(module_data, path, on_value)
        local target = module_data
        for i = 1, #path - 1 do
            target = target[path[i]]
        end
        target[path[#path]] = not target[path[#path]]
        utils.send_message(bindings.get_formatted_title(data.path) .. " " .. (target[path[#path]] and enabled_text or disabled_text))
    end

    local function toggle_number(module_data, path, on_value)
        local target = module_data
        for i = 1, #path - 1 do
            target = target[path[i]]
        end
        if target[path[#path]] == -1 then
            target[path[#path]] = on_value
            utils.send_message(bindings.get_formatted_title(data.path) .. " " .. enabled_text)
        else
            target[path[#path]] = -1
            utils.send_message(bindings.get_formatted_title(data.path) .. " " .. disabled_text)
        end
    end

    if type(on_value) == "boolean" then
        toggle_boolean(modules[module_index].data, path, on_value)
    elseif type(on_value) == "number" then
        toggle_number(modules[module_index].data, path, on_value)
    end

end
-- ================= Popup =====================

-- Popup updating function
function bindings.popup_update()
    if popup.open then
        if popup.listening then
            -- Get Currently pressed
            local current = popup.device == 1 and bindings.get_current_buttons() or bindings.get_current_keys_with_name()

            -- If currently pressing buttons
            if #current > 0 then
                if not popup.binding then
                    popup.binding = {}
                end

                popup.binding = current

                -- Add the new inputs to the binding list
                -- for _, input in pairs(current) do
                --     local in_list = false
                --     for _, binding in pairs(popup.binding) do
                --         if binding.code == input.code then
                --             in_list = true
                --         end
                --     end
                --     if not in_list then
                --         table.insert(popup.binding, input)
                --     end
                -- end
            elseif #current == 0 and popup.binding and #popup.binding > 0 then
                popup.listening = false
            end
        end
    end
end

-- Open the popup for the given device (1 = Gamepad, 2 = Keyboard)
function bindings.popup_open(device)
    bindings.popup_reset()
    popup.open = true
    popup.device = device
end

-- Close the popup and reset fields
function bindings.popup_close()
    imgui.close_current_popup()
    bindings.popup_reset()
end

-- Reset the popup fields
function bindings.popup_reset()
    popup = {
        open = false,
        device = 0,
        listening = false,
        path = nil,
        on = true,
        binding = {}
    }
end

-- Draw the popup
function bindings.popup_draw()
    if popup.open then
        local popup_size = Vector2f.new(350, 145)
        -- If a path has been chosen, make the window taller
        if popup.path ~= nil then
            popup_size.y = 190
        end
        imgui.set_next_window_size(popup_size, 1 + 256)
        imgui.begin_window("buffer_bindings", nil, 1)
        imgui.indent(10)
        imgui.spacing()
        imgui.spacing()

        -- Change title depending on device
        if popup.device == 1 then
            imgui.text(language.get("window.bindings.add_gamepad"))
        else
            imgui.text(language.get("window.bindings.add_keyboard"))
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        -- If no path has been chosen use the default text from the language file, otherwise display the path selected
        local bindings_text = language.get("window.bindings.choose_modification")
        if popup.path ~= nil then
            bindings_text = bindings.get_formatted_title(popup.path)
        end
        if imgui.begin_menu(bindings_text) then
            for _, module in pairs(modules) do
                if imgui.begin_menu(language.get(module.title .. ".title")) then
                    bindings.popup_draw_menu(module, module.title)
                    imgui.end_menu()
                end
            end
            imgui.end_menu()
        end
        imgui.same_line()
        imgui.text("          ")
        imgui.spacing()

        -- If a path has been chosen show the option for the on value
        if popup.path ~= nil then
            imgui.spacing()

            -- On value for numbers - only allow numbers
            if type(popup.on) == "number" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                imgui.same_line()
                local changed, on_value = imgui.input_text("     ", popup.on, 1)
                if changed and on_value ~= "" and tonumber(on_value) then
                    popup.on = tonumber(on_value)
                end

                -- On value for booleans, read only
            elseif type(popup.on) == "boolean" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                imgui.same_line()
                imgui.begin_disabled()
                imgui.input_text("   ", "true/false", 16384)
                imgui.end_disabled()
            end
            imgui.spacing()
            imgui.spacing()
            imgui.separator()
        end
        imgui.spacing()

        -- If not listening for inputs display default to listen from language file
        local listening_button_text = language.get("window.bindings.to_listen")

        -- If some inputs have been pressed, display them in a readable format
        if popup.binding and utils.getLength(popup.binding) > 0 then
            listening_button_text = ""

            for i, binding in pairs(popup.binding) do
                listening_button_text = listening_button_text .. binding.name
                if i < #popup.binding then
                    listening_button_text = listening_button_text .. " + "
                end
            end

            if popup.listening then
                listening_button_text = listening_button_text .. " + ..."
            end

            -- If no inputs pressed use default listening from language file
        elseif popup.listening then
            listening_button_text = language.get("window.bindings.listening")
        end

        if imgui.button(listening_button_text) then
            popup.listening = true
            popup.binding = nil
        end
        imgui.spacing()
        imgui.separator()
        imgui.spacing()

        if imgui.button(language.get("window.bindings.cancel")) then
            bindings.popup_close()
        end
        if popup.path and popup.binding then
            imgui.same_line()
            if imgui.button(language.get("window.bindings.save")) then
                local path = popup.path
                -- add .data after the fist . in the path
                path = string.gsub(path, "%.", ".data.", 1)
                bindings.add(popup.device, popup.binding, path, popup.on)
                bindings.popup_close()
            end
        end
        imgui.unindent(10)
        imgui.end_window()
    end
end

function bindings.popup_draw_menu(menu, language_path)
    menu = menu or modules
    language_path = string.gsub(language_path, "%.data", "") or ""

    for key, value in pairs(menu) do

        -- If value is a table, then go deeper in the menu
        if type(value) == "table" then
            if key ~= "old" and key ~= "hidden" then
                if key == "data" then
                    bindings.popup_draw_menu(value, language_path .. "." .. key)
                elseif imgui.begin_menu(language.get(language_path .. "." .. key .. ".title")) then
                    bindings.popup_draw_menu(value, language_path .. "." .. key)
                    imgui.end_menu()
                end

            end

            -- If the value is a boolean or number, display the key
        elseif type(value) == "boolean" or type(value) == "number" then
            if imgui.menu_item(language.get(language_path .. "." .. key), nil, false, true) then
                popup.path = language_path .. "." .. key
                if type(value) == "number" then
                    popup.on = tonumber(1)
                end
                if type(value) == "boolean" then
                    popup.on = true
                end
            end
        end
    end
end

return bindings
