local utils, config, language
local Module = {
    title = "character",
    data = {
        health = {
            max = false,
            unlimited = false,
            healing = false
        },
        stamina = {
            max = false,
            unlimited = false
        },
        item_buffs = {
            dash_juice = false,
            hot_drink = false,
            cool_drink = false,
            imunizer = false,
            might_pill = false, -- _Kairiki_G_Timer
            adamant_pill = false, -- _Nintai_G_Timer
           
            mega_demondrug = false, -- _KijinDrink_G
            mega_armorskin = false, -- _KoukaDrink_G 
            
            demon_powder = false, -- _KijinPowder_Timer
            hardshell_powder = false, -- _KoukaPowder_Timer
        },
        blights_and_conditions ={
            blights = {
                fire = false,
                thunder = false,
                water = false,
                ice = false,
                dragon = false,
                all = false
            },
            conditions = {
                poison = false,
                stench = false,
                blast = false,
                bleed = false,
                defense_down = false,
                frenzy = false,
                stun = false,
                paralyze = false,
                sleep = false,
                sticky = false,
                frozen = false,
                all = false
            }
        },
        
        unlimited_sharpness = false
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end


-- Hunter Character
-- app.IHunterContextHolder _ContextHolder
-- app.cHunterContext <Hunter>k__BackingField
-- app.cHunterStatus  <HunterStatus>k__BackingField


-- Meal Bonuses - a bit overpowered, so maybe I won't add these
-- app.cHunterMEalEffect _MealEffect -- make sure isActive is on
-- app.cMEalEffect _MealEffect (Yes again)
-- Can add 400 to _AttackAdd
-- Can add unlimited to _DefenceAdd



function Module.init_hooks()
    
    sdk.hook(sdk.find_type_definition("app.cHunterStatus"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterStatus") then return end

        if managed:get_IsMaster() == false then return end

        -- Health
        local health = managed:get_field("_Health")
        if health ~= nil then
            local health_manager = health:get_field("<HealthMgr>k__BackingField")

            if Module.data.health.unlimited then 
                health_manager:set_Health(health_manager:get_MaxHealth())
            end
            if Module.data.health.healing then 
                health:set_field("_RedHealth", health_manager:get_MaxHealth())
            end
        end

        local meal_effects = managed:get_field("_MealEffect")
        if meal_effects ~= nil then
            if Module.data.health.max then
                if meal_effects:get_field("_IsEffectActive") ~= true then
                    meal_effects:set_field("_IsEffectActive", true)
                end
                if meal_effects:get_field("_MaxHealthAdd") < 50 then
                    meal_effects:set_field("_MaxHealthAdd", 50)
                end
            end
        end

        -- Stamina
        local stamina = managed:get_field("_Stamina")

        if stamina ~= nil then
            if Module.data.stamina.unlimited then 
                stamina:set_field("_RequestHealStaminaMax", true)
            end

            if Module.data.stamina.max then 
                -- Meal Effect Not working
                -- if meal_effects:get_field("_IsEffectActive") ~= true then
                --     meal_effects:set_field("_IsEffectActive", true)
                -- end
                -- if meal_effects:get_field("_MaxStaminaAdd") < 50 then
                --     meal_effects:set_field("_MaxStaminaAdd", 50)
                -- end
                    stamina:set_field("_RequestAddMaxStamina", 1) -- Probably not the best way to do this
            end
        end

        -- Item Buffs
        local item_buffs = managed:get_field("_ItemBuff")
        if item_buffs ~= nil then
            if Module.data.item_buffs.dash_juice then
                item_buffs:set_field("_DashJuice_Timer", 600)
            end
            if Module.data.item_buffs.hot_drink then
                item_buffs:set_field("_HotDrink_Timer", 600)
            end
            if Module.data.item_buffs.cool_drink then
                item_buffs:set_field("_CoolerDrink_Timer", 600)
            end
            if Module.data.item_buffs.imunizer then
                item_buffs:set_field("_Immunizer_Timer", 300)
            end
            if Module.data.item_buffs.might_pill then
                item_buffs:set_field("_Kairiki_G_Timer", 90)
            end
            if Module.data.item_buffs.adamant_pill then
                item_buffs:set_field("_Nintai_G_Timer", 90)
            end
            if Module.data.item_buffs.mega_demondrug then 
                local demon_drug = item_buffs:get_field("_KijinDrink_G")
                if demon_drug:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(5), 1.0, 1.0)   
                end
            end
            if Module.data.item_buffs.mega_armorskin then
                local armor_skin = item_buffs:get_field("_KoukaDrink_G")
                if armor_skin:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(11), 1.0, 1.0)        
                end
            end

            if Module.data.item_buffs.demon_powder then
                item_buffs:set_field("_KijinPowder_Timer", 180)
            end
            if Module.data.item_buffs.hardshell_powder then
                item_buffs:set_field("_KoukaPowder_Timer", 180)
            end
        end


        -- Conditions
        local conditions = managed:get_field("_BadConditions")
        if Module.data.blights_and_conditions.conditions.poison or Module.data.blights_and_conditions.conditions.all then
            local poison = conditions:get_field("_Poison")
            if poison:get_field("_DurationTimer") > 0 then
                poison:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.stench or Module.data.blights_and_conditions.conditions.all then
            local stench = conditions:get_field("_Stench")
            if stench:get_field("_DurationTimer") > 0 then
                stench:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.blast or Module.data.blights_and_conditions.conditions.all then
            local blast = conditions:get_field("_Blast")
            if blast:get_field("_CureAccumerator") > 0 then
                blast:set_field("_CureAccumerator", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.bleed or Module.data.blights_and_conditions.conditions.all then
            local bleed = conditions:get_field("_Bleed")
            if bleed:get_field("_CureTimer") > 0 then
                bleed:set_field("_CureTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.defense_down or Module.data.blights_and_conditions.conditions.all then
            local def_Down = conditions:get_field("_DefDown")
            if def_Down:get_field("_DurationTimer") > 0 then
                def_Down:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.frenzy or Module.data.blights_and_conditions.conditions.all then -- Not far enough into story to know, will probably affect armor buff
            local frenzy = conditions:get_field("_Frenzy")
            frenzy:set_field("_IsImmune", true)
        end
        if Module.data.blights_and_conditions.conditions.stun or Module.data.blights_and_conditions.conditions.all then
            local stun = conditions:get_field("_Stun")
            if stun:get_field("_ReduceTimer") < 6 then -- Maybe a Jewel or skill lowers this - not far enough to know
                stun:set_field("_ReduceTimer", 6)
            end
        end
        if Module.data.blights_and_conditions.conditions.paralyze or Module.data.blights_and_conditions.conditions.all then
            local paralyze = conditions:get_field("_Paralyze") -- Effect still plays
            if paralyze:get_field("_DurationTime") > 0 then
                paralyze:set_field("_DurationTime", 0)
                paralyze:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.conditions.sleep or Module.data.blights_and_conditions.conditions.all then
            local sleep = conditions:get_field("_Sleep") -- Effect probably still plays
            if sleep:get_field("_DurationTime") > 0 then
                sleep:set_field("_DurationTime", 0)
                sleep:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.conditions.sticky or Module.data.blights_and_conditions.conditions.all then
            local sticky = conditions:get_field("_Sticky") -- Effect probably still plays
            if sticky:get_field("_DurationTime") > 0 then
                sticky:set_field("_DurationTime", 0)
                sticky:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.conditions.frozen or Module.data.blights_and_conditions.conditions.all then
            local frozen = conditions:get_field("_Frozen") -- Effect probably still plays
            if frozen:get_field("_DurationTime") > 0 then
                frozen:set_field("_DurationTime", 0)
                frozen:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.blights.fire or Module.data.blights_and_conditions.blights.all then
            local fire = conditions:get_field("_Fire")
            if fire:get_field("_DurationTimer") > 0 then
                fire:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.thunder or Module.data.blights_and_conditions.blights.all then
            local electric = conditions:get_field("_Elec")
            if electric:get_field("_DurationTimer") > 0 then
                electric:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.water or Module.data.blights_and_conditions.blights.all then
            local water = conditions:get_field("_Water")
            if water:get_field("_DurationTimer") > 0 then
                water:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.ice or Module.data.blights_and_conditions.blights.all then
            local ice = conditions:get_field("_Ice")
            if ice:get_field("_DurationTimer") > 0 then
                ice:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.dragon or Module.data.blights_and_conditions.blights.all then
            local dragon = conditions:get_field("_Dragon")
            if dragon:get_field("_DurationTimer") > 0 then
                dragon:set_field("_DurationTimer", 0)
            end
        end


    end, function(retval) end)

    sdk.hook(sdk.find_type_definition("app.cWeaponKireaji"):get_method("consumeKireaji"), function(args)
        local managed = sdk.to_managed_object(args[2])
        local weapon_sharpness = managed:get_field("_Kireaji")

        if Module.data.unlimited_sharpness then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
       
    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        languagePrefix = Module.title .. ".health."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.health.max = imgui.checkbox(language.get(languagePrefix .. "max"), Module.data.health.max)
            any_changed = any_changed or changed

            changed, Module.data.health.unlimited = imgui.checkbox(language.get(languagePrefix .. "unlimited"), Module.data.health.unlimited)
            any_changed = any_changed or changed
            
            changed, Module.data.health.healing = imgui.checkbox(language.get(languagePrefix .. "healing"), Module.data.health.healing)
            utils.tooltip(language.get(languagePrefix .. "healing_tooltip"))
            any_changed = any_changed or changed

            imgui.tree_pop()

        end

        languagePrefix = Module.title .. ".stamina."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.stamina.max = imgui.checkbox(language.get(languagePrefix .. "max"), Module.data.stamina.max)
            any_changed = any_changed or changed

            changed, Module.data.stamina.unlimited = imgui.checkbox(language.get(languagePrefix .. "unlimited"), Module.data.stamina.unlimited)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end
        
        languagePrefix = Module.title .. ".blights_and_conditions."
        
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            utils.tooltip(language.get(languagePrefix .. "tooltip"))
            
            
            languagePrefix = Module.title .. ".blights_and_conditions.blights."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then

                imgui.begin_table(Module.title.."1", 2, nil, nil, nil)
                imgui.table_next_row()
                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.blights.fire = imgui.checkbox(language.get(languagePrefix.."fire"), Module.data.blights_and_conditions.blights.fire)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.thunder = imgui.checkbox(language.get(languagePrefix.."thunder"), Module.data.blights_and_conditions.blights.thunder)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.water = imgui.checkbox(language.get(languagePrefix.."water"), Module.data.blights_and_conditions.blights.water)
                any_changed = any_changed or changed

                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.blights.ice = imgui.checkbox(language.get(languagePrefix.."ice"), Module.data.blights_and_conditions.blights.ice)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.dragon = imgui.checkbox(language.get(languagePrefix.."dragon"), Module.data.blights_and_conditions.blights.dragon)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.all = imgui.checkbox(language.get(languagePrefix.."all"), Module.data.blights_and_conditions.blights.all)
                any_changed = any_changed or changed

                imgui.end_table()
                imgui.tree_pop()
            end
            
            languagePrefix = Module.title .. ".blights_and_conditions.conditions."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then
                
                imgui.begin_table(Module.title.."2", 2, nil, nil, nil)
                imgui.table_next_row()
                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.conditions.poison = imgui.checkbox(language.get(languagePrefix.."poison"), Module.data.blights_and_conditions.conditions.poison)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.stench = imgui.checkbox(language.get(languagePrefix.."stench"), Module.data.blights_and_conditions.conditions.stench)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.blast = imgui.checkbox(language.get(languagePrefix.."blast"), Module.data.blights_and_conditions.conditions.blast)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.bleed = imgui.checkbox(language.get(languagePrefix.."bleed"), Module.data.blights_and_conditions.conditions.bleed)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.defense_down = imgui.checkbox(language.get(languagePrefix.."defense_down"), Module.data.blights_and_conditions.conditions.defense_down)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.frenzy = imgui.checkbox(language.get(languagePrefix.."frenzy"), Module.data.blights_and_conditions.conditions.frenzy)
                any_changed = any_changed or changed

                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.conditions.stun = imgui.checkbox(language.get(languagePrefix.."stun"), Module.data.blights_and_conditions.conditions.stun)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.paralyze = imgui.checkbox(language.get(languagePrefix.."paralyze"), Module.data.blights_and_conditions.conditions.paralyze)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.sleep = imgui.checkbox(language.get(languagePrefix.."sleep"), Module.data.blights_and_conditions.conditions.sleep)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.sticky = imgui.checkbox(language.get(languagePrefix.."sticky"), Module.data.blights_and_conditions.conditions.sticky)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.frozen = imgui.checkbox(language.get(languagePrefix.."frozen"), Module.data.blights_and_conditions.conditions.frozen)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.all = imgui.checkbox(language.get(languagePrefix.."all"), Module.data.blights_and_conditions.conditions.all)
                any_changed = any_changed or changed

                imgui.end_table()
                imgui.tree_pop()
            end
            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".item_buffs."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            imgui.begin_table(Module.title.."3", 2, nil, nil, nil)
            imgui.table_next_row()
            imgui.table_next_column()

            changed, Module.data.item_buffs.might_pill = imgui.checkbox(language.get(languagePrefix .. "might_pill"), Module.data.item_buffs.might_pill)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.mega_demondrug = imgui.checkbox(language.get(languagePrefix .. "mega_demondrug"), Module.data.item_buffs.mega_demondrug)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.demon_powder = imgui.checkbox(language.get(languagePrefix .. "demon_powder"), Module.data.item_buffs.demon_powder)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.hot_drink = imgui.checkbox(language.get(languagePrefix .. "hot_drink"), Module.data.item_buffs.hot_drink)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.dash_juice = imgui.checkbox(language.get(languagePrefix .. "dash_juice"), Module.data.item_buffs.dash_juice)
            any_changed = any_changed or changed

            imgui.table_next_column()

            changed, Module.data.item_buffs.adamant_pill = imgui.checkbox(language.get(languagePrefix .. "adamant_pill"), Module.data.item_buffs.adamant_pill)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.mega_armorskin = imgui.checkbox(language.get(languagePrefix .. "mega_armorskin"), Module.data.item_buffs.mega_armorskin)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.hardshell_powder = imgui.checkbox(language.get(languagePrefix .. "hardshell_powder"), Module.data.item_buffs.hardshell_powder)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.cool_drink = imgui.checkbox(language.get(languagePrefix .. "cool_drink"), Module.data.item_buffs.cool_drink)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.imunizer = imgui.checkbox(language.get(languagePrefix .. "imunizer"), Module.data.item_buffs.imunizer)
            any_changed = any_changed or changed
            
            imgui.end_table()
            imgui.tree_pop()
        end

        languagePrefix = Module.title .."."
        changed, Module.data.unlimited_sharpness = imgui.checkbox(language.get(languagePrefix .. "unlimited_sharpness"), Module.data.unlimited_sharpness)
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
