local utils, config, language
local Module = {
    title = "gunlance",
    data = {
        shell_level = -1,
        infinite_wyvern_fire = false,
        infinite_backstep = false,
        instant_charge = false,
        free_charge_shot = false
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

local function update_field(field_name, managed, new_value)
    if Module.old == nil then Module.old = {} end
    if Module.old[field_name] == nil then Module.old[field_name] = managed:get_field(field_name) end
    if new_value >= 0 then 
        managed:set_field(field_name, new_value) 
    else
        managed:set_field(field_name, Module.old[field_name])
        Module.old[field_name] = nil
    end 
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp07Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp07Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end

        -- Shell level
        update_field("_ShellLevel", managed, Module.data.shell_level)

        -- Infinite wyvernshots
        if Module.data.infinite_wyvern_fire then 
            managed:get_field("_RyuugekiGauge"):set_field("_Value", 2)
        end

        -- Infinite backstep
        if Module.data.infinite_backstep then 
            managed:set_field("_StepCount", 0) 
        end

        -- Instant charge
        if Module.data.instant_charge then 
            managed:set_field("_ChargeShotElapsedTimer", 2.6)
        end

        -- Free charge shot
        if Module.data.free_charge_shot then 
            managed:set_field("_ChargeShotBulletNum", 0)
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        imgui.begin_table(languagePrefix.."title", 3, nil, nil, nil)
        imgui.table_next_row()
        imgui.table_next_column()

        changed, Module.data.instant_charge = imgui.checkbox(language.get(languagePrefix .. "instant_charge"), Module.data.instant_charge)
        utils.tooltip(language.get(languagePrefix .. "instant_charge_tooltip"))
        any_changed = any_changed or changed

        imgui.table_next_column()

        changed, Module.data.free_charge_shot = imgui.checkbox(language.get(languagePrefix .. "free_charge_shot"), Module.data.free_charge_shot)
        any_changed = any_changed or changed
        
        imgui.end_table()

        changed, Module.data.shell_level = imgui.slider_int(language.get(languagePrefix .. "shell_level"), Module.data.shell_level, -1, 6, Module.data.shell_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed
        
        changed, Module.data.infinite_wyvern_fire = imgui.checkbox(language.get(languagePrefix .. "infinite_wyvern_fire"), Module.data.infinite_wyvern_fire)
        any_changed = any_changed or changed

        changed, Module.data.infinite_backstep = imgui.checkbox(language.get(languagePrefix .. "infinite_backstep"), Module.data.infinite_backstep)
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
