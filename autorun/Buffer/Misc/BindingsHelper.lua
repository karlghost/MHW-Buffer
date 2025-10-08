-- BindingsHelper module - extends the Bindings module with additional functionality
local bindings = require("Buffer.Misc.Bindings")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local file_path = "Buffer/Bindings.json"
local enabled_text
local disabled_text

local modules

-- Create a new table that inherits all of the original bindings functionality
local helper = {}
helper.popup = {} -- Store popup state in helper

setmetatable(helper, {
    __index = bindings
})

function helper.convert_old_format()
    local file = json.load_file(file_path)
    if file then
        local controller = file.btns
        local keyboard = file.keys
        if controller then
            for _, data in pairs(controller) do
                local inputs = type(data.input) == "table" and data.input or { data.input }
                local path = string.gsub(data.data.path, "%.data", "")
                helper.add(bindings.DEVICE_TYPES.CONTROLLER, inputs, path, data.data.on)
            end
        end
        if keyboard then
            for _, data in pairs(keyboard) do
                local inputs = type(data.input) == "table" and data.input or { data.input }
                local path = string.gsub(data.data.path, "%.data", "")
                helper.add(bindings.DEVICE_TYPES.KEYBOARD, inputs, path, data.data.on)
            end
        end

        if controller or keyboard then return true end
    end
end

-- Loads the bindings and initializes the helper
function helper.load(mods)
    modules = mods
    enabled_text = language.get("window.bindings.enabled")
    disabled_text = language.get("window.bindings.disabled")

    -- REMOVE AT A LATER DATE
    local hasOldFormat = helper.convert_old_format() -- Convert old bindings format to new one
    if hasOldFormat then
        helper.save()
        log.debug("Converted old bindings format to new one.")
        return
    end

    local file = json.load_file(file_path)
    if file then
        for _, bind in pairs(file) do
            helper.add(bind.device, bind.input, bind.path, bind.value)
        end
    end
end

-- Saves the current bindings to the file
function helper.save()
    local file = {}

    -- Iterate through both devices (1 for controller, 2 for keyboard)
    for i = 1, 2 do
        local bindings_list = bindings.get_bindings(i)
        for _, bind in pairs(bindings_list) do
            local data = {
                device = i,
                input = bind.input,
                path = bind.path,
                value = bind.value
            }
            table.insert(file, data)
        end
    end

    json.dump_file(file_path, file)
end

