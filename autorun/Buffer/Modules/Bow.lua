local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("bow", 
    {
        charge_level = -1,
        all_arrow_types = false,
        unlimited_bottles = false,
        max_trick_arrow_gauge = false,
        unlimited_bladescale = false
    }
)

-- Local variables
local tetrad_shot_active = false

function Module.create_hooks()

    -- Watch for weapon changes, need to re-apply the default arrow types 
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        -- Get weapon handling
        local weapon_handling = managed:get_WeaponHandling()
        local reserve_weapon_handling = managed:get_ReserveWeaponHandling()
        if not weapon_handling then return end

        -- Check if the weapon handling for the main or reserve is a bow
        weapon_handling = (weapon_handling and weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling")) and weapon_handling or nil
        reserve_weapon_handling = (reserve_weapon_handling and reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling")) and reserve_weapon_handling or nil

        -- Get the weapon handling
        local weapon = weapon_handling or reserve_weapon_handling
        if not weapon then return end

        -- Check if all_arrow_types is enabled and we have the old arrow types
        if Module.data.all_arrow_types and Module.old.bottle_infos then
            -- Reset arrow types when weapon changes
            Module:reset()
        end
    end, function(retval) end)
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp11Handling") then return end


        -- Charge Level
        if Module.data.charge_level ~= -1 then
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level)
        end

        --* <BottleType>k__BackingField
            -- 1 = Close Range
            -- 2 = Power
            -- 3 = Pierce
            -- 4 = Paralysis
            -- 5 = Poison
            -- 6 = Sleep
            -- 7 = Blast
            -- 8 = Exhaust

        -- All arrow types
        local bottle_infos = managed:get_field("<BottleInfos>k__BackingField")
        Module:cache_and_update_array_toggle("bottle_infos", bottle_infos, "<CanLoading>k__BackingField", Module.data.all_arrow_types)

        -- Unlimited bottles
        if Module.data.unlimited_bottles then
            -- Check for Tetrad Shot skill (index 38)
            tetrad_shot_active = utils.has_skill(managed:get_Hunter(), 38)

            local max_bottle_num = tetrad_shot_active and 4 or 10

            managed:set_field("<BottleNum>k__BackingField", max_bottle_num)
            managed:set_field("<BottleShotCount>k__BackingField", 10 - max_bottle_num)
        end

        -- Trick Arrow Gauge 
        if Module.data.max_trick_arrow_gauge then
            managed:get_field("<ArrowGauge>k__BackingField"):set_field("_Value", 100)
        end

        -- Bladescale Loading
        if Module.data.unlimited_bladescale then
            -- Check for Bladescale Loading skill (index 201)
            if utils.has_skill(managed:get_Hunter(), 201) then
                managed:set_field("<Skill218BottleNum>k__BackingField", 3)
            end
        end

    end, function(retval) end)
end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and language.get("base.disabled") or "%d")
    any_changed = any_changed or changed

    changed, Module.data.all_arrow_types = imgui.checkbox(language.get(languagePrefix .. "all_arrow_types"), Module.data.all_arrow_types)
    any_changed = any_changed or changed

    imgui.begin_table(Module.title.."1", 2, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.unlimited_bottles = imgui.checkbox(language.get(languagePrefix .. "unlimited_bottles"), Module.data.unlimited_bottles)
    if  tetrad_shot_active then
        imgui.same_line()
        utils.tooltip(language.get(languagePrefix .. "tetrad_shot_active"))
    end

    imgui.table_next_column()

    changed, Module.data.unlimited_bladescale = imgui.checkbox(language.get(languagePrefix .. "unlimited_bladescale"), Module.data.unlimited_bladescale)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.max_trick_arrow_gauge = imgui.checkbox(language.get(languagePrefix .. "max_trick_arrow_gauge"), Module.data.max_trick_arrow_gauge)
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end
    
    local weapon_handling = player:get_WeaponHandling()
    local reserve_weapon_handling = player:get_ReserveWeaponHandling()

    -- Check if the weapon handling for the main or reserve is a bow
    local weapon = weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling") and weapon_handling or reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling") and reserve_weapon_handling or nil
    if not weapon then return end

    -- Restore original arrow types
    local bottle_infos = weapon:get_field("<BottleInfos>k__BackingField")
    Module:cache_and_update_array_toggle("bottle_infos", bottle_infos, "<CanLoading>k__BackingField", false)
end

return Module
