local utils, config, language
local Module = {
    title = "insect_glaive",
    data = {
        kinsect = {
            power = -1,
            speed = -1,
            recovery = -1,
            unlimited_stamina = false,
            instant_charge = false,
        },
        red = false,
        white = false,
        orange = false,
        infinite_air_attacks = false,
        max_charge = false,
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

local function update_field(key, field_name, managed, new_value)
    if Module.old == nil then Module.old = {} end
    if Module.old[key] == nil then Module.old[key] = {} end
    if new_value >= 0 then 
        if Module.old[key][field_name] == nil then 
            Module.old[key][field_name] = managed:get_field(field_name) 
        end
        managed:set_field(field_name, new_value) 
    elseif Module.old[key][field_name] ~= nil then
        managed:set_field(field_name, Module.old[key][field_name])
        Module.old[key][field_name] = nil
    end 
end

function Module.init_hooks()

    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp10Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp10Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- Kinsect
        local kinsect = managed:get_Insect()
        update_field("kinsect", "_PowerLv", kinsect, Module.data.kinsect.power)
        update_field("kinsect", "_SpeedLv", kinsect, Module.data.kinsect.speed)
        update_field("kinsect", "_RecoveryLv", kinsect, Module.data.kinsect.recovery)
            
        if Module.data.kinsect.unlimited_stamina then 
            kinsect:get_field("Stamina"):set_field("_Value", 100.0)
        end

        if Module.data.kinsect.instant_charge and managed:get_field("InsectChargeTimer") > 0 then
            managed:set_field("InsectChargeTimer", 1.0)
        end

        -- Extracts
        if Module.data.red then 
            managed:get_field("ExtractTimer")[0]:set_field("_Value", 89.0)
        end
        if Module.data.white then 
            managed:get_field("ExtractTimer")[1]:set_field("_Value", 89.0)
        end
        if Module.data.orange then 
            managed:get_field("ExtractTimer")[2]:set_field("_Value", 89.0)
        end
        if Module.data.red and Module.data.white and Module.data.orange then 
            managed:get_field("TrippleUpTimer"):set_field("_Value", 89.0)
        end

        -- Air attacks
        if Module.data.infinite_air_attacks then 
            managed:set_field("_EmStepCount", 2)
        end

        -- Charge attack
        if Module.data.max_charge and managed:get_field("_ChargeTimer") > 0 then 
            managed:set_field("_ChargeTimer", 100.0)
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
        
        imgui.push_id(Module.title.."kinsect")
        languagePrefix = Module.title .. ".kinsect."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            changed, Module.data.kinsect.power = imgui.slider_int(language.get(languagePrefix .. "power"), Module.data.kinsect.power, -1, 200, Module.data.kinsect.power == -1 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.kinsect.speed = imgui.slider_int(language.get(languagePrefix .. "speed"), Module.data.kinsect.speed, -1, 100, Module.data.kinsect.speed == -1 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.kinsect.recovery = imgui.slider_int(language.get(languagePrefix .. "recovery"), Module.data.kinsect.recovery, -1, 100, Module.data.kinsect.recovery == -1 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.kinsect.unlimited_stamina = imgui.checkbox(language.get(languagePrefix .. "unlimited_stamina"), Module.data.kinsect.unlimited_stamina)
            any_changed = any_changed or changed

            changed, Module.data.kinsect.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.kinsect.instant_charge)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end
        imgui.pop_id()

        languagePrefix = Module.title .. "."
        imgui.begin_table(Module.title.."1", 3, nil, nil, nil)
        imgui.table_next_row()
        imgui.table_next_column()

        changed, Module.data.red = imgui.checkbox(language.get(languagePrefix .. "red"), Module.data.red)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.white = imgui.checkbox(language.get(languagePrefix .. "white"), Module.data.white)
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.orange = imgui.checkbox(language.get(languagePrefix .. "orange"), Module.data.orange)
        any_changed = any_changed or changed

        imgui.end_table()

        changed, Module.data.infinite_air_attacks = imgui.checkbox(language.get(languagePrefix .. "infinite_air_attacks"), Module.data.infinite_air_attacks)
        any_changed = any_changed or changed

        
        changed, Module.data.max_charge = imgui.checkbox(language.get(languagePrefix .. "max_charge"), Module.data.max_charge)
        any_changed = any_changed or changed

        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
    imgui.pop_id()
end

function Module.reset()
    -- Implement reset functionality if needed
end

function Module.create_config_section()
    return {
        [Module.title] = Module.data
    }
end

function Module.load_from_config(config_section)
    if not config_section then return end
    utils.mergeTables(Module.data, config_section)
end

return Module