-- Override the original add function to include custom functionality
helper.original_add = bindings.add
function helper.add(device, input, path, value)
    helper.original_add(device, input, function()
        local path_parts = utils.split(path, ".")
        local module_name = path_parts[1]
        local value = value
        local value_text = enabled_text

        local is_boolean = false
        local is_number = false

        -- Find the module by title
        local module_index
        for key, mod in pairs(modules) do
            if mod.title == module_name then
                module_index = key
                break
            end
        end
        if not module_index then return end

        -- Traverse to the target value
        table.remove(path_parts, 1)
        local target = modules[module_index].data
        for i = 1, #path_parts - 1 do
            target = target[path_parts[i]]
        end

        -- Toggle or set the value
        local target_value = target[path_parts[#path_parts]]
        local setting_path = module_name .. "." .. table.concat(path_parts, ".")

        -- Handle boolean values
        if type(target_value) == "boolean" then
            target_value = not target_value
            target[path_parts[#path_parts]] = target_value
            value_text = target_value and enabled_text or disabled_text

        -- Handle number values
        elseif type(target_value) == "number" then
            target_value = target_value > -1 and -1 or value
            target[path_parts[#path_parts]] = target_value
            value_text = target_value == -1 and disabled_text or
                string.gsub(language.get("window.bindings.set_to"), "%%d", tostring(target_value))
        end

        utils.send_message(helper.get_setting_name_from_path(setting_path) .. " " .. value_text)
    end)

    -- Apply additional data to the bindings
    bindings.apply_data(device, input, {
        path = path,
        value = value
    })
end

-- Override the original remove function to include custom functionality
helper.original_remove = bindings.remove
function helper.remove(device, number)
    -- Find the binding to remove
    local bindings = bindings.get_bindings(device)
    local binding = bindings[number]
    helper.original_remove(device, binding.input)
    helper.save()
end

--- Returns the name of the setting based on the provided path.
--- @param path string The path to the setting (e.g., "character.health").
--- @return string The formatted name of the setting.
function helper.get_setting_name_from_path(path)
    local path_parts = utils.split(path, ".")
    local title_parts = {}
    
    for i, part in ipairs(path_parts) do
        local current_path = table.concat(path_parts, ".", 1, i)
        local key = (i == #path_parts and type(language.get(current_path)) ~= "table") 
            and current_path 
            or current_path .. ".title"
        table.insert(title_parts, language.get(key))
    end
    
    return table.concat(title_parts, "/")
end

-- Draws the popup for adding a new binding
function helper.draw()
    local listener = helper.listener:create("Buffer Popup")
    if helper.popup.open then

        local popup_size = Vector2f.new(350, 145)
        -- If a path has been chosen, make the window taller
        if helper.popup.path ~= nil then
            popup_size.y = 190
        end
        imgui.set_next_window_size(popup_size, 1 + 256)
        imgui.begin_window("buffer_bindings", nil, 1)
        imgui.indent(10)
        imgui.spacing()
        imgui.spacing()

        -- Change title depending on device
        if helper.popup.device == bindings.DEVICE_TYPES.CONTROLLER then
            imgui.text(language.get("window.bindings.add_gamepad"))
        else
            imgui.text(language.get("window.bindings.add_keyboard"))
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        -- Draw the path menu selector
        local binding_path = language.get("window.bindings.choose_modification")
        if helper.popup.path ~= nil then
            binding_path = helper.get_setting_name_from_path(helper.popup.path)
        end

        if imgui.begin_menu(binding_path) then
            for module_key, module in pairs(modules) do
                if imgui.begin_menu(language.get(module.title .. ".title")) then

                    local function draw_menu(data, path)
                        for key, value in pairs(data) do
                            local current_path = path .. "." .. key
                            if type(value) == "table" then
                                if imgui.begin_menu(language.get(current_path .. ".title")) then
                                    draw_menu(value, current_path)
                                    imgui.end_menu()
                                end
                            else
                                local label_key = current_path
                                if not string.find(language.get(current_path .. ".title"), "Invalid Language Key") then
                                    label_key = current_path .. ".title"
                                end
                                if imgui.menu_item(language.get(label_key)) then
                                    helper.popup.path = current_path
                                    helper.popup.value = value
                                end
                            end
                        end
                    end
                    draw_menu(module.data, module.title)
                    imgui.end_menu()
                end
            end
            imgui.end_menu()
        end

        -- Draw the value input field
        if helper.popup.value ~= nil then
            imgui.text(language.get("window.bindings.on_value") .. ": ")
            imgui.same_line()
            if type(helper.popup.value) == "boolean" then
                imgui.begin_disabled()
                imgui.input_text("   ", "true/false")
                imgui.end_disabled()
            elseif type(helper.popup.value) == "number" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                local changed, on_value = imgui.input_text("     ", helper.popup.value, 1)
                if changed and on_value ~= "" and tonumber(on_value) then
                    helper.popup.value = tonumber(on_value)
                end
            end
        end

        imgui.spacing()

        -- Get the default hotkey text based on the device type
        local binding_hotkey = ""

        -- Popup listening
        if listener:is_listening() then
            helper.popup.device = listener:get_device()

            -- If listener is listening, display the current binding hotkey
            if #listener:get_inputs() ~= 0 then
                binding_hotkey = ""
                local inputs = listener:get_inputs()
                inputs = bindings.get_names(listener:get_device(), inputs)
                for _, input in ipairs(inputs) do
                    binding_hotkey = binding_hotkey .. input.name .. " + "
                end
            else
                binding_hotkey = language.get("window.bindings.listening")
            end

            -- If not listening, and inputs are available, display the inputs
        elseif #listener:get_inputs() ~= 0 then
            local inputs = listener:get_inputs()
            inputs = bindings.get_names(listener:get_device(), inputs)
            for i, input in ipairs(inputs) do
                binding_hotkey = binding_hotkey .. input.name
                if i < #listener:get_inputs() then
                    binding_hotkey = binding_hotkey .. " + "
                end
            end
        else
            binding_hotkey = language.get("window.bindings.to_listen")
        end

        -- Draw the hotkey button
        if imgui.button(binding_hotkey) then
            listener:start()
        end

        imgui.spacing()
        imgui.spacing()
        imgui.separator()
        imgui.spacing()

        if imgui.button(language.get("window.bindings.cancel")) then
            helper.popup_close()
        end
        if helper.popup.path and #listener:get_inputs() > 0 then
            imgui.same_line()
            if imgui.button(language.get("window.bindings.save")) then
                helper.add(helper.popup.device, listener:get_inputs(), helper.popup.path, helper.popup.value)
                helper.save()
                helper.popup_close()
                listener:stop()
                listener:clear()
                helper.popup.open = false
            end
        end
        imgui.unindent(10)
        imgui.end_window()

        -- In case the popup is closed but still listening
    elseif listener:is_listening() then
        helper.popup_close()
        listener:stop()
        listener:clear()
    end
end

-- Opens the popup
function helper.popup_open(device)
    helper.popup.open = true
    helper.popup.device = device
    helper.popup.path = nil
    helper.popup.binding = nil
    helper.popup.value = nil
end

-- Closes the popup
function helper.popup_close()
    helper.popup.open = false
end

return helper
