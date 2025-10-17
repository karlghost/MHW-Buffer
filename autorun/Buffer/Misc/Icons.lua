local language = require("Buffer.Misc.Language")

local Icons = {
    --//  glyphs_no_outline = {
    --//     great_sword = "\u{e917}",
    --//     sword_and_shield = "\u{e939}",
    --//     dual_blades = "\u{e918}",
    --//     long_sword = "\u{e91a}\u{e91b}\u{e91c}",
    --//     hammer = "\u{e91e}\u{e91f}",
    --//     hunting_horn = "\u{e921}",
    --//     lance = "\u{e924}",
    --//     gunlance = "\u{e925}\u{e926}",
    --//     switch_axe = "\u{e929}\u{e92a}",
    --//     charge_blade = "\u{e92b}",
    --//     insect_glaive = "\u{e92e}\u{e92f}",
    --//     bow = "\u{e931}",
    --//     light_bowgun = "\u{e933}\u{e934}",
    --//     heavy_bowgun = "\u{e936}\u{e937}",

    --//     character = "\u{e900}",
    --//     miscellaneous = "\u{e904}"

    --// },
    glyphs = {
        great_sword = "{black}\u{e916}{white}\u{e93f}",
        sword_and_shield = "\u{e939}",
        dual_blades = "\u{e918}{black}\u{e919}",
        long_sword = "\u{e91a}\u{e91b}\u{e91c}{black}\u{e91d}",
        hammer = "\u{e91e}\u{e91f}{black}\u{e920}",
        hunting_horn = "\u{e921}{black}\u{e922}",
        lance = "{black}\u{e923}{white}\u{e924}",
        gunlance = "\u{e925}\u{e926}{black}\u{e927}",
        switch_axe = "{black}\u{e928}{white}\u{e929}\u{e92a}",
        charge_blade = "\u{e92b}\u{e92c}{black}\u{e92d}",
        insect_glaive = "\u{e92e}\u{e92f}{black}\u{e930}",
        bow = "\u{e931}{black}\u{e932}",
        light_bowgun = "\u{e933}\u{e934}{black}\u{e935}",
        heavy_bowgun = "\u{e936}\u{e937}{black}\u{e938}",

        character = "{black}\u{e900}{white}\u{e901}\u{e902}\u{e903}",
        miscellaneous = "{black}\u{e904}{white}\u{e905}\u{e906}\u{e907}",

    },
    font = nil,
    loaded_font_size = nil,  -- Track the font size we loaded with
    default_color = 0xFFFFFFFF, -- White
    colors = {
        black = 0xFF333333, -- Made it more gray so it doesn't have as much contrast
        white = 0xFFFFFFFF
    }
}

--- Loads the icon font with the current language font size
function Icons.load_icons()
    Icons.font = imgui.load_font('Monster-Hunter-Icons.ttf', language.font.size+2, {0xE900, 0xE9FF, 0})
    Icons.loaded_font_size = language.font.size
end

--- Reload icons if the language font size has changed
function Icons.reload_if_needed()
    if Icons.loaded_font_size ~= language.font.size then
        Icons.load_icons()
    end
end

--- Draws the specified icon at the current cursor position
--- @param icon string The icon identifier (e.g., "great_sword", "dual_blades")
--- Supports color placeholders in format: "{color_name}\u{code}"
function Icons.draw_icon(icon)
    if Icons.font == nil then 
        Icons.load_icons() 
    else
        Icons.reload_if_needed()
    end
    
    imgui.push_font(Icons.font)
    local code = Icons.glyphs[icon] or "?"
    local pos = imgui.get_cursor_pos()
    local current_color = Icons.default_color
    
    -- Parse the string for UTF-8 codes and color placeholders
    local i = 1
    while i <= #code do
        -- Check if this is a color placeholder (starts with "{")
        local color_name = code:match("^{([^}]+)}", i)
        if color_name then
            -- Look up the color from the colors table
            current_color = Icons.colors[color_name] or Icons.default_color
            i = i + #color_name + 2  -- Skip "{color_name}"
        else
            -- It's a UTF-8 character, extract and display it
            local char_start = i
            local byte = code:byte(i)
            
            -- Determine UTF-8 character length
            local char_len = 1
            if byte >= 0xF0 then
                char_len = 4
            elseif byte >= 0xE0 then
                char_len = 3
            elseif byte >= 0xC0 then
                char_len = 2
            end
            
            -- Extract the character
            local char = code:sub(char_start, char_start + char_len - 1)
            
            -- Draw the character with current color
            imgui.set_cursor_pos(pos)
            imgui.text_colored(char, current_color)
            
            i = i + char_len
        end
    end
    
    imgui.pop_font()
end

return Icons
