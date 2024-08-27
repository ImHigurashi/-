-- Copyright © 2020-2024 Higurashi
local ScriptLoaded = true
local title = "Project Higurashi"
local script_version = "4.0.0.5"
local Dev = true

local root = os.getenv('APPDATA') .. "\\PopstarDevs\\2Take1Menu"
local paths = {
    root = root,
    spoofer = root .. "\\spoofer",
    outfits = root .. "\\moddedOutfits",
    vehicles = root .. "\\moddedVehicles",
    higurashi = root .. "\\scripts\\Project.Higurashi",
    datas = root .. "\\scripts\\Project.Higurashi\\datas",
    dev = root .. "\\scripts\\Project.Higurashi\\dev",
    logs = root .. "\\scripts\\Project.Higurashi\\logs",
    settings = root .. "\\scripts\\Project.Higurashi\\settings.ini",
}

for _, dir in pairs({ paths.logs, Dev and paths.dev or nil }) do
    if dir and not utils.dir_exists(dir) then
        utils.make_dir(dir)
    end
end

local function logger(text, prefix, file_name, menu_notify, title, seconds, color)
    local log_file = io.open(paths.logs .. "\\" .. (file_name or "default.log"), "a")
    local t = os.date("*t")
    local prefix_str = string.format("[%04d-%02d-%02d %02d:%02d:%02d] %s", t.year, t.month, t.day, t.hour, t.min, t.sec, prefix or "")
    print(text)
    log_file:write(prefix_str .. text .. "\n")
    log_file:close()

    if menu_notify then
        m.n(text, title or "", seconds or 3, color or c.white1)
    end
end

local luaFiles = {
    { name = "higurashi", path = paths.datas .. "\\higurashi.lua" },
    { name = "higurashi_globals", path = paths.datas .. "\\HigurashiGlobals.lua" },
    { name = "higurashi_weapon", path = paths.datas .. "\\HigurashiWeapons.lua" },
    { name = "higurashi_discord", path = paths.datas .. "\\HigurashiDiscordHandler.lua" },
    { name = "NATIVE", path = paths.datas .. "\\HigurashiNatives.lua" },
}

for _, file in ipairs(luaFiles) do
    _G[file.name] = dofile(file.path)
    if not _G[file.name] then
        logger("Error: " .. file.path .. " failed to load.", "Error", "Debug.log", true, title, 6, "CHAR_BLOCKED")
        return menu.exit()
    end
end

local function check_and_draw_text(text, offset, size, color, alignment)
    scriptdraw.draw_text(text, offset, v2(2, 2), size, color, alignment)
end

local function get_github_version()
    local response_code, version = web.get("https://raw.githubusercontent.com/ImHigurashi/-/main/Project.Higurashi/Version.txt")
    if response_code == 200 then
        return version:gsub("[\r\n]", "")
    end
    return nil
end

local function get_changelog()
    local response_code, changelog = web.get("https://raw.githubusercontent.com/ImHigurashi/-/main/Project.Higurashi/Changelog.txt")
    if response_code == 200 then
        return "\n\n\nChangelog:\n" .. changelog
    end
    return ""
end

local function get_text_offsets(strings, text_size)
    local screen_width = graphics.get_screen_width()
    strings.version_compare_x_offset = v2(-scriptdraw.get_text_size(strings.version_compare, text_size).x / screen_width, 0)
    strings.new_ver_x_offset = v2(-scriptdraw.get_text_size(strings.new_ver, text_size).x / screen_width, 0)
    strings.changelog_x_offset = v2(-scriptdraw.get_text_size(strings.changelog, text_size).x / screen_width, 0)
end

local function setup_vercheck_keys()
    local keys = { ctrl = MenuKey(), space = MenuKey(), enter = MenuKey(), rshift = MenuKey() }
    keys.ctrl:push_vk(0x11)
    keys.space:push_vk(0x20)
    keys.enter:push_vk(0x0D)
    keys.rshift:push_vk(0xA1)
    return keys
end

local function handle_update()
    local response_code, auto_updater = web.get("https://raw.githubusercontent.com/ImHigurashi/-/main/Project.Higurashi/datas/HigurashiAutoUpdater.lua")
    if response_code == 200 then
        auto_updater = load(auto_updater)
        m.ct(function()
            higurashi.logger("Update Started", "Please wait...", "", "", "Debug.log", true, "CHAR_SOCIAL_CLUB", 212)
            local status = auto_updater()
            if status then
                if type(status) == "string" then
                    higurashi.logger("Error", "Updating local files failed.", "Please redownload the Project Higurashi.", "", "Debug.log", true, "CHAR_BLOCKED", 6)
                else
                    higurashi.logger("Update Succeeded", "Please reload the Project Higurashi.", "", "", "Debug.log", true, "CHAR_SOCIAL_CLUB", 18)
                    dofile(utils.get_appdata_path("PopstarDevs", "2Take1Menu") .. "\\scripts\\ProjectHigurashi.lua")
                end
            else
                higurashi.logger("Error", "Download for updated files failed.", "Current files have not been replaced.", "", "Debug.log", true, "CHAR_BLOCKED", 6)
            end
        end, nil)
    else
        higurashi.logger("Error", "Getting updater failed.", "Check your connection and try downloading manually.", "", "Debug.log", true, "CHAR_BLOCKED", 6)
    end
end

local function show_update_prompt(keys, strings, text_size)
    while true do
        check_and_draw_text(strings.new_ver, strings.new_ver_x_offset, text_size, 0xFFFFFFFF, 2)
        check_and_draw_text(strings.version_compare, strings.version_compare_x_offset, text_size, 0xFFFFFFFF, 2)
        check_and_draw_text(strings.changelog, strings.changelog_x_offset, text_size, 0xFFFFFFFF, 2)
        if Dev or keys.ctrl:is_down() or keys.space:is_down() then
            MainScript()
            break
        elseif keys.enter:is_down() or keys.rshift:is_down() then
            handle_update()
            break
        end
        wait(0)
    end
end

if ScriptLoaded and menu.is_trusted_mode_enabled(1 << 3) and menu.is_trusted_mode_enabled(1 << 2) then
    m.ct(function()
        local vercheck_keys = setup_vercheck_keys()
        local github_version = get_github_version()
        if github_version and github_version ~= script_version then
            local text_size = (graphics.get_screen_width() * graphics.get_screen_height() / 3686400 * 0.5) + 0.5
            local strings = {
                version_compare = "\nCurrent Version:" .. script_version .. "\nLatest Version:" .. github_version,
                new_ver = "New version available. Press CTRL or SPACE to skip or press ENTER or RIGHT SHIFT to update.",
                changelog = get_changelog(),
            }
            get_text_offsets(strings, text_size)
            show_update_prompt(vercheck_keys, strings, text_size)
        else
            MainScript()
        end
    end, nil)
else
    if menu.is_trusted_mode_enabled(1 << 2) then
        http_trusted_off = true
    else
        m.n("Trusted mode > Natives has to be on. If you wish for auto updates enable Http too.", title, 3, c.red1)
    end
    menu.exit()
end
if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_STATS) then
    m.n("Trusted mode for > Stats not enabled.", "", 3, c.yellow1)
    return menu.exit()
end

if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_SCRIPT_VARS) then
    m.n("Trusted mode for > Globals / Locals not enabled.", "", 3, c.yellow1)
    return menu.exit()
end

function MainScript()
    if ScriptLoaded then
        m.ct(function()
            local script_execute_scaleform = NATIVE.REQUEST_SCALEFORM_MOVIE("mp_big_message_freemode")
            NATIVE.BEGIN_SCALEFORM_MOVIE_METHOD(script_execute_scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
            NATIVE.DRAW_SCALEFORM_MOVIE_FULLSCREEN(script_execute_scaleform, 255, 255, 255, 255, 0)
            NATIVE.SCALEFORM_MOVIE_METHOD_ADD_PARAM_TEXTURE_NAME_STRING(title)
            NATIVE.END_SCALEFORM_MOVIE_METHOD(script_execute_scaleform)
            NATIVE.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED("mp_big_message_freemode")
            higurashi.logger("Project Higurashi " .. script_version, " Successfully executed.", " Welcom " .. os.getenv("USERNAME") .. " to Project Higurashi", "", "Debug.log", true, "CHAR_SOCIAL_CLUB", 23)
        end, nil)
    end

    local settings = settings or {}

    local function SaveScriptSettings()
        local file = io.open(paths.settings, "w")
        if not file then
            higurashi.logger("Error opening settings file for writing.", "", "", "", "Error.log", true, "CHAR_SOCIAL_CLUB", 23)
            return
        end
        for k, v in pairs(settings) do
            file:write(string.format("%s=%s\n", k, tostring(v)))
        end
        file:close()
    end

    local function LoadScriptSettings()
        if not utils.file_exists(paths.settings) then return end
        for line in io.lines(paths.settings) do
            local key, value = line:match("^(.-)=(.-)$")
            if key and value then
                if value == "true" then
                    settings[key] = true
                elseif value == "false" then
                    settings[key] = false
                else
                    settings[key] = value
                end
            end
        end
    end

    LoadScriptSettings()

    higurashi.load_modder_flags()
    local Higurashi = Higurashi or {}
    local player_log = {}
    local chat_events = {}
    local parameters = {}

    local regions = {
        [0] = "English",
        [1] = "French",
        [2] = "German",
        [3] = "Italian",
        [4] = "Spanish",
        [5] = "Brazilian",
        [6] = "Polish",
        [7] = "Russian",
        [8] = "Korean",
        [9] = "Chinese Traditional",
        [10] = "Japanese",
        [11] = "Mexican",
        [12] = "Chinese Simplified",
    }

    function input_handler(title, prompt, handler)
        local r, s = input.get(prompt, "", 250, 0)
        if r == 1 then return HANDLER_CONTINUE end
        if r == 2 then
            m.n("Input canceled.", title, 3, c.yellow1)
            return HANDLER_POP
        end
        handler(s)
    end

    Higurashi.Parent1 = m.apf(c.purple2 .. title .. c.default, "parent", 0)

    local was_in_spectate = false

    Higurashi.SpectatePlayer = m.apf("Spectate Player", "toggle", Higurashi.Parent1.id, function(f, pid)
        if was_in_spectate then
            f.on = false
            return m.n("You are already spectating other players.", title, 3, c.red1)
        end
        if pid == NATIVE.PLAYER_ID() then
            f.on = false
            return m.n("No need to spectate yourself.", title, 3, c.red1)
        end
        was_in_spectate = true
        local playerPed = NATIVE.PLAYER_PED_ID()
        local spectatePed = NATIVE.GET_PLAYER_PED(pid)

        if NATIVE.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
            local vehicle = NATIVE.GET_VEHICLE_PED_IS_IN(playerPed, false)
            NATIVE.FREEZE_ENTITY_POSITION(vehicle, true)
        end
        NATIVE.FREEZE_ENTITY_POSITION(playerPed, true)
        NATIVE.SET_FOCUS_ENTITY(spectatePed)
        NATIVE.SET_MINIMAP_IN_SPECTATOR_MODE(true, spectatePed)
        while f.on do
            NATIVE.SET_GAMEPLAY_CAM_FOLLOW_PED_THIS_UPDATE(spectatePed)
            scriptdraw.draw_text(higurashi.get_user_name(pid), v2(), v2(), 1, 0xFF800080, 0)
            wait()
        end

        if NATIVE.IS_PED_IN_ANY_VEHICLE(playerPed, false) then
            local vehicle = NATIVE.GET_VEHICLE_PED_IS_IN(playerPed, false)
            NATIVE.FREEZE_ENTITY_POSITION(vehicle, false)
        end
        NATIVE.FREEZE_ENTITY_POSITION(playerPed, false)
        NATIVE.SET_MINIMAP_IN_SPECTATOR_MODE(true, playerPed)
        NATIVE.CLEAR_FOCUS()
        was_in_spectate = false
    end)

    Higurashi.GhostMode = m.apf("Ghostmode", "toggle", Higurashi.Parent1.id, function(f, pid)
        if pid == NATIVE.PLAYER_ID() then
            f.on = false
            return
        end
        NATIVE.SET_REMOTE_PLAYER_AS_GHOST(pid, f.on)
    end)
    Higurashi.GhostMode.hint = ""

    m.apf("Waypoint Player", "toggle", Higurashi.Parent1.id, function(f, pid)
        if pid == NATIVE.PLAYER_ID() then
            f.on = false
            return
        end
        while f.on do
            NATIVE.SET_NEW_WAYPOINT(v2(higurashi.get_player_coords(pid).x,
                higurashi.get_player_coords(pid).y))
            wait(200)
        end
        if NATIVE.IS_WAYPOINT_ACTIVE() and not f.on then
            NATIVE.DELETE_WAYPOINT()
        end
    end)

    m.apf("Teleport To ", "action_value_str", Higurashi.Parent1.id, function(f, pid)
        if NATIVE.PLAYER_ID() ~= pid then
            if f.value == 0 then
                higurashi.teleport_to(higurashi.get_player_coords(pid))
            elseif f.value == 1 then
                local veh = higurashi.get_player_vehicle(pid)
                if veh ~= 0 then
                    NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), veh, higurashi.get_empty_seats(veh))
                else
                    m.n(higurashi.get_user_name(pid) .. " is not in a vehicle.", title, 3, c.red1)
                end
            end
        end
    end):set_str_data({ "Player", "Vehicle" })

    m.apf("Teleport Player To ", "action_value_str", Higurashi.Parent1.id, function(f, pid)
        if f.value == 0 then
            higurashi.teleport_player_and_vehicle_to_position(pid, higurashi.get_most_accurate_position(higurashi.get_vector_relative_to_entity(NATIVE.PLAYER_PED_ID(), 8)), true,
                true)
        elseif f.value == 1 then
            if not NATIVE.IS_WAYPOINT_ACTIVE() then
                m.n("Waypoint not found.", title, 3, c.red1)
                return
            end
            local blip_id = NATIVE.GET_CLOSEST_BLIP_INFO_ID(8)
            local wp_pos = NATIVE.GET_BLIP_COORDS(blip_id)
            higurashi.teleport_player_and_vehicle_to_position(pid, higurashi.get_most_accurate_position(v3(wp_pos.x, wp_pos.y, wp_pos.z)), NATIVE.PLAYER_ID() ~= pid, false, true, f)
        elseif f.value == 2 then
            higurashi.teleport_player_and_vehicle_to_position(pid, v3(491.9401550293, 5587.0, 794.00347900391), NATIVE.PLAYER_ID() ~= pid, true)
        end
    end):set_str_data({ "Me", "Waypoint", "Mount Chiliad" })

    Higurashi.CEO = m.apf("Remote CEO / MC", "parent", Higurashi.Parent1.id)
    Higurashi.CEO.hint = "Interact with the organization of this player in many ways."

    Higurashi.InviteCEOorMC = m.apf("Invite", "action", Higurashi.CEO.id, function(f, pid)
        higurashi_globals.organization_invite(pid)
    end)

    Higurashi.InviteCEOorMC.hint = "Send the player an invite to join your organization."

    Higurashi.InviteCEOorMC2 = m.apf("Invite All Friends", "action", Higurashi.CEO.id, function(f, pid)
        for pid in higurashi.players() do
            if player.is_player_valid(pid) and player.is_player_friend(pid) then
                higurashi_globals.organization_invite(pid)
            end
        end
    end)

    Higurashi.DismissCEOorMC = m.apf("Remove", "action_value_str", Higurashi.CEO.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("CEO Kick", pid, { pid, 2, -1 })
        elseif f.value == 1 then
            higurashi_globals.send_script_event("CEO Ban", pid, { pid, 1, 5 })
        end
    end):set_str_data({ "Kick", "Ban" })

    m.apf("CEO Money", "toggle", Higurashi.CEO.id, function(f, pid)
        if f.on then
            higurashi_globals.send_script_event("CEO Money", pid, { NATIVE.PLAYER_ID(), 10000, -1292453789, 0, higurashi_globals.generic_player_global(pid), higurashi_globals.get_9_10_globals_pair() })
            wait(20000)
            higurashi_globals.send_script_event("CEO Money", pid, { NATIVE.PLAYER_ID(), 10000, -1292453789, 1, higurashi_globals.generic_player_global(pid), higurashi_globals.get_9_10_globals_pair() })
            wait(20000)
            higurashi_globals.send_script_event("CEO Money", pid, { NATIVE.PLAYER_ID(), 30000, 198210293, 1, higurashi_globals.generic_player_global(pid), higurashi_globals.get_9_10_globals_pair() })
            wait(120000)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.Friendly = m.apf("Friendly", "parent", Higurashi.Parent1.id)
    Higurashi.Friendly.hint = ""

    Higurashi.SpawnNeko = m.apf("Friendly Neko", "action_value_str", Higurashi.Friendly.id, function(f, pid)
        if f.value == 0 then
            local pos = higurashi.get_player_coords(pid)
            local spawned_cat = higurashi.create_ped(28, joaat("a_c_cat_01"), v3(pos.x, pos.y, pos.z), 0, true, false, true, false, false, true)
            NATIVE.SET_PED_COMPONENT_VARIATION(spawned_cat, 0, 0, math.random(1, 2), 0)
            NATIVE.DECOR_SET_INT(spawned_cat, "Skill_Blocker", -1)
            NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_cat, true)
            NATIVE.SET_ENTITY_INVINCIBLE(spawned_cat, true)
            NATIVE.SET_ENTITY_CAN_BE_DAMAGED(spawned_cat, false)
            NATIVE.SET_PED_CAN_RAGDOLL(spawned_cat, false)
            NATIVE.SET_PED_CAN_BE_TARGETTED(spawned_cat, false)
            NATIVE.SET_CAN_ATTACK_FRIENDLY(spawned_cat, false, true)
            NATIVE.SET_PED_AS_GROUP_MEMBER(spawned_cat, NATIVE.GET_PLAYER_GROUP(pid))
            NATIVE.SET_PED_NEVER_LEAVES_GROUP(spawned_cat, true)
        elseif f.value == 1 then
            for _, cats in pairs(ped.get_all_peds()) do
                if NATIVE.GET_ENTITY_MODEL(cats) == joaat("a_c_cat_01") and NATIVE.DECOR_EXIST_ON(cats, "Skill_Blocker") then
                    NATIVE.SET_ENTITY_COORDS_NO_OFFSET(cats, v3(pos.x + math.random(-2, 2), pos.y + math.random(-2, 2), pos.z))
                    NATIVE.SET_ENTITY_ROTATION(cats, v3(0.0, 0.0, math.random(-300, 300)))
                end
            end
        elseif f.value == 2 then
            for _, cats in pairs(ped.get_all_peds()) do
                if NATIVE.GET_ENTITY_MODEL(cats) == joaat("a_c_cat_01") and NATIVE.DECOR_EXIST_ON(cats, "Skill_Blocker") then
                    higurashi.remove_entity({ cats })
                end
            end
        end
    end):set_str_data({ "Spawn", "Replace", "Delete" })

    Higurashi.DropHealth = m.apf("Drop Health", "value_i", Higurashi.Friendly.id, function(f, pid)
        while f.on do
            local pos = higurashi.get_player_coords(pid)
            local pickup = higurashi.create_ambient_pickup(joaat("PICKUP_HEALTH_STANDARD"), higurashi.offset_coords(v3(pos.x, pos.y, pos.z + 1.0), higurashi.get_player_heading(pid), 0), 9999, 9999, joaat("prop_ld_health_pack"), true, true, true, false)
            wait(f.value)
        end
    end)
    Higurashi.DropHealth.max = 10000
    Higurashi.DropHealth.min = 0
    Higurashi.DropHealth.mod = 100
    Higurashi.DropHealth.value = 500

    Higurashi.DropArmor = m.apf("Drop Armor", "value_i", Higurashi.Friendly.id, function(f, pid)
        while f.on do
            local pos = higurashi.get_player_coords(pid)
            local pickup = higurashi.create_ambient_pickup(joaat("PICKUP_ARMOUR_STANDARD"), higurashi.offset_coords(v3(pos.x, pos.y, pos.z + 1.0), higurashi.get_player_heading(pid), 0), 1, 0, joaat("Prop_Armour_Pickup"), true, true, true, false)
            wait(f.value)
        end
    end)
    Higurashi.DropArmor.max = 10000
    Higurashi.DropArmor.min = 0
    Higurashi.DropArmor.mod = 100
    Higurashi.DropArmor.value = 500

    Higurashi.DropRepairKit = m.apf("Drop Repair Kit", "action", Higurashi.Friendly.id, function(f, pid)
        local pos = higurashi.get_player_coords(pid)
        --if NATIVE.CAN_REGISTER_MISSION_ENTITIES(0, 0, 0, 1) then
        local pickup = higurashi.create_ambient_pickup(joaat("PICKUP_VEHICLE_HEALTH_STANDARD_LOW_GLOW"), pos + v3(0.0, 0.0, 0.0), -1, 0, joaat("prop_ic_repair"), false, true, true, false)
        --end
    end)

    local function check_ped_gender(ped)
        local model_hash = NATIVE.GET_ENTITY_MODEL(ped)
        if model_hash == 0x705E61F2 then
            return "male"
        elseif model_hash == 0x9C9EFFD8 then
            return "female"
        else
            return "unknown"
        end
    end

    Higurashi.StealFace = m.apf("Steal Face", "action", Higurashi.Friendly.id, function(f, pid)
        local own_ped = NATIVE.PLAYER_PED_ID()
        local player_ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local own_gender = check_ped_gender(own_ped)
        local player_gender = check_ped_gender(player_ped)
        if own_gender == "is_not_mp_model" or player_gender == "is_not_mp_model" then
            m.n("Wrong model.", title, 2, c.red1)
            return
        end
        if own_gender ~= player_gender then
            m.n("You cannot steal the face of a player whose gender is different to yours.", title, 2, c.red1)
            return
        end
        local blend = ped.get_ped_head_blend_data(player_ped)
        if blend == nil then
            m.n("Head blend data not found.", title, 2, c.red1)
            return
        end
        NATIVE.SET_PED_HEAD_BLEND_DATA(own_ped, blend.shape_first,
            blend.shape_second, blend.shape_third,
            blend.skin_first, blend.skin_second,
            blend.skin_third, blend.mix_shape,
            blend.mix_skin, blend.mix_third)
        NATIVE.SET_HEAD_BLEND_EYE_COLOR(own_ped,
            NATIVE.GET_HEAD_BLEND_EYE_COLOR(player_ped))
        NATIVE.SET_PED_HAIR_TINT(own_ped, ped.get_ped_hair_color(player_ped),
            ped.get_ped_hair_highlight_color(player_ped))
        for i = 0, 19 do
            NATIVE.SET_PED_MICRO_MORPH(own_ped, i,
                ped.get_ped_face_feature(player_ped, i))
        end
        for i = 0, 12 do
            NATIVE.SET_PED_HEAD_OVERLAY(own_ped, i,
                NATIVE.GET_PED_HEAD_OVERLAY_VALUE(player_ped, i) or 0,
                ped.get_ped_head_overlay_opacity(player_ped, i) or 0)
            NATIVE.SET_PED_HEAD_OVERLAY_TINT(own_ped, i,
                ped.get_ped_head_overlay_color_type(player_ped, i) or 0,
                ped.get_ped_head_overlay_color(player_ped, i) or 0,
                ped.get_ped_head_overlay_highlight_color(player_ped, i) or 0)
        end
        m.n("Enjoy the new face.", title, 2, c.green1)
    end)

    Higurashi.StealFace.hint = "Clone the face feature of this player into your own ped, including their head blend."

    local function get_outfit(ped)
        local outfit = { components = {}, props = {} }
        for i = 0, 11 do
            outfit.components[i] = { NATIVE.GET_PED_DRAWABLE_VARIATION(ped, i), NATIVE.GET_PED_TEXTURE_VARIATION(ped, i) }
        end
        for i = 0, 9 do
            outfit.props[i] = { NATIVE.GET_PED_PROP_INDEX(ped, i), NATIVE.GET_PED_PROP_TEXTURE_INDEX(ped, i) }
        end
        return outfit
    end

    local function apply_outfit(components, props)
        for k, v in pairs(components) do
            NATIVE.SET_PED_COMPONENT_VARIATION(NATIVE.PLAYER_PED_ID(), tonumber(k), v[1], v[2], 0)
        end
        for k, v in pairs(props) do
            if v[1] == -1 then
                NATIVE.CLEAR_PED_PROP(NATIVE.PLAYER_PED_ID(), tonumber(k))
            else
                NATIVE.SET_PED_PROP_INDEX(NATIVE.PLAYER_PED_ID(), tonumber(k), v[1], v[2], true)
            end
        end
    end

    Higurashi.StealOutfit = m.apf("Steal Outfit", "action", Higurashi.Friendly.id, function(f, pid)
        local ped = NATIVE.GET_PLAYER_PED(pid)
        local outfit = get_outfit(ped)
        if check_ped_gender(NATIVE.PLAYER_PED_ID()) == "unknown" or check_ped_gender(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)) == "unknown" then
            m.n("Wrong model.", title, 2, c.red1)
            return
        else
            NATIVE.CLEAR_ALL_PED_PROPS(NATIVE.PLAYER_PED_ID())
            NATIVE.SET_PED_DEFAULT_COMPONENT_VARIATION(NATIVE.PLAYER_PED_ID())
            apply_outfit(outfit.components, outfit.props)
        end
        m.n("Enjoy the new outfit.", title, 2, c.green1)
    end)
    Higurashi.StealOutfit.hint = "Clone the outfit of this player into your own ped, including their hairstyle and make-up." .. c.orange2 .. "\nYou cannot steal the outfit of a player whose gender is different to yours."

    Higurashi.FriendlyRecovery = m.apf("Recovery", "parent", Higurashi.Friendly.id)
    Higurashi.FriendlyRecovery.hint = ""

    Higurashi.DropCash = m.apf("Drop Cash", "value_i", Higurashi.FriendlyRecovery.id, function(f, pid)
        while f.on do
            local pos = higurashi.get_player_coords(pid)
            local spawned_cash = higurashi.create_money_pickups(higurashi.offset_coords(v3(pos.x, pos.y, pos.z), higurashi.get_player_heading(pid), 0), 2500, 1, 0x9CA6F755)
            wait(f.value)
        end
    end)
    Higurashi.DropCash.max = 10000
    Higurashi.DropCash.min = 0
    Higurashi.DropCash.mod = 100
    Higurashi.DropCash.value = 500

    Higurashi.DropFigure = m.apf("Drop Figure", "value_i", Higurashi.FriendlyRecovery.id, function(f, pid)
        local model_hashes = { 0x4D6514A3, 0x748F3A2A, 0x1A9736DA, 0x3D1B7A2F, 0x1A126315, 0xD937A5E9, 0x23DDE6DB, 0x991F8C36 }
        while f.on do
            local pos = higurashi.get_player_coords(pid)
            local spawned_figure = higurashi.create_ambient_pickup(-1009939663, higurashi.offset_coords(v3(pos.x, pos.y, pos.z + 1.0), higurashi.get_player_heading(pid), 0), 0, 1, model_hashes[math.random(#model_hashes)], false, true, true, false)
            wait(f.value)
        end
    end)
    Higurashi.DropFigure.max = 10000
    Higurashi.DropFigure.min = 0
    Higurashi.DropFigure.mod = 100
    Higurashi.DropFigure.value = 500

    Higurashi.DropCard = m.apf("Drop Card", "value_i", Higurashi.FriendlyRecovery.id, function(f, pid)
        while f.on do
            local pos = higurashi.get_player_coords(pid)
            local spawned_card = higurashi.create_ambient_pickup(-1009939663, higurashi.offset_coords(v3(pos.x, pos.y, pos.z + 1.0), higurashi.get_player_heading(pid), 0), 0, 1, 0xB4A24065, false, true, true, false)
            wait(f.value)
        end
    end)
    Higurashi.DropCard.max = 10000
    Higurashi.DropCard.min = 0
    Higurashi.DropCard.mod = 100
    Higurashi.DropCard.value = 500

    Higurashi.FriendlyScriptEvent = m.apf("Script Events", "parent", Higurashi.Friendly.id)
    Higurashi.FriendlyScriptEvent.hint = ""

    m.apf("RP Loop", "toggle", Higurashi.FriendlyScriptEvent.id, function(f, pid)
        while f.on do
            for i = 21, 24 do
                higurashi_globals.send_script_event("Secret Asset", pid, { pid, pid, 4, i, 1, 1, 1 })
                higurashi_globals.send_script_event("Secret Asset", pid, { pid, pid, 8, -1, 1, 1, 1 })
            end
            wait(0)
        end
    end)

    m.apf("Never Wanted", "toggle", Higurashi.FriendlyScriptEvent.id, function(f, pid)
        while f.on do
            if NATIVE.GET_PLAYER_WANTED_LEVEL(pid) > 0 then
                higurashi_globals.remove_wanted2(pid)
            end
            wait(1000)
        end
    end)

    m.apf("Remove Wanted Level", "action_value_str", Higurashi.FriendlyScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.remove_wanted(pid)
        elseif f.value == 1 then
            higurashi_globals.remove_wanted2(pid)
        end
    end):set_str_data({ "V1", "V2" })

    m.apf("Give Off The Radar", "action", Higurashi.FriendlyScriptEvent.id, function(f, pid)
        higurashi_globals.off_the_radar(pid)
    end)



    m.apf("Give Collectables", "action_value_str", Higurashi.FriendlyScriptEvent.id, function(f, pid)
        local events_map = {
            [0] = { event = 0, count = 9 },
            [1] = { event = 1, count = 9 },
            [2] = { event = 2, count = 1 },
            [3] = { event = 3, count = 9 },
            [4] = { event = 4, count = 19 },
            [5] = { event = 5, count = 0 },
            [6] = { event = 6, count = 9 },
            [7] = { event = 9, count = 99 },
            [8] = { event = 10, count = 9 },
            [9] = { event = 4, count = 9 },
            [10] = { event = 16, count = 9 },
            [11] = { event = 17, count = 9 },
        }
        local function send_collectable_events(event, count)
            for i = 0, count do
                higurashi_globals.send_script_event("Secret Asset", pid, { 1, event, i, 1, 1, 1 })
                wait(1)
            end
        end

        local data = events_map[f.value]
        if data then
            send_collectable_events(data.event, data.count)
        end
    end):set_str_data({
        "Movie Props", "Hidden Caches", "Treasure Chests", "Radio Antennas", "Media USBs",
        "Shipwrecks", "Burried Stashes", "LD Organics Product", "Junk Energy Skydives",
        "Tuner Collectibles", "Snowmen", "G's Caches",
    })
    Higurashi.FriendlyVehicle = m.apf("Vehicle", "parent", Higurashi.Friendly.id)

    Higurashi.BoostPad = m.apf("Boost Pad", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        if f.on then
            local bloost_pad_obj = higurashi.create_object(joaat("stt_prop_track_speedup"), higurashi.get_player_coords(pid) + v3(0.0, 0.0, -0.8), true, false, false, true, false, false)
            local heading = higurashi.get_player_heading(pid)
            local heading = heading + 80.0
            NATIVE.SET_ENTITY_HEADING(bloost_pad_obj, heading)
            NATIVE.SET_ENTITY_VISIBLE(bloost_pad_obj, false, false)
            wait(300)
            higurashi.remove_entity({ bloost_pad_obj })
        end
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)

    Higurashi.SlowPad = m.apf("Slow Pad", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        if f.on then
            local slow_pad_obj = higurashi.create_object(joaat("stt_prop_track_slowdown"), higurashi.get_player_coords(pid) + v3(0.0, 0.0, -0.8), true, false, false, true, false, false)
            local heading = higurashi.get_player_heading(pid)
            local heading = heading + 80.0
            NATIVE.SET_ENTITY_HEADING(slow_pad_obj, heading)
            NATIVE.SET_ENTITY_VISIBLE(slow_pad_obj, false, false)
            wait(300)
            higurashi.remove_entity({ slow_pad_obj })
        end
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)

    local player_ground_water_obj

    m.apf("Drive On Water", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        if f.on then
            local pos = higurashi.get_player_coords(pid)
            if player_ground_water_obj == nil then
                player_ground_water_obj = higurashi.create_object(0x6CA1E917, pos + v3(0.0, 0.0, -3.5), true, false, false, false, false, false, true)
                NATIVE.SET_ENTITY_VISIBLE(player_ground_water_obj, false, false)
                NATIVE.SET_ENTITY_INVINCIBLE(player_ground_water_obj, true)
            end
            -- water.set_waves_intensity(-100000000)
            pos.z = -4.0
            higurashi.set_velocity_and_coords(player_ground_water_obj, pos)
        end
        if not f.on and player_ground_water_obj then
            --water.reset_waves_intensity()
            higurashi.remove_entity({ player_ground_water_obj })
            player_ground_water_obj = nil
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.PlayerHornBoost = m.apf("Horn Boost", "slider", Higurashi.FriendlyVehicle.id, function(f, pid)
        while f.on do
            wait(0)
            local veh = higurashi.get_player_vehicle(pid)
            if player.is_player_valid(pid) and
                NATIVE.IS_PED_IN_ANY_VEHICLE(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), true) and
                NATIVE.IS_PLAYER_PRESSING_HORN(pid) and
                higurashi.request_control_of_entity(veh) then
                NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, math.min(150, NATIVE.GET_ENTITY_SPEED(veh) + f.value))
                wait(550)
            end
        end
    end)
    Higurashi.PlayerHornBoost.hint = "This only works for players that are within 900 meters of you."
    Higurashi.PlayerHornBoost.max = 100
    Higurashi.PlayerHornBoost.min = 5
    Higurashi.PlayerHornBoost.mod = 5
    Higurashi.PlayerHornBoost.value = 25

    m.apf("Vehicle Customization", "action_value_str", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 and higurashi.request_control_of_entity(veh) then
            if f.value == 0 then
                higurashi.modify_vehicle(veh, "upgrade")
            elseif f.value == 1 then
                higurashi.modify_vehicle(veh, "downgrade")
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Upgrade", "Downgrade" })

    m.apf("Auto Repair", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        while f.on do
            local veh = higurashi.get_player_vehicle(pid, false)
            if veh ~= 0 then
                local health = NATIVE.GET_ENTITY_HEALTH(veh)
                local max_health = NATIVE.GET_ENTITY_MAX_HEALTH(veh)
                if health < max_health and higurashi.request_control_of_entity(veh) then
                    higurashi.repair_car(veh)
                end
            end
            wait(500)
        end
    end)

    m.apf("Repair Vehicle", "action", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 and higurashi.request_control_of_entity(veh) then
            higurashi.repair_car(veh)
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Remove Sticky Bombs", "action", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            NATIVE.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(veh, NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        end
    end)

    m.apf("Give Drift Mode", "action", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            NATIVE.SET_ENTITY_MAX_SPEED(veh, 30.0)
            NATIVE.MODIFY_VEHICLE_TOP_SPEED(veh, 200.0)
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Input Custom Max Speed", "action", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            local r, s = input.get("Enter a Speed value: ", "100.0", 64, 5)
            if r == 1 then return HANDLER_CONTINUE end
            if r == 2 then return HANDLER_POP end
            higurashi.request_control_of_entity(veh)
            NATIVE.SET_VEHICLE_MAX_SPEED(veh, s)
        else
            return
        end
    end)

    m.apf("Reset Max Speed", "action", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            local veh_model = NATIVE.GET_ENTITY_MODEL(veh)
            local get_veh_max_speed = NATIVE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(veh_model)
            NATIVE.MODIFY_VEHICLE_TOP_SPEED(veh, 1.0)
            NATIVE.SET_VEHICLE_MAX_SPEED(get_veh_max_speed, veh)
        else
            return
        end
    end)

    m.apf("Rapid Fire For Vehicle Weapons", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if f.on then
            wait(50)
            if veh ~= 0 then
                higurashi.request_control_of_entity(veh)
                NATIVE.SET_VEHICLE_FIXED(veh)
                NATIVE.SET_VEHICLE_DEFORMATION_FIXED(veh)
            end
        end
        return HANDLER_CONTINUE
    end)

    m.apf("Prevent Lock-On", "action_value_str", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            if f.value == 0 then
                NATIVE.SET_VEHICLE_CAN_BE_LOCKED_ON(veh, false, false)
                NATIVE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, false, false)
            elseif f.value == 1 then
                NATIVE.SET_VEHICLE_CAN_BE_LOCKED_ON(veh, true, true)
                NATIVE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, true, true)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    m.apf("Give Vehicle Godmode", "action_value_str", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            if f.value == 0 then
                NATIVE.SET_ENTITY_INVINCIBLE(veh, true)
                NATIVE.SET_ENTITY_CAN_BE_DAMAGED(veh, false)
                NATIVE.SET_ENTITY_PROOFS(veh, true, true, true, true, true, true, true, true, true)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(veh, true)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(veh, true)
                NATIVE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, false)
                NATIVE.SET_VEHICLE_CAN_BREAK(veh, false)
                NATIVE.SET_VEHICLE_ENGINE_CAN_DEGRADE(veh, false)
                NATIVE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(veh, false)
                NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
                NATIVE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, false)
                NATIVE.SET_ENTITY_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(veh, true, 0)
            elseif f.value == 1 then
                NATIVE.SET_ENTITY_INVINCIBLE(veh, false)
                NATIVE.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
                NATIVE.SET_ENTITY_PROOFS(veh, false, false, false, false, false, false, false, false, false)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(veh, false)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(veh, false)
                NATIVE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, true)
                NATIVE.SET_VEHICLE_CAN_BREAK(veh, true)
                NATIVE.SET_VEHICLE_ENGINE_CAN_DEGRADE(veh, true)
                NATIVE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(veh, true)
                NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, true)
                NATIVE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, true)
                NATIVE.SET_ENTITY_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(veh, false, 0)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    m.apf("Infinite F1 Boost", "toggle", Higurashi.FriendlyVehicle.id, function(f, pid)
        local f1_hashes = { 0x1446590A, 0x8B213907, 0x58F77553, 0x4669D038 }
        while f.on do
            local veh = higurashi.get_player_vehicle(pid)
            if veh ~= 0 then
                for x = 1, #f1_hashes do
                    if NATIVE.GET_ENTITY_MODEL(veh) == f1_hashes[x] then
                        higurashi.request_control_of_entity(veh)
                        NATIVE.SET_VEHICLE_FIXED(veh)
                    end
                end
            end
            wait(2500)
        end
    end)

    m.apf("Rocket Boost Refill", "action_value_str", Higurashi.FriendlyVehicle.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            if f.value == 0 then
                NATIVE.SET_VEHICLE_ROCKET_BOOST_REFILL_TIME(veh, 0.0000001)
                NATIVE.SET_VEHICLE_ROCKET_BOOST_PERCENTAGE(veh, 100.0)
            elseif f.value == 1 then
                NATIVE.SET_VEHICLE_ROCKET_BOOST_ACTIVE(veh, true)
                NATIVE.SET_VEHICLE_ROCKET_BOOST_REFILL_TIME(veh, 999999.0)
                NATIVE.SET_VEHICLE_ROCKET_BOOST_PERCENTAGE(veh, -999999.0)
            end
        end
    end):set_str_data({ "Fast", "Slow" })

    Higurashi.FriendlyWeapons = m.apf("Weapons", "parent", Higurashi.Friendly.id)
    Higurashi.FriendlyWeapons.hint = ""

    Higurashi.FriendlyWeaponLoadout = m.apf("Weapon Loadout", "parent", Higurashi.FriendlyWeapons.id)

    for i = 1, #higurashi_weapon.weapons do
        m.apf("Give: " .. higurashi_weapon.weapons[i][1], "action", Higurashi.FriendlyWeaponLoadout.id, function(f, pid)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.GET_PLAYER_PED(pid), higurashi_weapon.weapons[i][2], 9999, true)
        end)
    end

    Higurashi.ExplosiveAmmo = m.apf("Give Explosive Ammo", "value_str", Higurashi.FriendlyWeapons.id, function(f, pid)
        while f.on do
            if player.is_player_free_aiming(pid) and
                ped.is_ped_shooting(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)) then
                local _, pos = ped.get_ped_last_weapon_impact(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid))
                fire.add_explosion(pos, f.value, true, false, 0, NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid))
                -- higurashi.add_explosion(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), pos.x, pos.y, pos.z, f.value, 1.0, true, false, 1.0)
            end
            wait(0)
        end
    end):set_str_data({
        "GRENADE", "GRENADELAUNCHER", "STICKYBOMB", "MOLOTOV", "ROCKET", "TANKSHELL", "HI_OCTANE", "CAR", "PLANE", "PETROL_PUMP", "BIKE0", "DIR_STEAM", "DIR_FLAME", "DIR_WATER_HYDRANT", "DIR_GAS_CANISTER", "BOAT", "SHIP_DESTROY", "TRUCK", "BULLET", "SMOKEGRENADELAUNCHER", "SMOKEGRENADE0", "BZGAS", "FLARE", "GAS_CANISTER", "EXTINGUISHER", "_0x988620B8", "EXP_TAG_TRAIN", "EXP_TAG_BARREL", "EXP_TAG_PROPANE", "EXP_TAG_BLIMP", "EXP_TAG_DIR_FLAME_EXPLODE0", "EXP_TAG_TANKER", "PLANE_ROCKET",
        "EXP_TAG_VEHICLE_BULLET", "EXP_TAG_GAS_TANK", "EXP_TAG_BIRD_CRAP", "EXP_TAG_RAILGUN", "EXP_TAG_BLIMP2", "EXP_TAG_FIREWORK", "EXP_TAG_SNOWBALL", "EXP_TAG_PROXMINE0",
        "EXP_TAG_VALKYRIE_CANNON", "EXP_TAG_AIR_DEFENCE", "EXP_TAG_PIPEBOMB", "EXP_TAG_VEHICLEMINE", "EXP_TAG_EXPLOSIVEAMMO", "EXP_TAG_APCSHELL", "EXP_TAG_BOMB_CLUSTER", "EXP_TAG_BOMB_GAS", "EXP_TAG_BOMB_INCENDIARY", "EXP_TAG_BOMB_STANDARD0", "EXP_TAG_TORPEDO", "EXP_TAG_TORPEDO_UNDERWATER", "EXP_TAG_BOMBUSHKA_CANNON", "EXP_TAG_BOMB_CLUSTER_SECONDARY", "EXP_TAG_HUNTER_BARRAGE", "EXP_TAG_HUNTER_CANNON", "EXP_TAG_ROGUE_CANNON", "EXP_TAG_MINE_UNDERWATER", "EXP_TAG_ORBITAL_CANNON",
        "EXP_TAG_BOMB_STANDARD_WIDE0", "EXP_TAG_EXPLOSIVEAMMO_SHOTGUN", "EXP_TAG_OPPRESSOR2_CANNON", "EXP_TAG_MORTAR_KINETIC", "EXP_TAG_VEHICLEMINE_KINETIC", "EXP_TAG_VEHICLEMINE_EMP", "EXP_TAG_VEHICLEMINE_SPIKE", "EXP_TAG_VEHICLEMINE_SLICK", "EXP_TAG_VEHICLEMINE_TAR", "EXP_TAG_SCRIPT_DRONE", "EXP_TAG_RAYGUN0", "EXP_TAG_BURIEDMINE", "EXP_TAG_SCRIPT_MISSILE", "EXP_TAG_RCTANK_ROCKET", "EXP_TAG_BOMB_WATER", "EXP_TAG_BOMB_WATER_SECONDARY", "_0xF728C4A9", "_0xBAEC056F", "EXP_TAG_FLASHGRENADE",
        "EXP_TAG_STUNGRENADE", "_0x763D3B3B0", "EXP_TAG_SCRIPT_MISSILE_LARGE", "EXP_TAG_SUBMARINE_BIG", "EXP_TAG_EMPLAUNCHER_EMP",
    })

    m.apf("All Weapons", "action_value_str", Higurashi.FriendlyWeapons.id, function(f, pid)
        for _, weapon_hash in pairs(weapon.get_all_weapon_hashes()) do
            if f.value == 0 then
                higurashi_weapon.give_weapon_to(pid, weapon_hash, true)
            elseif f.value == 1 then
                higurashi_weapon.set_ped_weapon_attachments(NATIVE.PLAYER_PED_ID(), false, weapon_hash)
            end
        end
    end):set_str_data({ "Give", "Max" })

    m.apf("Give Infinite Parachutes", "toggle", Higurashi.FriendlyWeapons.id, function(f, pid)
        if f.on and
            weapon.has_ped_got_weapon(NATIVE.GET_PLAYER_PED(pid), 0xFBAB5776) == false then
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.GET_PLAYER_PED(pid), 0xFBAB5776, 1, false)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.Griefing = m.apf("Griefing", "parent", Higurashi.Parent1.id)
    Higurashi.Griefing.hint = "This is a collection of features that will allow you to annoy the player in many ways."

    Higurashi.KillGodModePlayer = m.apf("Kill Invulnerable Player", "value_str", Higurashi.Griefing.id, function(f, pid)
        local owner
        while f.on do
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            end
            if not NATIVE.IS_PLAYER_DEAD(pid) and owner ~= 0 then
                higurashi_globals.camera_forward(pid)
                wait(100)
                local pos = higurashi.get_player_coords(pid)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 58, 1000.0, false, true, 0.0)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 85, 1000.0, false, true, 0.0)
            end
            return HANDLER_CONTINUE
        end
    end):set_str_data({ "Anon", "Blamed" })

    m.apf("Make Nearby Peds Hostile", "toggle", Higurashi.Griefing.id, function(f, pid)
        if f.on then
            local ped_tracker = {}
            while f.on do
                wait(0)
                local player_ped = NATIVE.GET_PLAYER_PED(pid)
                local player_coords = NATIVE.GET_ENTITY_COORDS(player_ped, true)
                local count = 0
                for _, Ped in pairs(ped.get_all_peds()) do
                    if not NATIVE.IS_PED_A_PLAYER(Ped) and not NATIVE.DECOR_EXIST_ON(Ped, "Skill_Blocker") and higurashi.force_control_of_entity(Ped) then
                        local ped_coords = NATIVE.GET_ENTITY_COORDS(Ped, true)
                        local distance = NATIVE.GET_DISTANCE_BETWEEN_COORDS(player_coords.x, player_coords.y, player_coords.z, ped_coords.x, ped_coords.y, ped_coords.z, true)
                        if distance <= 150.0 then
                            if not ped_tracker[Ped] then
                                count = count + 1
                                NATIVE.GIVE_DELAYED_WEAPON_TO_PED(Ped, 0xD1D5F52B, 9999, true)
                                NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(Ped, false)
                                higurashi.set_combat_attributes(Ped, true, {})
                                NATIVE.TASK_COMBAT_PED(Ped, NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
                                NATIVE.SET_PED_CAN_RAGDOLL(Ped, false)
                                NATIVE.TASK_SHOOT_AT_ENTITY(Ped, player_ped, -1, joaat("FIRING_PATTERN_FULL_AUTO"))
                                ped_tracker[Ped] = true
                                if count == 20 then break end
                            end
                        end
                    end
                    if not f.on then break end
                end
            end
            for Ped in pairs(ped_tracker) do
                if NATIVE.IS_ENTITY_A_PED(Ped) and not NATIVE.DECOR_EXIST_ON(Ped, "Skill_Blocker") and higurashi.force_control_of_entity(Ped) then
                    NATIVE.REMOVE_ALL_PED_WEAPONS(Ped, false)
                    higurashi.clear_ped_tasks_and_wander(Ped)
                end
            end
        end
    end)

    Higurashi.GlitchPhysics = m.apf("Glitch Physics", "toggle", Higurashi.Griefing.id, function(f, pid)
        if f.on then
            local pos = higurashi.get_player_coords(pid)
            local glitch_obj = higurashi.create_object(joaat("prop_ld_ferris_wheel"), pos, true, false, false, false, false, false, true)
            NATIVE.SET_ENTITY_VISIBLE(glitch_obj, false)
            NATIVE.SET_ENTITY_INVINCIBLE(glitch_obj, true)
            NATIVE.SET_ENTITY_COLLISION(glitch_obj, true, true)
            local glitch_veh = higurashi.create_vehicle(joaat("rallytruck"), pos, 0, true, false, false, false, false, false, true)
            NATIVE.SET_ENTITY_VISIBLE(glitch_veh, false)
            wait(50)
            higurashi.remove_entity({ glitch_obj, glitch_veh })
            wait(50)
        end
        return f.on and HANDLER_CONTINUE or HANDLER_POP
    end)

    m.apf("Carpet Bombing", "action_value_str", Higurashi.Griefing.id, function(f, pid)
        local bomb_types = {
            [0] = { type = joaat("VEHICLE_WEAPON_BOMB"), model = "w_smug_bomb_01" },
            [1] = { type = joaat("VEHICLE_WEAPON_BOMB_CLUSTER"), model = "w_smug_bomb_02" },
            [2] = { type = joaat("VEHICLE_WEAPON_BOMB_GAS"), model = "w_smug_bomb_03" },
            [3] = { type = joaat("VEHICLE_WEAPON_BOMB_INCENDIARY"), model = "w_smug_bomb_04" },
        }
        local selected_bomb = bomb_types[f.value]
        higurashi.request_weapon_asset(selected_bomb.type)
        higurashi.request_model(selected_bomb.model, 0)
        local veh = higurashi.create_vehicle(joaat("bombushka"), NATIVE.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(NATIVE.GET_PLAYER_PED(pid), 0.0, -150.0, 80.0), higurashi.get_player_heading(pid), true, false, true, false, false, false, true)
        local spawned_ped = higurashi.create_ped_inside_vehicle(veh, -1, 0xAB300C07, -1, true, false, true, false, false, true)
        NATIVE.SET_ENTITY_CAN_BE_DAMAGED(veh, false)
        NATIVE.DISABLE_VEHICLE_WORLD_COLLISION(veh)
        NATIVE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        NATIVE.CONTROL_LANDING_GEAR(veh, 3)
        NATIVE.SET_HELI_BLADES_FULL_SPEED(veh)
        NATIVE.SET_PLANE_TURBULENCE_MULTIPLIER(veh, 0.0)
        NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, NATIVE.GET_VEHICLE_ESTIMATED_MAX_SPEED(veh))
        NATIVE.OPEN_BOMB_BAY_DOORS(veh)
        for i = 1, 60 do
            NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, NATIVE.GET_VEHICLE_ESTIMATED_MAX_SPEED(veh))
            NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(NATIVE.GET_ENTITY_COORDS(veh) + v3(0.0, 0.0, -2.0), higurashi.get_player_coords(pid), 999999, true, selected_bomb.type, spawned_ped, true, false, 1.0)
            wait(150)
        end
        NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, 110.0)
        wait(1200)
        NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, 130.0)
        wait(300)
        higurashi.remove_entity({ veh, spawned_ped })
        NATIVE.REMOVE_WEAPON_ASSET(selected_bomb.type)
    end):set_str_data({ "Standard Bomb", "Cluster Bomb", "Gas Bomb", "Incendiary Bomb" })

    m.apf("Send To Sky", "action", Higurashi.Griefing.id, function(f, pid)
        player.teleport_player_on_foot(pid, v3(0.0, 0.0, 0.0 + 99999.0))
    end)

    Higurashi.Assassins = m.apf("Send Attackers", "parent", Higurashi.Griefing.id)
    Higurashi.Assassins.hint = "Send attackers to the player."

    local attacker_godmode

    Higurashi.SetAssassinGodmode = m.apf("Make The Attackers Godmode", "autoaction_value_str", Higurashi.Assassins.id, function(f, pid)
        if f.value == 0 then
            attacker_godmode = false
        elseif f.value == 1 then
            attacker_godmode = true
        end
    end):set_str_data({ "Disable", "Enable" })

    local attacker_models = { "G_M_M_Slasher_01", "MP_M_FIBSec_01", "U_M_Y_Pogo_01", "U_M_M_StreetArt_01", "A_C_Chimp_02", "IG_LesterCrest", "U_M_M_YuleMonster", "A_C_Panther", "U_M_Y_ImpoRage", "U_M_M_Yeti" }
    local attacker_veh_models = { "Lazer", "fbi", "thruster", "blista3", "rcbandito" }

    m.apf("Air Raid", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_veh = {}
        local attacker_model = joaat("G_M_M_Slasher_01")
        local attacker_veh_model = joaat("Lazer")
        local player_pos = higurashi.get_player_coords(pid)
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-45, 45)
        player_pos.y = player_pos.y + math.random(-130, 130)
        player_pos.z = player_pos.z + math.random(120, 120)
        attacker_veh[1] = higurashi.create_vehicle(attacker_veh_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, false, true, false)
        NATIVE.DECOR_SET_INT(attacker_veh[1], "Skill_Blocker", -1)
        NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(attacker_veh[1], true)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker_veh[1], attacker_godmode or false)
        attacker[1] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, -1, true, false, true, false)
        NATIVE.DECOR_SET_INT(attacker[1], "Skill_Blocker", -1)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker[1], attacker_godmode or false)
        NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[1], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
        higurashi.set_combat_mode(attacker[1], { 1, 2, 5, 20, 46, 52 }, 9999.0, 4, 2, 100, 100.0, joaat("army"), true)
        NATIVE.TASK_COMBAT_PED(attacker[1], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
    end)

    m.apf("FIB", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_veh = {}
        local attacker_model = joaat("MP_M_FIBSec_01")
        local attacker_veh_model = joaat("fbi")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-10, 10)
        player_pos.y = player_pos.y + math.random(-10, 10)
        attacker_veh[1] = higurashi.create_vehicle(attacker_veh_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, false, true, false)
        NATIVE.DECOR_SET_INT(attacker_veh[1], "Skill_Blocker", -1)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker_veh[1], attacker_godmode or false)
        attacker[1] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, -1, true, false, true, false)
        attacker[2] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, higurashi.get_empty_seats(attacker_veh[1]), true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_CAN_RAGDOLL(attacker[i], false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], false)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_TACTICALRIFLE"), 9999, true)
            higurashi.set_combat_mode(attacker[1], { 1, 2, 3, 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("cop"), true)
            NATIVE.SET_PED_AS_COP(attacker[i], true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
        end
    end)

    m.apf("Flying Pogo", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_veh = {}
        local attacker_model = joaat("U_M_Y_Pogo_01")
        local attacker_veh_model = joaat("thruster")
        local player_pos = higurashi.get_player_coords(pid)
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-35, 35)
        player_pos.y = player_pos.y + math.random(-95, 95)
        player_pos.z = player_pos.z + math.random(45, 55)
        attacker_veh[1] = higurashi.create_vehicle(attacker_veh_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, false, true, false)
        NATIVE.DECOR_SET_INT(attacker_veh[1], "Skill_Blocker", -1)
        higurashi.modify_vehicle(attacker_veh[1], "upgrade")
        NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(attacker_veh[1], true)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker_veh[1], attacker_godmode or false)
        attacker[1] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, -1, true, false, true, false)
        NATIVE.DECOR_SET_INT(attacker[1], "Skill_Blocker", -1)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker[1], attacker_godmode or false)
        NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[1], false)
        NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[1], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
        higurashi.set_combat_mode(attacker[1], { 1, 2, 5, 20, 46, 52 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
        NATIVE.TASK_COMBAT_PED(attacker[1], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
    end)

    m.apf("Captain", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_veh = {}
        local attacker_model = joaat("U_M_M_StreetArt_01")
        local attacker_veh_model = joaat("blista3")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-7, 7)
        player_pos.y = player_pos.y + math.random(-7, 7)
        attacker_veh[1] = higurashi.create_vehicle(attacker_veh_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, false, true, false)
        NATIVE.DECOR_SET_INT(attacker_veh[1], "Skill_Blocker", -1)
        higurashi.modify_vehicle(attacker_veh[1], "upgrade")
        NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(attacker_veh[1], true)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker_veh[1], attacker_godmode or false)
        attacker[1] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, -1, true, false, true, false)
        NATIVE.DECOR_SET_INT(attacker[1], "Skill_Blocker", -1)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker[1], attacker_godmode or false)
        NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[1], false)
        NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[1], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
        NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[1], joaat("WEAPON_STUNGUN"), 9999, true)
        higurashi.set_combat_mode(attacker[1], { 1, 2, 5, 20, 46, 52 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
        NATIVE.TASK_COMBAT_PED(attacker[1], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 67108864  | 1073741824, 16)
    end)

    m.apf("Chimp", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_model = joaat("A_C_Chimp_02")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-3, 3)
        player_pos.y = player_pos.y + math.random(-3, 3)
        attacker[1] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[2] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[3] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_CAN_RAGDOLL(attacker[i], false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], false)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_STUNROD"), 9999, true)
            higurashi.set_combat_mode(attacker[i], { 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1073741824, 1073741824)
        end
    end)

    m.apf("Lester", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_model = joaat("IG_LesterCrest")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-3, 3)
        player_pos.y = player_pos.y + math.random(-3, 3)
        attacker[1] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[2] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[3] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_CAN_RAGDOLL(attacker[i], false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], true)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_STUNGUN"), 9999, true)
            higurashi.set_combat_mode(attacker[i], { 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1073741824, 1073741824)
        end
    end)

    m.apf("Gooch", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_model = joaat("U_M_M_YuleMonster")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-3, 3)
        player_pos.y = player_pos.y + math.random(-3, 3)
        attacker[1] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[2] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[3] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], true)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_SNOWBALL"), 9999, true)
            higurashi.set_combat_mode(attacker[i], { 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
        end
    end)

    m.apf("Panther", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_model = joaat("A_C_Panther")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-3, 3)
        player_pos.y = player_pos.y + math.random(-3, 3)
        attacker[1] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_CAN_RAGDOLL(attacker[i], false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], false)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_COUGAR"), 9999, true)
            higurashi.set_combat_mode(attacker[i], { 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 67108864  | 1073741824, 16)
        end
    end)

    m.apf("RCV", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_veh = {}
        local attacker_model = joaat("U_M_Y_ImpoRage")
        local attacker_veh_model = joaat("rcbandito")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-7, 7)
        player_pos.y = player_pos.y + math.random(-7, 7)
        attacker_veh[1] = higurashi.create_vehicle(attacker_veh_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, false, true, false)
        NATIVE.DECOR_SET_INT(attacker_veh[1], "Skill_Blocker", -1)
        higurashi.modify_vehicle(attacker_veh[1], "upgrade")
        NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(attacker_veh[1], true)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker_veh[1], attacker_godmode or false)
        attacker[1] = higurashi.create_ped_inside_vehicle(attacker_veh[1], -1, attacker_model, -1, true, false)
        NATIVE.DECOR_SET_INT(attacker[1], "Skill_Blocker", -1)
        NATIVE.SET_ENTITY_INVINCIBLE(attacker[1], attacker_godmode or false)
        NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[1], false)
        NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[1], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
        NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[1], joaat("WEAPON_PIPEBOMB"), 9999, true)
        higurashi.set_combat_mode(attacker[1], { 1, 2, 5, 20, 46, 52 }, 9999.0, 4, 3, 100, 100.0, joaat("army"), true)
        NATIVE.TASK_COMBAT_PED(attacker[1], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 16 | 1073741824, 16)
    end)

    m.apf("Yeti", "action", Higurashi.Assassins.id, function(f, pid)
        local attacker = {}
        local attacker_model = joaat("U_M_M_Yeti")
        local player_pos = higurashi.get_player_coords(pid)
        player_pos.x = player_pos.x + math.random(-3, 3)
        player_pos.y = player_pos.y + math.random(-3, 3)
        attacker[1] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[2] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        attacker[3] = higurashi.create_ped(-1, attacker_model, v3(player_pos.x, player_pos.y, player_pos.z), 0, true, false, true, false)
        for i = 1, #attacker do
            NATIVE.DECOR_SET_INT(attacker[i], "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(attacker[i], attacker_godmode or false)
            NATIVE.SET_PED_CAN_RAGDOLL(attacker[i], false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(attacker[i], false)
            NATIVE.TASK_GO_TO_COORD_ANY_MEANS(attacker[i], player_pos.x, player_pos.y, player_pos.z, 5.0, 0, false, 0, 0.0)
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(attacker[i], joaat("WEAPON_SNOWLAUNCHER"), 9999, true)
            higurashi.set_combat_mode(attacker[i], { 5, 46 }, 9999.0, 4, 2, 100, 100.0, joaat("HATES_PLAYER"), true)
            NATIVE.TASK_COMBAT_PED(attacker[i], NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 67108864  | 1073741824, 16)
        end
    end)


    m.apf("Delete All Attackers", "action", Higurashi.Assassins.id, function(f, pid)
        for _, peds in pairs(ped.get_all_peds()) do
            for i = 1, #attacker_models do
                if NATIVE.GET_ENTITY_MODEL(peds) == joaat(attacker_models[i]) and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                    higurashi.remove_entity({ peds })
                end
            end
        end
        for _, vehs in pairs(vehicle.get_all_vehicles()) do
            for i = 1, #attacker_veh_models do
                if NATIVE.GET_ENTITY_MODEL(vehs) == joaat(attacker_veh_models[i]) and NATIVE.DECOR_EXIST_ON(vehs, "Skill_Blocker") then
                    higurashi.remove_entity({ vehs })
                end
            end
        end
    end)

    Higurashi.Cages = m.apf("Cages", "parent", Higurashi.Griefing.id)
    Higurashi.Cages.hint =
    "Spawn a cage around this player, trapping them inside with no possibility to move."

    m.apf("Container", "action_value_str", Higurashi.Cages.id, function(f, pid)
        if f.value == 0 then
            local cage_object = {}
            NATIVE.DECOR_REGISTER("Skill_Blocker", 3)
            local pos = higurashi.get_player_coords(pid)
            pos.z = pos.z - 1.0
            cage_object[1] = higurashi.create_object(joaat("prop_gold_cont_01"), pos, true, false, false, true, false)
            local rot = entity.get_entity_rotation(cage_object[1])
            entity.set_entity_rotation(cage_object[1], rot)
            NATIVE.FREEZE_ENTITY_POSITION(cage_object[1], true)
            NATIVE.DECOR_SET_INT(cage_object[1], "Skill_Blocker", -1)
        elseif f.value == 1 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_gold_cont_01") and
                    NATIVE.DECOR_EXIST_ON(objs, "Skill_Blocker") then
                    higurashi.remove_entity({ objs })
                end
            end
        end
    end):set_str_data({ "Spawn", "Delete" })

    m.apf("Cage", "action_value_str", Higurashi.Cages.id, function(f, pid)
        if f.value == 0 then
            local cage_object = {}
            NATIVE.DECOR_REGISTER("Skill_Blocker", 3)
            local cage_obj_hash = joaat("prop_rub_cage01a")
            local pos = higurashi.get_player_coords(pid)
            cage_object[1] = higurashi.create_object(cage_obj_hash, v3(pos.x, pos.y, pos.z - 1.0), true, false, false, true, false)
            cage_object[2] = higurashi.create_object(cage_obj_hash, v3(pos.x, pos.y, pos.z + 1.2), true, false, false, true, false)
            NATIVE.SET_ENTITY_ROTATION(cage_object[2], -180.0, NATIVE.GET_ENTITY_ROTATION(cage_object[2], 2).y, 90.0, 1, true)
            for i = 1, #cage_object do
                NATIVE.FREEZE_ENTITY_POSITION(cage_object[i], true)
                NATIVE.DECOR_SET_INT(cage_object[i], "Skill_Blocker", -1)
            end
        elseif f.value == 1 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_rub_cage01a") and
                    NATIVE.DECOR_EXIST_ON(objs, "Skill_Blocker") then
                    higurashi.remove_entity({ objs })
                end
            end
        end
    end):set_str_data({ "Spawn", "Delete" })

    m.apf("Paragon", "action_value_str", Higurashi.Cages.id, function(f, pid)
        if f.value == 0 then
            local cage_object = {}
            NATIVE.DECOR_REGISTER("Skill_Blocker", 3)
            local pos = higurashi.get_player_coords(pid)
            pos.z = pos.z + 0.50
            cage_object[1] = higurashi.create_object(joaat("prop_feeder1_cr"), pos, true, false, false, true, false)
            NATIVE.FREEZE_ENTITY_POSITION(cage_object[1], true)
            NATIVE.DECOR_SET_INT(cage_object[1], "Skill_Blocker", -1)
        elseif f.value == 1 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_feeder1_cr") and
                    NATIVE.DECOR_EXIST_ON(objs, "Skill_Blocker") then
                    higurashi.remove_entity({ objs })
                end
            end
        end
    end):set_str_data({ "Spawn", "Delete" })

    m.apf("Fence", "action_value_str", Higurashi.Cages.id, function(f, pid)
        if f.value == 0 then
            local cage_object = {}
            NATIVE.DECOR_REGISTER("Skill_Blocker", 3)
            local cage_obj_hash = joaat("prop_fnclink_03e")
            local pos = higurashi.get_player_coords(pid)
            pos.z = pos.z - 1.0
            cage_object[1] = higurashi.create_object(cage_obj_hash, v3(pos.x - 1.5, pos.y + 1.5, pos.z), true, false, false, true, false)
            cage_object[2] = higurashi.create_object(cage_obj_hash, v3(pos.x - 1.5, pos.y - 1.5, pos.z), true, false, false, true, false)
            cage_object[3] = higurashi.create_object(cage_obj_hash, v3(pos.x + 1.5, pos.y + 1.5, pos.z), true, false, false, true, false)
            local rot_3 = NATIVE.GET_ENTITY_ROTATION(cage_object[3], 2)
            rot_3.z = -90.0
            NATIVE.SET_ENTITY_ROTATION(cage_object[3], rot_3.x, rot_3.y, rot_3.z, 1, true)
            cage_object[4] = higurashi.create_object(cage_obj_hash, v3(pos.x - 1.5, pos.y + 1.5, pos.z), true, false, false, true, false)
            local rot_4 = NATIVE.GET_ENTITY_ROTATION(cage_object[4], 2)
            rot_4.z = -90.0
            NATIVE.SET_ENTITY_ROTATION(cage_object[4], rot_4.x, rot_4.y, rot_4.z, 1, true)
            for i = 1, #cage_object do
                NATIVE.FREEZE_ENTITY_POSITION(cage_object[i], true)
                NATIVE.DECOR_SET_INT(cage_object[i], "Skill_Blocker", -1)
            end
        elseif f.value == 1 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_fnclink_03e") and
                    NATIVE.DECOR_EXIST_ON(objs, "Skill_Blocker") then
                    higurashi.remove_entity({ objs })
                end
            end
        end
    end):set_str_data({ "Spawn", "Delete" })

    m.apf("Delete All Cages", "action", Higurashi.Cages.id, function(f, pid)
        local cage_hashes = { "prop_gold_cont_01", "prop_rub_cage01a", "prop_feeder1_cr", "prop_fnclink_03e" }
        for i = 1, #cage_hashes do
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat(cage_hashes[i]) and
                    NATIVE.DECOR_EXIST_ON(objs, "Skill_Blocker") then
                    higurashi.remove_entity({ objs })
                end
            end
        end
        m.n("All cages cleared.", title, 3, c.blue1)
    end)

    Higurashi.Explode = m.apf("Explode", "parent", Higurashi.Griefing.id)
    Higurashi.Explode.hint = "Blow up this player."

    local function update_player_list1()
        valid_players = {}
        local player_table = {}
        for pid = 0, 31 do
            if player.is_player_valid(pid) then
                player_table[#player_table + 1] = higurashi.get_user_name(pid) .. " (" .. pid .. ")"
                valid_players[#valid_players + 1] = pid
            end
        end
        Higurashi.SpecificPlayer1:set_str_data(player_table)
    end

    event.add_event_listener("player_join", function()
        update_player_list1()
    end)

    event.add_event_listener("player_leave", function()
        update_player_list1()
    end)

    Higurashi.SpecificPlayer1 = m.apf("Satellite Cannon Owner:", "autoaction_value_str", Higurashi.Explode.id, function(f)
        BlamedPID1 = tonumber(f.str_data[f.value + 1]:match(".*%((%d+)%)"))
    end)

    Higurashi.SpecificPlayer1.hint = "If you select the Blamed variant, you will show up as the killer."

    update_player_list1()

    Higurashi.SatelliteCannon = m.apf("Satellite Cannon", "action", Higurashi.Explode.id, function(f, pid)
        local blame = NATIVE.GET_PLAYER_PED(BlamedPID1)
        local pos = higurashi.get_player_coords(pid)
        NATIVE.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, "", true, 100, true)
        higurashi.set_ptfx_asset("scr_xm_orbital")
        -- NATIVE.USE_PARTICLE_FX_ASSET("scr_xm_orbital")
        local ptfx1 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("scr_xm_orbital_blast", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 3.0, false, false, false, false)
        fire.add_explosion(pos, 82, true, false, 2, blame)
        fire.add_explosion(pos, 47, true, false, 2, blame)
        fire.add_explosion(pos, 48, true, false, 2, blame)
        fire.add_explosion(pos, 49, true, false, 2, blame)
        fire.add_explosion(pos, 59, true, false, 2, blame)
        fire.add_explosion(pos + v3(-10.0, 0.0, 5.0), 59, true, false, 2, blame)
        fire.add_explosion(pos + v3(0.0, -10.0, 5.0), 59, true, false, 2, blame)
        fire.add_explosion(pos + v3(10.0, 0.0, 5.0), 59, true, false, 3, blame)
        fire.add_explosion(pos + v3(0.0, 10.0, 5.0), 59, true, false, 3, blame)
        wait(100)
        higurashi.set_ptfx_asset("scr_xm_submarine")
        -- NATIVE.USE_PARTICLE_FX_ASSET("scr_xm_submarine")
        local ptfx2 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("scr_xm_submarine_explosion", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 8.0, false, false, false, false)
        fire.add_explosion(pos, 58, true, false, 2, blame)
        fire.add_explosion(pos, 82, true, false, 2, blame)
        fire.add_explosion(pos, 83, true, false, 2, blame)
        higurashi.set_ptfx_asset("core")
        --NATIVE.USE_PARTICLE_FX_ASSET("core")
        local ptfx3 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("exp_grd_molotov", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 6.0, false, false, false, false)
        wait(1500)
        NATIVE.REMOVE_NAMED_PTFX_ASSET("scr_xm_orbital")
        NATIVE.REMOVE_NAMED_PTFX_ASSET("scr_xm_submarine")
        NATIVE.REMOVE_NAMED_PTFX_ASSET("core")
    end)
    Higurashi.SatelliteCannon.hint = ""

    m.apf("Ragdoll", "action_value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.value == 0 then
            owner = higurashi.get_random_ped()
        elseif f.value == 1 then
            owner = NATIVE.PLAYER_PED_ID()
        elseif f.value == 2 then
            owner = NATIVE.GET_PLAYER_PED(pid)
        end
        higurashi.add_explosion(owner, higurashi.get_player_bone_coords(pid, 31086), 13, 1.0, false, true, 0.0)
    end):set_str_data({ "Anon", "Blamed", "Player" })

    m.apf("Remote Sniper", "value_str", Higurashi.Explode.id, function(f, pid)
        local weapon = joaat("WEAPON_REMOTESNIPER")
        local owner
        higurashi.request_weapon_asset(weapon)
        while f.on do
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            if not NATIVE.IS_PLAYER_DEAD(pid) then
                NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(higurashi.get_player_bone_coords(pid, 31086), higurashi.get_player_bone_coords(pid, 0, v3(0.0, 0.0, -0.5)), 10000, true, weapon, owner, false, true, 1.0)
            end
            wait(500)
            return HANDLER_CONTINUE
        end
    end):set_str_data({ "Anon", "Blamed", "Player" })

    m.apf("Tranquilizer", "value_str", Higurashi.Explode.id, function(f, pid)
        local weapon = joaat("weapon_tranquilizer")
        local owner
        higurashi.request_weapon_asset(weapon)
        while f.on do
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            if not NATIVE.IS_PLAYER_DEAD(pid) then
                NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(higurashi.get_player_bone_coords(pid, 11816), higurashi.get_player_bone_coords(pid, 39317), 1, true, weapon, owner, false, true, 1.0)
            end
            wait(500)
            return HANDLER_CONTINUE
        end
    end):set_str_data({ "Anon", "Blamed", "Player" })

    m.apf("Snowball", "value_str", Higurashi.Explode.id, function(f, pid)
        local weapon = joaat("WEAPON_SNOWLAUNCHER")
        local owner
        higurashi.request_weapon_asset(weapon)
        while f.on do
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
            end
            if not NATIVE.IS_PLAYER_DEAD(pid) then
                higurashi.shoot_bullet(higurashi.get_player_bone_coords(pid, 11816), higurashi.get_player_bone_coords(pid, 39317), 0, true, weapon, owner, true, false, 10000.0)
            end
            wait(100)
            return HANDLER_CONTINUE
        end
    end):set_str_data({ "Anon", "Blamed", "Player" })

    m.apf("Stun", "value_str", Higurashi.Explode.id, function(f, pid)
        local weapon = joaat("WEAPON_STUNGUN_MP")
        local owner
        higurashi.request_weapon_asset(weapon)
        while f.on do
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            if not NATIVE.IS_PLAYER_DEAD(pid) then
                NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(higurashi.get_player_bone_coords(pid, 0, v3(0.0, 0.0, -0.5)), higurashi.get_player_bone_coords(pid, 0, v3(0.0, 0.0, 0.5)), 0, true, weapon, owner, false, true, 1.0)
            end
            wait(500)
            return HANDLER_CONTINUE
        end
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeFirework = m.apf("Special Firework", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            wait(10)
            local pos = higurashi.get_player_coords(pid)
            NATIVE.PLAY_SOUND_FROM_COORD(-1, "FestiveGift", pos, "Feed_Message_Sounds", true, 10, true)
            higurashi.start_ptfx_non_looped_at_coord("core", "ent_dst_gen_gobstop", pos.x, pos.y, pos.z, v3(), 3.0, true, true, true)
            higurashi.start_ptfx_non_looped_at_coord("scr_rcbarry2", "scr_clown_bul", pos.x, pos.y, pos.z, v3(), 2.0, true, true, true)
            higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 38, 1.0, false, true, 0)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeTsunami = m.apf("Tsunami", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            wait(10)
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            local pos = higurashi.get_player_coords(pid)
            higurashi.start_ptfx_non_looped_at_coord("scr_xm_submarine", "scr_xm_submarine_surface_explosion", pos.x, pos.y, pos.z, v3(), 6.0, true, true, true)
            higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 52, 1000.0, true, true, 1)
            higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 58, 1000.0, true, true, 1)
            higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 74, 1000.0, true, true, 1)
            higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 75, 1000.0, true, true, 1)
            higurashi.start_ptfx_non_looped_at_coord("scr_trevor1", "scr_trev1_trailer_splash", pos.x, pos.y, pos.z, v3(), 6.0, true, true, true)
            audio.play_sound_from_entity(-1, "FallingInWaterHeavy", NATIVE.GET_PLAYER_PED(pid), "GTAO_Hot_Tub_PED_INSIDE_WATER", true)
            audio.play_sound_from_entity(-1, "DiveInWater", NATIVE.GET_PLAYER_PED(pid), "GTAO_Hot_Tub_PED_INSIDE_WATER", true)
            higurashi.start_ptfx_non_looped_at_coord("core", "water_splash_plane_in", pos.x, pos.y, pos.z, v3(), 5.0, true, true, true)
            wait(250)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeAcidBomb = m.apf("Acid Bomb", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            wait(100)
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            for x = 20, 0, -5 do
                local pos = higurashi.get_player_coords(pid)
                NATIVE.PLAY_SOUND_FROM_COORD(-1, "Shard_Disappear", pos, "GTAO_FM_Events_Soundset", true, 10, true)
                NATIVE.PLAY_SOUND_FROM_COORD(-1, "PIPES_LAND", pos, "CONSTRUCTION_ACCIDENT_1_SOUNDS", true, 10, true)
                fire.add_explosion(pos, 21, true, false, 0, owner)
                fire.add_explosion(pos, 48, false, false, 0, owner)
                wait(10)
                higurashi.start_ptfx_non_looped_at_coord("scr_michael2", "scr_acid_bath_splash", pos, v3(), 3, true, true, true)
                NATIVE.PLAY_SOUND_FROM_COORD(-1, "Shard_Disappear", pos, "GTAO_FM_Events_Soundset", true, 10, true)
                NATIVE.PLAY_SOUND_FROM_COORD(-1, "PIPES_LAND", pos, "CONSTRUCTION_ACCIDENT_1_SOUNDS", true, 10, true)
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeAtomizer = m.apf("Atomizer", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            wait(10)
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            local pos = higurashi.get_player_coords(pid)
            NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(pos + v3(0.0, 0.0, 20.0), pos, 999, 0xAF3696A1, owner, false, true, 999.0)
            wait(10)
            fire.add_explosion(pos, 70, true, false, 0, owner)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeDoubleTrouble = m.apf("Double Trouble", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            wait(10)
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            for x = 35, 0, -5 do
                wait(40)
                local pos = higurashi.get_player_coords(pid)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 13, 1.0, true, false, 0.0)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 14, 1.0, true, false, 0.0)
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeDragonBreath = m.apf("Dragon Breath", "value_str", Higurashi.Explode.id, function(f, pid)
        if not f.on then return HANDLER_POP end
        local owner
        wait(10)
        if f.value == 0 then
            owner = higurashi.get_random_ped()
        elseif f.value == 1 then
            owner = NATIVE.PLAYER_PED_ID()
        elseif f.value == 2 then
            owner = NATIVE.GET_PLAYER_PED(pid)
        end
        for x = 70, 0, -1 do
            wait(30)
            local pos = higurashi.get_player_coords(pid)
            pos.z = pos.z + x
            local explosions = {
                { type = 14, damage = 1000.0, isAudible = true, isInvis = false },
                { type = 3, damage = 1000.0, isAudible = false, isInvis = false },
                { type = 30, damage = 1000.0, isAudible = true, isInvis = false },
                { type = 14, damage = 1000.0, isAudible = true, isInvis = false },
                { type = 14, damage = 1000.0, isAudible = true, isInvis = false },
            }
            for _, explosion in ipairs(explosions) do
                higurashi.add_explosion(owner, pos, explosion.type, explosion.damage, explosion.isAudible, explosion.isInvis, 0)
            end
        end
        return HANDLER_CONTINUE
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeKnuckleCluster = m.apf("Knuckle Cluster", "value_str", Higurashi.Explode.id, function(f, pid)
        if f.on then
            wait(200)

            local owner
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end

            local pos = higurashi.get_player_coords(pid)
            pos.x = math.floor(pos.x)
            pos.y = math.floor(pos.y)
            pos.z = math.floor(pos.z)

            for x = 15, 0, -1 do
                local explosions = { 63, 64, 65, 66, 67, 68, 83 }
                for _, exp in ipairs(explosions) do
                    fire.add_explosion(pos, exp, true, false, 0, owner)
                end
            end

            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.ExplodeMeteor = m.apf("Meteor", "value_str", Higurashi.Explode.id, function(f, pid)
        local owner
        if f.on then
            wait(15)
            if f.value == 0 then
                owner = higurashi.get_random_ped()
            elseif f.value == 1 then
                owner = NATIVE.PLAYER_PED_ID()
            elseif f.value == 2 then
                owner = NATIVE.GET_PLAYER_PED(pid)
            end
            for x = 60, 0, -1 do
                wait(25)
                local pos = higurashi.get_player_coords(pid)
                pos.z = pos.z + x
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 47, 1000.0, true, false, 1.0)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 49, 1000.0, true, false, 1.0)
                higurashi.add_explosion(owner, v3(pos.x, pos.y, pos.z), 9, 1000.0, true, false, 1.0)
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Anon", "Blamed", "Player" })

    Higurashi.Bounty = m.apf("Bounty", "parent", Higurashi.Griefing.id)
    Higurashi.Bounty.hint = ""

    local anonymous_bounty

    Higurashi.AnonymousBounty = m.apf("Anonymous Bounty", "toggle", Higurashi.Bounty.id, function(f, pid)
        if f.on ~= anonymous_bounty then
            anonymous_bounty = f.on
            local pf = m.gpf(f.id)
            for i = 1, #pf.feats do
                pf.feats[i].on = anonymous_bounty
            end
        end
        return HANDLER_POP
    end)

    m.apf("Reapply Bounty", "toggle", Higurashi.Bounty.id, function(f, pid)
        while f.on do
            higurashi_globals.set_bounty(pid, 10000, anonymous_bounty)
            wait(1000)
        end
    end)

    Higurashi.CustomBounty = m.apf("Place Bounty", "action", Higurashi.Bounty.id, function(f, pid)
        local r, s = input.get("Input custom bounty value.", "", 64, 3)
        if r == 1 then return HANDLER_CONTINUE end
        if r == 2 then return HANDLER_POP end

        local value = tonumber(s)
        if not value then
            m.n("Invalid input. Please enter a valid number.", title, 3, c.red1)
            return
        end

        value = math.max(0, value)
        value = math.min(10000, value)

        higurashi_globals.send_limiter[#higurashi_globals.send_limiter + 1] = utils.time_ms() + 1000
        higurashi_globals.set_bounty(pid, value, anonymous_bounty)
    end)


    Higurashi.ScriptEvent = m.apf("Script Events", "parent", Higurashi.Griefing.id)
    Higurashi.ScriptEvent.hint = ""

    local freemodeactivities = {
        "Darts", "Golf", "Pilot School",
    }

    local arcadeGames = {
        "Race And Chase", "Badlands Revenge II", "The Wizards Ruin", "Space Monkey", "Qub3d", "Camhedz",
    }

    local freemodeMissions = {
        "Junk Energy Skydive", "Bike Service", "Ammunation Contract", "Acid Lab Setup", "Stash House Mission",
        "Taxi Mission", "Time Trial", "Tow Truck Service",
    }

    m.apf("Send To Online Intro", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.send_to_activity(pid, 20)
    end)

    m.apf("Remove Passive Mode", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.send_to_activity(pid, 49)
    end)

    m.apf("Send To Activity", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        local id = { 211, 212, 215 }
        higurashi_globals.send_to_activity(pid, id[f.value])
    end):set_str_data(freemodeactivities)

    m.apf("Send To Arcade Game", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        local id = { 229, 230, 231, 235, 236, 237 }
        higurashi_globals.send_to_activity(pid, id[f.value])
    end):set_str_data(arcadeGames)

    m.apf("Send To Freemode Mission", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        local id = { 267, 292, 296, 304, 308, 309, 318, 324 }
        script.trigger_script_event_2(1 << pid, 0x566F038B, -1, -1, id[f.value])
    end):set_str_data(freemodeMissions)

    m.apf("Send Fake Notify", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_BADSWOP")
        elseif f.value == 1 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_REPUTATION")
        elseif f.value == 2 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_DELET")
        elseif f.value == 3 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_KICKRES2")
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_CHTSWOP")
        elseif f.value == 4 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_SCSBANNED")
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_ROSBANPERM")
        elseif f.value == 5 then
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_G_S_FORCE", -1, -1)
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_C_RF_FAILED", -1, -1)
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_S_RS_FAILED", -1, -1)
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_G_S_HEART", -1, -1)
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_S_RF_FAILED", -1, -1)
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, "HUD_T_RF_FAILED", -1, -1)
        end
    end):set_str_data({ "Badsport", "Reputation", "Delete Character", "Cheater", "Ban", "Rockstar Support" })

    Higurashi.SendErrorNotifications = m.apf("Random Fake Notify", "toggle", Higurashi.ScriptEvent.id, function(f, pid)
        local HUD_notifications = {
            "HUD_1_CASHGIFT", "HUD_360TOPC_C", "HUD_360TOPS4_C",
            "HUD_360TOXB1_C", "HUD_ANOTHER", "HUD_BAIL1", "HUD_BAIL2",
            "HUD_BAIL3", "HUD_BAIL4", "HUD_BAIL5", "HUD_BAIL6", "HUD_BAIL7",
            "HUD_BAIL8", "HUD_BAIL9", "HUD_BAIL10", "HUD_BAIL11", "HUD_BAIL12",
            "HUD_BAIL13", "HUD_BAIL14", "HUD_BAIL15", "HUD_BAIL16",
            "HUD_BAIL17", "HUD_BAILFM", -- セッションにエラーが発生しました。
            "HUD_BAILSC", "HUD_BAILSPEC1", "HUD_BAILSPEC2", "HUD_BAILSPEC3",
            "HUD_BAIL_REVOKED", "HUD_BAIL_SUSPEND", "HUD_BLOCKER", "HUD_CANTIT",
            "HUD_CASHGIFT", "HUD_CASHREWARD1", "HUD_CASHREWARD2",
            "HUD_CASHREWARD3", "HUD_CASHREWARD4", "HUD_CASHREWARD5",
            "HUD_CASHREWARD6", "HUD_CASHREWARD7", "HUD_CASHREWARD8",
            "HUD_CASHREWARD9", "HUD_CASHREWARD10", "HUD_CASHREWARD11",
            "HUD_CASHREWARD12", "HUD_CASHREWARD13", "HUD_CASHREWARD14",
            "HUD_CASHREWARD15", "HUD_CASHREWARD16", "HUD_CASHREWARD17",
            "HUD_CASHREWARD", "HUD_CATAGLOG", "HUD_CGIGNORE", "HUD_CGINVITE",
            "HUD_CHNGCREWMSG", "HUD_CLOUDFAILMSG", "HUD_CLOUDOFFLIN",
            "HUD_CLOUDONLIN", "HUD_CNGSET", "HUD_COMBATPACK", "HUD_COMBATPACKT",
            "HUD_COMPATCLOD", "HUD_COMPTITLE", "HUD_COMPTITLEFAIL",
            "HUD_CONNECTION", "HUD_CONNPROB", "HUD_CONNT", "HUD_CONNTPS4SI",
            "HUD_CONSTR", "HUD_CV_RF_FAILED", "HUD_CV_RF_SMALL",
            "HUD_C_RF_FAILED",                            -- gtaオンラインのセッションでサーバーとの重要なカタログデータの同期に障害が発生しています。もう一度試して、www.rockstargames.com/support　...
            "HUD_DELEEXPL2", "HUD_DELEEXPL", "HUD_DELET", -- gtaオンラインのキャラクターを削除中、電源きらないで
            "HUD_DELETEQUE", "HUD_DELETESURE", "HUD_DIFF_AUTO", "HUD_DIFF_FREE",
            "HUD_DISCON", "HUD_ENDKICK", "HUD_ENDPARTYLEFT", "HUD_ESTAB",
            "HUD_GAMEUPD", "HUD_GONECHAR1", "HUD_GONECHAR2", "HUD_GONECHAR3",
            "HUD_GONECHAR4", "HUD_G_S_FORCE", -- このセッションでのプレイ続行が許可されていません。詳細は行動規範をご確認ください。
            "HUD_G_S_HEART",                  -- オンラインサービスと接続できない、wwwrockstargames
            "HUD_G_S_MAINT", "HUD_ICRP_REW", "HUD_IC_REW", "HUD_IMPORFIN",
            "HUD_INGINV", "HUD_INITSESSFAIL", "HUD_INVENTORY", "HUD_INVPROG",
            "HUD_ITEMREWARD", "HUD_JIPCLFAIL", "HUD_JIPFAILMSG",
            "HUD_JOINFAILMSG", "HUD_KICKCREWMSG",               -- クルーから除外
            "HUD_KICKRES1",                                     -- 投票により除外されました
            "HUD_KICKRES2",                                     -- チーとプレイヤーに指定されました。
            "HUD_KICKRES",                                      -- 無操作により除外されました
            "HUD_LEAVETIT", "HUD_LIVEFAIL", "HUD_LIVETUT", "HUD_LOADMAIN",
            "HUD_MIGRATE_WARN", "HUD_MM_FAIL", "HUD_MODINSTAL", -- 　改造されたバージョンでアクセスしようとしています。
            "HUD_MPBAILMESG", "HUD_MPCREWFIND", "HUD_MPFRNDFIND",
            "HUD_MPFRNDONLY", "HUD_MPINVITEBAIL", "HUD_MPREENTER",
            "HUD_MPTIMOUT", "HUD_NOBACKGRN", "HUD_NOTUNE", "HUD_PERM",
            "HUD_PLUGPU2", "HUD_PLUGPU", "HUD_PROFILECHNG", "HUD_PS3TOPC_C",
            "HUD_PS3TOPS4_C", "HUD_PS3TOXB1_C", "HUD_PS4TOPC_C", "HUD_PSPLUS",
            "HUD_QJIPFAILMS", "HUD_QUIT", "HUD_QUITDM", "HUD_QUITMISS",
            "HUD_QUITRACE", "HUD_QUITSESS", "HUD_QURETMEN", "HUD_QURETSP",
            "HUD_REBOOT", "HUD_REPUTATION",                                   -- あなたは評判が悪い
            "HUD_RESIGN", "HUD_RESIGN_LONG", "HUD_RETRYSTAT", "HUD_RETURNSP", -- gtavに戻る。
            "HUD_REVERT_TITLE", "HUD_REVERT_TRANS", "HUD_RE_ENTER",           -- gtavに戻ってください。
            "HUD_ROSBANNED", "HUD_ROSBANPERM", "HUD_ROSBANX",                 -- Suspended
            "HUD_RPC_REW", "HUD_RPGIFT", "HUD_RPGIFTDP", "HUD_RPI_REW",
            "HUD_RPREWARD", "HUD_SAVECAN", "HUD_SAVEFAILMSG",
            "HUD_SAVEMIGPOST1", "HUD_SAVEMIGPOST2", "HUD_SAVEMIGPOST3",
            "HUD_SAVEMIGPOST", "HUD_SAVETRA_INFO", "HUD_SCSBANNED",
            "HUD_SERVCAN_TITLE", "HUD_SERVCAN_TRANS", "HUD_SLOTONE",
            "HUD_SLOTTWO", "HUD_SOCMATFAIL", "HUD_SPRETRNFRSH",
            "HUD_SPRETURNTRY", "HUD_SPRETURNTRYNOW", "HUD_STATCORR1",
            "HUD_STATCORR2", "HUD_STATCORR3", "HUD_STATCORR4", "HUD_STATCORR",
            "HUD_STATCORRBOTH", "HUD_STATFAIL1", "HUD_STATFAIL2",
            "HUD_STATFAIL3", "HUD_STATFAIL4", "HUD_STATFAIL", "HUD_ST_AVAIL1",
            "HUD_ST_AVAIL2",                                 -- 転送を続けますか？
            "HUD_ST_AVAIL3", "HUD_SUCCESS",                  -- 完了
            "HUD_SUSPEND", "HUD_SYSTUPD", "HUD_S_RF_FAILED", -- ゲームアップデートを受信できない、もう一度試して、www.rockstargames
            "HUD_S_RS_FAILED", "HUD_TIMEFIN", "HUD_TIMEJOIN", "HUD_TIMEST",
            "HUD_TIMEWAIT", "HUD_TRANSCANCEL_F", "HUD_TRANSCANCEL_S",
            "HUD_TRANSFER", "HUD_TRYAGAIN", "HUD_T_RF_FAILED", -- サーバーとの通信に問題があったため...wwwrockstargames
            "HUD_UNSAVE", "HUD_UPDATEBAIL",                    -- アップデートして、再起度してください
            "HUD_WIPECHAR1", "HUD_WIPECHAR2", "HUD_WIPECHAR3", "HUD_WIPECHAR4",
            "HUD_WIPESURE", "HUD_XB1TOPC_C", "HUD_XBGOLD", "HUD_ERROR",
            "HUD_IMPORXB", "HUD_IMPORPS", "HUD_RENAME", "HUD_MAINTIT",
            "HUD_RETURNMP",               -- 終了
            "HUD_IMPORT", "HUD_ST_UATTF", "HUD_NOCLOUD", "HUD_LOCKED",
            "HUD_CHTSWOP", "HUD_BADSWOP", -- あなたは負け犬です
            "HUD_ST_EIPT", "HUD_BADORDER",
        }
        while f.on do
            local hash = HUD_notifications[math.random(#HUD_notifications)]
            script.trigger_script_event_2(1 << pid, 0x964D0D00, -1, -1, hash, -1, -1)
            wait(50)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.SendErrorNotifications2 = m.apf("Error Notifications", "toggle", Higurashi.ScriptEvent.id, function(f, pid)
        while f.on do
            script.trigger_script_event(0x1130D50C, pid, { pid, 0, math.random(0, 193) })
            wait(50)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.FreezePlayer = m.apf("Freeze", "toggle", Higurashi.ScriptEvent.id, function(f, pid)
        if f.on then
            higurashi_globals.send_script_event("Warehouse Invite", pid, { -1, -1, 1, 1, -1 })
            wait(700)
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.FreezePlayer.hint =
    "Stop this player in place for a brief moment, or keep them constantly locked in place."

    m.apf("Start Freemode Missions", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("Force Freemode Mission", pid, { pid, math.random(262, 264) })
        elseif f.value == 1 then
            higurashi_globals.send_script_event("Force Freemode Mission", pid, { pid, 159, -1 })
        elseif f.value == 2 then
            higurashi_globals.send_script_event("Force Freemode Mission", pid, { pid, 142, -1 })
        elseif f.value == 3 then
            higurashi_globals.send_script_event("Force Freemode Mission", pid, { pid, 166, -1 })
        elseif f.value == 4 then
            higurashi_globals.send_script_event("Force Freemode Mission 2", pid, { pid, 0 })
        end
    end):set_str_data({
        "Random", "Hostile Takeover", "Sightseer", "Head Hunter",
        "Defend Special Warehouse",
    })

    m.apf("Money Notifications", "value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.on then
            if f.value == 0 then
                script.trigger_script_event(0xD9B11BFD, pid, { pid, 0, 94410750, 999999999 })
            elseif f.value == 1 then
                script.trigger_script_event(0xD9B11BFD, pid, { pid, 0, -295926414, 999999999 })
            elseif f.value == 2 then
                script.trigger_script_event(0xD9B11BFD, pid, { pid, 0, -242911964, 999999999 })
            end
            wait(200)
        end
        return HANDLER_CONTINUE
    end):set_str_data({ "Deposit", "Stolen", "Disturb" })

    m.apf("Fake Typing", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("Start Typing", pid, { NATIVE.PLAYER_ID(), NATIVE.PLAYER_ID(), 0, math.random(1, 9999) })
        elseif f.value == 1 then
            higurashi_globals.send_script_event("Stop Typing", pid, { NATIVE.PLAYER_ID(), NATIVE.PLAYER_ID(), 0, math.random(1, 9999) })
        end
    end):set_str_data({ "Start", "Stop" })

    m.apf("Camera Manipulation", "toggle", Higurashi.ScriptEvent.id, function(f, pid)
        if f.on then higurashi_globals.camera_forward(pid) end
        return HANDLER_CONTINUE
    end)

    m.apf("Disable Abilities", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.send_script_event("Apartment Invite", pid, { -1, -1, -1, -1, -1, 115, 0, 0, 0, 0 })
    end)

    m.apf("Destroy Personal Vehicle", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.destroy_personal_vehicle(pid)
    end)

    Higurashi.KickFromVehicle = m.apf("Kick From Vehicle", "toggle", Higurashi.ScriptEvent.id, function(f, pid)
        if f.on then
            higurashi_globals.vehicle_kick(pid)
            wait(100)
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.KickFromVehicle.hint = "Force this player out of their vehicle."

    m.apf("Vehicle EMP", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.vehicle_emp(pid)
    end)

    m.apf("Block Passive Mode", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("Passive State", pid, { NATIVE.PLAYER_ID(), -1, 1 })
        elseif f.value == 1 then
            higurashi_globals.send_script_event("Passive State", pid, { NATIVE.PLAYER_ID(), -1, 0 })
        end
    end):set_str_data({ "Enable", "Disable" })

    m.apf("Job Text", "action", Higurashi.ScriptEvent.id, function(f, pid)
        local custom, text = input.get("Enter custom message", "", 70, 0)
        while custom == 1 do
            wait(0)
            custom, text = input.get("Enter custom message", "", 70, 0)
        end
        if custom == 2 then return HANDLER_POP end
        script.trigger_script_event_2(1 << pid, 0x46B9744E, "<font size='30'>~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~h~~b~~r~" .. text .. "~s~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~")
    end)

    m.apf("Invite To Beach Party", "action", Higurashi.ScriptEvent.id, function(f, pid)
        script.trigger_script_event(0x16414487, pid, { player.player_id(), player.player_id(), 0, 1, 0 })
    end)

    m.apf("Force To Cutscene", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("Casino Cutscene", pid, { pid, 0 })
        elseif f.value == 1 then
            local pos = higurashi.get_user_coords()
            NATIVE.SET_ENTITY_VISIBLE(NATIVE.PLAYER_PED_ID(), false)
            wait(700)
            for i = 0, 10 do
                higurashi.teleport_to(higurashi.get_player_coords(pid))
                higurashi_globals.send_island(pid)
                wait(100)
            end
            wait(0)
            higurashi.teleport_to(pos)
            NATIVE.SET_ENTITY_VISIBLE(NATIVE.PLAYER_PED_ID(), true)
        end
    end):set_str_data({ "Casino", "Cayo Perico" })

    m.apf("Force To Infinite Loading", "action", Higurashi.ScriptEvent.id, function(f, pid)
        higurashi_globals.send_script_event("Apartment Invite", pid, { NATIVE.PLAYER_ID(), 64, 6, -1, 1, 115, 0, 0, 0, 0 })
    end)

    Higurashi.SendToApartment = m.apf("Send to Apartment", "action_value_str", Higurashi.ScriptEvent.id, function(f, pid)
        if f.value == 0 then
            higurashi_globals.send_script_event("Apartment Invite", pid, { NATIVE.PLAYER_ID(), NATIVE.PLAYER_ID(), 2, -1, -1, 1, 0, 0, 0, 0 })
        elseif f.value == 1 then
            higurashi_globals.send_script_event("Apartment Invite", pid, { NATIVE.PLAYER_ID(), NATIVE.PLAYER_ID(), 2, -1, -1, 112, 0, 0, 0, 0 })
        elseif f.value == 2 then
            higurashi_globals.send_script_event("Apartment Invite", pid, { NATIVE.PLAYER_ID(), NATIVE.PLAYER_ID(), 2, -1, -1, 45, 0, 0, 0, 0 })
        end
    end):set_str_data({ "Eclipse Tower", "Mazebank Tower", "Strawberry Ave" })

    m.apf("Send to Random Mission", "action", Higurashi.ScriptEvent.id, function(f, pid) higurashi_globals.send_mission(pid) end)
    local radio_stations = {
        "OFF", "RADIO_01_CLASS_ROCK", "RADIO_02_POP", "RADIO_03_HIPHOP_NEW",
        "RADIO_04_PUNK", "RADIO_05_TALK_01", "RADIO_06_COUNTRY", "RADIO_07_DANCE_01",
        "RADIO_08_MEXICAN", "RADIO_09_HIPHOP_OLD", "RADIO_11_TALK_02", "RADIO_12_REGGAE",
        "RADIO_13_JAZZ", "RADIO_14_DANCE_02", "RADIO_15_MOTOWN", "RADIO_16_SILVERLAKE",
        "RADIO_17_FUNK", "RADIO_18_90s_ROCK", "RADIO_20_THELAB", "RADIO_21_DLC_XM17",
        "RADIO_22_DLC_BATTLE_MIX1_RADIO", "RADIO_23_DLC_XM19_RADIO", "RADIO_27_DLC_PRHEI4",
        "RADIO_34_DLC_HEI4_KULT", "RADIO_35_DLC_HEI4_MLR", "RADIO_36_AUDIOPLAYER", "RADIO_37_MOTOMAMI",
    }

    local function change_radio_station(veh, station)
        if veh ~= 0 and higurashi.request_control_of_entity(veh) then
            if not NATIVE.IS_VEHICLE_RADIO_ON(veh) then
                NATIVE.SET_VEHICLE_RADIO_ENABLED(veh, true)
            end
            NATIVE.SET_VEH_RADIO_STATION(veh, "OFF")
            wait()
            NATIVE.SET_VEH_RADIO_STATION(veh, station)
        end
    end
    Higurashi.VehicleGrief = m.apf("Vehicle", "parent", Higurashi.Griefing.id)

    m.apf("Change Radio Station", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, true)
        local selected_station = radio_stations[f.value + 1]
        change_radio_station(veh, selected_station)
    end):set_str_data({
        "OFF", "Los Santos Rock Radio", "Non-Stop-Pop FM", "Radio Los Santos", "Channel X",
        "West Coast Talk Radio", "Rebel Radio", "Soulwax FM", "East Los FM",
        "West Coast Classics", "Blaine County Radio", "Blue Ark", "Worldwide FM",
        "FlyLo FM", "The Lowdown 91.1", "Radio Mirror Park", "Space 103.2",
        "Vinewood Boulevard Radio", "The Lab", "Blonded Los Santos 97.8 FM",
        "Los Santos Underground Radio", "iFruit Radio", "Still Slipping Los Santos",
        "Kult FM", "The Music Locker", "Media Player", "MOTOMAMI Los Santos",
    })

    m.apf("Change Vehicle Horn", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if f.value == 0 and veh ~= 0 and higurashi.request_control_of_entity(veh) then
            NATIVE.OVERRIDE_VEH_HORN(veh, true, -1)
            NATIVE.SET_VEHICLE_HAS_MUTED_SIRENS(veh, true)
            NATIVE.SET_VEHICLE_SIREN(veh, false)
        elseif f.value == 1 and veh ~= 0 and higurashi.request_control_of_entity(veh) then
            NATIVE.OVERRIDE_VEH_HORN(veh, true, NATIVE.GET_VEHICLE_DEFAULT_HORN(veh))
            NATIVE.SET_VEHICLE_HAS_MUTED_SIRENS(veh, false)
            NATIVE.SET_VEHICLE_SIREN(veh, true)
        end
    end):set_str_data({ "Mute", "Default" })

    m.apf("Remote Control Vehicle", "toggle", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh == 0 then
            f.on = false
            return m.n("No vehicle found.", title, 3, c.red1)
        end

        if not higurashi.request_control_of_entity(veh) then
            f.on = false
            return m.n("Failed to gain control of the vehicle.", title, 3, c.red1)
        end
        local controlActions = {
            [32] = { action = 23, duration = 250 }, -- W
            [33] = { action = 28, duration = 250 }, -- S
            [34] = { action = 7, duration = 250 },  -- A
            [35] = { action = 8, duration = 250 },  -- D
            -- [51] = { func = function() NATIVE.START_VEHICLE_HORN(veh, 100, NATIVE.GET_HASH_KEY("HELDDOWN"), false) end }, -- E
        }

        while f.on do
            for control, data in pairs(controlActions) do
                if NATIVE.IS_CONTROL_PRESSED(0, control) then
                    while NATIVE.IS_CONTROL_PRESSED(0, control) do
                        if data.action then
                            NATIVE.TASK_VEHICLE_TEMP_ACTION(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), veh, data.action, data.duration)
                        elseif data.func then
                            data.func()
                        end
                        wait()
                    end
                end
            end
            wait()
        end
    end)

    m.apf("Delete Vehicle", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid)
        if veh ~= 0 then
            higurashi.remove_entity({ veh })
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)
    m.apf("Hijack Vehicle", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local ped_hashes = {
            [0] = 0xA8683715, -- Chimp
            [1] = 0xD32EEFAD, -- Yule Monster
            [2] = 0x50262DB9, -- Furry
            [3] = 0x4DA6E849, -- Lester
            [4] = 0x8CE6A476, -- Yeti
        }
        local ped_hash = ped_hashes[f.value] or 0xA8683715

        local ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = higurashi.get_player_coords(pid)
        local vehicle = NATIVE.GET_VEHICLE_PED_IS_USING(ped)
        local drivingStyle = 786603 -- DF_SwerveAroundAllCars
        local ping = NATIVE.ROUND(NATIVE.NETWORK_GET_AVERAGE_PING(pid))

        if vehicle == 0 or NATIVE.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
            return
        end

        pos.z = pos.z - 30
        if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)) then
            m.n("Vehicle has already been hijacked. :D")
            return
        end

        local randomPed = higurashi.create_ped(-1, ped_hash, v3(pos.x, pos.y, -50), 0, true, false, true, false, false, true)
        NATIVE.SET_ENTITY_INVINCIBLE(randomPed, true)
        NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(randomPed, true)
        NATIVE.TASK_ENTER_VEHICLE(randomPed, vehicle, 1000, -1, 1.0, 1 | 16 | 32, 0)

        local timer = utils.time_ms() + 2500
        while not NATIVE.GET_IS_TASK_ACTIVE(randomPed, 160) do
            if utils.time_ms() > timer then
                m.n("Failed to assign CTaskEnterVehicle to ped.")
                higurashi.remove_entity({ randomPed })
                return
            end
            wait(0)
        end

        timer = utils.time_ms() + 5000
        repeat
            if NATIVE.GET_IS_TASK_ACTIVE(ped, 2) then
                timer = utils.time_ms() + 2500
            end
            if utils.time_ms() > timer and NATIVE.IS_PED_IN_ANY_VEHICLE(ped) then
                m.n("Failed to hijack their vehicle due to high ping (" .. ping .. "ms).")
                higurashi.remove_entity({ randomPed })
                return
            end
            wait(0)
        until not NATIVE.IS_PED_IN_ANY_VEHICLE(ped)

        if higurashi.get_seat_ped_is_in(randomPed) == -1 then
            higurashi.force_control_of_entity(vehicle)
            NATIVE.TASK_VEHICLE_DRIVE_WANDER(randomPed, vehicle, 9999.0, drivingStyle)
            m.n("Bippity boppity their car is now your property")
            if not NATIVE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(vehicle, pid) then
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(vehicle, pid, true)
            end
        end

        wait(1000)
        if not NATIVE.GET_IS_TASK_ACTIVE(randomPed, 151) and not NATIVE.IS_PED_IN_ANY_VEHICLE(randomPed) then
            timer = utils.time_ms() + 2500
            repeat
                if utils.time_ms() > timer then
                    m.n("Failed to assign CTaskEnterVehicle to ped.")
                    higurashi.remove_entity({ randomPed })
                    return
                end
                NATIVE.SET_PED_INTO_VEHICLE(randomPed, vehicle, -1)
                wait(0)
            until NATIVE.GET_VEHICLE_PED_IS_USING(randomPed) == vehicle
            NATIVE.TASK_VEHICLE_DRIVE_WANDER(randomPed, vehicle, 9999.0, drivingStyle)
        end

        wait(5000)
        if randomPed and not NATIVE.IS_PED_IN_ANY_VEHICLE(randomPed, false) then
            higurashi.remove_entity({ randomPed })
        end
    end):set_str_data({ "Chimp", "Yule Monster", "Furry", "Lester", "Yeti" })
    --[[ m.apf("Hijack Vehicle", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local ped_hashes = {
            [0] = 0xA8683715, -- Chimp
            [1] = 0xD32EEFAD, -- Yule Monster
            [2] = 0x50262DB9, -- Furry
            [3] = 0x4DA6E849, -- Lester
            [4] = 0x8CE6A476, -- Yeti
        }
        local ped_hash = ped_hashes[f.value] or 0xA8683715

        local timer = utils.time_ms() + 2500
        local ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = higurashi.get_player_coords(pid)
        local vehicle = NATIVE.GET_VEHICLE_PED_IS_USING(ped)
        local drivingStyle = 'DF_SwerveAroundAllCars'
        local ping = NATIVE.ROUND(NATIVE.NETWORK_GET_AVERAGE_PING(pid))

        if NATIVE.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
            return
        end

        if vehicle == 0 then
            return
        end

        pos.z = pos.z - 30
        if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1)) then
            m.n("Vehicle has already been hijacked. :D")
            return
        end

        local randomPed = higurashi.create_ped(-1, ped_hash, v3(pos.x, pos.y, -50), 0, true, false, true, false, false, true)
        NATIVE.SET_ENTITY_INVINCIBLE(randomPed, true)
        NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(randomPed, true)
        NATIVE.TASK_ENTER_VEHICLE(randomPed, vehicle, 1000, -1, 1.0, 0 | 1 | 3 | 16 | 32, 0, false)

        while not NATIVE.GET_IS_TASK_ACTIVE(randomPed, 160) do
            if utils.time_ms() > timer then
                m.n("Failed to assign CTaskEnterVehicle to ped.")
                higurashi.remove_entity({ randomPed })
                return
            end
            wait(0)
        end

        repeat
            if NATIVE.GET_IS_TASK_ACTIVE(ped, 2) then
                timer = utils.time_ms() + 2500
            end
            if utils.time_ms() > timer and NATIVE.IS_PED_IN_ANY_VEHICLE(ped) then
                m.n("Failed to hijack their vehicle due to high ping (" .. ping .. "ms).")
                higurashi.remove_entity({ randomPed })
                return
            end
            wait(0)
        until not NATIVE.IS_PED_IN_ANY_VEHICLE(ped)

        if higurashi.get_seat_ped_is_in(randomPed) == -1 then
            higurashi.request_control_of_entity(vehicle)
            NATIVE.TASK_VEHICLE_DRIVE_WANDER(randomPed, vehicle, 9999.0, drivingStyle)
            m.n("Bippity boppity their car is now your property")
            if not NATIVE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(vehicle, pid) then
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(vehicle, pid, true)
            end
        end

        wait(1000)
        if not NATIVE.GET_IS_TASK_ACTIVE(randomPed, 151) then
            if not NATIVE.IS_PED_IN_ANY_VEHICLE(randomPed) then
                repeat
                    if utils.time_ms() > timer then
                        m.n("Failed to assign CTaskEnterVehicle to ped.")
                        higurashi.remove_entity({ randomPed })
                        return
                    end
                    NATIVE.SET_PED_INTO_VEHICLE(randomPed, vehicle, -1)
                    wait(0)
                until NATIVE.GET_VEHICLE_PED_IS_USING(randomPed) == vehicle
                --higurashi.request_control_of_entity(randomPed)
                NATIVE.TASK_VEHICLE_DRIVE_WANDER(randomPed, vehicle, 9999.0, drivingStyle)
            end
        end

        wait(5000)
        if randomPed and not NATIVE.IS_PED_IN_ANY_VEHICLE(randomPed, false) then
            higurashi.remove_entity({ randomPed })
        end
    end):set_str_data({ "Chimp", "Yule Monster", "Furry", "Lester", "Yeti" })]]

    m.apf("Fill Vehicle With Ped", "value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local ped_models = {
            [0] = 0xA8683715, -- Chimp
            [1] = 0xD32EEFAD, -- Yule Monster
            [2] = 0x50262DB9, -- Furry
            [3] = 0x4DA6E849, -- Lester
            [4] = 0x8CE6A476, -- Yeti
        }
        while f.on do
            local ped_model = ped_models[f.value] or 0xA8683715
            local veh = higurashi.get_player_vehicle(pid, false)
            if veh ~= 0 and NATIVE.ARE_ANY_VEHICLE_SEATS_FREE(veh) then
                local seat_found = false
                for i = -1, NATIVE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(NATIVE.GET_ENTITY_MODEL(veh)) - 1 do
                    if NATIVE.IS_VEHICLE_SEAT_FREE(veh, i, false) then
                        local spawned_ped = higurashi.create_ped_inside_vehicle(veh, -1, ped_model, i, true, false, true, false)
                        if spawned_ped ~= 0 then
                            NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_ped, true)
                            NATIVE.CAN_PED_RAGDOLL(spawned_ped, false)
                            NATIVE.SET_ENTITY_INVINCIBLE(spawned_ped, true)
                            wait(350)
                            if not NATIVE.IS_PED_IN_ANY_VEHICLE(spawned_ped, false) then
                                higurashi.hard_remove_entity(spawned_ped)
                            end
                        end
                        seat_found = true
                        break
                    end
                end
                if not seat_found then
                    return
                end
            else
                return
            end
            wait(250)
        end
    end):set_str_data({ "Chimp", "Yule Monster", "Furry", "Lester", "Yeti" })

    m.apf("Explode Vehicle", "toggle", Higurashi.VehicleGrief.id, function(f, pid)
        if f.on then
            local veh = higurashi.get_player_vehicle(pid, true)
            if veh ~= 0 then
                if higurashi.request_control_of_entity(veh) then
                    NATIVE.NETWORK_EXPLODE_VEHICLE(veh, true, false, pid)
                end
            else
                return m.n("No vehicle found.", title, 3, c.red1)
            end
        end
        wait(100)
        return HANDLER_CONTINUE
    end)

    m.apf("Vehicle EMP", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            local pos = NATIVE.GET_ENTITY_COORDS(veh, false)
            higurashi.add_explosion(higurashi.get_random_ped() or -1, v3(pos.x, pos.y, pos.z), 83, 1.0, false, true, 0.0)
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Bypass Anti-Lockon", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if higurashi.request_control_of_entity(veh) then
                NATIVE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, true, true)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    Higurashi.BurstAllTires = m.apf("Burst All Tires", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if higurashi.request_control_of_entity(veh) then
                if not NATIVE.GET_VEHICLE_TYRES_CAN_BURST(veh) then
                    NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, true)
                end
                for i = 0, 5 do
                    NATIVE.SET_VEHICLE_TYRE_BURST(veh, i, true, 0x447A0000)
                end
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)
    Higurashi.BurstAllTires.hint = "Pop a specific tire (or all of them) of this player's vehicle, even if they are bulletproof."

    m.apf("Remove Vehicle Godmode", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if higurashi.request_control_of_entity(veh) then
                NATIVE.SET_ENTITY_INVINCIBLE(veh, false)
                NATIVE.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
                NATIVE.SET_ENTITY_PROOFS(veh, false, false, false, false, false, false, false, false, false)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_DAMAGE(veh, false)
                NATIVE.SET_DISABLE_VEHICLE_PETROL_TANK_FIRES(veh, false)
                NATIVE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, true)
                NATIVE.SET_VEHICLE_CAN_BREAK(veh, true)
                NATIVE.SET_VEHICLE_ENGINE_CAN_DEGRADE(veh, true)
                NATIVE.SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(veh, true)
                NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, true)
                NATIVE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, true)
                NATIVE.SET_ENTITY_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(veh, false, 0)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Burn Vehicle", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if higurashi.request_control_of_entity(veh) then
                NATIVE.DECOR_SET_INT(veh, "GBMissionFire", true)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Freeze Vehicle", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if higurashi.request_control_of_entity(veh) then
                NATIVE.FREEZE_ENTITY_POSITION(veh, true)
                NATIVE.SET_VEHICLE_MAX_SPEED(veh, 0.1)
                NATIVE.MODIFY_VEHICLE_TOP_SPEED(veh, 0.1)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Door Lock", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            if f.value == 0 then
                higurashi.request_control_of_entity(veh)
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, true)
                wait(10)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, true)
            elseif f.value == 1 then
                higurashi.request_control_of_entity(veh)
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, false)
                wait(10)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, false)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    m.apf("Disallow Enter Your Vehicle", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            if f.value == 0 then
                higurashi.request_control_of_entity(veh)
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, true)
                wait(10)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, true)
            elseif f.value == 1 then
                higurashi.request_control_of_entity(veh)
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, false)
                wait(10)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, false)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    Higurashi.KickFromVehicle = m.apf("Kick From Vehicle", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            for i in higurashi.players() do
                if i ~= pid and i ~= NATIVE.PLAYER_ID() then
                    NATIVE.SET_VEHICLE_EXCLUSIVE_DRIVER(veh, NATIVE.GET_PLAYER_PED(i), 0)
                end
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    Higurashi.KickFromVehicle.hint = "Force this player out of their vehicle."

    Higurashi.KickFromVehicle2 = m.apf("Kick From Vehicle V2", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local timer = utils.time_ms() + 2500
        local player_ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = higurashi.get_player_coords(pid)
        local veh = higurashi.get_player_vehicle(pid, false)

        if NATIVE.IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(pid) then
            return m.n(higurashi.get_user_name(pid) .. "'s vehicle has not been cloned yet.")
        end
        if veh == 0 then
            return m.n("No vehicle found.", title, 3, c.red1)
        end
        if NATIVE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(NATIVE.GET_ENTITY_MODEL(veh)) == 1 then
            return m.n("Vehicle doesn't allow for passengers.")
        end
        if not NATIVE.IS_VEHICLE_SEAT_FREE(veh, -2) then
            return m.n("Passenger seat is currently occupied.")
        end
        if not NATIVE.CAN_SHUFFLE_SEAT(veh, -1) then
            return m.n("Seat cannot be shuffled into.")
        end

        local spawned_ped = higurashi.create_ped_inside_vehicle(veh, -1, joaat("IG_Furry"), 0, true, false, false, false, false, true)
        wait()
        NATIVE.DECOR_SET_INT(spawned_ped, "Skill_Blocker", -1)
        NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_ped, true)
        NATIVE.TASK_SHUFFLE_TO_NEXT_VEHICLE_SEAT(spawned_ped, veh)

        if NATIVE.IS_PED_IN_ANY_VEHICLE(player_ped) then
            repeat
                if NATIVE.GET_IS_TASK_ACTIVE(player_ped, 2) then
                    timer = utils.time_ms() + 2500
                end
                if utils.time_ms() > timer then
                    higurashi.remove_entity({ spawned_ped })
                    return m.n("Ped failed to shuffle to driver's seat.")
                end
                yield()
            until not NATIVE.IS_PED_IN_ANY_VEHICLE(player_ped)
        end

        higurashi.remove_entity({ spawned_ped })
        NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, true)
        wait(0)
        NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, true)
    end)

    m.apf("Tow Vehicle", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, true)
        if veh == 0 then
            f.on = false
            return m.n("No vehicle found.", title, 3, c.red1)
        end
        if f.value == 0 then
            local pos = NATIVE.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(veh, 0.0, 7.0, 0.0)
            local towtruck = higurashi.create_vehicle(joaat("towtruck3"), pos, NATIVE.GET_ENTITY_HEADING(veh), true, false, false, true, false, false, true)
            NATIVE.DECOR_SET_INT(towtruck, "Skill_Blocker", -1)
            higurashi.modify_vehicle(towtruck, "upgrade")
            NATIVE.SET_ENTITY_INVINCIBLE(towtruck, true)
            NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(towtruck, pid, true)
            NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(pid, false)
            NATIVE.ATTACH_VEHICLE_TO_TOW_TRUCK(towtruck, veh, false, 90.0, 90.0, -180.0)

            local randomPed = higurashi.create_ped_inside_vehicle(towtruck, -1, joaat("IG_Furry"), -1, true, false, false, false, false, true)
            NATIVE.DECOR_SET_INT(randomPed, "Skill_Blocker", -1)
            NATIVE.SET_ENTITY_INVINCIBLE(randomPed, true)
            NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(randomPed, true)
            NATIVE.TASK_VEHICLE_DRIVE_WANDER(randomPed, towtruck, 9999.0, "DF_AvoidRestrictedAreas")
            -- wait(2000) -- Added a bit more wait time to ensure the task is assigned
        elseif f.value == 1 then
            for _, vehs in pairs(vehicle.get_all_vehicles()) do
                if NATIVE.GET_ENTITY_MODEL(vehs) == joaat("towtruck3") and NATIVE.DECOR_EXIST_ON(vehs, "Skill_Blocker") then
                    higurashi.remove_entity({ vehs })
                end
            end
            for _, peds in pairs(ped.get_all_peds()) do
                if NATIVE.GET_ENTITY_MODEL(peds) == joaat("IG_Furry") and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                    higurashi.remove_entity({ peds })
                end
            end
        end
    end):set_str_data({ "Tow", "Delete" })

    m.apf("Force To Forward", "action", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, 60000.00)
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end)

    m.apf("Launch ", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, false)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            if f.value == 0 then
                NATIVE.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0.0, 0.0, 10000.0, true, false, true, false)
            elseif f.value == 1 then
                NATIVE.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0.0, 0.0, -10000.0, true, false, true, false)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Up", "Down" })

    m.apf("Explosive Device", "action_value_str", Higurashi.VehicleGrief.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, true)
        if veh ~= 0 then
            higurashi.request_control_of_entity(veh)
            if f.value == 0 then
                NATIVE.SET_VEHICLE_TIMED_EXPLOSION(veh, NATIVE.GET_PLAYER_PED(pid), true)
            elseif f.value == 1 then
                NATIVE.ADD_VEHICLE_PHONE_EXPLOSIVE_DEVICE(veh)
            elseif f.value == 2 then
                if NATIVE.HAS_VEHICLE_PHONE_EXPLOSIVE_DEVICE() then
                    NATIVE.DETONATE_VEHICLE_PHONE_EXPLOSIVE_DEVICE()
                end
            elseif f.value == 4 then
                if NATIVE.HAS_VEHICLE_PHONE_EXPLOSIVE_DEVICE() then
                    NATIVE.CLEAR_VEHICLE_PHONE_EXPLOSIVE_DEVICE()
                end
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Add Timed", "Add Normal", "Detonate", "Clear" })

    Higurashi.WeaponGrief = m.apf("Weapons", "parent", Higurashi.Griefing.id)

    m.apf("Remove Unarmed", "action", Higurashi.WeaponGrief.id, function(f, pid)
        if not NATIVE.IS_PED_ARMED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 7) then
            NATIVE.REMOVE_WEAPON_FROM_PED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0xA2719263)
        end
    end)

    m.apf("Remove All Weapons", "action", Higurashi.WeaponGrief.id, function(f, pid)
        if NATIVE.IS_PED_ARMED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 7) then
            for _, weapon_hash in pairs(weapon.get_all_weapon_hashes()) do
                NATIVE.REMOVE_WEAPON_FROM_PED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), weapon_hash)
            end
        end
    end)

    Higurashi.Malicious = m.apf("Malicious", "parent", Higurashi.Parent1.id)
    Higurashi.Malicious.hint = "Remove the player from the session."

    Higurashi.SendCustomScriptEvent = m.apf("Send Custom Script Events", "action", Higurashi.Malicious.id, function(f, pid)
        local _, p0 = input.get("Enter the event hash to send.", "", 64, 0)
        if _ ~= 1 then
            if player.is_player_valid(pid) then
                local custom_args = {
                    { pid, higurashi_globals.generic_player_global(pid) },
                    higurashi_globals.get_custom_arg(pid, 39), { pid, -1 }, {},
                    { pid, math.random(0, 1), math.random(0, 1), math.random(0, 1),
                        math.random(0, 1), math.random(0, 1), math.random(0, 1),
                        math.random(0, 1), math.random(0, 1), math.random(0, 1),
                        math.random(0, 1), math.random(0, 1), math.random(0, 1),
                        math.random(0, 1), math.random(0, 1), math.random(0, 1),
                    },
                }

                for _, args in ipairs(custom_args) do
                    script.trigger_script_event(p0, pid, args)
                    higurashi_globals.send_limiter[#higurashi_globals.send_limiter + 1] = utils.time_ms() + (1 // NATIVE.GET_FRAME_TIME())
                end
            end
        end
    end)

    Higurashi.SendCustomScriptEvent.hint =
        "Sends the entered script event to player." .. c.orange2 ..
        "\nDo not enter any value other than dec or hex."

    Higurashi.EntitySpam = m.apf("Entity Spam", "parent", Higurashi.Malicious.id)
    Higurashi.EntitySpam.hint =
    "Send lots of peds or huge vehicles to this player, in order to fill their entity pools and make them crash."

    Higurashi.SpamWade = m.apf("Spam Wade", "action", Higurashi.EntitySpam.id, function(f, pid)
        higurashi.block_syncs(pid, function()
            local pos = higurashi.get_player_coords(pid) + v3(0, 0, -2.0)
            local loops = 0
            while loops <= 100 do
                local wade = higurashi.create_ped(28, joaat("cs_wade"), pos, 0, true, false, false, false, false)
                NATIVE.FREEZE_ENTITY_POSITION(wade, true)
                yield(50)
                loops = loops + 1
            end
            yield(1500)
            for _, peds in pairs(ped.get_all_peds()) do
                if NATIVE.GET_ENTITY_MODEL(peds) == joaat("cs_wade") then
                    higurashi.hard_remove_entity(peds)
                end
            end
        end)
    end)
    Higurashi.SpamWade.hint =
    "Send lots of peds or huge vehicles to this player, in order to fill their entity pools and make them crash."

    Higurashi.KickPlayer = m.apf("Kick", "parent", Higurashi.Malicious.id)

    local function log_and_kick(action_name, pid, kick_func, hint)
        m.apf(action_name, "action", Higurashi.KickPlayer.id, function(f, pid)
            local user_name = higurashi.get_user_name(pid)
            logger("Attempt to kick " .. user_name .. ".", "[" .. action_name .. "]", "Debug.log", true, title, 2, c.blue1)
            kick_func(pid)
            logger("Done.", "[" .. action_name .. "]", "Debug.log", true, title, 2, c.green1)
        end).hint = hint
    end

    log_and_kick("Blacklist", pid, function(pid)
        higurashi.write(io.open(paths.root .. "\\cfg\\scid.cfg", "a"), higurashi.get_user_name(pid) .. ':' .. higurashi.scid_to_hex(higurashi.get_user_rid(pid)) .. ":4")
        wait()
        higurashi.kick(pid)
    end, "Use the power of Karen's loud bombastic voice to speak to the manager to forcefully remove a customer from the store. " .. c.orange2 .. " If you are the network host, Karen becomes the store manager and blacklists the customer from the store.")

    log_and_kick("Network Bail", pid, higurashi_globals.net_bail_kick, "Kick this player out of the lobby using a regular script event.")

    log_and_kick("Freemode Death", pid, higurashi.invalid_collectable_kick, c.orange2 .. "Lick a figure.")

    Higurashi.CrashPlayer = m.apf("Crash", "parent", Higurashi.Malicious.id)

    local function log_and_crash(action_name, pid, crash_func, hint)
        m.apf(action_name, "action", Higurashi.CrashPlayer.id, function(f, pid)
            local user_name = higurashi.get_user_name(pid)
            logger("Attempt to crash " .. user_name .. ".", "[" .. action_name .. "]", "Debug.log", true, title, 2, c.blue1)
            crash_func(pid)
            wait()
            logger("Done.", "[" .. action_name .. "]", "Debug.log", true, title, 2, c.green1)
        end).hint = hint
    end

    log_and_crash("Elegant", pid, higurashi_globals.se_crash, "Crash this player using a regular script event.")

    log_and_crash("Bass Cannon", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.sound_crash(pid, 1)
            wait()
        end)
    end, "Sound crash.")

    log_and_crash("Vehicular Manslaughter", pid, higurashi.vehicular_manslaughter_crash,
        "Hack into the traffic cameras and make them emit 5G to crash the target." .. c.orange2 .. "\nDue to the short range of 5G, the target must be near traffic and you should be next to them or spectating them.")

    log_and_crash("Quantum", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.quantum_crash(pid)
            wait()
        end)
    end, "Explode the target's brain into a million fragments." .. c.orange2 .. "\nYou must be close and/or spectating for best results")

    log_and_crash("Nature", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.invalid_pickup_object_crash(pid)
            wait()
        end)
    end, "")

    log_and_crash("Space", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.bad_parachute_crash(pid)
            wait()
        end)
    end, "")

    log_and_crash("Virus Rat", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.virus_rat_crash(pid)
            wait()
        end)
    end, c.orange2 .. "")

    log_and_crash("Coord", pid, higurashi.coord_crash, c.orange2 .. "Only works for session host.")

    log_and_crash("Baptism", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.heli_protect_crash(pid)
            wait()
        end)
    end, c.orange2 .. "")

    log_and_crash("Bro Hug", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.task_sweep_crash(pid)
            wait()
        end)
    end, "Send a hug filled with the love of family to crash a player, because nothing is stronger than family." .. c.orange2 .. "Although it will be easier for the family's love to reach the target if you are next to them or spectating them.")

    log_and_crash("Yo Mama", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.invalid_mounted_weapon_crash(pid)
            wait()
        end)
    end, "")

    log_and_crash("Limbo", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.task_climb_crash(pid)
            wait()
        end)
    end, c.orange2 .. "")

    log_and_crash("Woof", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.explode_ped_crash(pid)
            wait()
        end)
    end, c.orange2 .. "This will also crash other players close to your target.")

    log_and_crash("Human Error", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.invalid_ped_crash(pid)
            wait()
        end)
    end, "")

    log_and_crash("Pirate", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.invalid_veh_model_crash(pid)
            wait()
        end)
    end, "")

    log_and_crash("Indecent Exposure", pid, function(pid)
        higurashi.block_syncs(pid, function()
            higurashi.sync_mismatch_crash()
            wait()
        end)
    end, "")


    Higurashi.ParticleEffects = m.apf("Particle Effects", "parent", Higurashi.Parent1.id)

    Higurashi.PTFXScale = m.apf("Scale: ", "autoaction_value_f", Higurashi.ParticleEffects.id, function(f) PTFX_Scale = f.value end)
    Higurashi.PTFXScale.min = 0.0
    Higurashi.PTFXScale.max = 10.0
    Higurashi.PTFXScale.mod = 0.10
    Higurashi.PTFXScale.value = 1.0

    Higurashi.PTFXDelay = m.apf("Delay: ", "autoaction_value_i", Higurashi.ParticleEffects.id, function(f) PTFX_Delay = f.value end)
    Higurashi.PTFXDelay.min = 0
    Higurashi.PTFXDelay.max = 1000
    Higurashi.PTFXDelay.mod = 100
    Higurashi.PTFXDelay.value = 0

    m.apf("Phantom Vehicle", "toggle", Higurashi.ParticleEffects.id, function(f, pid)
        local veh = higurashi.get_player_vehicle(pid, true)
        if veh then
            local ptfx_loop = higurashi.start_ptfx_looped_on_entity(
                "scr_tn_phantom", "scr_tn_phantom_flames",
                veh, 0.0, 0.0, 0.0, 0.0, 0.0, 180.0,
                PTFX_Scale or 1.0, false, true, false, 1.0,
                1.0, 1.0, 0.0)
            while f.on do wait() end
            if NATIVE.DOES_PARTICLE_FX_LOOPED_EXIST(ptfx_loop) then
                NATIVE.REMOVE_PARTICLE_FX(ptfx_loop, 0)
            end
            NATIVE.REMOVE_NAMED_PTFX_ASSET("scr_tn_phantom")
        else
            return
        end
    end)

    local ptfx_preset = {
        { "core", "exp_grd_grenade_smoke" }, { "core", "ent_sht_flame" },
        { "core", "ent_amb_fbi_fire_beam" },
        { "core", "ent_ray_ch2_farm_fire_u_l" }, { "core", "exp_grd_propane" },
        { "core", "bul_carmetal" }, { "core", "ent_dst_mail" },
        { "core", "ent_dst_inflate_lilo" }, { "core", "veh_rotor_break" },
        { "core", "exp_grd_petrol_pump_post" }, { "core", "ent_dst_bread" },
        { "core", "ent_ray_fin_petrol_splash" }, { "core", "ent_dst_snow_tombs" },
        { "core", "ent_dst_rocks" }, { "core", "ent_sht_telegraph_pole" },
        { "core", "ent_brk_champagne_case" }, { "core", "exp_air_grenade" },
        { "core", "mel_carmetal" }, { "core", "glass_shards" },
        { "core", "ent_dst_gen_choc" }, { "core", "ent_dst_egg_mulch" },
        { "core", "ent_dst_pumpkin" }, { "core", "ent_brk_cactus" },
        { "core", "exp_grd_plane_spawn" }, { "core", "blood_mouth" },
        { "core", "bang_hydraulics" }, { "core", "shotgun_water" },
        { "core", "liquid_splash_gloopy" }, { "core", "exp_hydrant_decals_sp" },
        { "core", "water_splash_ped_in" }, { "core", "ent_brk_tree_trunk_bark" },
        { "core", "bul_foam" }, { "core", "ent_amb_fbi_falling_debris_sp" },
        { "core", "ent_brk_wood_splinter" }, { "core", "exp_grd_petrol_pump_sp" },
        { "core", "ped_foot_dirt_dry" }, { "core", "ent_anim_cig_exhale_nse" },
        { "core", "ent_brk_concrete" }, { "core", "ent_sht_bush_foliage" },
        { "core", "blood_chopper" }, { "core", "ent_dst_gen_paper" },
        { "core", "bang_concrete" }, { "core", "ent_dst_concrete_large" },
        { "core", "ent_dst_gen_gobstop" }, { "core", "td_blood_throat" },
        { "core", "water_splash_plane_in" }, { "core", "liquid_splash_oil" },
        { "core", "exp_bird_crap" }, { "core", "blood_entry_head_sniper" },
        { "core", "exp_grd_molotov" }, { "core", "ent_sht_molten_liquid" },
        { "core", "blood_melee_blunt" }, { "scr_rcbarry2", "scr_clown_appears" },
        { "scr_rcbarry2", "scr_clown_bul" }, { "scr_rcbarry2", "eject_clown" },
        { "scr_rcbarry2", "scr_exp_clown" }, { "scr_rcbarry2", "muz_clown" },
        { "scr_ch_finale", "scr_ch_cockroach_bag_drop" },
        { "weap_pipebomb", "proj_pipebomb_smoke" },
        { "scr_mp_creator", "scr_mp_plane_landing_tyre_smoke" },
        { "scr_mp_cig", "ent_anim_cig_smoke_car" },
        { "scr_carsteal4", "scr_carsteal4_wheel_burnout" },
        { "scr_recartheft", "scr_wheel_burnout" },
        { "scr_familyscenem", "scr_meth_pipe_smoke" },
        { "scr_reconstructionaccident", "scr_reconstruct_pipe_impact" },
        { "scr_trevor1", "scr_trev1_crash_dust" },
        { "scr_oddjobtaxi", "scr_ojtaxi_hotbox_trail" },
        { "scr_jewelheist", "scr_jew_biKe_burnout" },
        { "cut_hs4", "cut_hs4_cctv_animal_rip" },
        { "cut_hs4", "cut_hs4_cctv_blood_pool" },
        { "cut_hs4", "cut_hs4_cctv_animal_bite" },
        { "cut_hs4", "cut_hs4f_sub_propeller" },
        { "cut_hs4", "cut_hs4f_flipper_bubbles" },
        { "scr_fbi4", "scr_fbi4_trucks_crash" },
        { "scr_mp_tankbattle", "exp_grd_tankshell_mp" },
        { "scr_trevor3", "scr_trev3_c4_explosion" },
        { "scr_lester1a", "cs_cig_exhale_mouth" },
        { "scr_oddjobbusassassin", "scr_ojbusass_bus_impact" },
        { "scr_michael2", "scr_abattoir_ped_minced" },
        { "scr_michael2", "scr_acid_bath_splash" },
        { "scr_michael2", "scr_pts_headsplash" },
        { "scr_michael2", "scr_abattoir_ped_sliced" },
        { "scr_michael2", "scr_mich2_blood_stab" },
        { "scr_powerplay", "scr_powerplay_beast_vanish" },
        { "scr_weap_bombs", "scr_bomb_gas" },
        { "scr_weap_bombs", "scr_bomb_cluster" },
        { "scr_solomon3", "scr_trev4_747_blood_impact" },
        { "proj_indep_firework_v2", "scr_firework_indep_repeat_burst_rwb" },
        { "veh_xs_vehicle_mods", "exp_xs_mine_emp" },
        { "pat_heist", "scr_heist_ornate_thermal_burn_patch" },
        { "scr_trevor1", "scr_trev1_trailer_boosh" },
        { "scr_trevor1", "scr_trev1_trailer_wires" },
        { "weap_xs_vehicle_weapons", "muz_xs_turret_flamethrower_looping_sf" },
        { "scr_xs_celebration", "scr_xs_confetti_burst" },
        { "scr_xs_celebration", "scr_xs_money_rain" },
        { "scr_xs_celebration", "scr_xs_money_rain_celeb" },
        { "proj_indep_firework", "scr_indep_firework_grd_burst" },
        { "scr_bike_adversary", "scr_adversary_ped_glow" },
        { "scr_bike_adversary", "scr_adversary_slipstream" },
        { "scr_bike_adversary", "scr_adversary_judgement_lens_dirt" },
        { "scr_bike_adversary", "scr_adversary_judgement_ash" },
        { "scr_exile1", "scr_ex1_cargo_engine_trail" },
        { "scr_paletoscore", "scr_paleto_banknotes" },
        { "scr_paletoscore", "scr_trev_puke_splash_grd" },
        { "scr_recrash_rescue", "scr_recrash_rescue_fire" },
        { "scr_rcpaparazzo1", "scr_mich4_firework_trailburst_spawn" },
        { "scr_xm_orbital", "scr_xm_orbital_blast" },
        { "scr_agencyheist", "scr_fbi_mop_drips" },
        { "scr_agencyheist", "scr_fbi_mop_squeeze" },
        { "scr_agencyheistb", "scr_agency3b_elec_box" },
        { "scr_alien_charging{scr_rcbarry1", "scr_alien_charging" },
        { "scr_alien_impact_bul{scr_rcbarry1", "scr_alien_impact_bul" },
        { "scr_alien_teleport{scr_rcbarry1", "scr_alien_teleport" },
        { "scr_rcpap1_camera{scr_rcpaparazzo1", "scr_rcpap1_camera" },
        { "scr_sol1_sniper_impact{scr_martin1", "scr_sol1_sniper_impact" },
        { "scr_xm_submarine", "scr_xm_submarine_surface_explosion" },
        { "scr_xm_submarine", "scr_xm_submarine_explosion" },
        { "scr_xm_submarine", "scr_xm_submarine_surface_splashes" },
        { "scr_xm_submarine", "scr_xm_stromberg_scanner" },
        { "scr_gr_bunk", "scr_gr_bunk_drill_spark" },
        { "scr_sm_counter", "scr_sm_counter_chaff" },
        { "scr_sm_trans", "scr_sm_con_trans_fp" },
        { "scr_ie_svm_technical2", "scr_dst_cocaine" },
        { "scr_sm", "scr_dst_inflatable" },
        { "scr_ch_finale", "scr_ch_cockroach_bag_drop" },
        { "cut_narcotic_bike", "cs_dst_impotent_rage_toy" },
        { "scr_xs_props", "scr_xs_guided_missile_trail" },
        { "scr_xs_props", "scr_xs_ball_explosion" },
        { "scr_apartment_mp", "muz_yacht_defence" },
        { "scr_indep_fireworks", "scr_indep_firework_fountain" },
        { "scr_player_timetable_scene", "scr_pts_vomit_water" },
        { "scr_player_timetable_scene", "ent_dst_pineapple" },
        { "scr_player_timetable_scene", "scr_pts_headsplash" },
        { "scr_player_timetable_scene", "scr_pts_guitar_break" },
        { "scr_player_timetable_scene", "scr_pts_digging" },
        { "scr_paradise2_trailer", "scr_para_kick_blood" },
        { "scr_paradise2_trailer", "scr_prologue_door_blast" },
        { "scr_playerlamgraff", "scr_lamgraff_paint_spray" },
        { "scr_paintnspray", "scr_respray_smoke" },
        { "scr_mp_creator", "scr_mp_splash" },
        { "scr_mp_creator", "scr_mp_dust_cloud" },
        { "scr_jewelheist", "scr_jewel_fog_volume" },
        { "scr_jewelheist", "scr_jewel_cab_smash" },
        { "scr_exile1", "scr_ex1_water_exp_sp" },
        { "scr_cncpolicestationbustout", "scr_alarm_damage_sparks" },
        { "scr_amb_chop", "ent_anim_dog_poo" },
        { "scr_amb_chop", "liquid_splash_pee" },
        { "scr_amb_chop", "ent_anim_dog_peeing" },
        { "des_methtrailer", "ent_ray_meth_explosion" },
        { "des_pro_tree_crash", "ent_ray_pro_tree_crash" },
        { "des_pro_tree_crash", "ent_ray_pro_tree_crash_snow_slush" },
        { "des_pro_tree_crash", "ent_ray_pro_tree_crash_snow" },
        { "des_french_doors", "ent_ray_fam3_glass_break" },
        { "cut_prologue", "cs_prologue_brad_blood" },
        { "cut_prologue", "eject_auto" }, { "cut_family5", "cs_alien_light_bed" },
    }

    for i = 1, #ptfx_preset do
        m.apf(ptfx_preset[i][2], "toggle", Higurashi.ParticleEffects.id, function(f, pid)
            local ptfx = higurashi.start_ptfx_non_looped_at_coord(tostring(ptfx_preset[i][1]), tostring(ptfx_preset[i][2]), higurashi.get_player_coords(pid), v3(), PTFX_Scale, true, true, true, false)
            wait(PTFX_Delay)
            if f.on then
                return HANDLER_CONTINUE
            else
                if NATIVE.DOES_PARTICLE_FX_LOOPED_EXIST(ptfx) then
                    NATIVE.REMOVE_PARTICLE_FX(ptfx, 0)
                end
                NATIVE.REMOVE_NAMED_PTFX_ASSET(ptfx_preset[i][1])
                return HANDLER_POP
            end
        end)
    end

    Higurashi.Sounds = m.apf("Sounds", "parent", Higurashi.Parent1.id)
    Higurashi.Sounds.hint = "Loop annoyingly loud sounds on the target's game."

    Higurashi.SoundRange = m.apf("Range: ", "autoaction_value_i", Higurashi.Sounds.id, function(f) Sound_Range = f.value end)
    Higurashi.SoundRange.min = 0
    Higurashi.SoundRange.max = 100
    Higurashi.SoundRange.mod = 1
    Higurashi.SoundRange.value = 0

    Higurashi.SoundDelay = m.apf("Delay: ", "autoaction_value_i", Higurashi.Sounds.id, function(f) Sound_Delay = f.value end)
    Higurashi.SoundDelay.min = 0
    Higurashi.SoundDelay.max = 1000
    Higurashi.SoundDelay.mod = 100
    Higurashi.SoundDelay.value = 0

    m.apf("Stop All Sound", "action", Higurashi.Sounds.id, function()
        for i = -1, 100 do
            NATIVE.STOP_SOUND(i)
            NATIVE.RELEASE_SOUND_ID(i)
        end
        wait(0)
    end)

    for i = 1, #higurashi.sound_preset do
        local sound_name = higurashi.sound_preset[i][1]
        local sound_params = higurashi.sound_preset[i][2]
        m.apf(sound_name, "toggle", Higurashi.Sounds.id, function(f, pid)
            local pos = higurashi.get_player_coords(pid)
            NATIVE.PLAY_SOUND_FROM_COORD(-1, tostring(sound_name), pos.x, pos.y, pos.z, tostring(sound_params), true, Sound_Range, false)
            wait(Sound_Delay)
            if f.on then
                return HANDLER_CONTINUE
            else
                return HANDLER_POP
            end
        end)
    end

    Higurashi.PlayerUtilities = m.apf("Player Utilities", "parent", Higurashi.Parent1.id)

    m.apf("Check Region", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        m.n("Result: " .. regions[script.get_global_i(1887305 + 1 + (pid * 610) + 10 + 121)], title, 3, c.yellow1)
    end)

    m.apf("Send Friend Request", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        NATIVE.NETWORK_ADD_FRIEND(higurashi.get_gamer_handle(pid), "")
    end)

    m.apf("Open SC Profile", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        NATIVE.NETWORK_SHOW_PROFILE_UI(higurashi.get_gamer_handle(pid))
    end)

    Higurashi.SendCustomSMS = m.apf("Send Text Message", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        local custom, text = input.get("Enter custom message", "", 128, 0)
        while custom == 1 do
            wait(0)
            custom, text = input.get("Enter custom message", "", 128, 0)
        end
        if custom == 2 then return HANDLER_POP end
        NATIVE.NETWORK_SEND_TEXT_MESSAGE(text, higurashi.get_gamer_handle(pid))
    end)

    Higurashi.SendCustomSMS.hint =
    "Send a text message to this player using the built-in feature of the game."

    Higurashi.AddToFakeFriends = m.apf("Add To Fake Friends", "action_value_str", Higurashi.PlayerUtilities.id, function(f, pid)
        if pid ~= NATIVE.PLAYER_ID() then
            local actions = {
                [0] = ":0",
                [1] = ":4",
                [2] = ":11",
                [3] = ":1",
            }
            local action = actions[f.value]
            if action then
                local file = io.open(paths.root .. "\\cfg\\scid.cfg", "a")
                if file then
                    higurashi.write(file, higurashi.get_user_name(pid) .. ':' .. higurashi.scid_to_hex(higurashi.get_user_rid(pid)) .. action)
                    file:close()
                    m.n("Added " .. higurashi.get_user_name(pid) .. " to the Fake Friends\nReinject the Menu for it to take effect.", title, 3, c.blue1)
                end
            end
        else
            m.n("Error, It's not executable.", title, 3, c.red1)
        end
    end):set_str_data({ "Blacklist", "Timeout", "Friend List + Stalk", "Stalk" })

    local player_script_hooks = {}

    m.apf("Log Script Events", "toggle", Higurashi.PlayerUtilities.id, function(f, pid)
        if f.on then
            if not player_script_hooks[pid] then
                player_script_hooks[pid] = hook.register_script_event_hook(function(source, target, parameters, count)
                    if source == pid then
                        local scid = higurashi.get_user_rid(pid)
                        local name = higurashi.get_user_name(pid) or "Invalid Name"
                        local uuid = scid .. " - " .. name
                        local dir = paths.logs .. "\\" .. uuid
                        local file = dir .. "\\" .. "ScriptEvents.log"
                        if not utils.dir_exists(dir) then
                            utils.make_dir(dir)
                        end
                        local text = string.format("Script Events from %s RID: %s\n%sScript Event Logger\n0x%s, {%s}\nParameter count: %d\n", name, scid, higurashi.time_prefix(), higurashi.dec_to_hex(parameters[1]), table.concat(parameters, ", ", 2), count - 1)
                        higurashi.write(io.open(file, "a"), text)
                    end
                end)
            end
            return HANDLER_CONTINUE
        elseif player_script_hooks[pid] then
            hook.remove_script_event_hook(player_script_hooks[pid])
            player_script_hooks[pid] = nil
        end
    end)


    local NetEvents = {
        [0] = "OBJECT_ID_FREED_EVENT",
        [1] = "OBJECT_ID_REQUEST_EVENT",
        [2] = "ARRAY_DATA_VERIFY_EVENT",
        [3] = "SCRIPT_ARRAY_DATA_VERIFY_EVENT",
        [4] = "REQUEST_CONTROL_EVENT",
        [5] = "GIVE_CONTROL_EVENT",
        [6] = "WEAPON_DAMAGE_EVENT",
        [7] = "REQUEST_PICKUP_EVENT",
        [8] = "REQUEST_MAP_PICKUP_EVENT",
        [9] = "GAME_CLOCK_EVENT",
        [10] = "GAME_WEATHER_EVENT",
        [11] = "RESPAWN_PLAYER_PED_EVENT",
        [12] = "GIVE_WEAPON_EVENT",
        [13] = "REMOVE_WEAPON_EVENT",
        [14] = "REMOVE_ALL_WEAPONS_EVENT",
        [15] = "VEHICLE_COMPONENT_CONTROL_EVENT",
        [16] = "FIRE_EVENT",
        [17] = "EXPLOSION_EVENT",
        [18] = "START_PROJECTILE_EVENT",
        [19] = "UPDATE_PROJECTILE_TARGET_EVENT",
        [20] = "REMOVE_PROJECTILE_ENTITY_EVENT",
        [21] = "BREAK_PROJECTILE_TARGET_LOCK_EVENT",
        [22] = "ALTER_WANTED_LEVEL_EVENT",
        [23] = "CHANGE_RADIO_STATION_EVENT",
        [24] = "RAGDOLL_REQUEST_EVENT",
        [25] = "PLAYER_TAUNT_EVENT",
        [26] = "PLAYER_CARD_STAT_EVENT",
        [27] = "DOOR_BREAK_EVENT",
        [28] = "SCRIPTED_GAME_EVENT",
        [29] = "REMOTE_SCRIPT_INFO_EVENT",
        [30] = "REMOTE_SCRIPT_LEAVE_EVENT",
        [31] = "MARK_AS_NO_LONGER_NEEDED_EVENT",
        [32] = "CONVERT_TO_SCRIPT_ENTITY_EVENT",
        [33] = "SCRIPT_WORLD_STATE_EVENT",
        [34] = "CLEAR_AREA_EVENT",
        [35] = "CLEAR_RECTANGLE_AREA_EVENT",
        [36] = "NETWORK_REQUEST_SYNCED_SCENE_EVENT",
        [37] = "NETWORK_START_SYNCED_SCENE_EVENT",
        [38] = "NETWORK_STOP_SYNCED_SCENE_EVENT",
        [39] = "NETWORK_UPDATE_SYNCED_SCENE_EVENT",
        [40] = "INCIDENT_ENTITY_EVENT",
        [41] = "GIVE_PED_SCRIPTED_TASK_EVENT",
        [42] = "GIVE_PED_SEQUENCE_TASK_EVENT",
        [43] = "NETWORK_CLEAR_PED_TASKS_EVENT",
        [44] = "NETWORK_START_PED_ARREST_EVENT",
        [45] = "NETWORK_START_PED_UNCUFF_EVENT",
        [46] = "NETWORK_SOUND_CAR_HORN_EVENT",
        [47] = "NETWORK_ENTITY_AREA_STATUS_EVENT",
        [48] = "NETWORK_GARAGE_OCCUPIED_STATUS_EVENT",
        [49] = "PED_CONVERSATION_LINE_EVENT",
        [50] = "SCRIPT_ENTITY_STATE_CHANGE_EVENT",
        [51] = "NETWORK_PLAY_SOUND_EVENT",
        [52] = "NETWORK_STOP_SOUND_EVENT",
        [53] = "NETWORK_PLAY_AIRDEFENSE_FIRE_EVENT",
        [54] = "NETWORK_BANK_REQUEST_EVENT",
        [55] = "NETWORK_AUDIO_BARK_EVENT",
        [56] = "REQUEST_DOOR_EVENT",
        [57] = "NETWORK_TRAIN_REPORT_EVENT",
        [58] = "NETWORK_TRAIN_REQUEST_EVENT",
        [59] = "NETWORK_INCREMENT_STAT_EVENT",
        [60] = "MODIFY_VEHICLE_LOCK_WORD_STATE_DATA",
        [61] = "MODIFY_PTFX_WORD_STATE_DATA_SCRIPTED_EVOLVE_EVENT",
        [62] = "REQUEST_PHONE_EXPLOSION_EVENT",
        [63] = "REQUEST_DETACHMENT_EVENT",
        [64] = "KICK_VOTES_EVENT",
        [65] = "GIVE_PICKUP_REWARDS_EVENT",
        [66] = "NETWORK_CRC_HASH_CHECK_EVENT",
        [67] = "BLOW_UP_VEHICLE_EVENT",
        [68] = "NETWORK_SPECIAL_FIRE_EQUIPPED_WEAPON",
        [69] = "NETWORK_RESPONDED_TO_THREAT_EVENT",
        [70] = "NETWORK_SHOUT_TARGET_POSITION",
        [71] = "VOICE_DRIVEN_MOUTH_MOVEMENT_FINISHED_EVENT",
        [72] = "PICKUP_DESTROYED_EVENT",
        [73] = "UPDATE_PLAYER_SCARS_EVENT",
        [74] = "NETWORK_CHECK_EXE_SIZE_EVENT",
        [75] = "NETWORK_PTFX_EVENT",
        [76] = "NETWORK_PED_SEEN_DEAD_PED_EVENT",
        [77] = "REMOVE_STICKY_BOMB_EVENT",
        [78] = "NETWORK_CHECK_CODE_CRCS_EVENT",
        [79] = "INFORM_SILENCED_GUNSHOT_EVENT",
        [80] = "PED_PLAY_PAIN_EVENT",
        [81] = "CACHE_PLAYER_HEAD_BLEND_DATA_EVENT",
        [82] = "REMOVE_PED_FROM_PEDGROUP_EVENT",
        [83] = "REPORT_MYSELF_EVENT",
        [84] = "REPORT_CASH_SPAWN_EVENT",
        [85] = "ACTIVATE_VEHICLE_SPECIAL_ABILITY_EVENT",
        [86] = "BLOCK_WEAPON_SELECTION",
        [87] = "NETWORK_CHECK_CATALOG_CRC",
    }

    local function get_net_event_name(event_id)
        return NetEvents[event_id] or ("Unknown (" .. event_id .. ")")
    end

    local player_net_hooks = {}

    m.apf("Log Net Events", "toggle", Higurashi.PlayerUtilities.id, function(f, pid)
        if f.on then
            if not player_net_hooks[pid] then
                player_net_hooks[pid] = hook.register_net_event_hook(function(source, target, EventID)
                    if source == pid then
                        local scid = higurashi.get_user_rid(pid)
                        local name = higurashi.get_user_name(pid) or "Invalid Name"
                        local uuid = scid .. " - " .. name
                        local file = paths.logs .. "\\" .. uuid .. "\\" .. "NetEvents.log"
                        local prefix = higurashi.time_prefix() .. "Net Event Logger"
                        local text = prefix

                        if not utils.file_exists(file) then
                            m.n("Started logging net events.\nProject.Higurashi/logs/", title, 3, c.blue1)
                            text = "Net Events from " .. name .. " RID:" .. scid .. "\n" .. text
                        end

                        local event_name = get_net_event_name(EventID)
                        text = text .. "\nEvent: " .. event_name .. "\nEvent ID: " .. EventID .. "\n"
                        higurashi.write(io.open(file, "a"), text)
                    end
                end)
            end
            return HANDLER_CONTINUE
        end

        if not f.on and player_net_hooks[pid] then
            hook.remove_net_event_hook(player_net_hooks[pid])
            player_net_hooks[pid] = nil
        end
    end)

    m.apf("Clear Script Event Log", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        local scid = higurashi.get_user_rid(pid)
        local name = higurashi.get_user_name(pid) or "Invalid Name"
        local uuid = tostring(scid) .. " - " .. name
        local file = paths.logs .. "\\" .. uuid .. "\\" .. "ScriptEvents.log"
        if utils.file_exists(file) then
            io.remove(file)
            m.n("Deleted script events log.", title, 3, c.green1)
        else
            m.n("There was no log to delete.", title, 3, c.red1)
        end
    end)

    m.apf("Clear Net Event Log", "action", Higurashi.PlayerUtilities.id, function(f, pid)
        local scid = higurashi.get_user_rid(pid)
        local name = higurashi.get_user_name(pid) or "Invalid Name"
        local uuid = tostring(scid) .. " - " .. name
        local file = paths.logs .. "\\" .. uuid .. "\\" .. "NetEvents.log"
        if utils.file_exists(file) then
            io.remove(file)
            m.n("Deleted net events log.", title, 3, c.green1)
        else
            m.n("There was no log to delete.", title, 3, c.red1)
        end
    end)


    function copy_player_info(f, pid)
        local info_to_copy
        if f.value == 0 then
            info_to_copy = higurashi.get_user_name(pid)
            m.n("Copied Username to clipboard.", title, 3, c.blue1)
        elseif f.value == 1 then
            info_to_copy = higurashi.get_user_rid(pid)
            m.n("Copied SCID to clipboard.", title, 3, c.blue1)
        elseif f.value == 2 then
            info_to_copy = higurashi.dec_to_ipv4(player.get_player_ip(pid))
            m.n("Copied IP to clipboard.", title, 3, c.blue1)
        elseif f.value == 3 then
            info_to_copy = higurashi.dec_to_hex(player.get_player_host_token(pid))
            m.n("Copied host token to clipboard.", title, 3, c.blue1)
        end

        if info_to_copy then
            utils.to_clipboard(info_to_copy)
        end
        wait(0)
    end

    m.apf("Copy", "action_value_str", Higurashi.PlayerUtilities.id, copy_player_info):set_str_data({ "Username", "SCID", "IP", "Host Token" })

    if Dev then
        Higurashi.DeveloperFeatures1 = m.apf(c.green2 .. "Developer Features", "parent", Higurashi.Parent1.id)

        m.apf("Inv Veh Decor", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local veh = higurashi.get_player_vehicle(pid, false)
            if veh ~= 0 then
                if higurashi.force_control_of_entity(veh) then
                    local hash = NATIVE.NETWORK_HASH_FROM_PLAYER_HANDLE(pid)
                    local decor_keys = {
                        "Vehicle_Reward", "Vehicle_Reward_Teams", "Skill_Blocker", "TargetPlayerForTeam",
                        "XP_Blocker", "CrowdControlSetUp", "Bought_Drugs", "HeroinInPossession",
                        "CokeInPossession", "WeedInPossession", "MethInPossession", "bombdec",
                        "bombdec1", "bombowner", "noPlateScan", "prisonBreakBoss",
                        "cashondeadbody", "MissionType", "MatchId", "TeamId",
                        "Not_Allow_As_Saved_Veh", "Veh_Modded_By_Player", "MPBitset", "MC_EntityID",
                        "MC_ChasePedID", "MC_Team0_VehDeliveredRules", "MC_Team1_VehDeliveredRules", "MC_Team2_VehDeliveredRules",
                        "MC_Team3_VehDeliveredRules", "AttributeDamage", "GangBackup", "BeforeCorona_0",
                        "BeforeCorona_1", "BeforeCorona_2", "BeforeCorona_3", "BeforeCorona_4",
                        "BeforeCorona_5", "BeforeCorona_6", "BeforeCorona_7", "BeforeCorona_8",
                        "BeforeCorona_9", "BeforeCorona_10", "BeforeCorona_11", "BeforeCorona_12",
                        "BeforeCorona_13", "BeforeCorona_14", "BeforeCorona_15", "Heist_Veh_ID",
                        "CC_iState", "CC_iStatePrev", "CC_iBitSet", "CC_fInfluenceDirectThreat",
                        "CC_fInfluenceShouting", "CC_iBeatdownHitsRemaining", "CC_iBeatdownRounds", "LUXE_MINIGAME_ACT_PROPS",
                        "LUXE_VEH_INSTANCE_ID", "UsingForTimeTrial", "EnableVehLuxeActs", "PHOTO_TAKEN",
                        "doe_elk", "hunt_score", "hunt_weapon", "hunt_undetected",
                        "hunt_nocall", "hunt_chal_weapon", "hunt_kill_time", "DismissedBy",
                        "Darts_name", "Getaway_Winched", "MapGauntlet", "IgnoredByQuickSave",
                        "GetawayVehicleValid", "RampageCarExploded", "Carwash_Vehicle_Decorator", "Casino_Game_Info_Decorator",
                        "MPBitset", "PYV_Owner", "PYV_Vehicle", "Player_Vehicle",
                        "PYV_Yacht", "Player_Moon_Pool", "Player_Avenger", "Company_SUV",
                        "Player_Submarine", "Player_Submarine_Dinghy", "RespawnVeh",
                    }

                    for _, key in ipairs(decor_keys) do
                        NATIVE.DECOR_SET_INT(veh, key, hash)
                    end
                end
            else
                return m.n("No vehicle found.", title, 3, c.red1)
            end
        end)

        m.apf("Control Test", "action_value_str", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local veh = higurashi.get_player_vehicle(pid, false)
            if veh == 0 then
                return m.n("No vehicle found.", title, 3, c.red1)
            end
            local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
            higurashi.force_control_of_entity(veh)
            NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
            local get_owner = network.get_entity_net_owner(veh)
            m.n("Entity Owner: " .. higurashi.get_user_name(get_owner) or "null", "")
            if f.value == 0 then
                NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
            elseif f.value == 1 then
                NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, true)
                network.give_player_control_of_entity(pid, veh)
            elseif f.value == 2 then
                local get_owner = network.get_entity_net_owner(veh)
                m.n("Entity Owner: " .. (higurashi.get_user_name(get_owner) or "null"))
            end
        end):set_str_data({ "Take Control", "Give Control", "Check Entity Owner" })

        m.apf("Lester Spinbot", "action_value_str", Higurashi.DeveloperFeatures1.id, function(f, pid)
            if f.value == 0 then
                local weapon = joaat("weapon_stungun_mp")
                higurashi.request_weapon_asset(weapon)
                local spin_ped = higurashi.create_ped(26, 0x4DA6E849, higurashi.get_player_coords(pid) + v3(0.0, 0.0, -0.5), 0, true, false, true, false, false, true)
                NATIVE.DECOR_SET_INT(spin_ped, "Skill_Blocker", -1)
                higurashi.set_entity_godmode(spin_ped, true)
                NATIVE.GIVE_WEAPON_TO_PED(spin_ped, weapon, 9999, true, true)
                NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(spin_ped, true)
                NATIVE.SET_PED_CURRENT_WEAPON_VISIBLE(spin_ped, false, false, false, false)
                NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spin_ped, true)
                NATIVE.SET_PED_CAN_BE_TARGETTED(spin_ped, false)
                NATIVE.SET_CAN_ATTACK_FRIENDLY(spin_ped, false, true)
                NATIVE.TASK_SHOOT_AT_ENTITY(spin_ped, spin_ped, 999999999, joaat("FIRING_PATTERN_FULL_AUTO"))
            elseif f.value == 1 then
                for _, peds in ipairs(ped.get_all_peds()) do
                    if NATIVE.GET_ENTITY_MODEL(peds) == 0x4DA6E849 and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                        higurashi.hard_remove_entity(peds)
                    end
                end
            end
        end):set_str_data({ "Spawn", "Delete" })

        m.apf("Invaild Weapon Crash", "action", Higurashi.DeveloperFeatures1.id, function(feat, pid)
            local weapon_bomb = joaat("VEHICLE_WEAPON_BOMB_INCENDIARY")
            higurashi.request_weapon_asset(weapon_bomb)
            higurashi.request_model("w_smug_bomb_04", 0)
            local explode_ped = higurashi.create_ped(26, joaat("A_C_Poodle"), higurashi.get_player_coords(pid) + v3(0.0, 0.0, -3.0), 0, true, false, false, false, false, true)
            NATIVE.GIVE_WEAPON_TO_PED(explode_ped, weapon_bomb, 9999, true, true)
            NATIVE.SET_PED_CURRENT_WEAPON_VISIBLE(explode_ped, false, false, false, false)
            NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(explode_ped, false)
            wait()
            higurashi.shoot_bullet(NATIVE.GET_ENTITY_COORDS(explode_ped, false) + v3(), NATIVE.GET_ENTITY_COORDS(explode_ped, false) + v3(), 1, true, weapon_bomb, explode_ped, false, false, 100.0)
            NATIVE.EXPLODE_PROJECTILES(explode_ped, weapon_bomb, true)
            NATIVE.APPLY_DAMAGE_TO_PED(explode_ped, 999999, 1, 0)
            wait(500)
            higurashi.remove_entity({ explode_ped })
        end)

        m.apf("PTFX Loop", "toggle", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local ptfx = { dic = 'scr_rcbarry2', name = 'scr_clown_appears' }

            -- PTFXアセットを要求し、ロードされるまで待機
            NATIVE.REQUEST_NAMED_PTFX_ASSET(ptfx.dic)
            while not NATIVE.HAS_NAMED_PTFX_ASSET_LOADED(ptfx.dic) do
                wait(0)
            end

            -- PTFXアセットを使用する設定
            NATIVE.USE_PARTICLE_FX_ASSET(ptfx.dic)

            while f.on do
                wait(250)

                local defpstarget = NATIVE.GET_PLAYER_PED(pid)
                if NATIVE.DOES_ENTITY_EXIST(defpstarget) then
                    local tar1 = NATIVE.GET_ENTITY_COORDS(defpstarget, false)
                    NATIVE.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD(ptfx.name, tar1.x, tar1.y, tar1.z + 1, 0, 0, 0, 10.0, true, true, true, false)
                end
            end


            NATIVE.REMOVE_NAMED_PTFX_ASSET(ptfx.dic)
        end)


        m.apf("Drop Frame Attack", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local drop_frame = {}
            local drop_frame_count = 1
            higurashi.block_syncs(pid, function()
                local pos = higurashi.get_player_coords(pid)
                local veh_hash = joaat("tug")
                for i = 1, 200 do
                    drop_frame[drop_frame_count] = higurashi.create_vehicle(veh_hash, pos.x, pos.y, pos.z, 0, true, false, false, false, false, false)
                    local netID = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(drop_frame[drop_frame_count])
                    NATIVE.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(netID, pid, true)
                    NATIVE.SET_ENTITY_AS_MISSION_ENTITY(drop_frame[drop_frame_count], true, false)
                    NATIVE.SET_ENTITY_VISIBLE(drop_frame[drop_frame_count], false, false)
                end
                wait(10000)
                for _, tug in pairs(vehicle.get_all_vehicles()) do
                    if NATIVE.GET_ENTITY_MODEL(tug) == joaat(veh_hash) then
                        higurashi.remove_entity({ tug })
                    end
                end
            end)
        end)

        m.apf("Pickup", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local pos = higurashi.get_player_coords(pid)
            local pickup_hash = joaat("PICKUP_WEAPON_STUNROD")
            local model_hash = joaat("W_ME_Rod_M41") --518706036
            --if NATIVE.CAN_REGISTER_MISSION_ENTITIES(0, 0, 0, 1) then
            local pickup = higurashi.create_ambient_pickup(pickup_hash, pos + v3(0.0, 0.0, 0.0), 0, 9999, model_hash, false, true, true, false)
            --end
            NATIVE.ATTACH_PORTABLE_PICKUP_TO_PED(pickup, NATIVE.GET_PLAYER_PED(pid))
        end)

        m.apf("Error Events", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            script.trigger_script_event(0x899ac8a2, pid, { pid, 1, 1, 0, 0 })
            -- script.trigger_script_event(-988842806, pid, { pid, -1 })
        end)

        m.apf("Get Player Coords", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local pos = higurashi.get_player_coords(pid)
            m.n(string.format("%f, %f, %f", pos.x, pos.y, pos.z), title, 3, c.blue1)
            utils.to_clipboard(string.format("%f, %f, %f", pos.x, pos.y, pos.z))
        end)

        m.apf("Get Player Rotation", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local pos = NATIVE.GET_ENTITY_ROTATION(NATIVE.GET_PLAYER_PED(pid), 5)
            m.n(string.format("%f, %f, %f", pos.x, pos.y, pos.z), title, 3, c.blue1)
            utils.to_clipboard(string.format("%f, %f, %f", pos.x, pos.y, pos.z))
        end)

        m.apf("Get Veh Coords", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local veh = higurashi.get_player_vehicle(pid, true)
            if veh ~= 0 then
                local veh_pos = NATIVE.GET_ENTITY_COORDS(veh, false)
                m.n(string.format("%f, %f, %f", veh_pos.x, veh_pos.y, veh_pos.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", veh_pos.x, veh_pos.y, veh_pos.z))
            end
        end)

        m.apf("Get Veh Rotation", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local veh = higurashi.get_player_vehicle(pid, true)
            if veh ~= 0 then
                local veh_rot = NATIVE.GET_ENTITY_ROTATION(veh, 5)
                m.n(string.format("%f, %f, %f", veh_rot.x, veh_rot.y, veh_rot.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", veh_rot.x, veh_rot.y, veh_rot.z))
            end
        end)

        m.apf("Get Veh Name", "action", Higurashi.DeveloperFeatures1.id, function(f, pid)
            local veh = higurashi.get_player_vehicle(pid, true)
            if veh ~= 0 then
                local vehModel = NATIVE.GET_ENTITY_MODEL(veh)
                local vehName = NATIVE.GET_LABEL_TEXT(NATIVE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(vehModel))
                local vehMake = NATIVE.GET_LABEL_TEXT(NATIVE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(vehModel))
                m.n("" .. vehMake .. " " .. vehName)
                utils.to_clipboard(vehName .. vehName)
            end
        end)
    end

    Higurashi.Parent2 = m.af(c.purple2 .. title .. c.default, "parent", 0)

    Higurashi.Self = m.af("Self", "parent", Higurashi.Parent2.id)
    Higurashi.Self.hint = ""

    Higurashi.AimProtection = m.af("Aim Protection", "parent", Higurashi.Self.id)

    Higurashi.IncludeFriendsinAimProtection = m.af("Include Friends", "toggle", Higurashi.AimProtection.id, function(f)
        settings["IncludeFriendsinAimProtection"] = f.on
    end)
    Higurashi.IncludeFriendsinAimProtection.on = settings["IncludeFriendsinAimProtection"]

    local function aim_protection_action(setting_key, message, action)
        Higurashi[setting_key] = m.af(message, "toggle", Higurashi.AimProtection.id, function(f, pid)
            settings[setting_key] = true
            while f.on do
                for pid = 0, 31 do
                    if player.get_entity_player_is_aiming_at(pid) == NATIVE.PLAYER_PED_ID() and (Higurashi.IncludeFriendsinAimProtection.on or higurashi.is_not_friend(pid)) then
                        action(pid)
                    end
                end
                wait(250)
            end
            settings[setting_key] = false
        end)
        Higurashi[setting_key].on = settings[setting_key]
    end

    aim_protection_action("AimProtection1", "Notify", function(pid)
        m.n(higurashi.get_user_name(pid) .. " is aiming at you.", title, 2, c.purple1)
    end)

    aim_protection_action("AimProtection2", "Stun", function(pid)
        higurashi.shoot_bullet(higurashi.get_player_bone_coords(pid, 11816), higurashi.get_player_bone_coords(pid, 39317), 1, true, joaat("WEAPON_STUNGUN_MP"), higurashi.get_random_ped() or -1, false, true, 1.0)
    end)

    aim_protection_action("AimProtection3", "Ragdoll", function(pid)
        higurashi.shoot_bullet(higurashi.get_player_bone_coords(pid, 11816), higurashi.get_player_bone_coords(pid, 39317), 1, true, joaat("WEAPON_SNOWLAUNCHER"), higurashi.get_random_ped() or -1, true, false, 10000.0)
    end)

    aim_protection_action("AimProtection4", "Kill", function(pid)
        higurashi.add_explosion(higurashi.get_random_ped() or -1, higurashi.get_player_bone_coords(pid, 0), 61, 1000.0, true, false, 0)
    end)

    aim_protection_action("AimProtection5", "Blamed Kill", function(pid)
        higurashi.add_explosion(NATIVE.PLAYER_PED_ID(), higurashi.get_player_bone_coords(pid, 0), 61, 1000.0, true, false, 0)
    end)

    aim_protection_action("AimProtection6", "Vehicle Kick", function(pid)
        if NATIVE.GET_VEHICLE_PED_IS_USING(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)) ~= 0 then
            higurashi_globals.vehicle_kick(pid)
        end
    end)

    aim_protection_action("AimProtection7", "Freeze", function(pid)
        higurashi_globals.send_script_event("Warehouse Invite", pid, { -1, -1, 1, 1, -1 })
    end)

    Higurashi.Animation = m.af("Animation", "parent", Higurashi.Self.id, function()
    end)

    local emote_props = {}

    local AnimationProp = {}

    function AnimationProp.add(propmodel, bone, off1, off2, off3, rot1, rot2, rot3)
        local player_ped = NATIVE.PLAYER_PED_ID()
        propmodel = tonumber(propmodel) or joaat(propmodel)
        local prop = higurashi.create_object_no_offset(propmodel, higurashi.get_user_coords(), true, false, false, true, false)
        NATIVE.SET_ENTITY_INVINCIBLE(prop, true)
        NATIVE.ATTACH_ENTITY_TO_ENTITY(prop, player_ped, NATIVE.GET_PED_BONE_INDEX(player_ped, bone), off1 or 0.0, off2 or 0.0, off3 or 0.0, rot1 or 0.0, rot2 or 0.0, rot3 or 0.0, false, false, false, false, 1, true)
        NATIVE.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(prop, false, true)
        table.insert(emote_props, prop)
    end

    function AnimationProp.destroy_all()
        local player_ped = NATIVE.PLAYER_PED_ID()
        for _, ent in ipairs(emote_props) do
            if NATIVE.IS_AN_ENTITY(ent) and player_ped == NATIVE.GET_ENTITY_ATTACHED_TO(ent) and NATIVE.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(player_ped, false) ~= ent then
                higurashi.request_control_of_entity(ent)
                NATIVE.DETACH_ENTITY(ent, true, false)
                higurashi.remove_entity({ ent })
            end
        end
        emote_props = {}
    end

    local Animation = {}

    function Animation.play(EmoteName)
        local player_ped = NATIVE.PLAYER_PED_ID()
        if not NATIVE.IS_AN_ENTITY(player_ped) then return false end
        local InVehicle = ped.is_ped_in_any_vehicle(player_ped, true)
        local ChosenDict, ChosenAnimation, ename = table.unpack(EmoteName)
        local AnimationDuration = -1

        if #emote_props > 0 then AnimationProp.destroy_all() end
        if ChosenDict == "MaleScenario" or ChosenDict == "Scenario" then
            if InVehicle then return end
            NATIVE.CLEAR_PED_TASKS(player_ped)
            if ChosenDict == "MaleScenario" then
                NATIVE.TASK_START_SCENARIO_IN_PLACE(player_ped, ChosenAnimation, 0, true)
            elseif ChosenDict == "ScenarioObject" then
                NATIVE.TASK_START_SCENARIO_AT_POSITION(player_ped, ChosenAnimation, entity.get_entity_coords(player_ped) - v3(0.0, 0.0, 0.5), entity.get_entity_heading(player_ped), 0, true, false)
            else
                NATIVE.TASK_START_SCENARIO_IN_PLACE(player_ped, ChosenAnimation, 0, true)
            end
            print("Playing scenario = (" .. ChosenAnimation .. ")")
            return true
        end

        higurashi.request_anim_dict(ChosenDict, 100)
        local MovementType = 0
        if EmoteName.AnimationOptions then
            local options = EmoteName.AnimationOptions
            if options.EmoteLoop then
                MovementType = options.EmoteMoving and 51 or 1
            elseif options.EmoteMoving then
                MovementType = 51
            elseif options.EmoteStuck then
                MovementType = 50
            end
            AnimationDuration = options.EmoteDuration or -1
        end
        if InVehicle == 1 then MovementType = 51 end
        NATIVE.TASK_PLAY_ANIM(player_ped, ChosenDict, ChosenAnimation, 2.0, 2.0, AnimationDuration, MovementType, 0.0, false, false, false)
        NATIVE.REMOVE_ANIM_DICT(ChosenDict)

        if EmoteName.AnimationOptions and EmoteName.AnimationOptions.Prop then
            local options = EmoteName.AnimationOptions
            AnimationProp.add(options.Prop, options.PropBone, table.unpack(options.PropPlacement))
            if options.SecondProp then
                AnimationProp.add(options.SecondProp, options.SecondPropBone, table.unpack(options.SecondPropPlacement))
            end
        end

        return true
    end

    function Animation.cancel()
        local player_ped = NATIVE.PLAYER_PED_ID()
        NATIVE.CLEAR_PED_TASKS(player_ped)
        AnimationProp.destroy_all()
    end

    Higurashi.StopAnimation = m.af("X Key To Stop Animation", "toggle", Higurashi.Animation.id, function(f)
        settings["StopAnimation"] = f.on
        if f.on and NATIVE.IS_CONTROL_PRESSED(0, 73) then
            Animation.cancel()
        end
        return HANDLER_CONTINUE or HANDLER_POP
    end)
    Higurashi.StopAnimation.on = settings["StopAnimation"]

    local emote_categories = {
        { name = "Animations", id = "Emotes1", emotes = higurashi.emotes },
        { name = "Animation With Props", id = "Emotes2", emotes = higurashi.emotes2 },
        { name = "Dance", id = "Dance", emotes = higurashi.dances },
    }

    for _, category in ipairs(emote_categories) do
        Higurashi[category.id] = m.af(category.name, "parent", Higurashi.Animation.id)
        for key, emote in higurashi.iterate_sorted_keys(category.emotes, function(t, a, b) return t[a][3] < t[b][3] end) do
            m.af(key, "action", Higurashi[category.id].id, function() return Animation.play(emote) end)
        end
    end

    Higurashi.Health = m.af("Health", "parent", Higurashi.Self.id)

    Higurashi.GodMode = m.af("Godmode", "toggle", Higurashi.Health.id, function(f)
        settings["GodMode"] = f.on
        while f.on do
            wait(0)
            higurashi.set_entity_godmode(NATIVE.PLAYER_PED_ID(), true)
            --NATIVE.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(NATIVE.PLAYER_PED_ID(), false)
            --NATIVE.SET_ENTITY_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(NATIVE.PLAYER_PED_ID(), true, 0)
        end
        higurashi.set_entity_godmode(NATIVE.PLAYER_PED_ID(), false)
        --NATIVE.SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(NATIVE.PLAYER_PED_ID(), true)
        --NATIVE.SET_ENTITY_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(NATIVE.PLAYER_PED_ID(), false, 0)
    end)

    Higurashi.GodMode.on = settings["GodMode"]
    Higurashi.GodMode.hint =
    "Your character becomes completely immune to damage. You will still receive damage from the nerve gas in the Casino Heist vault, and also from crashing towards a building at high speeds while in a vehicle."

    local health_preset = { { "Suicide", -1 }, { "Health to 0", 0 }, { "Health to 328", 328 }, { "Health to 1337", 1337 }, { "Health to 6969", 6969 }, { "Health to 999999", 999999 }, { "Health to 2147483647", 2147483647 } }

    for i = 1, #health_preset do
        m.af("" .. health_preset[i][1], "action", Higurashi.Health.id, function(f)
            local own_ped = NATIVE.PLAYER_PED_ID()
            NATIVE.SET_PED_MAX_HEALTH(own_ped, health_preset[i][2])
            if NATIVE.GET_PED_MAX_HEALTH(own_ped) ~= 0 then
                ped.set_ped_health(own_ped, health_preset[i][2])
            else
            end
            return HANDLER_POP
        end)
    end

    Higurashi.Status = m.af("Status Options", "parent", Higurashi.Self.id)

    Higurashi.Heist = m.af("Heist", "parent", Higurashi.Status.id)

    Higurashi.CasinoHeist = m.af("Casino Heist", "parent", Higurashi.Heist.id)

    m.af("Casino Heist Insta Play", "action", Higurashi.CasinoHeist.id, function(f)
        local CHIP1 = {
            { "H3_COMPLETEDPOSIX", -1 }, { "H3OPT_MASKS", 2 }, { "H3OPT_WEAPS", 1 },
            { "H3OPT_VEHS", 3 }, { "CAS_HEIST_FLOW", -1 }, { "H3_LAST_APPROACH", 0 },
            { "H3OPT_APPROACH", 2 }, { "H3_HARD_APPROACH", 0 }, { "H3OPT_TARGET", 3 },
            { "H3OPT_POI", 1023 }, { "H3OPT_ACCESSPOINTS", 2047 },
            { "H3OPT_CREWWEAP", 4 }, { "H3OPT_CREWDRIVER", 3 },
            { "H3OPT_CREWHACKER", 4 }, { "H3OPT_DISRUPTSHIP", 3 },
            { "H3OPT_BODYARMORLVL", -1 }, { "H3OPT_KEYLEVELS", 2 },
            { "H3OPT_BITSET1", 159 }, { "H3OPT_BITSET0", 524118 },
        }
        script.set_global_i(262145 + 29015, 1410065408)
        for i = 1, #CHIP1 do
            higurashi.stat_set_int(CHIP1[i][1], true, CHIP1[i][2])
            m.n("Loaded Casino heist.", title, 2, c.white1)
        end
    end)

    m.af("Remove Cooldown", "action", Higurashi.CasinoHeist.id, function(f)
        local CHRC1 = { { "H3_COMPLETEDPOSIX", -1 }, { "MPPLY_H3_COOLDOWN", -1 } }
        for i = 1, #CHRC1 do
            higurashi.stat_set_int(CHRC1[i][1], true, CHRC1[i][2])
            m.n("Cooldown removed.", title, 2, c.white1)
        end
    end)

    m.af("Reset", "action", Higurashi.CasinoHeist.id, function(f)
        local CHR1 = {
            { "H3_LAST_APPROACH", 0 }, { "H3OPT_APPROACH", 0 },
            { "H3_HARD_APPROACH", 0 }, { "H3OPT_TARGET", 0 }, { "H3OPT_POI", 0 },
            { "H3OPT_ACCESSPOINTS", 0 }, { "H3OPT_BITSET1", 0 },
            { "H3OPT_CREWWEAP", 0 }, { "H3OPT_CREWDRIVER", 0 },
            { "H3OPT_CREWHACKER", 0 }, { "H3OPT_WEAPS", 0 }, { "H3OPT_VEHS", 0 },
            { "H3OPT_DISRUPTSHIP", 0 }, { "H3OPT_BODYARMORLVL", 0 },
            { "H3OPT_KEYLEVELS", 0 }, { "H3OPT_MASKS", 0 }, { "H3OPT_BITSET0", 0 },
        }
        for i = 1, #CHR1 do
            higurashi.stat_set_int(CHR1[i][1], true, CHR1[i][2])
            m.n("Heist removed.", title, 2, c.white1)
        end
    end)

    Higurashi.CayoPerico = m.af("Cayo Perico", "parent", Higurashi.Heist.id)

    m.af("Cayo Perico Insta Play", "action", Higurashi.CayoPerico.id, function(f)
        local CPIP1 = {
            { "H4CNF_BS_GEN", 262143 }, { "H4CNF_BS_ENTR", 63 },
            { "H4CNF_BS_ABIL", 63 }, { "H4CNF_WEP_DISRP", 3 },
            { "H4CNF_ARM_DISRP", 3 }, { "H4CNF_HEL_DISRP", 3 },
            { "H4CNF_BOLTCUT", 4424 }, { "H4CNF_UNIFORM", 5256 },
            { "H4CNF_GRAPPEL", 5156 }, { "H4CNF_APPROACH", -1 },
            { "H4LOOT_CASH_I", 0 }, { "H4LOOT_CASH_C", 0 }, { "H4LOOT_WEED_I", 0 },
            { "H4LOOT_WEED_C", 0 }, { "H4LOOT_COKE_I", 0 }, { "H4LOOT_COKE_C", 0 },
            { "H4LOOT_GOLD_I", 0 }, { "H4LOOT_GOLD_C", 0 }, { "H4LOOT_PAINT", 0 },
            { "H4LOOT_CASH_V", 0 }, { "H4LOOT_COKE_V", 0 }, { "H4LOOT_GOLD_V", 0 },
            { "H4LOOT_PAINT_V", 0 }, { "H4LOOT_WEED_V", 0 },
            { "H4LOOT_CASH_I_SCOPED", 0 }, { "H4LOOT_CASH_C_SCOPED", 0 },
            { "H4LOOT_WEED_I_SCOPED", 0 }, { "H4LOOT_WEED_C_SCOPED", 0 },
            { "H4LOOT_COKE_I_SCOPED", 0 }, { "H4LOOT_COKE_C_SCOPED", 0 },
            { "H4LOOT_GOLD_I_SCOPED", 0 }, { "H4LOOT_GOLD_C_SCOPED", 0 },
            { "H4LOOT_PAINT_SCOPED", 0 }, { "H4CNF_WEAPONS", 1 },
            { "H4_MISSIONS", 65283 }, { "H4_PROGRESS", 126823 },
            { "H4_PLAYTHROUGH_STATUS", 5 },
        }
        for i = 1, #CPIP1 do
            higurashi.stat_set_int(CPIP1[i][1], true, CPIP1[i][2])
            m.n("Loaded Cayo Perico heist.", title, 2, c.white1)
        end
    end)

    m.af("Remove Cooldown", "action", Higurashi.CayoPerico.id, function(f)
        local CPRC1 = { { "H4_COOLDOWN", -1 }, { "H4_COOLDOWN_HARD", -1 } }
        for i = 1, #CPRC1 do
            higurashi.stat_set_int(CPRC1[i][1], true, CPRC1[i][2])
            m.n("Cooldown removed.", title, 2, c.white1)
        end
    end)

    m.af("Reset", "action", Higurashi.CayoPerico.id, function(f)
        local CPR1 = { { "H4_MISSIONS", 0 }, { "H4_PROGRESS", 0 }, { "H4CNF_APPROACH", 0 }, { "H4CNF_BS_ENTR", 0 }, { "H4CNF_BS_GEN", 0 }, { "H4_PLAYTHROUGH_STATUS", 0 } }
        for i = 1, #CPR1 do
            higurashi.stat_set_int(CPR1[i][1], true, CPR1[i][2])
            m.n("Heist removed.", title, 2, c.white1)
        end
    end)

    m.af("Instant Finish Casino / Classic Hesit", "action", Higurashi.Heist.id, function()
        local hash1 = joaat("fm_mission_controller")
        if not NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT() == NATIVE.PLAYER_ID() then
            higurashi.force_script_host()
            wait(3000)
            script.set_local_i(hash1, 19728 + 1741, 80)       -- Casino Aggressive Kills & Act 3
            script.set_local_i(hash1, 19728 + 2686, 10000000) -- How much did you take in the casino and pacific standard heist
            script.set_local_i(hash1, 27489 + 859, 99999)     -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 69, 99999)      -- 'fm_mission_controller' instant finish variable?
        else
            script.set_local_i(hash1, 19728 + 1741, 80)       -- Casino Aggressive Kills & Act 3
            script.set_local_i(hash1, 19728 + 2686, 10000000) -- How much did you take in the casino and pacific standard heist
            script.set_local_i(hash1, 27489 + 859, 99999)     -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 69, 99999)      -- 'fm_mission_controller' instant finish variable?
        end
    end)

    m.af("Instant Finish Doomsday Hesit", "action", Higurashi.Heist.id, function(f)
        local hash1 = joaat("fm_mission_controller")
        if not NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT() == NATIVE.PLAYER_ID() then
            higurashi.force_script_host()
            wait(3000)
            script.set_local_i(hash1, 19728, 12)          -- ???, 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 19728 + 1741, 150)  -- Casino Aggressive Kills & Act 3
            script.set_local_i(hash1, 27489 + 859, 99999) -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 69, 99999)  -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 97, 80)     -- Act 1 Kills? Seem not to work
        else
            script.set_local_i(hash1, 19728, 12)          -- ???, 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 19728 + 1741, 150)  -- Casino Aggressive Kills & Act 3
            script.set_local_i(hash1, 27489 + 859, 99999) -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 69, 99999)  -- 'fm_mission_controller' instant finish variable?
            script.set_local_i(hash1, 31603 + 97, 80)     -- Act 1 Kills? Seem not to work
        end
    end)

    m.af("Instant Finish Cayo / Tuners / ULP / Agency", "action", Higurashi.Heist.id, function(f)
        local hash2 = joaat("fm_mission_controller_2020")
        if not NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT() == NATIVE.PLAYER_ID() then
            higurashi.force_script_host()
            wait(3000)
            script.set_local_i(hash2, 48513 + 1, 51338752)  -- 'fm_mission_controller_2020' instant finish variable?
            script.set_local_i(hash2, 48513 + 1765 + 1, 50) -- 'fm_mission_controller_2020' instant finish variable?
        else
            script.set_local_i(hash2, 48513 + 1, 51338752)  -- 'fm_mission_controller_2020' instant finish variable?
            script.set_local_i(hash2, 48513 + 1765 + 1, 50) -- 'fm_mission_controller_2020' instant finish variable?
        end
    end)

    Higurashi.RemoveCCTVs = m.af("Remove CCTVs", "toggle", Higurashi.Heist.id, function(f)
        settings["RemoveCCTVs"] = f.on
        local cctv_lists = {
            "prop_cctv_cam_01a", "prop_cctv_cam_01b", "prop_cctv_cam_02a",
            "prop_cctv_cam_03a", "prop_cctv_cam_04a", "prop_cctv_cam_04c",
            "prop_cctv_cam_05a", "prop_cctv_cam_06a", "prop_cctv_cam_07a",
            "prop_cs_cctv", "p_cctv_s", "hei_prop_bank_cctv_01",
            "hei_prop_bank_cctv_02", "ch_prop_ch_cctv_cam_02a",
            "xm_prop_x17_server_farm_cctv_01",
        }
        if f.on then
            local cctv_hashes = {}
            for _, model in ipairs(cctv_lists) do
                table.insert(cctv_hashes, joaat(model))
            end
            for _, obj in pairs(object.get_all_objects()) do
                if table.contains(cctv_hashes, NATIVE.GET_ENTITY_MODEL(obj)) then
                    higurashi.remove_entity({ obj })
                end
            end
            wait(1200)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)

    Higurashi.RemoveCCTVs.on = settings["RemoveCCTVs"]

    Higurashi.BadSport = m.af("Bad Sport Manager", "parent", Higurashi.Status.id)

    m.af("Set Bad Sport", "action", Higurashi.BadSport.id, function()
        stats.stat_set_int(2829961636, 1, true)
        stats.stat_set_int(2301392608, 1, true)
    end)

    m.af("Remove Bad Sport", "action", Higurashi.BadSport.id, function()
        stats.stat_set_int(2301392608, 0, true)
    end)

    Higurashi.Account = m.af("Account", "parent", Higurashi.Status.id)

    m.af("Unlock eCola Sprunk plate", "action", Higurashi.Account.id, function()
        NATIVE.STAT_SET_INT(joaat("MPPLY_XMAS23_PLATES0"), -1, true)
    end)

    m.af("Transfer All Money", "action_value_str", Higurashi.Account.id, function(f)
        local wallet_cash = NATIVE.NETWORK_GET_VC_WALLET_BALANCE(0)
        local bank_cash = NATIVE.NETWORK_GET_VC_BANK_BALANCE()
        local transfer_money = (f.value == 0 and wallet_cash > 0) and NATIVE.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK or (f.value == 1 and bank_cash > 0) and NATIVE.NET_GAMESERVER_TRANSFER_BANK_TO_WALLET
        if transfer_money then
            transfer_money(0, f.value == 0 and wallet_cash or bank_cash)
        else
            logger("Funds could not be transferred.", "[Money Transfer]", "Debug.log", true, title, 2, c.red1)
        end
    end):set_str_data({ "To Bank", "To Wallet" })

    m.af("{!} Nightclub Money Loop", "toggle", Higurashi.Account.id, function(f)
        while f.on do
            stats.stat_set_int(joaat(higurashi.get_last_mp("CLUB_POPULARITY")), 1000, f.on)
            stats.stat_set_int(joaat(higurashi.get_last_mp("CLUB_PAY_TIME_LEFT")), -1, f.on)

            wait(250)
        end
    end)

    m.af("{!} 1.25m Orbital Refund Loop", "toggle", Higurashi.Account.id, function(f)
        while f.on do
            script.set_global_i(1961347, 1)
            wait(0)
            script.set_global_i(1961347, 2)
            wait(0)
            script.set_global_i(1961347, 0)
            wait(10000)
        end
    end)

    m.af("{!} 7.9m Sell Personal Vehicle", "toggle", Higurashi.Account.id, function(f)
        while f.on do
            script.set_global_i(101444 + 1018 + 1, 7900000)

            wait(0)
        end
    end)

    m.af("{!} Sell Vehicle Over 50k", "toggle", Higurashi.Account.id, function(f)
        while f.on do
            stats.stat_set_int(joaat("MPPLY_VEHICLE_SELL_TIME"), -1, false)
            script.set_global_i(262145 + 175, 999999999)

            wait(1000)
        end
    end)

    m.af("{!} Reset Vehicle Sell Limit", "toggle", Higurashi.Account.id, function(f)
        while f.on do
            stats.stat_set_int(joaat("MPPLY_VEHICLE_SELL_TIME"), 0, true)
            stats.stat_set_int(joaat("MPPLY_NUM_CARS_SOLD_TODAY"), 0, true)

            wait(1000)
        end
    end)

    Higurashi.AutoREP = m.af("Automatic Reputation Adder", "toggle", Higurashi.Account.id, function(f)
        settings["AutoREP"] = f.on
        local function get_current_rep(value)
            for i = 1, #higurashi.tuners_ranks - 1 do
                if value >= higurashi.tuners_ranks[i][2] and value < higurashi.tuners_ranks[i + 1][2] then
                    return i
                end
            end
            return #higurashi.tuners_ranks
        end

        while f.on do
            local reputation = stats.stat_get_int(joaat("MP0_CAR_CLUB_REP"), -1)
            local level = get_current_rep(reputation) + 1
            local current_level = get_current_rep(reputation)
            if reputation < 997430 then
                if reputation ~= higurashi.tuners_ranks[level][2] - 1 then
                    local next_rep = higurashi.tuners_ranks[level][2] - 1
                    m.n("You have received: " .. higurashi.tuners_unlocks[current_level][2], title, 3, c.green1)
                    stats.stat_set_int(joaat("MP0_CAR_CLUB_REP"), next_rep, true)
                    stats.stat_set_int(joaat("MP1_CAR_CLUB_REP"), next_rep, true)
                    m.n("Tuners Reputation set to " .. next_rep, title, 3, c.blue1)
                    m.n("You will receive " .. higurashi.tuners_unlocks[level][2], title, 3, c.green1)
                else
                    wait(15)
                end
            else
                m.n("Level 1000 reached.", title, 3, c.blue1)
                wait(100)
            end

            wait(0)
        end
        settings["AutoREP"] = false
    end)
    Higurashi.AutoREP.on = settings["AutoREP"] or false

    m.af("Fast Run and Reload", "action_value_str", Higurashi.Account.id, function(f)
        local FAST_RUN_ON = {
            { "CHAR_FM_ABILITY_1_UNLCK", 0xFFFFFFF },
            { "CHAR_FM_ABILITY_2_UNLCK", 0xFFFFFFF },
            { "CHAR_FM_ABILITY_3_UNLCK", 0xFFFFFFF },
            { "CHAR_ABILITY_1_UNLCK", 0xFFFFFFF },
            { "CHAR_ABILITY_2_UNLCK", 0xFFFFFFF },
            { "CHAR_ABILITY_3_UNLCK", 0xFFFFFFF },
        }
        local FAST_RUN_OFF = {
            { "CHAR_FM_ABILITY_1_UNLCK", 0 }, { "CHAR_FM_ABILITY_2_UNLCK", 0 },
            { "CHAR_FM_ABILITY_3_UNLCK", 0 }, { "CHAR_ABILITY_1_UNLCK", 0 },
            { "CHAR_ABILITY_2_UNLCK", 0 }, { "CHAR_ABILITY_3_UNLCK", 0 },
        }
        if f.value == 0 then
            for i = 1, #FAST_RUN_ON do
                higurashi.stat_set_int(FAST_RUN_ON[i][1], true, FAST_RUN_ON[i][2])
            end
        else
            for i = 1, #FAST_RUN_OFF do
                higurashi.stat_set_int(FAST_RUN_OFF[i][1], true, FAST_RUN_OFF[i][2])
            end
        end
    end):set_str_data({ "On", "Off" })

    m.af("Check Current Balance", "action", Higurashi.Account.id, function()
        local function GTAO_USER_MP()
            MP_ = stats.stat_get_int(joaat("MPPLY_LAST_MP_CHAR"), 1)
            return tostring(MP_)
        end
        local PlayerMP = "MP" .. GTAO_USER_MP()
        local wallet_balance = stats.stat_get_i64(joaat(PlayerMP .. "_WALLET_BALANCE"), -1)
        local bank_balance = stats.stat_get_i64(joaat("BANK_BALANCE"))
        m.n("Wallet: $" .. wallet_balance .. "\nBank: $" .. bank_balance .. "", title, 3, c.pink1)
    end)

    m.af("{!} Remove Cash", "action", Higurashi.Account.id, function()
        local custom, amount = input.get("Insert how much to remove", "", 10, 3)
        while custom == 1 do
            wait(0)
            custom, amount = input.get("Insert how much to remove", "", 10, 3)
        end
        if custom == 2 or amount == "" then
            m.n("Canceled.", title, 3, c.red1)
            return HANDLER_POP
        end
        m.n("You want to remove: $" .. amount ..
            "Go to the Interaction Menu/Ballistic Equipment Services/Request Ballistic Equipment",
            title, 3, c.green1)
        script.set_global_i(262145 + 20498, tonumber(amount))
    end)

    m.af("{!} Delete: Character, Stat, Rank, Vehicle", "action", Higurashi.Account.id, function()
        local custom, text = input.get("Type 'Y' to confirm", "", 3, 0)
        while custom == 1 do
            wait(0)
            custom, text = input.get("Type 'Y' to confirm", "", 3, 0)
        end
        if custom == 2 or text == "" then
            m.n("Canceled.", title, 3, c.red1)
            return HANDLER_POP
        end
        if text ~= "Y" then
            m.n("Canceled.", title, 3, c.red1)
            return
        end
        NATIVE.NETWORK_DELETE_CHARACTER(script.get_global_i(1574926), 1, 0)
        m.n("Character deleted, return to story.", title, 3, c.green1)
        wait(1000)
    end)

    Higurashi.Services = m.af("Services", "parent", Higurashi.Status.id)

    m.af("Start CEO", "action", Higurashi.Services.id, function()
        script.set_global_i(1887305 + 1 + (player.player_id() * 610) + 10, player.player_id())
    end)

    m.af("Start MC", "action", Higurashi.Services.id, function()
        script.set_global_i(1887305 + 1 + (player.player_id() * 610) + 10, player.player_id())
        script.set_global_i(1887305 + 1 + (player.player_id() * 610) + 10 + 429, 1)
    end)

    m.af("Remote Access", "action_value_str", Higurashi.Services.id, function(f)
        local script_name_map = {
            "appbunkerbusiness", "appsmuggler", "appbusinesshub",
            "appbikerbusiness", "apparcadebusinesshub", "apphackertruck", "appfixersecurity",
        }
        if NATIVE.IS_PAUSE_MENU_ACTIVE() then
            m.n("Please close your opened pause menu to open any apps remotely.", title, 2, c.red1)
            return
        end
        local script_name = script_name_map[f.value + 1]
        if script_name then
            higurashi.start_script(script_name)
        end
    end):set_str_data({ "Bunker", "Air Cargo", "Nightclub", "The Open Road", "Master Control Terminal", "Touchscreen Terminal", "Agency App" })

    local request_services = {
        { name = "Acid Lab", value = 2738934 + 944 },
        { name = "Avenger", value = 2738934 + 938 },
        { name = "Ballistic Armor", value = 2738934 + 901 },
        { name = "Dinghy", value = 2738934 + 972 },
        { name = "Kosatka", value = 2738934 + 960 },
        { name = "MOC", value = 2738934 + 930 },
        { name = "RC Tank", value = 2738934 + 6894 },
        { name = "RC Bandito", value = 2738934 + 6880 },
        { name = "Terrobyte", value = 2738934 + 943 },
    }

    for _, service in ipairs(request_services) do
        m.af("Request " .. service.name, "action", Higurashi.Services.id, function(f)
            script.set_global_i(service.value, 1)
        end)
    end

    m.af("Toggle Snow", "action_value_str", Higurashi.Status.id, function(f)
        script.set_global_i(262145 + 4575, f.value)
    end):set_str_data({ "Off", "On" })

    m.af("Modify Stone Hatchet Power", "toggle", Higurashi.Status.id, function(f)
        while f.on do
            script.set_global_f(262145 + 25484, 99999)
            script.set_global_f(262145 + 25485, 99999)
            script.set_global_f(262145 + 25486, 0)
            script.set_global_i(262145 + 25479, 99999)
            script.set_global_i(262145 + 25482, 99999)
            script.set_global_i(262145 + 25483, 99999)
            wait(10)
        end
    end)

    Higurashi.SetMentalState = m.af("Set Mental State", "action_value_f", Higurashi.Status.id, function(f)
        local stat_hash = joaat(higurashi.get_last_mp("PLAYER_MENTAL_STATE"))
        local stat_result1 = stats.stat_get_float(stat_hash, 0.0)
        stats.stat_set_float(stat_hash, tonumber(f.value), true)
        local stat_result2 = stats.stat_get_float(stat_hash, 0.0)
        m.n("Current mental state: " .. stat_result2 .. "", title, 2, c.white1)
    end)
    Higurashi.SetMentalState.max = 100.0
    Higurashi.SetMentalState.min = 0.0
    Higurashi.SetMentalState.mod = 50.0
    Higurashi.SetMentalState.value = 0.0

    m.af("Disable Mechanic Cooldown", "toggle", Higurashi.Status.id, function(f)
        while f.on do
            script.set_global_i(262145 + 19048, 0)
            script.set_global_i(262145 + 19049, 0)
            wait(0)
        end
    end)

    m.af("Disable Kosatka Missiles Cooldown", "toggle", Higurashi.Status.id, function(f)
        while f.on do
            script.set_global_i(262145 + 30464, 0)
            script.set_global_i(262145 + 30465, 99999)
            if not f.on then return end
            wait(0)
        end
    end)

    Higurashi.AllMissionsInPrivateSessions = m.af("All Missions In Private Sessions", "toggle", Higurashi.Status.id, function(f)
        settings["AllMissionsInPrivateSessions"] = f.on
        while f.on do
            NATIVE.NETWORK_SESSION_GET_PRIVATE_SLOTS()
            if not f.on then return end
            wait(1000)
        end
        settings["AllMissionsInPrivateSessions"] = false
    end)
    Higurashi.AllMissionsInPrivateSessions.on = settings["AllMissionsInPrivateSessions"] or false

    m.af("Yacht Defences", "toggle", Higurashi.Status.id, function(f)
        if f.on then
            local stat = higurashi.get_last_mp("YACHT_DEFENCE_SETTING")
            local stat_hash = joaat(stat)
            stats.stat_set_int(stat_hash, 7, true)
            return HANDLER_CONTINUE
        end
    end)

    m.af("Max Popular Nightclub", "toggle", Higurashi.Status.id, function(f)
        if f.on then
            local stat = higurashi.get_last_mp("CLUB_POPULARITY")
            local stat_hash = joaat(stat)
            local result = stats.stat_get_int(stat_hash, 1)
            if result < 900 then
                stats.stat_set_int(stat_hash, 1000, true)
                wait(20000)
            end
            return HANDLER_CONTINUE
        end
    end)

    m.af("{!} Reset Orbital Cannon Cooldown", "action", Higurashi.Status.id, function(f)
        local ORBT_CLDWN_ = { { "ORBITAL_CANNON_COOLDOWN", 0 } }
        for i = 1, #ORBT_CLDWN_ do
            higurashi.stat_set_int(ORBT_CLDWN_[i][1], true, ORBT_CLDWN_[i][2])
        end
    end)

    m.af("Unlock Daily Objectives Awards", "action", Higurashi.Status.id, function()
        local ADOB1 = {
            { "AWD_DAILYOBJCOMPLETED", 0 }, { "AWD_DAILYOBJCOMPLETED", 10 },
            { "AWD_DAILYOBJCOMPLETED", 25 }, { "AWD_DAILYOBJCOMPLETED", 50 },
            { "AWD_DAILYOBJCOMPLETED", 100 }, { "CONSECUTIVEWEEKCOMPLETED", 0 },
            { "CONSECUTIVEWEEKCOMPLETED", 7 }, { "CONSECUTIVEWEEKCOMPLETED", 28 },
        }
        local ADOB2 = {
            { "AWD_DAILYOBJWEEKBONUS", true }, { "AWD_DAILYOBJMONTHBONUS", true },
        }
        for i = 1, #ADOB2 do
            higurashi.stat_set_bool(ADOB2[i][1], true, ADOB2[i][2])
            for i = 2, #ADOB1 do
                higurashi.stat_set_int(ADOB1[i][1], true, ADOB1[i][2])
            end
        end
    end)

    m.af("Refill Inventory", "action", Higurashi.Status.id, function()
        local RI1 = {
            { "NO_BOUGHT_YUM_SNACKS", 30 }, { "NO_BOUGHT_HEALTH_SNACKS", 15 },
            { "NO_BOUGHT_EPIC_SNACKS", 5 }, { "NUMBER_OF_ORANGE_BOUGHT", 10 },
            { "NUMBER_OF_BOURGE_BOUGHT", 10 }, { "NUMBER_OF_CHAMP_BOUGHT", 5 },
            { "CIGARETTES_BOUGHT", 20 }, { "MP_CHAR_ARMOUR_1_COUNT", 10 },
            { "MP_CHAR_ARMOUR_2_COUNT", 10 }, { "MP_CHAR_ARMOUR_3_COUNT", 10 },
            { "MP_CHAR_ARMOUR_4_COUNT", 10 }, { "MP_CHAR_ARMOUR_5_COUNT", 10 },
        }
        for i = 1, #RI1 do
            higurashi.stat_set_int(RI1[i][1], true, RI1[i][2])
        end
    end)

    m.af("Remove Vehicle Sell Daily Limit", "action", Higurashi.Status.id, function()
        local VSL1 = {
            { "MPPLY_VEHICLE_SELL_TIME", 0 }, { "MPPLY_NUM_CARS_SOLD_TODAY", 0 },
        }
        for i = 1, #VSL1 do
            higurashi.stat_set_int(VSL1[i][1], true, VSL1[i][2])
            higurashi.stat_set_int(VSL1[i][1], false, VSL1[i][2])
        end
    end)

    m.af("Helmet Visor", "action", Higurashi.Status.id, function()
        local stat = higurashi.get_last_mp("IS_VISOR_UP")
        local stat_hash = joaat(stat)
        local statenow
        local state = stats.stat_get_bool(stat_hash, 0)
        local setstate = not state
        stats.stat_set_bool(stat_hash, setstate, true)
        local stat_result = stats.stat_get_bool(stat_hash, 0)
        if stat_result == true then
            statenow = "UP"
        else
            statenow = "DOWN"
        end
    end)

    m.af("Thermal & Nightvision", "action", Higurashi.Status.id, function()
        local stat = higurashi.get_last_mp("HAS_DEACTIVATE_NIGHTVISION")
        local stat_hash = joaat(stat)
        local state = stats.stat_get_bool(stat_hash, 0)
        local setstate = not state
        local statenow
        stats.stat_set_bool(stat_hash, setstate, true)
        local stat_result = stats.stat_get_bool(stat_hash, 0)
        if stat_result == true then
            statenow = "OFF"
        else
            statenow = "ON"
        end
    end)

    Higurashi.AutoSkipConversation = m.af("Auto Skip Conversation", "toggle", Higurashi.Status.id, function(f)
        settings["AutoSkipConversation"] = f.on
        while f.on do
            if NATIVE.IS_SCRIPTED_CONVERSATION_ONGOING() then
                if index == 1 then
                    NATIVE.STOP_SCRIPTED_CONVERSATION(false)
                elseif index == 2 then
                    NATIVE.SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE()
                end
            end
            if not f.on then return end
            wait(0)
        end
        settings["AutoSkipConversation"] = false
    end)
    Higurashi.AutoSkipConversation.on = settings["AutoSkipConversation"]

    Higurashi.AutoSkipCutscenes = m.af("Auto Skip Cutscenes", "toggle", Higurashi.Status.id, function(f)
        settings["AutoSkipCutscenes"] = f.on
        while f.on do
            if NATIVE.IS_CUTSCENE_PLAYING() then
                NATIVE.STOP_CUTSCENE_IMMEDIATELY()
            end
            if not f.on then return end
            wait(0)
        end
        settings["AutoSkipCutscenes"] = false
    end)
    Higurashi.AutoSkipCutscenes.on = settings["AutoSkipCutscenes"]

    Higurashi.DisableTransactionErrors = m.af("Disable Transaction Errors", "toggle", Higurashi.Status.id, function(f)
        settings["DisableTransactionErrors"] = f.on
        while f.on do
            if script.get_global_i(4536683) == 4 or 20 then
                script.set_global_i(4537455, 0)
                script.set_global_i(4537456, 0)
                script.set_global_i(4537457, 0)
            end
            if not f.on then return end
            wait(100)
        end
        settings["DisableTransactionErrors"] = false
    end)
    Higurashi.DisableTransactionErrors.on = settings["DisableTransactionErrors"]

    Higurashi.InstantRespawn = m.af("Instant Respawn", "toggle", Higurashi.Status.id, function(f)
        settings["InstantRespawn"] = f.on
        if f.on then
            local health = player.get_player_health(player.player_id())
            if health <= 0 then
                NATIVE.ANIMPOSTFX_STOP_ALL()
                local glob = script.get_global_i(2672855 + 1689 + 756)
                glob = glob / 2
                script.set_global_i(2672855 + 1689 + 756, math.floor(glob))
            end
            return HANDLER_CONTINUE
        end
        settings["InstantRespawn"] = false
    end)
    Higurashi.InstantRespawn.on = settings["InstantRespawn"]
    Higurashi.InstantRespawn.hint = ""

    Higurashi.SelfVehicle = m.af("Vehicle Options", "parent", Higurashi.Self.id)

    Higurashi.CustomVehicle = m.af("Custom Vehicles", "parent", Higurashi.SelfVehicle.id)

    m.af("BMX X3", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_1()
    end)

    -- m.af("Deluxo X Savage", "action", Higurashi.CustomVehicle.id, function()
    --    higurashi.vehicle_type_2()
    -- end)

    m.af("Raiju X Lazer", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_3()
    end)

    m.af("Kraken V3", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_4()
    end)

    m.af("MK2 X Thruster", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_5()
    end)

    m.af("MK2 X3", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_6()
    end)

    m.af("Phantom Wedge X3", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_7()
    end)

    m.af("Rocket Voltic X Ramp Buggy", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_8()
    end)

    m.af("Ruiner X Toreador", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_9()
    end)

    -- m.af("Shinigami Starship", "action", Higurashi.CustomVehicle.id, function()
    --    higurashi.vehicle_type_10()
    -- end)

    m.af("Veto Rhesus", "action", Higurashi.CustomVehicle.id, function()
        higurashi.vehicle_type_11()
    end)

    m.af("Delete All Custom Vehicles", "action", Higurashi.CustomVehicle.id, function()
        higurashi.delete_custom_vehicles()
    end)

    Higurashi.AIDriving = m.af("AI Driving", "parent", Higurashi.SelfVehicle.id)

    -- Driving style selection and AI driving functionalities

    local drivingstyle

    local driving_styles = {
        normal = 385,
        take_shortest_path = 262144,
        extremly_rushed1 = 537657381,
        extremly_rushed2 = 1076631588,
        extremly_rushed3 = 1090781748,
    } -- https://vespura.com/fivem/drivingstyle/

    Higurashi.AIDrivingStyle = m.af("Set Driving Style", "autoaction_value_str", Higurashi.AIDriving.id, function(f)
        drivingstyle = driving_styles[f.value == 0 and "normal" or f.value == 1 and "take_shortest_path" or f.value == 2 and "extremly_rushed1" or f.value == 3 and "extremly_rushed2" or "extremly_rushed3"]
    end):set_str_data({ "Normal", "Take Shortest Path", "Extremly Rushed 1", "Extremly Rushed 2", "Extremly Rushed 3" })

    Higurashi.AIDrivingStart = m.af("Enable AI Driving", "value_str", Higurashi.AIDriving.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        local own_ped = NATIVE.PLAYER_PED_ID()
        if f.on and veh ~= 0 then
            local waypoint = ui.get_waypoint_coord()
            NATIVE.SET_DRIVER_ABILITY(own_ped, 1.0)
            NATIVE.SET_DRIVER_AGGRESSIVENESS(own_ped, 0.0)
            if f.value == 0 then
                NATIVE.TASK_VEHICLE_DRIVE_WANDER(own_ped, veh, 100.00, drivingstyle or 0)
            else
                NATIVE.TASK_VEHICLE_DRIVE_TO_COORD(own_ped, veh, v3(waypoint.x, waypoint.y, 0.0), 100.0, 10, NATIVE.GET_ENTITY_MODEL(veh), drivingstyle or 0, 1.0, 1.0)
                if waypoint.x == 16000 and waypoint.y == 16000 then
                    m.n("Waypoint reached.", title, 3, c.blue1)
                    NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(own_ped)
                    NATIVE.SET_PED_INTO_VEHICLE(own_ped, veh, -1)
                end
            end
            wait(5000)
        elseif not f.on then
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(own_ped)
            NATIVE.SET_PED_INTO_VEHICLE(own_ped, veh, -1)
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end):set_str_data({ "Wander Around", "To Waypoint", "To Waypoint & Stop" })

    Higurashi.AIDrivingStop = m.af("Force Stop", "action", Higurashi.AIDriving.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), veh, -1)
        end
    end)

    Higurashi.LicensePlate = m.af("License Plate", "parent", Higurashi.SelfVehicle.id)

    local plates = {
        {
            name = "Project Higurashi",
            sequence = {
                "       G", "      GT", "     GTA", "    GTAV", "   GTAV ",
                "  GTAV M", " GTAV MO", "GTAV MOD", "TAV MOD ", "AV MOD D",
                "V MOD DE", " MOD DEV", "MOD DEVE", "OD DEVEL", "D DEVELO",
                " DEVELOP", "DEVELOPE", "EVELOPER", "VELOPERS", "ELOPERS ",
                "LOPERS  ", "OPERS   ", "PERS    ", "ERS     ", "RS      ",
                "S       ", "        ",
            },
        },
        {
            name = "Scum Gang 69",
            sequence = {
                "       S", "      SC", "     SCU", "    SCUM", "   SCUM ",
                "  SCUM G", " SCUM GA", "SCUM GAN", "CUM GANG", "UM GANG ",
                "M GANG 6", " GANG 69", "ANG 69  ", "NG 69   ", "G 69    ",
                " 69     ", "69      ", "9       ", "        ",
            },
        },
        {
            name = "Higurashi When They Cry",
            sequence = {
                "       H", "      HI", "     HIG", "    HIGU", "   HIGUR",
                "  HIGURA", " HIGURAS", "HIGURASH", "IGURASHI", "GURASHI ",
                "URASHI W", "RASHI WH", "ASHI WHE", "SHI WHEN", "HI WHEN ",
                "I WHEN T", " WHEN TH", "WHEN THE", "HEN THEY", "EN THEY ",
                "N THEY C", " THEY CR", "THEY CRY", "HEY CRY ", "EY CRY  ",
                "Y CRY   ", " CRY    ", "CRY     ", "RY      ", "Y       ",
                "        ",
            },
        },
    }

    Higurashi.LicensePlateAninmation = m.af("Animation", "value_str", Higurashi.LicensePlate.id, function(f)
        if f.on then
            local plate = plates[f.value + 1]
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                for i = 1, #plate.sequence do
                    if f.on then
                        NATIVE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, plate.sequence[i])
                        wait(200)
                    else
                        NATIVE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "")
                        return HANDLER_POP
                    end
                end
            end
        end
        return HANDLER_CONTINUE
    end):set_str_data({ plates[1].name, plates[2].name, plates[3].name })

    local speedometer_units = {
        { " MPS", 1, "Meter per Second" }, { " MPH", 2.23694, "Miles per Hour" },
        { " KMH", 3.6, "Kilometers per Hour" }, { " KN", 1.94384, "Knots" },
        { " FPS", 3.28084, "Feet per Second" },
        { "MACH", 0.002915451895, "MACH / Soundspeed" },
        { "C", 0.00000333564095198, "Lightspeed in 300,000 Kilometers" },
        { " KPS", 0.001, "Kilometers per Second" },
        { " MPK", 864, "Meters per Kermit" },
        { " KPK", 0.864, "Kilometers per Kermit" },
        { " MPM", 90, "Meters per Moment" },
        { " HPS", 9.84252, "Hands per Second" },
        { " HPM", 25, "Horses per Minute" },
        { " BPM", 39.37007874, "Bathtubs per Minute" },
    }

    Higurashi.Speedometer = m.af("License Plate Speedometer", "value_i", Higurashi.LicensePlate.id, function(f)
        if f.on then
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                local sp = NATIVE.GET_ENTITY_SPEED(veh) * speedometer_units[f.value][2]
                sp = sp < 10 and sp > 0.01 and string.format("%.2f", sp) or sp >= 10 and sp < 100 and string.format("%.1f", sp) or sp < 0.01 and f.value == 7 and string.format("%.5f", sp) or math.floor(sp)
                NATIVE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, tostring(sp) .. speedometer_units[f.value][1])
            end
        else
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.Speedometer.max = #speedometer_units
    Higurashi.Speedometer.min = 1


    Higurashi.OwnVehicle = m.af("Own Vehicle", "parent", Higurashi.SelfVehicle.id)

    m.af("Teleport Own Vehicle To Me", "action", Higurashi.OwnVehicle.id, function()
        local veh = player.get_personal_vehicle()
        if veh ~= 0 then
            higurashi.set_velocity_and_coords(veh, higurashi.offset_coords(higurashi.get_user_coords(), higurashi.user_ped_heading(), 5))
            NATIVE.SET_ENTITY_HEADING(veh, higurashi.user_ped_heading())
        end
    end)

    m.af("Teleport Own Vehicle To Me & Drive", "action", Higurashi.OwnVehicle.id, function()
        local veh = player.get_personal_vehicle()
        if veh ~= 0 then
            higurashi.set_velocity_and_coords(veh, higurashi.get_user_coords())
            NATIVE.SET_ENTITY_HEADING(veh, higurashi.user_ped_heading())
            NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), veh, -1)
        end
    end)

    m.af("Drive Own Vehicle", "action", Higurashi.OwnVehicle.id, function()
        local veh = player.get_personal_vehicle()
        if veh ~= 0 then
            NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), veh, -1)
        end
    end)

    m.af("Teleport To Own Vehicle", "action", Higurashi.OwnVehicle.id, function()
        local veh = player.get_personal_vehicle()
        if veh ~= 0 then
            higurashi.teleport_to(higurashi.offset_coords(NATIVE.GET_ENTITY_COORDS(veh, false), NATIVE.GET_ENTITY_HEADING(veh), -5), 0, NATIVE.GET_ENTITY_HEADING(veh))
        end
    end)

    m.af("Vehicle Godmode", "action_value_str", Higurashi.SelfVehicle.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            if f.value == 0 then
                NATIVE.SET_ENTITY_PROOFS(veh, true, true, true, true, true, true, true, true, true)
                NATIVE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, false)
                NATIVE.SET_VEHICLE_CAN_BREAK(veh, false)
                NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, false)
                NATIVE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, false)
            elseif f.value == 1 then
                NATIVE.SET_ENTITY_PROOFS(veh, false, false, false, false, false, false, false, false, false)
                NATIVE.SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(veh, true)
                NATIVE.SET_VEHICLE_CAN_BREAK(veh, true)
                NATIVE.SET_VEHICLE_TYRES_CAN_BURST(veh, true)
                NATIVE.SET_VEHICLE_WHEELS_CAN_BREAK(veh, true)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    Higurashi.HazardLights = m.af("Hazard Lights", "toggle", Higurashi.SelfVehicle.id, function(f)
        if f.on then
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 0, true)
                NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 1, true)
            end
        end
        if not f.on then
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 0, false)
                NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 1, false)
            end
            return HANDLER_POP
        end
        settings["HazardLights"] = f.on
        return HANDLER_CONTINUE
    end)

    Higurashi.Blinker = m.af("Blinker", "toggle", Higurashi.SelfVehicle.id, function(f)
        if f.on then
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                if NATIVE.IS_CONTROL_PRESSED(0, 63) then
                    NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 1, true)
                else
                    NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 1, false)
                    if NATIVE.IS_CONTROL_PRESSED(0, 64) then
                        NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 0, true)
                    else
                        NATIVE.SET_VEHICLE_INDICATOR_LIGHTS(veh, 0, false)
                    end
                end
            end
        end
        settings["Blinker"] = f.on
        return HANDLER_CONTINUE
    end)

    m.af("Drift Mode", "action", Higurashi.SelfVehicle.id, function()
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= nil then
            NATIVE.SET_ENTITY_MAX_SPEED(veh, 30.0)
            NATIVE.MODIFY_VEHICLE_TOP_SPEED(veh, 200.0)
        end
    end)

    Higurashi.KeepEngineOn = m.af("Keep Engine On", "toggle", Higurashi.SelfVehicle.id, function(f)
        settings["KeepEngineOn"] = f.on
        while f.on do
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(veh, true)
            else
                m.n("No vehicle found.", title, 3, c.red1)
            end
            wait(1000)
        end
        if not f.on then
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(veh, false)
            end
        end
        settings["KeepEngineOn"] = false
    end)

    Higurashi.KeepEngineOn.on = settings["KeepEngineOn"]

    m.af("Prevent Lock-On", "action_value_str", Higurashi.SelfVehicle.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            if f.value == 0 then
                NATIVE.SET_VEHICLE_CAN_BE_LOCKED_ON(veh, false, false)
                NATIVE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, false, false)
            else
                NATIVE.SET_VEHICLE_CAN_BE_LOCKED_ON(veh, true, true)
                NATIVE.SET_VEHICLE_ALLOW_HOMING_MISSLE_LOCKON(veh, true, true)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Enable", "Disable" })

    Higurashi.BlockControlPersonalVehicle = m.af("Block Control Personal Vehicle", "toggle", Higurashi.SelfVehicle.id, function(f)
        settings["BlockControlPersonalVehicle"] = f.on
        while f.on do
            if NATIVE.NETWORK_IS_PLAYER_CONNECTED(NATIVE.PLAYER_ID()) and NATIVE.NETWORK_IS_SESSION_STARTED() then
                local veh = player.get_personal_vehicle()
                if veh ~= 0 then
                    local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
                    higurashi.request_control_of_id(net_id)
                    NATIVE.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
                    NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
                    NATIVE.SET_NETWORK_ID_CAN_BE_REASSIGNED(net_id, false)
                end
            end
            wait(1500)
        end
        settings["BlockControlPersonalVehicle"] = false
    end)
    Higurashi.BlockControlPersonalVehicle.on = settings["BlockControlPersonalVehicle"]

    Higurashi.AutoRepair = m.af("Auto Repair", "toggle", Higurashi.SelfVehicle.id, function(f)
        settings["AutoRepair"] = f.on
        while f.on do
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                higurashi.repair_car(veh)
                local health = NATIVE.GET_ENTITY_HEALTH(veh)
                local max_health = NATIVE.GET_ENTITY_MAX_HEALTH(veh)
                if health < max_health then
                    higurashi.repair_car(veh)
                end
            end
            wait(500)
        end
        settings["AutoRepair"] = false
    end)
    Higurashi.AutoRepair.on = settings["AutoRepair"]

    local lock_counter = 0
    Higurashi.AccessLockedVehicles = m.af("Access Locked Vehicles", "toggle", Higurashi.SelfVehicle.id, function(f)
        settings["AccessLockedVehicles"] = f.on
        while f.on do
            for pid in higurashi.players() do
                local ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                local veh = NATIVE.GET_VEHICLE_PED_IS_USING(ped)
                if veh ~= 0 then
                    if NATIVE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, NATIVE.PLAYER_ID()) and NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 160) then
                        repeat
                            if lock_counter > 250 and not NATIVE.IS_PED_IN_ANY_VEHICLE(NATIVE.PLAYER_PED_ID(), false) and not NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 2) then
                                lock_counter = 0
                                return
                            end
                            NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, NATIVE.PLAYER_ID(), false)
                            NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(pid, false)
                            NATIVE.SET_VEHICLE_DOORS_LOCKED(veh, 1) -- Force unlock doors for everyone
                            lock_counter = lock_counter + 1
                            wait()
                        until not NATIVE.GET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, NATIVE.PLAYER_ID())
                        lock_counter = 0
                    end
                end
            end
            wait(1000)
        end
        settings["AccessLockedVehicles"] = false
    end)
    Higurashi.AccessLockedVehicles.on = settings["AccessLockedVehicles"]

    m.af("Door Lock", "value_str", Higurashi.SelfVehicle.id, function(f)
        while f.on do
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                if f.value == 0 then
                    value = true
                elseif f.value == 1 then
                    value = false
                end
                for pid in higurashi.players() do
                    NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, pid, value)
                end
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(veh, value)
            else
                return
            end
            wait(1000)
        end
    end):set_str_data({ "Enable", "Disable" })

    m.af("Vehicle Customization", "action_value_str", Higurashi.SelfVehicle.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            if f.value == 0 then
                higurashi.modify_vehicle(veh, "upgrade")
            elseif f.value == 1 then
                higurashi.modify_vehicle(veh, "downgrade")
            elseif f.value == 2 then
                higurashi.upgrade_all_vehicle_parts(veh)
            end
        else
            return m.n("No vehicle found.", title, 3, c.red1)
        end
    end):set_str_data({ "Upgrade", "Downgrade", "" })

    m.af("No Collision", "toggle", Higurashi.SelfVehicle.id, function(f)
        while f.on do
            wait(0)
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                local all_peds = ped.get_all_peds()
                for _, ped_id in ipairs(all_peds) do
                    if not NATIVE.IS_PED_A_PLAYER(ped_id, -1, false) and higurashi.request_control_of_entity(ped_id) then
                        entity.set_entity_no_collsion_entity(ped_id, veh, true)
                        entity.set_entity_no_collsion_entity(veh, ped_id, true)
                    end
                end
                local all_objects = object.get_all_objects()
                for _, obj_id in ipairs(all_objects) do
                    entity.set_entity_no_collsion_entity(obj_id, veh, true)
                    entity.set_entity_no_collsion_entity(veh, obj_id, true)
                end
                local all_vehs = vehicle.get_all_vehicles()
                for _, veh_id in ipairs(all_vehs) do
                    local seat_ped = NATIVE.GET_PED_IN_VEHICLE_SEAT(veh_id)
                    if not NATIVE.IS_PED_A_PLAYER(seat_ped, -1, false) and
                        not NATIVE.DECOR_EXIST_ON(veh_id, "Player_Vehicle") and higurashi.request_control_of_entity(veh_id) then
                        entity.set_entity_no_collsion_entity(veh_id, veh, true)
                        entity.set_entity_no_collsion_entity(veh, veh_id, true)
                    end
                end
            end
        end
    end)

    m.af("Rocket Boost Refill", "toggle", Higurashi.SelfVehicle.id, function(f)
        if f.on then
            if NATIVE.IS_PED_IN_ANY_VEHICLE(NATIVE.PLAYER_PED_ID()) == true then
                local veh = higurashi.get_user_vehicle(false)
                if NATIVE.IS_VEHICLE_ROCKET_BOOST_ACTIVE(veh) == false then
                    return HANDLER_CONTINUE
                end
                wait(1500)
                NATIVE.SET_VEHICLE_ROCKET_BOOST_PERCENTAGE(veh, 100.0)
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)

    m.af("Infinite F1 Boost", "toggle", Higurashi.SelfVehicle.id, function(f)
        local f1_hashes = { 0x1446590A, 0x8B213907, 0x58F77553, 0x4669D038 }
        while f.on do
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                for x = 1, #f1_hashes do
                    if NATIVE.GET_ENTITY_MODEL(veh) == f1_hashes[x] then
                        NATIVE.SET_VEHICLE_FIXED(veh)
                        local speed = NATIVE.GET_ENTITY_SPEED(veh)
                        if speed > 75.0 then
                            NATIVE.SET_VEHICLE_FORWARD_SPEED(veh, speed)
                        end
                    end
                end
            end
            wait(2500)
        end
    end)

    Higurashi.NitrousMod = m.af("Nitrous Mod", "value_f", Higurashi.SelfVehicle.id, function(f)
        local veh = higurashi.get_user_vehicle(false)
        local ptfx_asset = "veh_xs_vehicle_mods"

        if veh == 0 then
            return
        end

        if f.on then
            higurashi.set_ptfx_asset(ptfx_asset)
            NATIVE.SET_OVERRIDE_NITROUS_LEVEL(veh, true, f.value, f.value, 100.0, false)
        else
            NATIVE.SET_OVERRIDE_NITROUS_LEVEL(veh, false, 0.0, 0.0, 100.0, false)
            NATIVE.REMOVE_NAMED_PTFX_ASSET(ptfx_asset)
            NATIVE.REMOVE_PARTICLE_FX_FROM_ENTITY(veh)
        end
    end)

    Higurashi.NitrousMod.max = 100.0
    Higurashi.NitrousMod.min = 0.0
    Higurashi.NitrousMod.mod = 1.0
    Higurashi.NitrousMod.value = 1.0

    Higurashi.PreventAutoSeatShuffle = m.af("Prevent Auto Seat Shuffle", "toggle", Higurashi.SelfVehicle.id, function(f)
        local playerPed = NATIVE.PLAYER_PED_ID()
        if f.on then
            NATIVE.SET_PED_CONFIG_FLAG(playerPed, 184, true)
        else
            NATIVE.SET_PED_CONFIG_FLAG(playerPed, 184, false)
            return HANDLER_POP
        end
        settings["PreventAutoSeatShuffle"] = f.on
        return HANDLER_CONTINUE
    end)

    Higurashi.SwapVehicleSeat = m.af("Swap Vehicle Seat", "autoaction_value_i", Higurashi.SelfVehicle.id, function()
        local veh = higurashi.get_user_vehicle(false)
        if veh ~= 0 then
            NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), veh, Higurashi.SwapVehicleSeat.value)
        end
    end)
    Higurashi.SwapVehicleSeat.min = -1
    Higurashi.SwapVehicleSeat.value = -1
    Higurashi.SwapVehicleSeat.max = NATIVE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(NATIVE.GET_ENTITY_MODEL(higurashi.get_user_vehicle(false)))

    Higurashi.SelfWeapons = m.af("Weapons", "parent", Higurashi.Self.id)

    Higurashi.Crosshair = m.af("Show Crosshair", "toggle", Higurashi.SelfWeapons.id, function(f)
        if f.on then
            while f.on do
                wait(0)
                NATIVE.SHOW_HUD_COMPONENT_THIS_FRAME(14)
                wait()
            end
        end
        settings["Crosshair"] = f.on
    end)

    m.af("Infinite Parachutes", "toggle", Higurashi.SelfWeapons.id, function(f)
        if f.on and not weapon.has_ped_got_weapon(NATIVE.PLAYER_PED_ID(), 0xFBAB5776) then
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.PLAYER_PED_ID(), 0xFBAB5776, 1, false)
        end
        settings["InfiniteParachutes"] = f.on
        return HANDLER_CONTINUE
    end)

    Higurashi.ChangeWeaponImpact = m.af("Change Bullet Impact", "value_str", Higurashi.SelfWeapons.id, function(f)
        if f.on then
            if player.is_player_free_aiming(NATIVE.PLAYER_ID()) then
                if NATIVE.IS_PED_SHOOTING(NATIVE.PLAYER_PED_ID()) then
                    if NATIVE.IS_PED_SHOOTING(NATIVE.PLAYER_PED_ID()) then
                        -- NATIVE.DISABLE_PLAYER_FIRING(NATIVE.PLAYER_ID(), true)
                        for i = 1, 1 do
                            if f.value == 0 then
                                WeaponImpact =
                                    joaat("VEHICLE_WEAPON_AVENGER_CANNON")
                            elseif f.value == 1 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_SUBCAR_MISSILE")
                            elseif f.value == 2 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_RCTANK_ROCKET")
                            elseif f.value == 3 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_OPPRESSOR2_CANNON")
                            elseif f.value == 4 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_RCTANK_LAZER")
                            elseif f.value == 5 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_THRUSTER_MISSILE")
                            elseif f.value == 6 then
                                WeaponImpact = joaat("WEAPON_STUNGUN")
                            elseif f.value == 7 then
                                WeaponImpact = joaat("WEAPON_ACIDPACKAGE")
                            elseif f.value == 8 then
                                WeaponImpact = joaat("WEAPON_TRANQUILIZER")
                            elseif f.value == 9 then
                                WeaponImpact = joaat("WEAPON_EMPLAUNCHER")
                            elseif f.value == 10 then
                                WeaponImpact = joaat("WEAPON_MOLOTOV")
                            elseif f.value == 11 then
                                WeaponImpact = joaat("WEAPON_RAILGUNXM3")
                            elseif f.value == 12 then
                                WeaponImpact = joaat("WEAPON_GRENADELAUNCHER_SMOKE")
                            elseif f.value == 13 then
                                WeaponImpact = joaat("WEAPON_BIRD_CRAP")
                            elseif f.value == 14 then
                                WeaponImpact = joaat("WEAPON_SNOWBALL")
                            elseif f.value == 15 then
                                WeaponImpact = joaat("WEAPON_FLARE")
                            elseif f.value == 16 then
                                WeaponImpact = joaat("WEAPON_PIPEBOMB")
                            elseif f.value == 17 then
                                WeaponImpact = joaat("WEAPON_RAYPISTOL")
                            elseif f.value == 18 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_ROTORS")
                            elseif f.value == 19 then
                                WeaponImpact = joaat("VEHICLE_WEAPON_PLAYER_SAVAGE")
                            end
                            if not NATIVE.HAS_WEAPON_ASSET_LOADED(WeaponImpact) then
                                NATIVE.REQUEST_WEAPON_ASSET(WeaponImpact, 31, false)
                            end
                            local weapon_ent = NATIVE.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(NATIVE.PLAYER_PED_ID(), false)
                            local weapon_bone = NATIVE.GET_ENTITY_BONE_INDEX_BY_NAME(weapon_ent, "gun_muzzle")
                            local weapon_bone_pos = NATIVE.GET_ENTITY_BONE_POSTION(weapon_ent, weapon_bone)
                            local v3_end = higurashi.get_user_coords()
                            dir = NATIVE.GET_GAMEPLAY_CAM_ROT()
                            dir:transformRotToDir()
                            dir = dir * 1500
                            v3_end = v3_end + dir
                            NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(weapon_bone_pos.x, weapon_bone_pos.y, weapon_bone_pos.z, v3_end, 1000, true, WeaponImpact, NATIVE.PLAYER_PED_ID(), false, true, 1000.0)
                            NATIVE.SET_CONTROL_SHAKE(0, 50, 100)
                            if NATIVE.IS_DISABLED_CONTROL_JUST_RELEASED(0, 24) then
                                NATIVE.STOP_CONTROL_SHAKE(0)
                                settings["ChangeWeaponImpact"] = f.value
                            end
                        end
                    end
                end
            end
        end
        if not f.on then
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end):set_str_data({
        "VEHICLE_WEAPON_AVENGER_CANNON", "VEHICLE_WEAPON_SUBCAR_MISSILE", "VEHICLE_WEAPON_RCTANK_ROCKET",
        "VEHICLE_WEAPON_OPPRESSOR2_CANNON", "VEHICLE_WEAPON_RCTANK_LAZER", "VEHICLE_WEAPON_THRUSTER_MISSILE",
        "WEAPON_STUNGUN", "WEAPON_ACIDPACKAGE", "WEAPON_TRANQUILIZER", "WEAPON_EMPLAUNCHER", "WEAPON_MOLOTOV",
        "WEAPON_RAILGUNXM3", "WEAPON_GRENADELAUNCHER_SMOKE", "WEAPON_BIRD_CRAP", "WEAPON_SNOWBALL",
        "WEAPON_FLARE", "WEAPON_PIPEBOMB", "WEAPON_RAYPISTOL", "VEHICLE_WEAPON_ROTORS", "VEHICLE_WEAPON_PLAYER_SAVAGE",
    })

    Higurashi.RainbowWeapon = m.af("Rainbow Weapon", "value_i", Higurashi.SelfWeapons.id, function(f)
        local own_ped = NATIVE.PLAYER_PED_ID()
        if f.on and not NATIVE.IS_ENTITY_DEAD(own_ped) then
            NATIVE.SET_PED_WEAPON_TINT_INDEX(own_ped, ped.get_current_ped_weapon(own_ped), math.random(0, NATIVE.GET_WEAPON_TINT_COUNT(ped.get_current_ped_weapon(own_ped))))
        end
        wait(f.value)
        settings["RainbowWeapon"] = f.value
        return HANDLER_CONTINUE
    end)
    Higurashi.RainbowWeapon.min = 0
    Higurashi.RainbowWeapon.max = 1000
    Higurashi.RainbowWeapon.value = 100
    Higurashi.RainbowWeapon.mod = 100

    Higurashi.TeleportGun = m.af("Teleport Gun", "toggle", Higurashi.SelfWeapons.id, function(f)
        while f.on do
            local bool_rtn, v3_coord = ped.get_ped_last_weapon_impact(NATIVE.PLAYER_PED_ID())
            local v2_coord = v2(v3_coord.x, v3_coord.y)
            if v2_coord.x ~= 0 or v2_coord.y ~= 0 then
                NATIVE.SET_NEW_WAYPOINT(v2_coord.x, v2_coord.y)
                m.gfbhk("local.teleport.waypoint"):toggle()
            end
            wait()
        end
        settings["TeleportGun"] = f.on
    end)

    m.af("Delete Gun", "toggle", Higurashi.SelfWeapons.id, function(f)
        if f.on then
            if NATIVE.IS_PED_SHOOTING(NATIVE.PLAYER_PED_ID()) then
                local aimed_entity = player.get_entity_player_is_aiming_at(NATIVE.PLAYER_ID())
                if aimed_entity and NATIVE.IS_AN_ENTITY(aimed_entity) then
                    higurashi.hard_remove_entity(aimed_entity)
                end
            end
        end
        settings["DeleteGun"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)

    m.af("Hash Gun", "toggle", Higurashi.SelfWeapons.id, function(f)
        while f.on do
            local hash = higurashi.dec_to_hex(joaat(player.get_entity_player_is_aiming_at(NATIVE.PLAYER_ID())))
            if NATIVE.IS_PED_SHOOTING(NATIVE.PLAYER_PED_ID()) then
                if NATIVE.IS_AN_ENTITY(player.get_entity_player_is_aiming_at(NATIVE.PLAYER_ID())) then
                    utils.to_clipboard(hash)
                    m.n("Copied entity hash: 0x" .. hash .. " to clipboard.", title, 3, c.blue1)
                end
            end
            wait(200)
        end
        settings["HashGun"] = f.on
    end)

    Higurashi.DoubleTap = m.af("Double Tap", "toggle", Higurashi.SelfWeapons.id, function(f)
        if f.on then
            if NATIVE.IS_PED_SHOOTING(NATIVE.PLAYER_PED_ID()) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        if not f.on then return HANDLER_POP end
    end)

    Higurashi.FastWeaponSwap = m.af("Fast Swap Current Weapon", "toggle", Higurashi.SelfWeapons.id, function(feat)
        if feat.on then
            local me = NATIVE.PLAYER_PED_ID()
            if not NATIVE.IS_ENTITY_DEAD(me) then
                if not (player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) or NATIVE.IS_PED_IN_ANY_VEHICLE(me)) then
                    local current_weapon = NATIVE.GET_SELECTED_PED_WEAPON(me)
                    local weapon_type = weapon.get_weapon_weapon_type(current_weapon)

                    if weapon_type ~= 3189615009 then
                        if ped.is_ped_shooting(me) and not NATIVE.IS_ENTITY_DEAD(me) then
                            local success, error_message = pcall(function()
                                higurashi_weapon.remove_weapon_from(NATIVE.PLAYER_ID(), current_weapon)
                                while NATIVE.IS_ENTITY_DEAD(me) do
                                    wait(100)
                                end
                                higurashi_weapon.give_weapon_to(NATIVE.PLAYER_ID(), current_weapon, true)
                                higurashi_weapon.give_ammo(NATIVE.PLAYER_ID(), weapon_type, true)
                            end)

                            if not success then
                                -- print("武器のスワップ中にエラーが発生しました: " .. error_message)
                            end
                        end
                    end
                end
            end
            settings["FastWeaponSwap"] = feat.on
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)

    m.af("Get Parachute", "action", Higurashi.SelfWeapons.id, function()
        NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.PLAYER_PED_ID(), joaat("GADGET_PARACHUTE"), 1, 0)
    end)

    m.af("All Weapons", "action_value_str", Higurashi.SelfWeapons.id, function(f)
        for _, weapon_hash in pairs(weapon.get_all_weapon_hashes()) do
            if f.value == 0 then
                NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.PLAYER_PED_ID(), weapon_hash, 9999, true)
            elseif f.value == 1 then
                NATIVE.REMOVE_ALL_PED_WEAPONS(NATIVE.PLAYER_PED_ID(), true)
            elseif f.value == 2 then
                higurashi_weapon.set_ped_weapon_attachments(NATIVE.PLAYER_PED_ID(), false, weapon_hash)
            end
        end
    end):set_str_data({ "Give", "Remove", "Max" })

    m.af("Weapon Selection", "action_value_str", Higurashi.SelfWeapons.id, function(f)
        if f.value == 0 then
            ped.set_ped_can_switch_weapons(NATIVE.PLAYER_PED_ID(), true)
        elseif f.value == 1 then
            ped.set_ped_can_switch_weapons(NATIVE.PLAYER_PED_ID(), false)
        end
    end):set_str_data({ "Block", "Unlock" })

    Higurashi.WeaponLoadout = m.af("Weapon Loadout", "parent", Higurashi.SelfWeapons.id)

    for i = 1, #higurashi_weapon.weapons do
        m.af("Equip: " .. higurashi_weapon.weapons[i][1], "action", Higurashi.WeaponLoadout.id, function()
            NATIVE.GIVE_DELAYED_WEAPON_TO_PED(NATIVE.PLAYER_PED_ID(), higurashi_weapon.weapons[i][2], 9999, true)
        end)
    end

    Higurashi.Communication2 = m.af("Communication", "parent", Higurashi.Parent2.id)

    m.af("Send Text Message To Session", "action", Higurashi.Communication2.id, function(f, pid)
        local custom, text = input.get("Enter custom message", "", 128, 0)
        while custom == 1 do
            wait(0)
            custom, text = input.get("Enter custom message", "", 128, 0)
        end
        if custom == 2 then return HANDLER_POP end
        for pid = 0, 31 do
            if player.is_player_valid(pid) then
                NATIVE.NETWORK_SEND_TEXT_MESSAGE(text, higurashi.get_gamer_handle(pid))
            end
        end
    end)

    m.af("Team Only Chat", "autoaction_value_str", Higurashi.Communication2.id, function(f)
        if f.value == 0 then
            team_only = false
        elseif f.value == 1 then
            team_only = true
        end
    end):set_str_data({ "Off", "On" })

    m.af("Send Clipboard Contents", "action", Higurashi.Communication2.id, function(f)
        network.send_chat_message(utils.from_clipboard(), team_only or false)
    end)

    m.af("Spam Clipboard Contents", "toggle", Higurashi.Communication2.id, function(f)
        if f.on then
            network.send_chat_message(utils.from_clipboard(), team_only or false)
            wait(0)
            return HANDLER_CONTINUE
        end
    end)

    m.af("Clear Chat", "action", Higurashi.Communication2.id, function(f) network.send_chat_message(" ", team_only or false) end)

    m.af("Hard Clear Chat", "toggle", Higurashi.Communication2.id, function(f)
        if f.on then
            network.send_chat_message(" ", team_only or false)
            wait(100)
            return HANDLER_CONTINUE
        end
    end)

    m.af("Start Count", "action", Higurashi.Communication2.id, function(f)
        local count = 4
        for i = 0, 3 do
            count = count - 1
            if count == 0 then count = "Go" end
            network.send_chat_message(count, team_only or false)
            wait(1000)
        end
    end)

    m.af("Send Fake Chinese Advertisement", "action", Higurashi.Communication2.id, function(f)
        network.send_chat_message("【微信：GTAV6699】【QQ33011337】需要/刷钱科技/改等级外挂/无敌/瞬移【匿名搜索:暮蟬商店】全网100多种外挂任你挑选/科技名称/科技价格/功能介绍（新店搞活动 下单有优惠）诚招代理", team_only or false)
    end)

    Higurashi.Protection = m.af("Protections", "parent", Higurashi.Parent2.id)

    Higurashi.AntiCrashCamera = m.af("Anti Crash Camera", "toggle", Higurashi.Protection.id, function(f)
        local own_pos = higurashi.get_user_coords()
        local function activateAntiCrashCamera()
            higurashi.teleport_to(v3(-8292.664, -4596.8257, 14358.0))
            while f.on do
                local cam_pos = v3(-8292.664, -4596.8257, 14358.0)
                local cam_rot = NATIVE.GET_GAMEPLAY_CAM_ROT()
                local anti_crash_cam_player_cam = NATIVE.CREATE_CAM_WITH_PARAMS("DEFAULT_SCRIPTED_CAMERA", cam_pos.x, cam_pos.y, cam_pos.z, cam_rot.x, cam_rot.y, cam_rot.z, 70.0, false, false)

                NATIVE.SET_CAM_ACTIVE(anti_crash_cam_player_cam, true)
                NATIVE.RENDER_SCRIPT_CAMS(true, true, 0, true, true, 0)
                wait(0)
                NATIVE.SET_ENTITY_COORDS_NO_OFFSET(NATIVE.PLAYER_PED_ID(), cam_pos)
            end
        end
        local function deactivateAntiCrashCamera()
            local cam_rot = NATIVE.GET_GAMEPLAY_CAM_ROT()
            local anti_crash_cam_player_cam = NATIVE.CREATE_CAM_WITH_PARAMS("DEFAULT_SCRIPTED_CAMERA", own_pos.x, own_pos.y, own_pos.z, cam_rot.x, cam_rot.y, cam_rot.z, 70.0, false, false)
            NATIVE.SET_CAM_ACTIVE(anti_crash_cam_player_cam, false)
            NATIVE.RENDER_SCRIPT_CAMS(false, false, 0, false, false, 0)
            wait(0)
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(NATIVE.PLAYER_PED_ID(), own_pos)
        end
        m.ct(function()
            if f.on then
                activateAntiCrashCamera()
            else
                deactivateAntiCrashCamera()
            end
        end, nil)
    end)

    Higurashi.AntiCrashCamera.hint = ""

    Higurashi.AntiBeast = m.af("Anti Beast", "toggle", Higurashi.Protection.id, function(f)
        while f.on do
            if NATIVE.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("am_hunt_the_Beast")) > 0 then
                local host = NATIVE.NETWORK_GET_HOST_OF_SCRIPT("am_launcher", -1, 0)
                local beast = script.get_local_i(joaat("am_hunt_the_Beast"), 608)
                local game_state = script.get_local_i(joaat("am_hunt_the_Beast"), 601)
                if beast == NATIVE.PLAYER_ID() and game_state ~= 3 then
                    script.set_local_i(joaat("am_hunt_the_Beast"), 601, 3)
                    m.n("Prevented a freemode activity (Hunt The Beast), likely started by" .. higurashi.get_user_name(host), title, 3, c.yellow1)
                end
            end
            wait()
            settings["AntiBeast"] = f.on
        end
    end)
    Higurashi.AntiBeast.on = settings["AntiBeast"]

    Higurashi.AntiMugger = m.af("Anti Muggers", "toggle", Higurashi.Protection.id, function(f)
        while f.on do
            if NATIVE.NETWORK_IS_SCRIPT_ACTIVE("am_gang_call", 0, true, 0) then
                local ped_netId = script.get_local_i(joaat("am_gang_call"), 62 + 10 + (0 * 7 + 1))
                local sender = script.get_local_i(joaat("am_gang_call"), 286)
                local target = script.get_local_i(joaat("am_gang_call"), 287)
                if (sender ~= NATIVE.PLAYER_ID() and target == NATIVE.PLAYER_ID() and NATIVE.NETWORK_DOES_NETWORK_ID_EXIST(ped_netId)) and NATIVE.NETWORK_REQUEST_CONTROL_OF_NETWORK_ID(ped_netId) then
                    local mugger = NATIVE.NET_TO_PED(ped_netId)
                    higurashi.hard_remove_entity(mugger)
                    m.n("Blocked mugger from " .. higurashi.get_user_name(sender), title, 3, c.yellow1)
                end
            end
            wait()
            settings["AntiMugger"] = f.on
        end
    end)
    Higurashi.AntiMugger.on = settings["AntiMugger"]

    Higurashi.FriendlyAI = m.af("Anti NPC Hostility", "toggle", Higurashi.Protection.id, function(f)
        if f.on then
            NATIVE.SET_EVERYONE_IGNORE_PLAYER(NATIVE.PLAYER_ID(), true)
            NATIVE.SET_PED_RESET_FLAG(NATIVE.PLAYER_PED_ID(), 124, true)
        else
            NATIVE.SET_EVERYONE_IGNORE_PLAYER(NATIVE.PLAYER_ID(), false)
            NATIVE.SET_PED_RESET_FLAG(NATIVE.PLAYER_PED_ID(), 124, false)
            return HANDLER_POP
        end
        settings["FriendlyAI"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.FriendlyAI.on = settings["FriendlyAI"]
    Higurashi.FriendlyAI.hint = ""

    Higurashi.BlockElectricDamage = m.af("Block Electric Damage", "toggle", Higurashi.Protection.id, function(f)
        if f.on then
            NATIVE.SET_PED_CONFIG_FLAG(NATIVE.PLAYER_PED_ID(), 461, true)
        else
            NATIVE.SET_PED_CONFIG_FLAG(NATIVE.PLAYER_PED_ID(), 461, false)
            return HANDLER_POP
        end
        settings["BlockElectricDamage"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.BlockElectricDamage.on = settings["BlockElectricDamage"]

    local function toggleBlameProtection(f)
        if f.on then
            NATIVE.NETWORK_SET_FRIENDLY_FIRE_OPTION(false)
            NATIVE.SET_CAN_ATTACK_FRIENDLY(NATIVE.PLAYER_PED_ID(), false, false)
        else
            NATIVE.NETWORK_SET_FRIENDLY_FIRE_OPTION(true)
            NATIVE.SET_CAN_ATTACK_FRIENDLY(NATIVE.PLAYER_PED_ID(), false, true)
            return HANDLER_POP
        end
        settings["BlameProtection"] = f.on
        return HANDLER_CONTINUE
    end

    Higurashi.BlameProtection = m.af("Blame Protection", "toggle", Higurashi.Protection.id, toggleBlameProtection)
    Higurashi.BlameProtection.on = settings["BlameProtection"]
    Higurashi.BlameProtection.hint = "Makes you unable to damage others so that explosions blamed on you equally do no damage. Also makes other people unable to damage you."

    Higurashi.BlockVehicleDragout = m.af("Block Vehicle Dragout", "toggle", Higurashi.Protection.id, function(f)
        if f.on then
            NATIVE.SET_PED_CAN_BE_DRAGGED_OUT(NATIVE.PLAYER_PED_ID(), false)
        end
        settings["BlockVehicleDragout"] = f.on
        if not f.on then
            NATIVE.SET_PED_CAN_BE_DRAGGED_OUT(NATIVE.PLAYER_PED_ID(), true)
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.BlockVehicleDragout.on = settings["BlockVehicleDragout"]

    Higurashi.BlockPTFX = m.af("Block PTFX", "toggle", Higurashi.Protection.id, function(f)
        if f.on then
            local pos = higurashi.get_user_coords()
            NATIVE.REMOVE_PARTICLE_FX_IN_RANGE(pos.x, pos.y, pos.z, 100.0)
            NATIVE.REMOVE_PARTICLE_FX_FROM_ENTITY(NATIVE.PLAYER_PED_ID())
            wait(300)
            settings["BlockPTFX"] = f.on
            return HANDLER_CONTINUE
        end
        settings["BlockPTFX"] = f.on
        return HANDLER_POP
    end)

    m.af("Mark All As Modder", "action_value_str", Higurashi.Protection.id, function(f, pid)
        if f.value == 0 then
            for pid = 0, 31 do
                player.set_player_as_modder(pid, higurashi.modder_flags[1][2])
            end
        elseif player.is_player_modder(pid, -1) then
            for pid = 0, 31 do player.unset_player_as_modder(pid, -1) end
        end
    end):set_str_data({ "Enable", "Disable" })

    local function toggleStatsSpoof(globalIndex, getValueFunc, setValueFunc, valueOn, valueOff, hint)
        return m.af(hint, "toggle", Higurashi.Protection.id, function(f)
            if f.on then
                if NATIVE.NETWORK_IS_SESSION_STARTED() then
                    setValueFunc(globalIndex, valueOn)
                    wait(10)
                end
            else
                if NATIVE.NETWORK_IS_SESSION_STARTED() then
                    setValueFunc(globalIndex, getValueFunc(player.player_id()))
                    wait(10)
                    return HANDLER_POP
                end
            end
            return HANDLER_CONTINUE
        end)
    end

    Higurashi.StatsRadioStationSpoof = toggleStatsSpoof(
        (1845263 + 1 + player.player_id() * 877 + 205 + 53),
        higurashi_globals.get_player_fav_station,
        script.set_global_i,
        -1,
        higurashi_globals.get_player_fav_station(player.player_id()),
        "Automatically Spoofs Favorite Radio Station Stats"
    )
    Higurashi.StatsKDSpoof = toggleStatsSpoof(
        (1845263 + 1 + player.player_id() * 877 + 205 + 26),
        higurashi_globals.get_player_kd,
        script.set_global_f,
        1.00,
        higurashi_globals.get_player_kd(player.player_id()),
        "Automatically Spoofs K/D Stats"
    )
    Higurashi.StatsMoneySpoof = toggleStatsSpoof(
        (1845263 + 1 + player.player_id() * 877 + 205 + 3),
        higurashi_globals.get_player_wallet,
        script.set_global_i,
        13370,
        higurashi_globals.get_player_wallet(player.player_id()),
        "Automatically Spoofs Total/Wallet Money Stats"
    )


    Higurashi.UnmarkFriends = m.af("Unmark Friends", "toggle", Higurashi.Protection.id, function(f, pid)
        settings["UnmarkFriends"] = true
        while f.on do
            for pid in higurashi.players() do
                if player.is_player_friend(pid) then
                    if player.is_player_modder(pid, -1) then
                        player.unset_player_as_modder(pid, -1)
                    end
                end
            end
            wait(300)
        end
    end)
    Higurashi.UnmarkFriends.on = settings["UnmarkFriends"]

    Higurashi.Friendly2 = m.af("Session Friendly", "parent", Higurashi.Parent2.id)

    Higurashi.FriendlyScriptEvent2 = m.af("Script Events", "parent", Higurashi.Friendly2.id)

    m.af("Never Wanted", "toggle", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        while f.on do
            for pid in higurashi.players() do
                if NATIVE.GET_PLAYER_WANTED_LEVEL(pid) > 0 and
                    NATIVE.IS_PLAYER_PLAYING(pid) then
                    higurashi_globals.remove_wanted2(pid)
                end
            end
            wait(1000)
        end
    end)

    Higurashi.NeverWanted2 = m.af("Never Wanted All Friends", "toggle", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        while f.on do
            for pid in higurashi.players() do
                if player.is_player_valid(pid) and player.is_player_friend(pid) then
                    if NATIVE.GET_PLAYER_WANTED_LEVEL(pid) > 0 then
                        higurashi_globals.remove_wanted2(pid)
                    end
                end
            end
            wait(1000)
        end
    end)

    m.af("Remove Wanted All Friends", "action_value_str", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            if player.is_player_valid(pid) and player.is_player_friend(pid) then
                if f.value == 0 then
                    higurashi_globals.remove_wanted(pid)
                elseif f.value == 1 then
                    higurashi_globals.remove_wanted2(pid)
                end
            end
        end
    end):set_str_data({ "V1", "V2" })

    m.af("Remove Wanted Level", "action", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.remove_wanted2(pid)
        end
    end)

    m.af("Give Off The Radar", "action", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.off_the_radar(pid)
        end
    end)

    m.af("Give Collectables", "action_value_str", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        local collectable_types = {
            { 1, 0, "Movie Props" },           -- Movie Props
            { 1, 1, "Hidden Caches" },         -- Hidden Caches
            { 1, 2, "Treasure Chests" },       -- Treasure Chests
            { 1, 3, "Radio Antennas" },        -- Radio Antennas
            { 1, 4, "Media USBs" },            -- Media USBs
            { 1, 5, "Shipwrecks" },            -- Shipwrecks
            { 1, 6, "Burried Stashes" },       -- Burried Stashes
            { 1, 9, "LD Organics Product" },   -- LD Organics Product
            { 1, 10, "Junk Energy Skydives" }, -- Junk Energy Skydives
            { 1, 16, "Tuner Collectibles" },   -- Tuner Collectibles
            { 1, 17, "Snowmen" },              -- Snowmen
            { 1, 4, "G's Caches" },            -- G's Caches
        }
        local collectable_type = collectable_types[f.value + 1]
        local type_id = collectable_type[1]
        local sub_type = collectable_type[2]
        for pid in higurashi.players() do
            if f.value == 2 then
                higurashi_globals.send_script_event("Secret Asset", pid, { type_id, sub_type, 0, 1, 1, 1 })
                higurashi_globals.send_script_event("Secret Asset", pid, { type_id, sub_type, 1, 1, 1, 1 })
            elseif f.value == 7 then
                for i = 0, 99 do
                    higurashi_globals.send_script_event("Secret Asset", pid, { type_id, sub_type, i, 1, 1, 1 })
                end
            else
                for i = 0, 9 do
                    higurashi_globals.send_script_event("Secret Asset", pid, { type_id, sub_type, i, 1, 1, 1 })
                end
            end
        end
    end):set_str_data({ "Movie Props", "Hidden Caches", "Treasure Chests", "Radio Antennas", "Media USBs", "Shipwrecks", "Burried Stashes", "LD Organics Product", "Junk Energy Skydives", "Tuner Collectibles", "Snowmen", "G's Caches" })

    Higurashi.RemoteCloudSave2 = m.af("Force Cloud Save", "action", Higurashi.FriendlyScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_script_event("Secret Asset", pid, { pid, -3301 })
            wait(0)
            higurashi_globals.send_script_event("Secret Asset", pid, { pid, -1337, 3301, -1, -1, -1 })
        end
    end)
    Higurashi.RemoteCloudSave2.hint = "Remotely save a players game."

    Higurashi.Griefing2 = m.af("Session Griefing", "parent", Higurashi.Parent2.id)

    Higurashi.WeaponGrief2 = m.af("Weapons", "parent", Higurashi.Griefing2.id)

    m.af("Remove Unarmed", "action", Higurashi.WeaponGrief2.id, function(f, pid)
        for pid in higurashi.players() do
            if not NATIVE.IS_PED_ARMED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 7) then
                NATIVE.REMOVE_WEAPON_FROM_PED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 0xA2719263)
            end
        end
    end)

    m.af("Remove All Weapons", "action", Higurashi.WeaponGrief2.id, function(f, pid)
        for pid in higurashi.players() do
            if NATIVE.IS_PED_ARMED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), 7) then
                for _, weapon_hash in pairs(weapon.get_all_weapon_hashes()) do
                    NATIVE.REMOVE_WEAPON_FROM_PED(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), weapon_hash)
                end
            end
        end
    end)

    Higurashi.ScriptEvent2 = m.af("Script Events", "parent", Higurashi.Griefing2.id)

    m.af("Send To Online Intro", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_to_activity(pid, 20)
        end
    end)

    m.af("Remove Passive Mode", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_to_activity(pid, 49)
        end
    end)


    m.af("Send To Activity", "action_value_str", Higurashi.ScriptEvent2.id, function(f, pid)
        local id = { 211, 212, 215 }
        for pid in higurashi.players() do
            higurashi_globals.send_to_activity(pid, id[f.value])
        end
    end):set_str_data(freemodeactivities)

    m.af("Send To Arcade Game", "action_value_str", Higurashi.ScriptEvent2.id, function(f, pid)
        local id = { 229, 230, 231, 235, 236, 237 }
        for pid in higurashi.players() do
            higurashi_globals.send_to_activity(pid, id[f.value])
        end
    end):set_str_data(arcadeGames)

    m.af("Fake Typing", "action_value_str", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            if f.value == 0 then
                script.trigger_script_event(0x970e710f, pid, { NATIVE.PLAYER_PED_ID(), pid, math.random(1, 9999) })
            elseif f.value == 1 then
                script.trigger_script_event(0x1c6002bd, pid, { NATIVE.PLAYER_PED_ID(), pid, math.random(1, 9999) })
            end
        end
    end):set_str_data({ "Start", "Stop" })

    m.af("Camera Forward", "toggle", Higurashi.ScriptEvent2.id, function(f, pid)
        if f.on then
            for pid in higurashi.players() do
                higurashi_globals.camera_forward(pid)
                wait(10)
            end
            return HANDLER_CONTINUE
        end
    end)

    m.af("Disable Jumping", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_script_event("Apartment Invite", pid, { pid, 31, 4294967295, 1, 115, 0, 0, 0 })
        end
    end)

    m.af("Bounty On Lobby", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_limiter[#higurashi_globals.send_limiter + 1] = utils.time_ms() + (1 // NATIVE.GET_FRAME_TIME())
            higurashi_globals.set_bounty(pid, 10000, 1)
        end
    end)

    m.af("Reapply Bounty", "toggle", Higurashi.ScriptEvent2.id, function(f, pid)
        while f.on do
            for pid in higurashi.players() do
                higurashi_globals.send_limiter[#higurashi_globals.send_limiter + 1] = utils.time_ms() + (1 // NATIVE.GET_FRAME_TIME())
                higurashi_globals.set_bounty(pid, 10000, 1)
                wait(1000)
            end
        end
    end)

    m.af("Block Passive Mode", "action_value_str", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            if f.value == 0 then
                higurashi_globals.send_script_event("Passive State", pid, { NATIVE.PLAYER_ID(), -1, 1 })
            elseif f.value == 1 then
                higurashi_globals.send_script_event("Passive State", pid, { NATIVE.PLAYER_ID(), -1, 0 })
            end
        end
    end):set_str_data({ "Enable", "Disable" })

    m.af("Give OTR", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.off_the_radar(pid)
        end
    end)

    m.af("Send To Mission", "action", Higurashi.ScriptEvent2.id, function(f, pid)
        for pid in higurashi.players() do
            higurashi_globals.send_mission(pid)
        end
    end)

    local function update_player_list2()
        valid_players = {}
        local player_table = {}
        for pid = 0, 31 do
            if player.is_player_valid(pid) then
                player_table[#player_table + 1] = higurashi.get_user_name(pid) .. " (" .. pid .. ")"
                valid_players[#valid_players + 1] = pid
            end
        end
        Higurashi.SpecificPlayer2:set_str_data(player_table)
    end

    event.add_event_listener("player_join", function() update_player_list2() end)

    event.add_event_listener("player_leave", function()
        update_player_list2()
    end)

    Higurashi.SpecificPlayer2 = m.af("Explode Owner:", "autoaction_value_str", Higurashi.Griefing2.id, function(f, pid)
        BlamedPID2 = tonumber(f.str_data[f.value + 1]:match(".*%((%d+)%)"))
    end)
    update_player_list2()

    Higurashi.SessionExplode = m.af("Explode Blamed", "value_str", Higurashi.Griefing2.id, function(f, pid)
        while f.on do
            for pid in higurashi.players() do
                if not NATIVE.IS_ENTITY_DEAD(NATIVE.GET_PLAYER_PED(pid)) then
                    local pos = higurashi.get_player_coords(pid)
                    higurashi.add_explosion(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(BlamedPID2), v3(pos.x, pos.y, pos.z), f.value, 1.0, true, false, 0)
                end
            end
            wait(100)
        end
    end):set_str_data({
        "GRENADE", "GRENADELAUNCHER", "STICKYBOMB", "MOLOTOV", "ROCKET",
        "TANKSHELL", "HI_OCTANE", "CAR", "PLANE", "PETROL_PUMP", "BIKE0",
        "DIR_STEAM", "DIR_FLAME", "DIR_WATER_HYDRANT", "DIR_GAS_CANISTER",
        "BOAT", "SHIP_DESTROY", "TRUCK", "BULLET", "SMOKEGRENADELAUNCHER",
        "SMOKEGRENADE0", "BZGAS", "FLARE", "GAS_CANISTER", "EXTINGUISHER",
        "_0x988620B8", "EXP_TAG_TRAIN", "EXP_TAG_BARREL", "EXP_TAG_PROPANE",
        "EXP_TAG_BLIMP", "EXP_TAG_DIR_FLAME_EXPLODE0", "EXP_TAG_TANKER",
        "PLANE_ROCKET", "EXP_TAG_VEHICLE_BULLET", "EXP_TAG_GAS_TANK",
        "EXP_TAG_BIRD_CRAP", "EXP_TAG_RAILGUN", "EXP_TAG_BLIMP2",
        "EXP_TAG_FIREWORK", "EXP_TAG_SNOWBALL", "EXP_TAG_PROXMINE0",
        "EXP_TAG_VALKYRIE_CANNON", "EXP_TAG_AIR_DEFENCE", "EXP_TAG_PIPEBOMB",
        "EXP_TAG_VEHICLEMINE", "EXP_TAG_EXPLOSIVEAMMO", "EXP_TAG_APCSHELL",
        "EXP_TAG_BOMB_CLUSTER", "EXP_TAG_BOMB_GAS", "EXP_TAG_BOMB_INCENDIARY",
        "EXP_TAG_BOMB_STANDARD0", "EXP_TAG_TORPEDO",
        "EXP_TAG_TORPEDO_UNDERWATER", "EXP_TAG_BOMBUSHKA_CANNON",
        "EXP_TAG_BOMB_CLUSTER_SECONDARY", "EXP_TAG_HUNTER_BARRAGE",
        "EXP_TAG_HUNTER_CANNON", "EXP_TAG_ROGUE_CANNON",
        "EXP_TAG_MINE_UNDERWATER", "EXP_TAG_ORBITAL_CANNON",
        "EXP_TAG_BOMB_STANDARD_WIDE0", "EXP_TAG_EXPLOSIVEAMMO_SHOTGUN",
        "EXP_TAG_OPPRESSOR2_CANNON", "EXP_TAG_MORTAR_KINETIC",
        "EXP_TAG_VEHICLEMINE_KINETIC", "EXP_TAG_VEHICLEMINE_EMP",
        "EXP_TAG_VEHICLEMINE_SPIKE", "EXP_TAG_VEHICLEMINE_SLICK",
        "EXP_TAG_VEHICLEMINE_TAR", "EXP_TAG_SCRIPT_DRONE", "EXP_TAG_RAYGUN0",
        "EXP_TAG_BURIEDMINE", "EXP_TAG_SCRIPT_MISSILE", "EXP_TAG_RCTANK_ROCKET",
        "EXP_TAG_BOMB_WATER", "EXP_TAG_BOMB_WATER_SECONDARY", "_0xF728C4A9",
        "_0xBAEC056F", "EXP_TAG_FLASHGRENADE", "EXP_TAG_STUNGRENADE",
        "_0x763D3B3B0", "EXP_TAG_SCRIPT_MISSILE_LARGE", "EXP_TAG_SUBMARINE_BIG",
        "EXP_TAG_EMPLAUNCHER_EMP",
    })

    Higurashi.SessionMalicious = m.af("Session Malicious", "parent", Higurashi.Parent2.id)

    Higurashi.SessionRegionKick = m.af("Region Kick", "parent", Higurashi.SessionMalicious.id)

    local function kick_player_by_region(pid, region_id)
        local user_name = higurashi.get_user_name(pid)
        local region_name = regions[region_id]
        m.n("Kicked: " .. user_name .. " Region: " .. region_name, title, 3, c.blue1)
        higurashi.kick(pid)
    end

    for region_id, region_name in pairs(regions) do
        Higurashi["AutoKick_" .. region_name] = m.af("Auto Kick: " .. region_name, "toggle", Higurashi.SessionRegionKick.id, function(f)
            settings["AutoKick_" .. region_name] = f.on
            while f.on do
                if not NATIVE.NETWORK_IS_SESSION_STARTED() then
                    return
                end
                for pid in higurashi.players() do
                    if NATIVE.NETWORK_IS_PLAYER_ACTIVE(pid) and script.get_global_i(1887305 + 1 + (pid * 610) + 10 + 121) == region_id then
                        kick_player_by_region(pid, region_id)
                        return
                    end
                end
                wait(200)
            end
        end)
        Higurashi["AutoKick_" .. region_name].on = settings["AutoKick_" .. region_name]
    end

    local karma_se_hook = nil
    Higurashi.KarmaSE = m.af("Karma Every Script Event", "toggle", Higurashi.SessionMalicious.id, function(f)
        settings["KarmaSE"] = f.on
        if f.on and karma_se_hook == nil then
            karma_se_hook = hook.register_script_event_hook(function(pid, target, parameters, count)
                local cse = table.remove(parameters, 1)
                script.trigger_script_event(cse, pid, parameters)
                m.n("Karma: " .. pid .. cse, title, 2, c.blue1)
            end)
        elseif not f.on and karma_se_hook ~= nil then
            hook.remove_script_event_hook(karma_se_hook)
            karma_se_hook = nil
        end
    end)
    Higurashi.KarmaSE.on = settings["KarmaSE"]

    Higurashi.BlockScriptHostMigration = m.af("Block Script Host Migration", "toggle", Higurashi.SessionMalicious.id, function(f)
        settings["BlockScriptHostMigration"] = f.on
        if f.on then
            if network.is_session_started() and network.network_is_host() then
                NATIVE.NETWORK_PREVENT_SCRIPT_HOST_MIGRATION()
            end
            wait(50)
        end
        if not f.on then
            wait(50)
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.BlockScriptHostMigration.on = settings["BlockScriptHostMigration"]

    Higurashi.ForceScriptHost = m.af("Force Script Host", "value_str", Higurashi.SessionMalicious.id, function(f)
        settings["ForceScriptHost"] = f.on
        local function should_force_host()
            return NATIVE.NETWORK_IS_SESSION_STARTED() and player.is_player_valid(NATIVE.PLAYER_ID()) and NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT() ~= NATIVE.PLAYER_ID()
        end
        while f.on do
            local current_time = utils.time_ms()
            if should_force_host() then
                if f.value == 0 and m.gfbhk("online.lobby.force_script_host") ~= nil then
                    m.gfbhk("online.lobby.force_script_host"):toggle()
                else
                    local end_time = current_time + 8000
                    while utils.time_ms() < end_time and should_force_host() do
                        higurashi.force_script_host()
                        wait()
                    end
                end
            end
            wait(4000)
        end
    end)
    Higurashi.ForceScriptHost.on = settings["ForceScriptHost"]

    local force_script_host_option = m.gfbhk("online.lobby.force_script_host")
    if force_script_host_option ~= nil then
        Higurashi.ForceScriptHost:set_str_data({ "Magic", "Natives" })
    end

    Higurashi.ForceHost = m.af("Force Host", "toggle", Higurashi.SessionMalicious.id, function(f)
        settings["ForceHost"] = f.on
        if f.on then
            if not NATIVE.NETWORK_IS_SESSION_STARTED() then
                logger("Please enter GTA Online.", "[Force Host]", "Debug.log", true, title, 2, c.blue1)
                Higurashi.ForceHost.on = false
                return HANDLER_POP
            end
            local pid = player.get_host()
            if not NATIVE.NETWORK_IS_HOST() then
                network.force_remove_player(pid)
                wait(200)
            end
            if NATIVE.NETWORK_IS_HOST() then
                logger("You are now the session host.", "[Force Host]", "Debug.log", true, title, 2, c.blue1)
                Higurashi.ForceHost.on = false
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)
    Higurashi.ForceHost.on = settings["ForceHost"]

    m.af("Kick Session", "action_value_str", Higurashi.SessionMalicious.id, function(f, pid)
        if f.value == 0 then
            for pid in higurashi.players() do higurashi.kick(pid) end
        elseif f.value == 1 then
            for pid in higurashi.players() do
                higurashi_globals.net_bail_kick(pid)
            end
        end
    end):set_str_data({ "Smart", "Network Bail" })

    Higurashi.CrashSession = m.af("Crash Session", "action_value_str", Higurashi.SessionMalicious.id, function(f, pid)
        if f.value == 0 then
            for pid in higurashi.players() do
                higurashi_globals.se_crash(pid)
            end
        elseif f.value == 1 then
            for pid in higurashi.players() do
                higurashi.sound_crash(pid, 999999999)
            end
        elseif f.value == 2 then
            higurashi.sync_mismatch_crash()
        elseif f.value == 3 then
            higurashi.math_crash()
        elseif f.value == 4 then
            higurashi.bad_parachute_crash2()
        end
    end):set_str_data({ "Elegant", "Bass", "Sync Mismatch", "Math", "Windsock" })


    Higurashi.World = m.af("World Options", "parent", Higurashi.Parent2.id)
    Higurashi.WorldEnhancement = m.af("Enhancement", "parent", Higurashi.World.id)

    m.af("Teleport To", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        local teleport_locations = {
            v3(-368.671, -103.088, 39.537),  -- Los Santos Custom
            v3(2443.262, 3772.367, 41.013),  -- Alien Camp
            v3(100.463, -1073.303, 29.374),  -- Caesars Auto Parking
            v3(-427.449, 1116.932, 326.768), -- Galileo Observatory
            v3(-1659.694, -953.830, 7.718),  -- Vespucci Beach
        }

        higurashi.teleport_to(teleport_locations[f.value + 1])
    end):set_str_data({ "Los Santos Custom", "Alien Camp", "Caesars Auto Parking", "Galileo Observatory", "Vespucci Beach" })

    local lsc_dj = {}
    local lsc_dj_count = 1
    local lsc_dj_prop = {}
    local dj_models = { "IG_Dix", "IG_TalMM", "IG_TalCC", "IG_Sol", "IG_DJBlaMadon" }

    local function spawnDJ()
        local dj_model = joaat(dj_models[math.random(#dj_models)])
        local dj_ped = higurashi.create_ped(2, dj_model, v3(-368.671, -103.088, 39.537), 0, true, false, true, false, false)

        NATIVE.DECOR_SET_INT(dj_ped, "Skill_Blocker", -1)
        NATIVE.SET_PED_DEFAULT_COMPONENT_VARIATION(dj_ped)
        higurashi.set_entity_godmode(dj_ped, true)
        NATIVE.SET_PED_COMBAT_ATTRIBUTES(dj_ped, 46, true)
        NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(dj_ped, true)
        NATIVE.SET_PED_CAN_RAGDOLL(dj_ped, false)
        NATIVE.SET_PED_CAN_BE_TARGETTED(dj_ped, false)
        NATIVE.SET_CAN_ATTACK_FRIENDLY(dj_ped, false, true)
        --NATIVE.SET_PED_CONFIG_FLAG(dj_ped, 241, true)
        wait(500)
        NATIVE.FREEZE_ENTITY_POSITION(dj_ped, true)
        NATIVE.SET_ENTITY_ROTATION(dj_ped, v3(0.0, 0.0, 160.0))
        NATIVE.SET_ENTITY_COORDS_NO_OFFSET(dj_ped, v3(-368.671, -103.088, 39.537))

        return dj_ped
    end

    local function clearDJBody()
        for _, peds in pairs(ped.get_all_peds()) do
            for i = 1, #dj_models do
                if NATIVE.GET_ENTITY_MODEL(peds) == joaat(dj_models[i]) and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                    higurashi.clear_ped_body(peds)
                end
            end
        end
    end

    local function removeDJ()
        for _, peds in pairs(ped.get_all_peds()) do
            for i = 1, #dj_models do
                if NATIVE.GET_ENTITY_MODEL(peds) == joaat(dj_models[i]) and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                    higurashi.remove_entity({ peds })
                end
            end
        end
    end

    local function playDJAnimation(dj_ped)
        local male_dj_animations = {
            { "anim@amb@nightclub@djs@dixon@", "dixn_idle_trns_hp_hd_nk_dix" },
            { "anim@amb@nightclub@djs@dixon@", "temp_dxn_set_dixon" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_idle_cntr_b_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_idle_cntr_g_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_idle_cntr_gb_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_j_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_dance_open_a_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_dance_cntr_open_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_idle_cntr_a_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_lft_a_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_a_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_b_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_c_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_e_dix" },
            { "anim@amb@nightclub@djs@dixon@", "dixn_sync_cntr_f_dix" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_d_mix_05_b_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_h_mix_11_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_m_mix_13_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_n_mix_16_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_a_q_r_17_headphones_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_n_q_l_21_headphones_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_p_q_r_05_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_o_q_l_10_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_aa_mix_19_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_b_mix_20_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_d_q_l_05_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_i_q_l_12_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_i_mix_19_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_x_mix_20_dj_ptrax" },
            { "anim@scripted@nightclub@dj@dj_ptrax@", "ptrx_idle_ii_mix_24_headphones_dj_ptrax" },
            { "anim@amb@nightclub@djs@solomun@", "temp_slmn_set_solomun" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_wide_a_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_wide_b_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_mid_c_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_mid_g_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_mid_h_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_sync_g_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_dance_i_sol" },
            { "anim@amb@nightclub@djs@solomun@", "sol_idle_ctr_mid_a_sol" },
        }
        local female_dj_animations = {
            { "anim@amb@nightclub@djs@black_madonna@", "pose_a_idle_a_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_a_idle_b_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_a_idle_c_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "dance_b_idle_a_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "dance_b_idle_d_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_b_idle_i_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_c_idle_a_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_c_idle_b_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_c_idle_c_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "pose_c_idle_d_blamadon" },
            { "anim@amb@nightclub@djs@black_madonna@", "temp_blkmdna_set_blackmadonna" },
        }

        local dj_animation
        if NATIVE.IS_PED_MALE(dj_ped) then
            dj_animation = male_dj_animations[math.random(#male_dj_animations)]
        else
            dj_animation = female_dj_animations[math.random(#female_dj_animations)]
        end
        higurashi.request_anim_dict(dj_animation[1])
        NATIVE.TASK_PLAY_ANIM(dj_ped, dj_animation[1], dj_animation[2], 1.0, 1.0, -1, 3, 100.0, false, false, false)
        NATIVE.REMOVE_ANIM_DICT(dj_animation[1])
        NATIVE.SET_ENTITY_ROTATION(dj_ped, v3(0.0, 0.0, 160.0))
        NATIVE.SET_ENTITY_COORDS_NO_OFFSET(dj_ped, v3(-368.671, -103.088, 39.537))

        wait(15500)
    end

    m.af("LSC DJ", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            local dj_ped = spawnDJ()
            lsc_dj[lsc_dj_count] = dj_ped
            local anim_thread = m.ct(function()
                while true do
                    if dj_ped and NATIVE.DOES_ENTITY_EXIST(dj_ped) then
                        playDJAnimation(dj_ped)
                    else
                        return false
                    end
                end
            end)
        elseif f.value == 1 then
            clearDJBody()
        elseif f.value == 2 then
            removeDJ()
        end
    end):set_str_data({ "Spawn", "Clear Body", "Delete" })


    local party_cust_models = {
        "A_F_Y_ClubCust_01", "A_F_Y_ClubCust_02", "A_F_Y_ClubCust_03", "A_F_Y_ClubCust_04",
        "A_F_Y_Beach_02", "A_M_O_Beach_02", "A_M_Y_Beach_04", "A_M_Y_ClubCust_01", "A_M_Y_ClubCust_02", "A_M_Y_ClubCust_03", "A_M_Y_ClubCust_04",
    }


    m.af("Cust", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        local pos = higurashi.get_user_coords()
        local male_dance_animations = {
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_m01" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_m02" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_m03" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_m04" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_a_m05" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_m01" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_m02" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_m03" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_c_m01" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_c_m02" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_c_m03" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_m01" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_m02" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_m03" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_d_m04" },
            { "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_down" },
            { "anim@amb@nightclub@mini@dance@dance_solo@male@var_a@", "high_center" },
            { "anim@amb@nightclub@mini@dance@dance_solo@male@var_b@", "high_center_up" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_15_v1_male^5" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "mi_dance_facedj_09_v1_male^4" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_11_v1_male^2" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_17_v2_male^5" },
            { "anim@amb@nightclub_island@dancers@crowddance_facedj@", "mi_dance_facedj_15_v2_male^4" },
            { "anim@amb@nightclub_island@dancers@crowddance_facedj@", "hi_dance_facedj_hu_15_v2_male^4" },
            { "anim@amb@nightclub_island@dancers@crowddance_facedj@", "mi_dance_facedj_15_v2_male^4" },
            { "anim@amb@nightclub@dancers@podium_dancers@", "hi_dance_facedj_17_v2_male^5" },
            { "anim@amb@nightclub@dancers@crowddance_single_props@hi_intensity", "hi_dance_prop_13_v2_male^2" },
            { "anim@amb@nightclub_island@dancers@crowddance_groups@groupd@", "mi_dance_crowd_13_v2_male^1" },
        }

        local female_dance_animations = {
            { "anim@amb@nightclub@dancers@solomun_entourage@", "mi_dance_facedj_17_v1_female^1" },
            { "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center" },
            { "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center_up" },
            { "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center_up" },
            { "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_center_down" },
            { "anim@amb@nightclub@mini@dance@dance_solo@female@var_a@", "high_left_up" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^1" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^2" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_09_v2_female^3" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_09_v2_female^4" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "li_dance_facedj_13_v1_female^3" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_09_v1_female^6" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_15_v2_female^3" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_17_v2_female^4" },
            { "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_13_v1_female^6" },
            { "anim@amb@nightclub_island@dancers@beachdance@", "hi_idle_b_f01" },
            { "anim@amb@nightclub_island@dancers@club@", "hi_idle_a_f01" },
            { "anim@amb@nightclub_island@dancers@club@", "hi_idle_a_f03" },
            { "anim@amb@nightclub_island@dancers@club@", "hi_idle_d_f01" },
            { "anim@amb@nightclub_island@dancers@club@", "hi_idle_f_f02" },
        }
        local function handlePedOperations(operationFunc)
            for _, peds in pairs(ped.get_all_peds()) do
                for i = 1, #party_cust_models do
                    if NATIVE.GET_ENTITY_MODEL(peds) == joaat(party_cust_models[i]) and NATIVE.DECOR_EXIST_ON(peds, "Skill_Blocker") then
                        operationFunc(peds)
                    end
                end
            end
        end
        if f.value == 0 then
            for i = 1, 6 do
                local random_model = party_cust_models[math.random(#party_cust_models)]
                local new_ped = higurashi.create_ped(2, joaat(random_model), v3(pos.x + math.random(-5, 5), pos.y + math.random(-5, 5), pos.z), 0, true, false, true, false, false, true, true)
                NATIVE.DECOR_SET_INT(new_ped, "Skill_Blocker", -1)
                higurashi.set_entity_godmode(new_ped, true)
                NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(new_ped, true)
                NATIVE.SET_PED_CAN_RAGDOLL(new_ped, false)
                NATIVE.SET_PED_CAN_BE_TARGETTED(new_ped, false)
                NATIVE.SET_CAN_ATTACK_FRIENDLY(new_ped, false, true)
                --NATIVE.SET_PED_CONFIG_FLAG(new_ped, 241, true)
                NATIVE.SET_ENTITY_ROTATION(new_ped, v3(0.0, 0.0, math.random(-300, 300)))
            end
        elseif f.value == 1 then
            handlePedOperations(function(ped)
                local dance_animations = NATIVE.IS_PED_MALE(ped) and male_dance_animations or female_dance_animations
                local dance_anim = dance_animations[math.random(#dance_animations)]

                higurashi.request_anim_dict(dance_anim[1])
                NATIVE.TASK_PLAY_ANIM(ped, dance_anim[1], dance_anim[2], 1.0, 1.0, -1, 3, 100.0, false, false, false)
                NATIVE.REMOVE_ANIM_DICT(dance_anim[1])
            end)
        elseif f.value == 2 then
            handlePedOperations(function(ped)
                NATIVE.FREEZE_ENTITY_POSITION(ped, true)
            end)
        elseif f.value == 3 then
            handlePedOperations(function(ped)
                NATIVE.FREEZE_ENTITY_POSITION(ped, false)
            end)
        elseif f.value == 4 then
            handlePedOperations(function(ped)
                NATIVE.SET_ENTITY_ROTATION(ped, v3(0.0, 0.0, math.random(-300, 300)))
                NATIVE.SET_ENTITY_COORDS_NO_OFFSET(ped, v3(pos.x + math.random(-5, 5), pos.y + math.random(-5, 5), pos.z))
            end)
        elseif f.value == 5 then
            handlePedOperations(function(ped)
                higurashi.clear_ped_body(ped)
            end)
        elseif f.value == 6 then
            handlePedOperations(function(ped)
                higurashi.remove_entity({ ped })
            end)
        end
    end):set_str_data({ "Spawn", "Random Dance", "Freeze", "Unfreeze", "Replace", "Clear Body", "Delete" })

    Higurashi.SetRadioStation = m.af("Set Radio Station", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        pbus_selected_station = radio_stations[f.value + 1]
        for _, veh in pairs(vehicle.get_all_vehicles()) do
            if NATIVE.GET_ENTITY_MODEL(veh) == joaat("pbus2") and NATIVE.DECOR_EXIST_ON(veh, "Skill_Blocker") then
                change_radio_station(veh, pbus_selected_station)
            end
        end
    end):set_str_data({
        "OFF", "Los Santos Rock Radio", "Non-Stop-Pop FM", "Radio Los Santos", "Channel X",
        "West Coast Talk Radio", "Rebel Radio", "Soulwax FM", "East Los FM", "West Coast Classics",
        "Blaine County Radio", "Blue Ark", "Worldwide FM", "FlyLo FM", "The Lowdown 91.1",
        "Radio Mirror Park", "Space 103.2", "Vinewood Boulevard Radio", "The Lab",
        "Blonded Los Santos 97.8 FM", "Los Santos Underground Radio", "iFruit Radio",
        "Still Slipping Los Santos", "Kult FM", "The Music Locker", "Media Player", "MOTOMAMI Los Santos",
    })


    local lsc_pbus = {}
    local lsc_party_props = {}
    local lsc_cust = {}
    local lsc_cust_models = { "U_F_Y_DanceBurl_01", "U_F_Y_DanceRave_01" }
    local lsc_party_prop_lists = {
        "sf_prop_sf_dj_desk_01a", "h4_prop_h4_mic_dj_01a", "h4_prop_battle_dj_mixer_01f", "sf_prop_sf_speaker_l_01a", "sf_prop_sf_speaker_stand_01a", "prop_table_07", "sf_prop_sf_laptop_01b",
        "sf_p_sf_grass_gls_s_01a", "h4_prop_h4_t_bottle_01a", "m23_2_prop_m32_t_bottle_02a", "h4_prop_h4_t_bottle_02b", "ba_prop_battle_whiskey_bottle_s", "ba_prop_battle_whiskey_bottle_2_s",
        "ba_prop_battle_whiskey_opaque_s", "ba_prop_battle_decanter_03_s", "prop_champ_cool", "prop_drink_whisky", "hei_p_hei_champ_flute_s", "prop_drink_champ", "ba_prop_club_water_bottle", "sf_prop_sf_lamp_studio_02a", "m23_2_prop_m32_planninglight_01a",
        "v_ret_neon_blarneys", "vw_prop_vw_wallart_31a", "vw_prop_vw_wallart_30a", "sf_prop_sf_vend_drink_01a", "ba_prop_battle_poster_skin_01", "ba_prop_battle_poster_skin_02",
        "ba_prop_battle_poster_skin_03", "ba_prop_battle_poster_skin_04", "sf_prop_sf_blocker_studio_01a", "ba_rig_dj_04_lights_04_a", "m24_1_prop_m41_camera_01a", "h4_rig_dj_04_lights_04_c" }

    m.af("LSC Party", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_dumpster_02b") then
                    higurashi.remove_entity({ objs })
                end
            end
            local user_pos = higurashi.get_user_coords() + v3()
            local veh_hash = joaat("pbus2")
            lsc_pbus[1] = higurashi.create_vehicle(veh_hash, v3(-374.298, -81.828, 45.921), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[1], v3(0.021, -0.001, 158.161), 5, 0)
            lsc_pbus[2] = higurashi.create_vehicle(veh_hash, v3(-343.401, -90.055, 45.922), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[2], v3(-0.045, 0.017, -21.097), 5, 0)
            lsc_pbus[3] = higurashi.create_vehicle(veh_hash, v3(-347.660, -101.497, 45.922), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[3], v3(0.082, -0.031, -20.299), 5, 0)
            lsc_pbus[4] = higurashi.create_vehicle(veh_hash, v3(-361.395, -76.740, 45.921), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[4], v3(-0.005, -0.001, 70.723), 5, 0)
            lsc_pbus[5] = higurashi.create_vehicle(veh_hash, v3(-350.161, -81.180, 45.922), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[5], v3(-0.005, -0.001, 70.723), 5, 0)
            lsc_pbus[6] = higurashi.create_vehicle(veh_hash, v3(-389.572, -104.512, 38.963), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[6], v3(0.841, 0.377, 119.673), 5, 0)
            lsc_pbus[7] = higurashi.create_vehicle(veh_hash, v3(-385.463, -147.848, 38.790), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[7], v3(-0.032, -0.018, -150.927), 5, 0)
            lsc_pbus[8] = higurashi.create_vehicle(veh_hash, v3(-397.207, -127.580, 38.791), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.FREEZE_ENTITY_POSITION(lsc_pbus[8], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[8], v3(-0.032, -0.018, -150.927), 5, 0)
            lsc_pbus[9] = higurashi.create_vehicle(veh_hash, v3(-362.575, -145.977, 38.505), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.FREEZE_ENTITY_POSITION(lsc_pbus[9], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[9], v3(0.168, 0.055, -60.427), 5, 0)
            lsc_pbus[10] = higurashi.create_vehicle(veh_hash, v3(-355.382, -114.109, 38.955), 0, true, false, false, true, false, false, true)
            wait()
            NATIVE.FREEZE_ENTITY_POSITION(lsc_pbus[10], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[10], v3(0.040, 0.021, -19.042), 5, 0)
            wait()
            lsc_pbus[11] = higurashi.create_vehicle(veh_hash, v3(-367.930, -97.573, 35.427), 0, true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_pbus[11], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_pbus[11], v3(0.000, 0.000, 68.059), 5, 0)
            NATIVE.SET_VEHICLE_EXTRA(lsc_pbus[11], 1, true)
            wait()
            NATIVE.START_AUDIO_SCENE("DLC_BTL_PBUS2_Music_Boost_Scene")
            for i = 1, #lsc_pbus do
                NATIVE.DECOR_SET_INT(lsc_pbus[i], "Skill_Blocker", -1)
                NATIVE.ADD_ENTITY_TO_AUDIO_MIX_GROUP(lsc_pbus[i], "DLC_BTL_PBUS2_Music_Boost_Mixgroup", 0)
                higurashi.set_visible_god_freeze({ lsc_pbus[i] }, true, true, true)
                NATIVE.SET_VEHICLE_ENGINE_ON(lsc_pbus[i], true, true, false)
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(lsc_pbus[i], true)
                NATIVE.SET_VEHICLE_LIGHTS(lsc_pbus[i], 3)
                NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), lsc_pbus[i], -1)
                wait(0)
                NATIVE.SET_CONTROL_NORMAL(2, 86, 1.0)
                NATIVE.SET_VEH_RADIO_STATION(lsc_pbus[i], "OFF")
                wait(20)
                NATIVE.SET_VEHICLE_RADIO_ENABLED(lsc_pbus[i], true)
                NATIVE.SET_VEH_RADIO_STATION(lsc_pbus[i], pbus_selected_station)
                NATIVE.SET_VEHICLE_RADIO_LOUD(lsc_pbus[i], true)
                NATIVE.SET_VEHICLE_DOORS_LOCKED(lsc_pbus[i], 2)
            end
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            higurashi.teleport_to(user_pos)
            --[[
            lsc_party_props[] = higurashi.create_object(joaat("h4_prop_battle_dj_deck_01a"), v3(-369.267, -103.580, 39.466), true, false, false)    -- 3
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[], 0, 0, 160.0)

            lsc_party_props[] = higurashi.create_object(joaat("h4_prop_battle_dj_deck_01a"), v3(-369.587, -103.460, 39.466), true, false, false)    -- 4
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[], 0, 0, 160.0)]]

            lsc_party_props[1] = higurashi.create_object(joaat("sf_prop_sf_dj_desk_01a"), v3(-369.000, -103.750, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[1], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[1], 0, 0, -20.0)

            lsc_party_props[2] = higurashi.create_object(joaat("h4_prop_battle_dj_mixer_01f"), v3(-368.920, -103.700, 39.466), true, false, false, true, false, false, true)
            --lsc_party_props[2] = higurashi.create_object(joaat("h4_prop_battle_analoguemixer_01a"), v3(-368.910, -103.700, 39.466), true, false, false)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[2], 0, 0, 160.0)

            lsc_party_props[3] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-370.470, -103.500, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[3], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[3], 0, 0, -20.0)

            lsc_party_props[4] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-367.720, -104.500, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[4], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[4], 0, 0, -20.0)

            lsc_party_props[5] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-371.190, -103.250, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[5], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[5], 0, 0, -20.0)

            lsc_party_props[6] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-367.000, -104.750, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[6], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[6], 0, 0, -20.0)

            lsc_party_props[7] = higurashi.create_object(joaat("prop_table_07"), v3(-370.000, -102.250, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[7], true)

            local bottle_models = { "h4_prop_h4_t_bottle_01a", "m23_2_prop_m32_t_bottle_02a", "h4_prop_h4_t_bottle_02b", "ba_prop_battle_whiskey_bottle_s", "ba_prop_battle_whiskey_bottle_2_s", "ba_prop_battle_whiskey_opaque_s", "ba_prop_battle_decanter_03_s" }
            lsc_party_props[8] = higurashi.create_object(joaat(bottle_models[math.random(#bottle_models)]), v3(-369.840, -102.210, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[8], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[8], 0, 0, -14.0)

            lsc_party_props[9] = higurashi.create_object(joaat("prop_champ_cool"), v3(-370.079, -102.216, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[9], true)

            lsc_party_props[10] = higurashi.create_object(joaat("prop_drink_whisky"), v3(-369.929, -102.342, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[10], true)

            local champglass_models = { "hei_p_hei_champ_flute_s", "prop_drink_champ" }
            lsc_party_props[11] = higurashi.create_object(joaat(champglass_models[math.random(#champglass_models)]), v3(-370.000, -102.500, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[11], true)

            lsc_party_props[12] = higurashi.create_object(joaat("prop_table_07"), v3(-367.000, -103.500, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[12], true)

            lsc_party_props[13] = higurashi.create_object(joaat("sf_prop_sf_laptop_01b"), v3(-367.000, -103.500, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[13], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[13], v3(0.0, 0.0, -96.0))

            lsc_party_props[14] = higurashi.create_object(joaat("sf_p_sf_grass_gls_s_01a"), v3(-367.000, -103.750, 39.373), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[14], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[14], v3(0.0, 0.0, -111.0))

            lsc_party_props[15] = higurashi.create_object(joaat("h4_prop_h4_mic_dj_01a"), v3(-369.900, -103.660, 39.453), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[15], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[15], 0, 0, 115.0)

            lsc_party_props[16] = higurashi.create_object(joaat("ba_prop_club_water_bottle"), v3(-368.250, -104.250, 39.460), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[16], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[16], 0, 0, 85.0)

            lsc_party_props[17] = higurashi.create_object(joaat("ba_prop_club_water_bottle"), v3(-369.887, -103.399, 39.460), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[17], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[17], 0, 0, 35.0)

            lsc_party_props[18] = higurashi.create_object(joaat("sf_prop_sf_lamp_studio_02a"), v3(-375.000, -99.250, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[18], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[18], 0, 0, -20.0)

            lsc_party_props[19] = higurashi.create_object(joaat("sf_prop_sf_lamp_studio_02a"), v3(-361.000, -104.250, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[19], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[19], 0, 0, -20.0)

            lsc_party_props[20] = higurashi.create_object(joaat("m23_2_prop_m32_planninglight_01a"), v3(-368.500, -101.000, 41.352), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[20], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[20], 0.0, 0.0, -20.0)

            lsc_party_props[21] = higurashi.create_object(joaat("v_ret_neon_blarneys"), v3(-368.500, -100.850, 40.260), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[21], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[21], 0.0, 0.0, -20.0)

            lsc_party_props[22] = higurashi.create_object(joaat("vw_prop_vw_wallart_31a"), v3(-373.519, -98.824, 40.371), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[22], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[22], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[22], v3(-373.519, -98.824, 40.371))

            lsc_party_props[23] = higurashi.create_object(joaat("vw_prop_vw_wallart_30a"), v3(-371.432, -99.584, 40.283), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[23], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[23], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[23], v3(-371.432, -99.584, 40.283))

            lsc_party_props[24] = higurashi.create_object(joaat("sf_prop_sf_vend_drink_01a"), v3(-377.500, -100.500, 37.684), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[24], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[24], v3(0.0, 0.0, -20.0))

            lsc_party_props[25] = higurashi.create_object(joaat("ba_prop_battle_poster_skin_01"), v3(-365.688, -101.727, 40.291), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[25], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[25], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[25], v3(-365.688, -101.727, 40.291))

            lsc_party_props[26] = higurashi.create_object(joaat("ba_prop_battle_poster_skin_02"), v3(-365.037, -101.964, 40.291), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[26], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[26], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[26], v3(-365.037, -101.964, 40.291))

            lsc_party_props[27] = higurashi.create_object(joaat("ba_prop_battle_poster_skin_03"), v3(-364.372, -102.207, 40.291), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[27], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[27], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[27], v3(-364.372, -102.207, 40.291))

            lsc_party_props[28] = higurashi.create_object(joaat("ba_prop_battle_poster_skin_04"), v3(-363.688, -102.456, 40.291), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[28], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[28], v3(0.0, 0.0, -20.0))
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(lsc_party_props[28], v3(-363.688, -102.456, 40.291))

            lsc_party_props[29] = higurashi.create_object(joaat("sf_prop_sf_blocker_studio_01a"), v3(-368.000, -102.000, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[29], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[29], v3(0.0, 0.0, -115.0))

            lsc_party_props[30] = higurashi.create_object(joaat("sf_prop_sf_speaker_stand_01a"), v3(-371.000, -101.500, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[30], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[30], 0.0, 0.0, -20.0)

            lsc_party_props[31] = higurashi.create_object(joaat("sf_prop_sf_speaker_stand_01a"), v3(-366.250, -103.250, 38.548), true, false, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[31], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[31], 0.0, 0, -20.0)

            lsc_party_props[32] = higurashi.create_world_object(joaat("ba_rig_dj_04_lights_04_a"), v3(-372.119, -100.689, 43.999), true, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[32], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[32], 0.0, 45.0, -110.0)

            lsc_party_props[33] = higurashi.create_world_object(joaat("ba_rig_dj_04_lights_04_a"), v3(-363.622, -103.811, 43.999), true, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[33], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[33], 0.0, 45.0, -110.0)

            lsc_party_props[34] = higurashi.create_world_object(joaat("h4_rig_dj_04_lights_04_c"), v3(-372.226, -101.019, 43.389), true, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[34], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[34], 0.0, 45.0, -110.0)

            lsc_party_props[35] = higurashi.create_world_object(joaat("h4_rig_dj_04_lights_04_c"), v3(-363.767, -104.133, 43.389), true, false, true, false, false, true)
            NATIVE.FREEZE_ENTITY_POSITION(lsc_party_props[35], true)
            NATIVE.SET_ENTITY_ROTATION(lsc_party_props[35], 0.0, 45.0, -110.0)
            wait(0)
            for i = 1, #lsc_party_props do
                NATIVE.SET_ENTITY_INVINCIBLE(lsc_party_props[i], true)
            end
            lsc_cust[1] = higurashi.create_ped(2, joaat("U_F_Y_DanceBurl_01"), v3(-373.710, -101.299, 39.542), 0, true, false, true, false, false, true, true)
            lsc_cust[2] = higurashi.create_ped(2, joaat("U_F_Y_DanceRave_01"), v3(-365.099, -104.004, 39.543), 0, true, false, true, false, false, true, true)
            for i = 1, #lsc_cust do
                NATIVE.DECOR_SET_INT(lsc_cust[i], "Skill_Blocker", -1)
                NATIVE.SET_PED_DEFAULT_COMPONENT_VARIATION(lsc_cust[i])
                higurashi.set_entity_godmode(lsc_cust[i], true)
                NATIVE.SET_PED_COMBAT_ATTRIBUTES(lsc_cust[i], 46, true)
                NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(lsc_cust[i], true)
                NATIVE.SET_PED_CAN_RAGDOLL(lsc_cust[i], false)
                NATIVE.SET_PED_CAN_BE_TARGETTED(lsc_cust[i], false)
                NATIVE.SET_CAN_ATTACK_FRIENDLY(lsc_cust[i], false, true)
                --NATIVE.SET_PED_CONFIG_FLAG(lsc_cust[i], 241, true)
                wait(500)
                NATIVE.FREEZE_ENTITY_POSITION(lsc_cust[i], true)
                NATIVE.SET_ENTITY_ROTATION(lsc_cust[i], v3(0.0, 0.0, 160.0))
            end
            higurashi.request_anim_dict("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")
            NATIVE.TASK_PLAY_ANIM(lsc_cust[1], "anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^3", 1.0, 1.0, -1, 3, 100.0, false, false, false)
            NATIVE.REMOVE_ANIM_DICT("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")
            higurashi.request_anim_dict("anim@amb@nightclub@dancers@crowddance_facedj@")
            NATIVE.TASK_PLAY_ANIM(lsc_cust[2], "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_17_v2_female^1", 1.0, 1.0, -1, 3, 100.0, false, false, false)
            NATIVE.REMOVE_ANIM_DICT("anim@amb@nightclub@dancers@crowddance_facedj@")
            m.n("LSC Party loaded.", title, 3, c.green1)
        elseif f.value == 1 then
            for i = 1, #lsc_pbus do
                NATIVE.REMOVE_ENTITY_FROM_AUDIO_MIX_GROUP(lsc_pbus[i], 0.0)
                higurashi.remove_entity({ lsc_pbus[i] })
            end
            for i = 1, #lsc_party_props do
                higurashi.remove_entity({ lsc_party_props[i] })
            end
            for i = 1, #lsc_cust do
                higurashi.remove_entity({ lsc_cust[i] })
            end
            NATIVE.STOP_AUDIO_SCENE("DLC_BTL_PBUS2_Music_Boost_Scene")
            m.n("LSC Party unloaded.", title, 3, c.yellow1)
        end
    end):set_str_data({ "Spawn", "Delete" })

    local alien_camp_pbus = {}
    local alien_camp_party_props = {}
    local alien_camp_cust = {}
    local alien_camp_party_prop_lists = {}

    m.af("Alien Camp Party", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            local alien_camp_default_props = { "prop_paints_bench01", "prop_paints_pallete01", "prop_paints_can01", "prop_paints_can02", "prop_paints_can03", "prop_paints_can04", "prop_paints_can06", "prop_paints_can07", "prop_paint_spray01a",
                "prop_paint_spray01b", "prop_rub_monitor", "prop_barrel_01a", "prop_barrel_02a", "prop_paint_stepl01b", "prop_paint_stepl02", "prop_worklight_02a", "v_ind_cm_paintbckt04",
                "prop_crate_05a", "prop_crate_06a", "prop_crate_08a", "prop_tool_box_03", "prop_tool_box_04", "prop_tool_bench01", "prop_wheelbarrow01a", "prop_paint_roller", "prop_boombox_01" }
            for _, objs in pairs(object.get_all_objects()) do
                for i = 1, #alien_camp_default_props do
                    if NATIVE.GET_ENTITY_MODEL(objs) == joaat(alien_camp_default_props[i]) then
                        higurashi.remove_entity({ objs })
                    end
                end
            end
            local user_pos = higurashi.get_user_coords() + v3()
            local veh_hash = joaat("pbus2")
            alien_camp_pbus[1] = higurashi.create_vehicle(veh_hash, v3(2456.898926, 3756.400146, 42.221741), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[1], v3(0.661, 1.180, -143.500), 5, 0)
            alien_camp_pbus[2] = higurashi.create_vehicle(veh_hash, v3(2470.355957, 3744.380859, 42.453945), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[2], v3(0.915, 0.053, -127.770), 5, 0)
            alien_camp_pbus[3] = higurashi.create_vehicle(veh_hash, v3(2486.914551, 3737.943848, 43.052338), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[3], v3(5.362, 0.394, -98.997), 5, 0)
            alien_camp_pbus[4] = higurashi.create_vehicle(veh_hash, v3(2506.981201, 3746.405029, 43.567207), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[4], v3(-0.343, -1.010, -39.222), 5, 0)
            alien_camp_pbus[5] = higurashi.create_vehicle(veh_hash, v3(2484.001221, 3810.357422, 40.594322), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[5], v3(-1.545, 5.268, 114.213), 5, 0)
            alien_camp_pbus[6] = higurashi.create_vehicle(veh_hash, v3(2470.753906, 3802.684814, 40.622055), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[6], v3(-0.292, 1.512, 122.164), 5, 0)
            alien_camp_pbus[7] = higurashi.create_vehicle(veh_hash, v3(2461.200195, 3791.519775, 40.937088), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[7], v3(2.187, 2.141, 147.419), 5, 0)
            alien_camp_pbus[8] = higurashi.create_vehicle(veh_hash, v3(2454.143799, 3777.999023, 41.571815), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[8], v3(3.330, 0.502, 157.363), 5, 0)
            wait()
            alien_camp_pbus[9] = higurashi.create_vehicle(veh_hash, v3(2516.143799, 3788.123535, 49.106831), 0, true, false, false, true, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_pbus[9], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[9], v3(0.959, -0.000, 1.133), 5, 0)
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(alien_camp_pbus[9], v3(2516.143799, 3788.123535, 49.106831))
            wait()
            alien_camp_pbus[10] = higurashi.create_vehicle(veh_hash, v3(2516.312256, 3779.579590, 47.990456), 0, true, false, false, true, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_pbus[10], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_pbus[10], v3(4.277, 0.000, -9.050), 5, 0)
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(alien_camp_pbus[10], v3(2516.312256, 3779.579590, 47.990456))
            for i = 1, 7 do
                NATIVE.SET_VEHICLE_EXTRA(alien_camp_pbus[9], i, true)
                NATIVE.SET_VEHICLE_EXTRA(alien_camp_pbus[10], i, true)
            end
            wait()
            for i = 1, #alien_camp_pbus do
                NATIVE.DECOR_SET_INT(alien_camp_pbus[i], "Skill_Blocker", -1)
                NATIVE.ADD_ENTITY_TO_AUDIO_MIX_GROUP(alien_camp_pbus[i], "DLC_BTL_PBUS2_Music_Boost_Mixgroup", 0)
                higurashi.set_visible_god_freeze({ alien_camp_pbus[i] }, true, true, true)
                NATIVE.SET_VEHICLE_ENGINE_ON(alien_camp_pbus[i], true, true, false)
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(alien_camp_pbus[i], true)
                NATIVE.SET_VEHICLE_LIGHTS(alien_camp_pbus[i], 3)
                NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), alien_camp_pbus[i], -1)
                wait(0)
                NATIVE.SET_CONTROL_NORMAL(2, 86, 1.0)
                NATIVE.SET_VEH_RADIO_STATION(alien_camp_pbus[i], "OFF")
                wait(20)
                NATIVE.SET_VEHICLE_RADIO_ENABLED(alien_camp_pbus[i], true)
                NATIVE.SET_VEH_RADIO_STATION(alien_camp_pbus[i], selected_radio_station)

                NATIVE.SET_VEHICLE_RADIO_LOUD(alien_camp_pbus[i], true)
                NATIVE.SET_VEHICLE_DOORS_LOCKED(alien_camp_pbus[i], 2)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(alien_camp_pbus[i], true)
            end
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            higurashi.teleport_to(user_pos)
            --[[

            alien_camp_party_props[1] = higurashi.create_object(joaat("sf_prop_sf_dj_desk_01a"), v3(-369.000, -103.750, 38.548), true, false, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_party_props[1], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[1], 0, 0, -20.0)

            alien_camp_party_props[2] = higurashi.create_object(joaat("h4_prop_battle_dj_mixer_01f"), v3(-368.920, -103.700, 39.466), true, false, false)
            --alien_camp_party_props[2] = higurashi.create_object(joaat("h4_prop_battle_analoguemixer_01a"), v3(-368.910, -103.700, 39.466), true, false, false)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[2], 0, 0, 160.0)

            alien_camp_party_props[3] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-370.470, -103.500, 38.548), true, false, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_party_props[3], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[3], 0, 0, -20.0)

            alien_camp_party_props[4] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-367.720, -104.500, 38.548), true, false, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_party_props[4], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[4], 0, 0, -20.0)

            alien_camp_party_props[5] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-371.190, -103.250, 38.548), true, false, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_party_props[5], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[5], 0, 0, -20.0)

            alien_camp_party_props[6] = higurashi.create_object(joaat("sf_prop_sf_speaker_l_01a"), v3(-367.000, -104.750, 38.548), true, false, false)
            NATIVE.FREEZE_ENTITY_POSITION(alien_camp_party_props[6], true)
            NATIVE.SET_ENTITY_ROTATION(alien_camp_party_props[6], 0, 0, -20.0)
            wait(0)
            for i = 1, #alien_camp_party_props do
                NATIVE.SET_ENTITY_INVINCIBLE(alien_camp_party_props[i], true)
            end]]
            --[[alien_camp_cust[1] = higurashi.create_ped(2, joaat(""), v3(-373.710, -101.299, 39.542), 0, true, false, true, false)
            NATIVE.SET_PED_DEFAULT_COMPONENT_VARIATION(alien_camp_cust[1])
            alien_camp_cust[2] = higurashi.create_ped(2, joaat(""), v3(-365.099, -104.004, 39.543), 0, true, false, true, false)
            NATIVE.SET_PED_DEFAULT_COMPONENT_VARIATION(alien_camp_cust[2])
            for i = 1, #alien_camp_cust do
                higurashi.request_control_of_entity(alien_camp_cust[i])
                local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(alien_camp_cust[i])
                NATIVE.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
                NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
                NATIVE.DECOR_SET_INT(alien_camp_cust[i], "Skill_Blocker", -1)
                NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(alien_camp_cust[i], true)
                NATIVE.SET_PED_CAN_RAGDOLL(alien_camp_cust[i], false)
                NATIVE.SET_PED_CAN_BE_TARGETTED(alien_camp_cust[i], false)
                NATIVE.SET_CAN_ATTACK_FRIENDLY(alien_camp_cust[i], false, false)
                NATIVE.SET_ENTITY_INVINCIBLE(alien_camp_cust[i], true)
                NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(alien_camp_cust[i])
                wait(500)
                NATIVE.FREEZE_ENTITY_POSITION(alien_camp_cust[i], true)
                NATIVE.SET_ENTITY_ROTATION(alien_camp_cust[i], v3(0.0, 0.0, 160.0))
            end
            higurashi.request_anim_dict("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")
            NATIVE.TASK_PLAY_ANIM(alien_camp_cust[1], "anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^3", 1.0, 1.0, -1, 3, 100.0, false, false, false)
            NATIVE.REMOVE_ANIM_DICT("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")
            higurashi.request_anim_dict("anim@amb@nightclub@dancers@crowddance_facedj@")
            NATIVE.TASK_PLAY_ANIM(alien_camp_cust[2], "anim@amb@nightclub@dancers@crowddance_facedj@", "hi_dance_facedj_17_v2_female^1", 1.0, 1.0, -1, 3, 100.0, false, false, false)
            NATIVE.REMOVE_ANIM_DICT("anim@amb@nightclub@dancers@crowddance_facedj@")
            higurashi.request_anim_dict("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")
            NATIVE.TASK_PLAY_ANIM(alien_camp_cust[3], "anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity", "hi_dance_facedj_hu_15_v1_female^5", 1.0, 1.0, -1, 3, 100.0, false, false, false)
            NATIVE.REMOVE_ANIM_DICT("anim@amb@nightclub_island@dancers@crowddance_facedj@hi_intensity")]]
        elseif f.value == 1 then
            for i = 1, #alien_camp_pbus do
                higurashi.remove_entity({ alien_camp_pbus[i] })
            end --[[
            for i = 1, #alien_camp_party_props do
                higurashi.remove_entity({ alien_camp_party_props[i] })
            end
            for i = 1, #lsc_dj do
                higurashi.remove_entity({ alien_camp_dj[i] })
            end
            for i = 1, #alien_camp_cust do
                higurashi.remove_entity({ alien_camp_cust[i] })
            end]]
            m.n("Alien Camp Party unloaded.", title, 3, c.yellow1)
        end
    end):set_str_data({ "Spawn", "Delete" })

    local caesars_auto_parking_pbus = {}

    m.af("Caesars Auto Parking Party", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            local caesars_auto_parking_default_props = { "prop_fnclink_05d", "prop_dumpster_01a", "prop_wall_light_17a" }
            for _, objs in pairs(object.get_all_objects()) do
                for i = 1, #caesars_auto_parking_default_props do
                    if NATIVE.GET_ENTITY_MODEL(objs) == joaat(caesars_auto_parking_default_props[i]) then
                        higurashi.remove_entity({ objs })
                    end
                end
            end
            local user_pos = higurashi.get_user_coords() + v3()
            local veh_hash = joaat("pbus2")
            --local screen_prop = joaat("ba_prop_battle_pbus_screen")
            -- NATIVE.START_AUDIO_SCENE("DLC_BTL_PBUS2_Music_Boost_Scene")
            caesars_auto_parking_pbus[1] = higurashi.create_vehicle(veh_hash, v3(105.527, -1049.875, 29.592), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[1], v3(0.130, 0.210, 155.589), 5, 0)
            caesars_auto_parking_pbus[2] = higurashi.create_vehicle(veh_hash, v3(100.582, -1060.680, 29.580), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[2], v3(0.123, 0.177, 155.489), 5, 0)
            caesars_auto_parking_pbus[3] = higurashi.create_vehicle(veh_hash, v3(93.070, -1076.733, 29.554), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[3], v3(0.005, 0.107, 156.124), 5, 0)
            caesars_auto_parking_pbus[4] = higurashi.create_vehicle(veh_hash, v3(120.913, -1053.415, 29.451), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[4], v3(-0.010, -0.036, 70.461), 5, 0)
            caesars_auto_parking_pbus[5] = higurashi.create_vehicle(veh_hash, v3(141.258, -1060.759, 29.456), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[5], v3(-0.201, 0.397, 70.474), 5, 0)
            caesars_auto_parking_pbus[6] = higurashi.create_vehicle(veh_hash, v3(153.521, -1067.919, 29.451), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[6], v3(0.001, -0.037, 69.604), 5, 0)
            caesars_auto_parking_pbus[7] = higurashi.create_vehicle(veh_hash, v3(168.578, -1078.860, 29.452), 0, true, false, false, true, false)
            NATIVE.SET_ENTITY_ROTATION(caesars_auto_parking_pbus[10], v3(0.032, -0.043, -0.648), 5, 0)
            --[[obj[1] = higurashi.create_object(screen_prop, v3(105.527, -1049.875, 29.592),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[1], caesars_auto_parking_pbus[1], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[2] = higurashi.create_object(screen_prop, v3(100.582, -1060.680, 29.580),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[2], caesars_auto_parking_pbus[2], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[3] = higurashi.create_object(screen_prop, v3(93.070, -1076.733, 29.554),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[3], caesars_auto_parking_pbus[3], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[4] = higurashi.create_object(screen_prop, v3(120.913, -1053.415, 29.451),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[4], caesars_auto_parking_pbus[4], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[5] = higurashi.create_object(screen_prop, v3(141.258, -1060.759, 29.456),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[5], caesars_auto_parking_pbus[5], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[6] = higurashi.create_object(screen_prop, v3(153.521, -1067.919, 29.451),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[6], caesars_auto_parking_pbus[6], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[7] = higurashi.create_object(screen_prop, v3(168.578, -1078.860, 29.452),true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[7], caesars_auto_parking_pbus[7], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
              ]]
            wait()
            for i = 1, #caesars_auto_parking_pbus do
                NATIVE.DECOR_SET_INT(caesars_auto_parking_pbus[i], "Skill_Blocker", -1)
                NATIVE.ADD_ENTITY_TO_AUDIO_MIX_GROUP(caesars_auto_parking_pbus[i], "DLC_BTL_PBUS2_Music_Boost_Mixgroup", 0)
                higurashi.set_visible_god_freeze({ caesars_auto_parking_pbus[i] }, true, true, true)
                NATIVE.SET_VEHICLE_ENGINE_ON(caesars_auto_parking_pbus[i], true, true, false)
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(caesars_auto_parking_pbus[i], true)
                NATIVE.SET_VEHICLE_LIGHTS(caesars_auto_parking_pbus[i], 3)
                NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), caesars_auto_parking_pbus[i], -1)
                wait(0)
                NATIVE.SET_CONTROL_NORMAL(2, 86, 1.0)
                NATIVE.SET_VEH_RADIO_STATION(caesars_auto_parking_pbus[i], "OFF")
                wait(20)
                NATIVE.SET_VEHICLE_RADIO_ENABLED(caesars_auto_parking_pbus[i], true)
                NATIVE.SET_VEH_RADIO_STATION(caesars_auto_parking_pbus[i], selected_radio_station)
                NATIVE.SET_VEHICLE_RADIO_LOUD(caesars_auto_parking_pbus[i], true)
                NATIVE.SET_VEHICLE_DOORS_LOCKED(caesars_auto_parking_pbus[i], 2)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(caesars_auto_parking_pbus[i], true)
            end
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            higurashi.teleport_to(user_pos)
            --[[ m.ct(function()
                    local handler = higurashi.create_named_render_target_for_model("pbus_screen", screen_prop)
                    local pbus_scaleform = NATIVE.REQUEST_SCALEFORM_MOVIE("PARTY_BUS")
                    while true do
                        if (NATIVE.HAS_SCALEFORM_MOVIE_LOADED(pbus_scaleform)) then
                            NATIVE.SET_SCALEFORM_MOVIE_TO_USE_LARGE_RT(pbus_scaleform, true)
                            NATIVE.SET_TEXT_RENDER_ID(handler)
                            NATIVE.SET_SCRIPT_GFX_DRAW_ORDER(4)
                            NATIVE.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(1)
                            NATIVE.DRAW_SCALEFORM_MOVIE(pbus_scaleform, 0.4, 0.045, 0.8, 0.09, 255, 255, 255, 255, 0)
                            NATIVE.SET_TEXT_RENDER_ID(NATIVE.GET_DEFAULT_SCRIPT_RENDERTARGET_RENDER_ID())
                        end
                        wait(0)
                    end
                end)]]
        elseif f.value == 1 then
            for i = 1, #caesars_auto_parking_pbus do
                higurashi.remove_entity({ caesars_auto_parking_pbus[i] })
            end
        end
    end):set_str_data({ "Spawn", "Delete" })

    local galileo_observatory_pbus = {}
    local galileo_observatory_party_props = {}
    m.af("Galileo Observatory Party", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == joaat("prop_streetlight_09") then
                    higurashi.hard_remove_entity(objs)
                end
            end
            local user_pos = higurashi.get_user_coords() + v3()
            local veh_hash = joaat("pbus2")
            galileo_observatory_pbus[1] = higurashi.create_vehicle(veh_hash, v3(-440.818848, 1170.101807, 326.163086), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[1], v3(0.004690, 0.004843, 134.101639), 5, 0)
            galileo_observatory_pbus[2] = higurashi.create_vehicle(veh_hash, v3(-450.975464, 1160.549561, 326.162781), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[2], v3(-0.021907, 0.018432, 133.006561), 5, 0)
            galileo_observatory_pbus[3] = higurashi.create_vehicle(veh_hash, v3(-461.094330, 1151.429810, 326.1624456), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[3], v3(-0.002317, -0.002672, 132.196426), 5, 0)
            galileo_observatory_pbus[4] = higurashi.create_vehicle(veh_hash, v3(-464.131256, 1136.274292, 326.162933), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[4], v3(-0.008461, -0.021923, -105.480179), 5, 0)
            galileo_observatory_pbus[5] = higurashi.create_vehicle(veh_hash, v3(-450.801544, 1132.561523, 326.162567), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[5], v3(0.003143, -0.014400, -105.813362), 5, 0)
            galileo_observatory_pbus[6] = higurashi.create_vehicle(veh_hash, v3(-433.771606, 1127.848877, 326.163666), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[6], v3(0.004942, 0.005290, -105.743347), 5, 0)
            galileo_observatory_pbus[7] = higurashi.create_vehicle(veh_hash, v3(-414.230652, 1122.624023, 326.163177), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[7], v3(0.012281, 0.020471, -104.755447), 5, 0)
            galileo_observatory_pbus[8] = higurashi.create_vehicle(veh_hash, v3(-405.913940, 1134.883423, 326.163330), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[8], v3(-0.015757, -0.001757, -16.297609), 5, 0)
            galileo_observatory_pbus[9] = higurashi.create_vehicle(veh_hash, v3(-401.976685, 1148.654907, 326.141846), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[9], v3(-0.551110, 0.246910, -16.266266), 5, 0)
            galileo_observatory_pbus[10] = higurashi.create_vehicle(veh_hash, v3(-397.943573, 1162.979248, 326.167908), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[10], v3(0.073615, 0.217584, -16.116291), 5, 0)
            wait()
            galileo_observatory_pbus[11] = higurashi.create_vehicle(veh_hash, v3(-429.774994, 1106.586182, 328.291321), 0, true, false, false, true, false)

            NATIVE.FREEZE_ENTITY_POSITION(galileo_observatory_pbus[11], true)
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_pbus[11], v3(0.624178, 2.432326, -104.397232), 5, 0)
            NATIVE.SET_ENTITY_COORDS_NO_OFFSET(galileo_observatory_pbus[11], v3(-429.774994, 1106.586182, 328.291321))
            --           wait()
            for i = 1, 7 do
                NATIVE.SET_VEHICLE_EXTRA(galileo_observatory_pbus[11], i, true)
            end
            wait()
            NATIVE.START_AUDIO_SCENE("DLC_BTL_PBUS2_Music_Boost_Scene")
            for i = 1, #galileo_observatory_pbus do
                NATIVE.DECOR_SET_INT(galileo_observatory_pbus[i], "Skill_Blocker", -1)
                NATIVE.ADD_ENTITY_TO_AUDIO_MIX_GROUP(galileo_observatory_pbus[i], "DLC_BTL_PBUS2_Music_Boost_Mixgroup", 0)
                higurashi.set_visible_god_freeze({ galileo_observatory_pbus[i] }, true, true, true)
                NATIVE.SET_VEHICLE_ENGINE_ON(galileo_observatory_pbus[i], true, true, false)
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(galileo_observatory_pbus[i], true)
                NATIVE.SET_VEHICLE_LIGHTS(galileo_observatory_pbus[i], 3)
                NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), galileo_observatory_pbus[i], -1)
                wait(0)
                NATIVE.SET_CONTROL_NORMAL(2, 86, 1.0)
                NATIVE.SET_VEH_RADIO_STATION(galileo_observatory_pbus[i], "OFF")
                wait(20)
                NATIVE.SET_VEHICLE_RADIO_ENABLED(galileo_observatory_pbus[i], true)
                NATIVE.SET_VEH_RADIO_STATION(galileo_observatory_pbus[i], selected_radio_station)
                NATIVE.SET_VEHICLE_RADIO_LOUD(galileo_observatory_pbus[i], true)
                NATIVE.SET_VEHICLE_DOORS_LOCKED(galileo_observatory_pbus[i], 2)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(galileo_observatory_pbus[i], true)
            end
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            higurashi.teleport_to(user_pos)
            --[[
            galileo_observatory_party_props[] = higurashi.create_object(joaat("h4_prop_battle_dj_deck_01a"), v3(-369.267, -103.580, 39.466), true, false, false)    -- 3
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_party_props[], 0, 0, 160.0)

            galileo_observatory_party_props[] = higurashi.create_object(joaat("h4_prop_battle_dj_deck_01a"), v3(-369.587, -103.460, 39.466), true, false, false)    -- 4
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_party_props[], 0, 0, 160.0)]]

            galileo_observatory_party_props[1] = higurashi.create_object(joaat("sf_prop_sf_dj_desk_01a"), v3(-427.250, 1117.500, 325.768), true, false, false, true, false)
            NATIVE.FREEZE_ENTITY_POSITION(galileo_observatory_party_props[1], true)
            NATIVE.SET_ENTITY_ROTATION(galileo_observatory_party_props[1], 0, 0, 165.0)
            wait(0)
            for i = 1, #galileo_observatory_party_props do
                NATIVE.SET_ENTITY_INVINCIBLE(galileo_observatory_party_props[i], true)
            end
        elseif f.value == 1 then
            for i = 1, #galileo_observatory_pbus do
                higurashi.remove_entity({ galileo_observatory_pbus[i] })
            end
            for i = 1, #galileo_observatory_party_props do
                higurashi.remove_entity({ galileo_observatory_party_props[i] })
            end
            NATIVE.STOP_AUDIO_SCENE("DLC_BTL_PBUS2_Music_Boost_Scene")
        end
    end):set_str_data({ "Spawn", "Delete" })

    local vespucci_beach_pbus = {}

    m.af("Vespucci Beach Party", "action_value_str", Higurashi.WorldEnhancement.id, function(f)
        if f.value == 0 then
            local user_pos = higurashi.get_user_coords() + v3()
            local veh_hash = joaat("pbus2")
            vespucci_beach_pbus[1] = higurashi.create_vehicle(veh_hash, v3(-1601.030884, -861.649353, 10.385275), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[1], v3(-0.096761, 0.025363, 49.641857), 5, 0)
            vespucci_beach_pbus[2] = higurashi.create_vehicle(veh_hash, v3(-1610.705688, -853.426880, 10.382395), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[2], v3(-0.025816, 0.057151, 49.003948), 5, 0)
            vespucci_beach_pbus[3] = higurashi.create_vehicle(veh_hash, v3(-1620.331421, -845.312988, 10.390876), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[3], v3(-0.134832, -0.046846, 49.630234), 5, 0)
            vespucci_beach_pbus[4] = higurashi.create_vehicle(veh_hash, v3(-1629.986084, -837.092773, 10.392920), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[4], v3(-0.251410, 0.168822, 49.113853), 5, 0)
            vespucci_beach_pbus[5] = higurashi.create_vehicle(veh_hash, v3(-1639.551758, -828.726440, 10.393950), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[5], v3(0.040948, 0.181824, 48.343605), 5, 0)
            vespucci_beach_pbus[6] = higurashi.create_vehicle(veh_hash, v3(-1715.042847, -918.106018, 7.935760), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[6], v3(-0.032364, -0.034499, -133.070831), 5, 0)
            vespucci_beach_pbus[7] = higurashi.create_vehicle(veh_hash, v3(-1707.041016, -928.866699, 7.935344), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[7], v3(-0.046373, -0.019566, -150.967514), 5, 0)
            vespucci_beach_pbus[8] = higurashi.create_vehicle(veh_hash, v3(-1699.620605, -941.067505, 7.935336), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[8], v3(-0.010601, -0.026106, -145.150696), 5, 0)
            vespucci_beach_pbus[9] = higurashi.create_vehicle(veh_hash, v3(-1686.978760, -946.253479, 7.935071), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[9], v3(-0.007171, -0.025807, -106.486397), 5, 0)
            vespucci_beach_pbus[10] = higurashi.create_vehicle(veh_hash, v3(-1673.622437, -950.142578, 7.936090), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[10], v3(0.008736, -0.018792, -107.279045), 5, 0)
            vespucci_beach_pbus[11] = higurashi.create_vehicle(veh_hash, v3(-1634.464233, -960.223022, 8.172328), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[11], v3(1.225953, -1.078215, -131.761215), 5, 0)
            vespucci_beach_pbus[12] = higurashi.create_vehicle(veh_hash, v3(-1580.096436, -888.268555, 10.226367), 0, true, false, false, true, false)
            wait()
            NATIVE.SET_ENTITY_ROTATION(vespucci_beach_pbus[12], v3(0.688966, -1.538544, 50.207573), 5, 0)
            wait()
            --[[obj[1] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[1], vespucci_beach_pbus[1], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[2] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[2], vespucci_beach_pbus[2], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[3] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[3], vespucci_beach_pbus[3], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[4] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[4], vespucci_beach_pbus[4], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[5] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[5], vespucci_beach_pbus[5], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[6] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[6], vespucci_beach_pbus[6], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[7] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[7], vespucci_beach_pbus[7], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[8] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[8], vespucci_beach_pbus[8], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[9] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[9], vespucci_beach_pbus[9], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[10] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[10], vespucci_beach_pbus[10], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                obj[11] = higurashi.create_object(screen_prop, user_pos,true, false, false)
                NATIVE.ATTACH_ENTITY_TO_ENTITY(obj[11], vespucci_beach_pbus[11], 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1)
                wait()]]
            for i = 1, #vespucci_beach_pbus do
                NATIVE.DECOR_SET_INT(vespucci_beach_pbus[i], "Skill_Blocker", -1)
                NATIVE.ADD_ENTITY_TO_AUDIO_MIX_GROUP(vespucci_beach_pbus[i], "DLC_BTL_PBUS2_Music_Boost_Mixgroup", 0)
                higurashi.set_visible_god_freeze({ vespucci_beach_pbus[i] }, true, true, true)
                NATIVE.SET_VEHICLE_ENGINE_ON(vespucci_beach_pbus[i], true, true, false)
                NATIVE.SET_VEHICLE_KEEP_ENGINE_ON_WHEN_ABANDONED(vespucci_beach_pbus[i], true)
                NATIVE.SET_VEHICLE_LIGHTS(vespucci_beach_pbus[i], 3)
                NATIVE.TASK_WARP_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), vespucci_beach_pbus[i], -1)
                wait(0)
                NATIVE.SET_CONTROL_NORMAL(2, 86, 1.0)
                NATIVE.SET_VEH_RADIO_STATION(vespucci_beach_pbus[i], "OFF")
                wait(20)
                NATIVE.SET_VEHICLE_RADIO_ENABLED(vespucci_beach_pbus[i], true)
                NATIVE.SET_VEH_RADIO_STATION(vespucci_beach_pbus[i], pbus_selected_station)
                NATIVE.SET_VEHICLE_RADIO_LOUD(vespucci_beach_pbus[i], true)
                NATIVE.SET_VEHICLE_DOORS_LOCKED(vespucci_beach_pbus[i], 2)
                NATIVE.SET_DONT_ALLOW_PLAYER_TO_ENTER_VEHICLE_IF_LOCKED_FOR_PLAYER(vespucci_beach_pbus[i], true)
            end
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
            higurashi.teleport_to(user_pos)
            --[[m.ct(function()
                    local handler = higurashi.create_named_render_target_for_model("pbus_screen", screen_prop)
                    local pbus_scaleform = NATIVE.REQUEST_SCALEFORM_MOVIE("PARTY_BUS")
                    while true do
                        if (NATIVE.HAS_SCALEFORM_MOVIE_LOADED(pbus_scaleform)) then
                            NATIVE.SET_SCALEFORM_MOVIE_TO_USE_LARGE_RT(pbus_scaleform, true)
                            NATIVE.SET_TEXT_RENDER_ID(handler)
                            NATIVE.SET_SCRIPT_GFX_DRAW_ORDER(4)
                            NATIVE.SET_SCRIPT_GFX_DRAW_BEHIND_PAUSEMENU(1)
                            NATIVE.DRAW_SCALEFORM_MOVIE(pbus_scaleform, 0.4, 0.045, 0.8, 0.09, 255, 255, 255, 255, 0)
                            NATIVE.SET_TEXT_RENDER_ID(NATIVE.GET_DEFAULT_SCRIPT_RENDERTARGET_RENDER_ID())
                        end
                        wait(0)
                    end
                end)]]
        elseif f.value == 1 then
            for i = 1, #vespucci_beach_pbus do
                higurashi.remove_entity({ vespucci_beach_pbus[i] })
            end
            --[[for _, objs in pairs(object.get_all_objects()) do
                    wait()
                    if NATIVE.GET_ENTITY_MODEL(objs) == joaat("ba_prop_battle_pbus_screen") then
                        higurashi.hard_remove_entity(objs)
                    end
                end]]
        end
    end):set_str_data({ "Spawn", "Delete" })

    m.af("Delete All Party", "action", Higurashi.WorldEnhancement.id, function(f)
        local function remove_party_entities(entities)
            for _, entity in pairs(entities) do
                higurashi.remove_entity({ entity })
            end
        end
        for _, veh in pairs(vehicle.get_all_vehicles()) do
            if NATIVE.GET_ENTITY_MODEL(veh) == joaat("pbus2") and NATIVE.DECOR_EXIST_ON(veh, "Skill_Blocker") then
                remove_party_entities({ veh })
            end
        end
        wait()
        local function remove_objects(objects, model_list)
            for _, obj in pairs(objects) do
                local model = NATIVE.GET_ENTITY_MODEL(obj)
                for _, model_hash in ipairs(model_list) do
                    if model == joaat(model_hash) then
                        remove_party_entities({ obj })
                        break
                    end
                end
            end
        end
        local all_peds = ped.get_all_peds()
        remove_objects(object.get_all_objects(), lsc_party_prop_lists)
        remove_objects(all_peds, lsc_cust_models)
        remove_objects(all_peds, dj_models)
        remove_objects(all_peds, party_cust_models)

        m.n("force removed")
    end)

    Higurashi.SpawnRepairPickup = m.af("Spawn Repair Kit", "parent", Higurashi.WorldEnhancement.id)

    local repair_pickups = {}

    local function createRepairPickup(name, pos)
        m.af(name, "toggle", Higurashi.SpawnRepairPickup.id, function(f)
            settings[name] = f.on
            if f.on then
                if NATIVE.NETWORK_IS_PLAYER_CONNECTED(NATIVE.PLAYER_ID()) and NATIVE.NETWORK_IS_SESSION_STARTED() then
                    if not repair_pickups[name] or not NATIVE.DOES_ENTITY_EXIST(repair_pickups[name]) then
                        repair_pickups[name] = higurashi.create_ambient_pickup(joaat("PICKUP_VEHICLE_HEALTH_STANDARD_LOW_GLOW"), v3(pos.x, pos.y, pos.z), -1, 0, joaat("prop_ic_repair"), false, true, true, false)
                        wait(1700)
                    end
                end
            else
                if repair_pickups[name] or NATIVE.DOES_ENTITY_EXIST(repair_pickups[name]) then
                    higurashi.remove_entity({ repair_pickups[name] })
                end
            end
            return HANDLER_CONTINUE
        end).on = settings[name]
    end

    createRepairPickup("Spawn Repair Kits For Los Santos Custom", { x = -360.464752, y = -128.309601, z = 38.495698 })
    createRepairPickup("Spawn Repair Kits For Caesars Auto Parking", { x = 135.358704, y = -1050.252808, z = 29.151817 })
    createRepairPickup("Spawn Repair Kits For Galileo Observatory", { x = -397.931091, y = 1235.908447, z = 325.641785 })
    createRepairPickup("Spawn Repair Kits For Galileo Observatory 2", { x = -430.358917, y = 1190.894531, z = 325.641357 })
    createRepairPickup("Spawn Repair Kits For Los Santos Car Meet", { x = -2086.312988, y = 1120.904175, z = 25.517773 })
    createRepairPickup("Spawn Repair Kits For Vespucci Beach", { x = -1637.173340, y = -812.744690, z = 10.171953 })
    createRepairPickup("Spawn Repair Kits For xxxx", { x = 1209.839844, y = -2988.166260, z = 5.861721 })
    Higurashi.TrainControl = m.af("Train Control", "parent", Higurashi.World.id)

    Higurashi.EnterClosestTrain = m.af("Enter Closest Train", "action", Higurashi.TrainControl.id, function(f)
        local closest_train = higurashi.find_closest_train()
        if closest_train ~= 0 then
            if ped.is_ped_in_vehicle(NATIVE.PLAYER_PED_ID(), closest_train) == true then
                m.n("You are already in a train.", title, 3, c.yellow1)
            else
                higurashi.remove_entity({ vehicle.get_ped_in_vehicle_seat(closest_train, -1) })
                NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), closest_train, -1)
            end
        else
            m.n("Could not find any trains nearby.", title, 3, c.red1)
        end
    end)

    local train_models = { "freight", "freightcar", "freightgrain", "freightcont1", "freightcont2", "freighttrailer", "tankercar", "metrotrain", "s_m_m_lsmetro_01" }

    Higurashi.SpawnTrain = m.af("Spawn A New Train", "action", Higurashi.TrainControl.id, function(f)
        NATIVE.SET_TRAIN_TRACK_SPAWN_FREQUENCY(0, 120000)
        NATIVE.SET_TRAIN_TRACK_SPAWN_FREQUENCY(3, 120000)
        NATIVE.SET_RANDOM_TRAINS(false)
        NATIVE.SET_MISSION_FLAG(true)
        for _, train_model in ipairs(train_models) do
            higurashi.request_model(joaat(train_model))
        end
        Higurashi.NewSpawnedTrain = NATIVE.CREATE_MISSION_TRAIN(Higurashi.TrainVariation.value, higurashi.get_user_coords(), Higurashi.TrainDirection.value)
        local findtrain = higurashi.find_closest_train()
        if findtrain ~= 0 and Higurashi.TeleportIntoNewTrain.on then
            NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), findtrain, -1)
        end
        m.n("Spawned Train:\nVariation: " .. Higurashi.TrainVariation.value .. "\nDirection: " .. Higurashi.TrainDirection.str_data[Higurashi.TrainDirection.value + 1], title, 3, c.blue1)
    end)

    Higurashi.TeleportIntoNewTrain = m.af("Teleport Into Spawned Train", "toggle", Higurashi.TrainControl.id)

    Higurashi.TrainVariation = m.af("Set Spawn Train Variation", "action_value_i", Higurashi.TrainControl.id)
    Higurashi.TrainVariation.min = 0
    Higurashi.TrainVariation.max = 23
    Higurashi.TrainVariation.mod = 1

    Higurashi.TrainDirection = m.af("Set Spawn Train Direction", "action_value_str", Higurashi.TrainControl.id)
    Higurashi.TrainDirection:set_str_data({ "Clockwise", "Anti-Clockwise" })

    Higurashi.ModifyTrainSpeed = m.af("Modify Current Train Speed", "value_f", Higurashi.TrainControl.id, function(f)
        local train = higurashi.find_closest_train()
        while f.on do
            NATIVE.SET_TRAIN_SPEED(train, f.value)
            NATIVE.SET_TRAIN_CRUISE_SPEED(train, f.value)
            wait(0)
        end
    end)
    Higurashi.ModifyTrainSpeed.max = 10000
    Higurashi.ModifyTrainSpeed.min = -10000
    Higurashi.ModifyTrainSpeed.mod = 5
    Higurashi.ModifyTrainSpeed.value = 15

    Higurashi.RenderTrainDerailed = m.af("Render Train As Derailed", "toggle", Higurashi.TrainControl.id, function(f)
        local train = higurashi.find_closest_train()
        if train ~= 0 then
            NATIVE.SET_RENDER_TRAIN_AS_DERAILED(train, f.on)
        end
    end)

    Higurashi.ExitTrain = m.af("Exit Train", "action", Higurashi.TrainControl.id, function(f)
        if player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) then
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
        else
            m.n("You're not in a train.", title, 3, c.red1)
        end
    end)

    Higurashi.DeleteAllTrains = m.af("Delete All Trains", "action", Higurashi.TrainControl.id, function(f)
        for _, train_model in ipairs(train_models) do
            local tempmodel = joaat(train_model)
            for _, veh in ipairs(vehicle.get_all_vehicles()) do
                if NATIVE.GET_ENTITY_MODEL(veh) == tempmodel then
                    higurashi.remove_entity({ veh })
                    m.n("Deleted all nearby trains.", title, 3, c.blue1)
                    break
                end
            end
        end
    end)

    Higurashi.WorldPed = m.af("Peds", "parent", Higurashi.World.id)

    m.af("Teleport All Peds To Me", "action", Higurashi.WorldPed.id, function(f)
        for _, peds in pairs(ped.get_all_peds()) do
            if not NATIVE.IS_PED_A_PLAYER(peds) then
                local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(peds)
                NATIVE.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, false)
                NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
                NATIVE.SET_ENTITY_COORDS_NO_OFFSET(peds, higurashi.get_most_accurate_position(higurashi.get_vector_relative_to_entity(NATIVE.PLAYER_PED_ID(), 10)))
            end
        end
    end)

    Higurashi.ClearAllPedsTasks = m.af("Clear Ped Tasks", "toggle", Higurashi.WorldPed.id, function(f)
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) then
                    NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(peds)
                end
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    m.af("Drop Weapons All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        higurashi.request_anim_dict("mp_weapon_drop")
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds) and NATIVE.IS_PED_ARMED(peds, 7) and higurashi.request_control_of_entity(peds) then
                    NATIVE.SET_PED_DROPS_WEAPONS_WHEN_DEAD(peds, true)
                    NATIVE.TASK_PLAY_ANIM(peds, "mp_weapon_drop", "drop_bh", 8.0, 2.0, -1, 0, 2.0, 0, 0, 0)
                    NATIVE.SET_PED_DROPS_INVENTORY_WEAPON(peds, NATIVE.GET_SELECTED_PED_WEAPON(peds), 0.0, 2.0, 0.0, -1)
                end
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    m.af("Remove All Weapons", "toggle", Higurashi.WorldPed.id, function(f)
        while f.on do
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds) and NATIVE.IS_PED_ARMED(peds, 7) and higurashi.request_control_of_entity(peds) then
                    NATIVE.REMOVE_ALL_PED_WEAPONS(peds, true)
                end
            end
            if not f.on then
                return
            end
            wait(100)
        end
    end)

    m.af("Exterminate All Peds", "value_str", Higurashi.WorldPed.id, function(f)
        if f.on then
            for i, peds in pairs(ped.get_all_peds()) do
                if NATIVE.DOES_ENTITY_EXIST(peds) and (not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds)) then
                    local blame = NATIVE.PLAYER_PED_ID()
                    local pos = NATIVE.GET_PED_BONE_COORDS(peds, 0, v3(0.0, 0.0, 0.0))
                    local effects = {
                        [0] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.5), pos, 100.0, 0x461DDDB0, blame, false, true, 9999.0)
                        end,
                        [1] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 30), pos, 100.0, 0x62E2140E, blame, false, true, 2000.0)
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 2.5), pos, 100.0, 0xE783C3BA, blame, false, true, 2000.0)
                        end,
                        [2] = function()
                            fire.add_explosion(pos, 70, true, false, 0, blame)
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 10), pos, 999.0, joaat("WEAPON_RAYPISTOL"), blame, false, true, 500.0)
                        end,
                        [3] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.4), pos, 999.0, joaat("WEAPON_STUNGUN"), blame, false, true, 9999.0)
                        end,
                        [4] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 30), pos, 1.0, joaat("VEHICLE_WEAPON_ENEMY_LASER"), blame, false, true, 999.0)
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 30), pos, 1.0, joaat("VEHICLE_WEAPON_PLAYER_LASER"), blame, false, true, 999.0)
                            fire.add_explosion(pos, 59, true, false, 0, blame)
                        end,
                        [5] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 1.8), pos, 100.0, 0x47757124, blame, false, true, 2000.0)
                        end,
                        [6] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.1), pos, 100.0, joaat("WEAPON_MOLOTOV"), blame, false, true, 999.0)
                            fire.add_explosion(pos, 14, true, false, 0, blame)
                        end,
                        [7] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.5), pos, 999.0, 0xDB26713A, blame, false, true, 100.0)
                            fire.add_explosion(pos, 65, true, false, 0, blame)
                        end,
                        [8] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.5), pos, 100.0, joaat("WEAPON_TRANQUILIZER"), blame, false, true, 9999.0)
                        end,
                        [9] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 25.0), pos, 100.0, joaat("WEAPON_FIREWORK"), blame, false, true, 2000.0)
                        end,
                        [10] = function()
                            fire.add_explosion(pos, 52, true, true, 1.2, blame)
                            fire.add_explosion(pos, 58, true, true, 1, blame)
                        end,
                        [11] = function()
                            fire.add_explosion(pos, 21, true, true, 0.5, blame)
                            fire.add_explosion(pos, 48, true, true, 0.2, blame)
                        end,
                        [12] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 1.5), pos, 5000.0, joaat("VEHICLE_WEAPON_OPPRESSOR2_CANNON"), blame, false, true, 100.0)
                        end,
                        [13] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 6.5), pos, 1000.0, 0x4635DD15, blame, false, true, 15.0)
                        end,
                        [14] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 4.5), pos, 500.0, joaat("WEAPON_RAILGUNXM3"), blame, false, true, 15.0)
                        end,
                        [15] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 20.5), pos, 1000.0, joaat("VEHICLE_WEAPON_AVENGER_CANNON"), blame, false, true, 1000.0)
                        end,
                        [16] = function()
                            gameplay.shoot_single_bullet_between_coords(pos + v3(0.0, 0.0, 0.2), pos, 999999.0, joaat("WEAPON_SNOWLAUNCHER"), blame, false, true, 10000.0)
                        end,
                    }
                    local effect_func = effects[f.value]
                    if effect_func then
                        effect_func()
                    end
                    wait(50)
                end
            end
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end):set_str_data({ "Shoot Out", "Missiles", "Ray Gun", "Electrocute", "Laser Cannon", "Flare", "Blow Up", "EMP", "Tranquilizer", "Firework", "Earthquake", "Gas", "Cannon", "Carpet Bombing", "Railgun XM3", "Gunship Cannon", "Snowball" })

    Higurashi.KillEnemies = m.af("Kill Enemies", "toggle", Higurashi.WorldPed.id, function(f)
        while f.on do
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds) and (NATIVE.GET_BLIP_COLOUR(NATIVE.GET_BLIP_FROM_ENTITY(peds)) == 1 or NATIVE.GET_IS_TASK_ACTIVE(peds, 352)) then
                    if higurashi.request_control_of_entity(peds) then
                        NATIVE.APPLY_DAMAGE_TO_PED(peds, 2147483647, false, true, 0)
                    end
                end
            end
            wait(10)
        end
    end)

    Higurashi.KillAllPeds = m.af("Kill All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        while f.on do
            local count = 1
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds) then
                    if higurashi.request_control_of_entity(peds) then
                        NATIVE.APPLY_DAMAGE_TO_PED(peds, 2147483647, false, true, 0)
                        count = count + 1
                    end
                end
                if count % 10 == 0 then
                    wait(0)
                end
            end
            wait(10)
        end
    end)

    m.af("Resurrect All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and NATIVE.IS_ENTITY_DEAD(peds) and higurashi.request_control_of_entity(peds) then
                    NATIVE.RESURRECT_PED(peds)
                    NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(peds)
                end
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    m.af("Beast Jump All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and not NATIVE.IS_ENTITY_DEAD(peds) and higurashi.request_control_of_entity(peds) then
                    NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(peds)
                    NATIVE.SET_PED_CAN_RAGDOLL(peds, false)
                    NATIVE.TASK_JUMP(peds, 1, 1, 1)
                end
            end
            wait(2000)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.DeleteAllPeds = m.af("Delete All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) then
                    higurashi.remove_entity({ peds })
                end
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    m.af("Freeze All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        local all_peds = ped.get_all_peds()
        for i = 1, #all_peds do
            if not NATIVE.IS_PED_A_PLAYER(all_peds[i]) and higurashi.request_control_of_entity(all_peds[i]) then
                NATIVE.FREEZE_ENTITY_POSITION(all_peds[i], f.on)
            end
        end
        if not f.on then
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.StopBurningAllPeds = m.af("Stop Burning All Peds", "toggle", Higurashi.WorldPed.id, function(f)
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(peds) and NATIVE.IS_ENTITY_ON_FIRE(peds) and higurashi.request_control_of_entity(peds) then
                    NATIVE.STOP_ENTITY_FIRE(peds)
                end
            end
            wait(300)
        end
        settings["StopBurningAllPeds"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.StopBurningAllPeds.on = settings["StopBurningAllPeds"]

    Higurashi.ProtectShops = m.af("Protect Shopkeepers", "toggle", Higurashi.WorldPed.id, function(f)
        local ped_models = { "s_m_m_autoshop_01", "s_m_y_ammucity_01", "s_m_m_ammucountry", "s_f_y_shop_low", "s_f_y_shop_mid", "s_f_m_shop_high", "s_m_m_hairdress_01", "s_f_m_fembarber", "u_m_y_tattoo_01", "s_m_y_shop_mask", "mp_m_shopkeep_01", "ig_benny" }
        if f.on then
            for _, ped in ipairs(ped.get_all_peds()) do
                local model_hash = NATIVE.GET_ENTITY_MODEL(ped)
                local interior_id = NATIVE.GET_INTERIOR_FROM_ENTITY(ped)
                for _, model_name in ipairs(ped_models) do
                    if model_hash == joaat(model_name) and interior_id ~= 0 and not NATIVE.IS_ENTITY_DEAD(ped) and not NATIVE.IS_PED_A_PLAYER(ped) then
                        NATIVE.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(ped, true)
                        NATIVE.SET_PED_CAN_RAGDOLL(ped, false)
                        higurashi.set_visible_god_freeze({ ped }, false, true, true)
                        NATIVE.SET_ENTITY_COORDS_NO_OFFSET(ped, NATIVE.GET_ENTITY_COORDS(ped) + v3(0.0, 0.0, -70.0))
                    end
                end
            end
            wait(500)
        end
        settings["ProtectShops"] = f.on
        return HANDLER_CONTINUE
    end)

    Higurashi.ProtectShops.on = settings["ProtectShops"]

    Higurashi.WorldObject = m.af("Objects", "parent", Higurashi.World.id)

    m.af("Teleport All Objects To Me", "action", Higurashi.WorldObject.id, function()
        for _, objs in pairs(object.get_all_objects()) do
            higurashi.entity_teleport(objs, higurashi.get_most_accurate_position(higurashi.get_vector_relative_to_entity(NATIVE.PLAYER_PED_ID())))
        end
    end)

    m.af("Teleport All Pickups To Me", "action", Higurashi.WorldObject.id, function()
        for _, objs in pairs(object.get_all_pickups()) do
            higurashi.entity_teleport(objs, higurashi.get_most_accurate_position(higurashi.get_vector_relative_to_entity(NATIVE.PLAYER_PED_ID())))
        end
    end)

    Higurashi.DeleteAllObjects = m.af("Delete All Objects", "toggle", Higurashi.WorldObject.id, function(f)
        if f.on then
            for _, objs in pairs(object.get_all_objects()) do
                higurashi.remove_entity({ objs })
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.DeleteAllPickups = m.af("Delete All Pickups", "toggle", Higurashi.WorldObject.id, function(f)
        if f.on then
            for _, objs in pairs(object.get_all_pickups()) do
                higurashi.remove_entity({ objs })
            end
            wait(300)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.WorldVehicle = m.af("Vehicles", "parent", Higurashi.World.id)

    m.af("Teleport All Vehicles To Me", "action", Higurashi.WorldVehicle.id, function(f)
        local all_vehs = vehicle.get_all_vehicles()
        for i = 1, #all_vehs do
            if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(all_vehs[i], -1, false)) and not NATIVE.DECOR_EXIST_ON(all_vehs[i], "Player_Vehicle") and not NATIVE.DECOR_EXIST_ON(all_vehs[i], "CreatedByPegasus") and higurashi.request_control_of_entity(all_vehs[i]) then
                higurashi.entity_teleport(all_vehs[i], higurashi.get_most_accurate_position(higurashi.get_vector_relative_to_entity(NATIVE.PLAYER_PED_ID())))
            end
        end
    end)

    m.af("Auto Repair Vehicles Around You", "toggle", Higurashi.WorldVehicle.id, function(f, pid)
        if f.on then
            local all_vehs = vehicle.get_all_vehicles()
            for i = 1, #all_vehs do
                if vehicle.is_vehicle_damaged(all_vehs[i]) then
                    higurashi.repair_car(all_vehs[i])
                end
            end
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.ExplodeAllVehs = m.af("Explode All Vehicles", "toggle", Higurashi.WorldVehicle.id, function(f)
        if f.on then
            local all_vehs = vehicle.get_all_vehicles()
            for i = 1, #all_vehs do
                if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(all_vehs[i], -1, false)) and not NATIVE.DECOR_EXIST_ON(all_vehs[i], "Player_Vehicle") and not NATIVE.IS_ENTITY_DEAD(all_vehs[i]) and higurashi.request_control_of_entity(all_vehs[i]) then
                    NATIVE.NETWORK_EXPLODE_VEHICLE(all_vehs[i], true, false, NATIVE.PLAYER_ID())
                end
            end
            wait(250)
        end
        return HANDLER_CONTINUE
    end)

    m.af("Stop Burning All Vehicles", "toggle", Higurashi.WorldVehicle.id, function(f)
        if f.on then
            local all_vehs = vehicle.get_all_vehicles()
            for i = 1, #all_vehs do
                if NATIVE.IS_ENTITY_ON_FIRE(all_vehs[i]) then
                    NATIVE.STOP_ENTITY_FIRE(all_vehs[i])
                end
            end
            wait(250)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.FreezeAllVehicles = m.af("Freeze All Vehicles", "toggle", Higurashi.WorldVehicle.id, function(f)
        local function freeze_vehicles(state)
            for _, veh in pairs(vehicle.get_all_vehicles()) do
                local driver = NATIVE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
                if not NATIVE.IS_PED_A_PLAYER(driver) and not NATIVE.DECOR_EXIST_ON(veh, "Player_Vehicle") and higurashi.request_control_of_entity(veh) then
                    NATIVE.FREEZE_ENTITY_POSITION(veh, state)
                end
            end
        end
        while f.on do
            freeze_vehicles(true)
            wait(250)
        end
        if not f.on then
            freeze_vehicles(false)
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.DeleteAllVehicles = m.af("Delete All Vehicles", "toggle", Higurashi.WorldVehicle.id, function(f)
        if f.on then
            local all_vehs = vehicle.get_all_vehicles()
            for i = 1, #all_vehs do
                if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(all_vehs[i], -1, false) and not NATIVE.DECOR_EXIST_ON(all_vehs[i], "Player_Vehicle")) then
                    higurashi.remove_entity({ all_vehs[i] })
                end
            end
            wait(250)
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.RealTime = m.af("Real Time", "toggle", Higurashi.World.id, function(f)
        if f.on then
            local t = os.date("*t")
            NATIVE.SET_CLOCK_TIME(t.hour, t.min, t.sec)
            NATIVE.UNLOAD_ALL_CLOUD_HATS()
        end
        if not f.on then
            return
                HANDLER_POP
        end
        settings["RealTime"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.RealTime.on = settings["RealTime"]

    local self_ground_water_obj

    m.af("Drive On Water", "toggle", Higurashi.World.id, function(f)
        if f.on then
            local pos = higurashi.get_user_coords()
            if self_ground_water_obj == nil then
                self_ground_water_obj = higurashi.create_object(0x6CA1E917, higurashi.get_user_coords() + v3(0.0, 0.0, -3.5), true, false, false, false, false, false)
                NATIVE.SET_ENTITY_VISIBLE(self_ground_water_obj, false, false)
                NATIVE.SET_ENTITY_INVINCIBLE(self_ground_water_obj, true)
            end
            water.set_waves_intensity(-100000000)
            pos.z = -4.0
            higurashi.set_velocity_and_coords(self_ground_water_obj, pos)
        end
        if not f.on and self_ground_water_obj then
            water.reset_waves_intensity()
            higurashi.remove_entity({ self_ground_water_obj })
            self_ground_water_obj = nil
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)

    Higurashi.ClearProjectiles = m.af("Clear Projectiles", "value_f", Higurashi.World.id, function(f)
        local pos = higurashi.get_user_coords()
        while f.on do
            NATIVE.CLEAR_AREA_OF_PROJECTILES(pos.x, pos.y, pos.z, tonumber(f.value), 0)
            wait(100)
        end
    end)
    Higurashi.ClearProjectiles.max = 5000.0
    Higurashi.ClearProjectiles.min = 0.0
    Higurashi.ClearProjectiles.mod = 50.0
    Higurashi.ClearProjectiles.value = 50.0

    Higurashi.ClearArea = m.af("Clear Area", "value_f", Higurashi.World.id, function(f)
        local pos = higurashi.get_user_coords()
        local disable_traffic = true
        local disable_peds = true
        local pop_multiplier_id
        local ped_sphere, traffic_sphere
        if f.on then
            if disable_peds then
                ped_sphere = 0.0
            else
                ped_sphere = 1.0
            end
            if disable_traffic then
                traffic_sphere = 0.0
            else
                traffic_sphere = 1.0
            end
            pop_multiplier_id = NATIVE.ADD_POP_MULTIPLIER_SPHERE(pos.x, pos.y, pos.z, tonumber(f.value), ped_sphere, traffic_sphere, false, true)
            wait(50)
            NATIVE.CLEAR_AREA(pos.x, pos.y, pos.z, tonumber(f.value), true, false, false, true)
            wait(50)
        end
        if not f.on then
            NATIVE.REMOVE_POP_MULTIPLIER_SPHERE(pop_multiplier_id, false)
            wait(0)
            return HANDLER_POP
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.ClearArea.max = 5000.0
    Higurashi.ClearArea.min = 0.0
    Higurashi.ClearArea.mod = 50.0
    Higurashi.ClearArea.value = 50.0

    Higurashi.EntityManager = m.af("Controls Aimed Entities", "toggle", Higurashi.World.id, function(f)
        settings["EntityManager"] = true
        if f.on then
            while f.on do
                wait(0)
                if player.is_player_free_aiming(NATIVE.PLAYER_ID()) then
                    local controls_entity_aimed_at = player.get_entity_player_is_aiming_at(NATIVE.PLAYER_ID())
                    if NATIVE.IS_ENTITY_A_PED(controls_entity_aimed_at) and not NATIVE.IS_PED_IN_ANY_VEHICLE(controls_entity_aimed_at) and not NATIVE.IS_PED_A_PLAYER(controls_entity_aimed_at) then
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("| Ped |", v2(0.5, 0.925))
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("X : Delete | H : Resurrect | B : Copy Hash | K : Explode | N : Kill | U : Ragdoll | C : Clear Tasks", v2(0.5, 0.95))
                        NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                        if NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 323) then
                            higurashi.remove_entity(controls_entity_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 304) then
                            m.ct(function()
                                if NATIVE.IS_ENTITY_DEAD(controls_entity_aimed_at, true) then
                                    NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                                    if (not NATIVE.NETWORK_HAS_CONTROL_OF_ENTITY(controls_entity_aimed_at)) then
                                        NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                                    end
                                    ped.resurrect_ped(controls_entity_aimed_at)
                                    NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(controls_entity_aimed_at)
                                    entity.set_entity_collision(controls_entity_aimed_at, true, true, true)
                                    for i = 1, 500 do
                                        NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(controls_entity_aimed_at)
                                    end
                                    wait(100)
                                    local health = NATIVE.GET_PED_MAX_HEALTH(controls_entity_aimed_at)
                                    NATIVE.SET_PED_MAX_HEALTH(controls_entity_aimed_at, health)
                                    wait(100)
                                    ped.set_ped_health(controls_entity_aimed_at, health)
                                    NATIVE.SET_PED_COMPONENT_VARIATION(controls_entity_aimed_at)
                                end
                            end, nil)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
                            utils.to_clipboard(NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at))
                            m.n("Copied hash: " .. NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at) .. "", title, 3, c.blue1)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 311) then
                            fire.add_explosion(NATIVE.GET_ENTITY_COORDS(controls_entity_aimed_at, false), 52, true, false, 0.1, controls_entity_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 306) then
                            NATIVE.SET_PED_MAX_HEALTH(controls_entity_aimed_at, 0)
                            ped.set_ped_health(controls_entity_aimed_at, 0)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 303) then
                            ped.set_ped_to_ragdoll(controls_entity_aimed_at, 1000, 1000, 0)
                        elseif NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 324) then
                            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(controls_entity_aimed_at)
                        end
                    elseif NATIVE.IS_ENTITY_A_PED(controls_entity_aimed_at) and
                        NATIVE.IS_PED_IN_ANY_VEHICLE(controls_entity_aimed_at) then
                        local controls_vehicle_aimed_at = ped.get_vehicle_ped_is_using(controls_entity_aimed_at)
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("| Vehicle |", v2(0.5, 0.925))
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("X : Delete | B : Copy Hash | K : Explode | N : Kill Engine | U : No Control | H : Enter | C : Freeze", v2(0.5, 0.95))
                        NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_vehicle_aimed_at)
                        if NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 323) then
                            higurashi.remove_entity(controls_vehicle_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
                            utils.to_clipboard(NATIVE.GET_ENTITY_MODEL(controls_vehicle_aimed_at))
                            m.n("Copied hash: " .. NATIVE.GET_ENTITY_MODEL(controls_vehicle_aimed_at) .. "", title, 3, c.blue1)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 311) then
                            fire.add_explosion(NATIVE.GET_ENTITY_COORDS(controls_entity_aimed_at, false), 52, true, false, 0.1, controls_vehicle_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 306) then
                            NATIVE.SET_VEHICLE_ENGINE_HEALTH(controls_vehicle_aimed_at, 0.0)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 303) then
                            NATIVE.SET_VEHICLE_OUT_OF_CONTROL(controls_vehicle_aimed_at, true, true)
                            -- elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 303) then
                            --     NATIVE.SET_VEHICLE_OUT_OF_CONTROL(controls_vehicle_aimed_at, true, true)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 304) then
                            if NATIVE.IS_PED_A_PLAYER(vehicle.get_ped_in_vehicle_seat(controls_vehicle_aimed_at, -1)) then
                                NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), controls_vehicle_aimed_at, -2)
                            else
                                NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle.get_ped_in_vehicle_seat(controls_vehicle_aimed_at, -1))
                                NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_vehicle_aimed_at)
                                NATIVE.SET_PED_INTO_VEHICLE(vehicle.get_ped_in_vehicle_seat(controls_vehicle_aimed_at, -1), controls_vehicle_aimed_at, -2)
                                NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), controls_vehicle_aimed_at, -1)
                            end
                        end
                        if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 324) then
                            NATIVE.FREEZE_ENTITY_POSITION(controls_vehicle_aimed_at, true)
                        else
                            NATIVE.FREEZE_ENTITY_POSITION(controls_vehicle_aimed_at, false)
                        end
                    elseif NATIVE.IS_ENTITY_A_VEHICLE(controls_entity_aimed_at) then
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("| Vehicle |", v2(0.5, 0.925))
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("X : Delete | B : Copy Hash | K : Explode | N : Kill Engine | U : No Control | H : Enter | C : Freeze", v2(0.5, 0.95))
                        NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                        if NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 323) then
                            higurashi.remove_entity(controls_entity_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
                            utils.to_clipboard(NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at))
                            m.n("Copied hash: " .. NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at) .. "", title, 3, c.blue1)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 311) then
                            fire.add_explosion(NATIVE.GET_ENTITY_COORDS(controls_entity_aimed_at, false), 52, true, false, 0.1, controls_entity_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 306) then
                            NATIVE.SET_VEHICLE_ENGINE_HEALTH(controls_entity_aimed_at, 0.0)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 303) then
                            NATIVE.SET_VEHICLE_OUT_OF_CONTROL(controls_entity_aimed_at, true, true)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 303) then
                            NATIVE.SET_VEHICLE_OUT_OF_CONTROL(controls_entity_aimed_at, true, true)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 304) then
                            if NATIVE.IS_PED_A_PLAYER(vehicle.get_ped_in_vehicle_seat(controls_entity_aimed_at, -1)) then
                                NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), controls_entity_aimed_at, -2)
                            else
                                NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle.get_ped_in_vehicle_seat(controls_entity_aimed_at, -1))
                                NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                                NATIVE.SET_PED_INTO_VEHICLE(vehicle.get_ped_in_vehicle_seat(controls_entity_aimed_at, -1), controls_entity_aimed_at, -2)
                                NATIVE.SET_PED_INTO_VEHICLE(NATIVE.PLAYER_PED_ID(), controls_entity_aimed_at, -1)
                            end
                        end
                        if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 324) then
                            NATIVE.FREEZE_ENTITY_POSITION(controls_entity_aimed_at, true)
                        else
                            NATIVE.FREEZE_ENTITY_POSITION(controls_entity_aimed_at, false)
                        end
                    elseif NATIVE.IS_ENTITY_AN_OBJECT(controls_entity_aimed_at) then
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("| Object |", v2(0.5, 0.925))
                        ui.set_text_scale(0.4)
                        ui.set_text_font(4)
                        ui.set_text_centre(0)
                        ui.set_text_outline(true)
                        ui.set_text_color(255, 255, 255, 255)
                        ui.draw_text("X : Delete | B : Copy Hash", v2(0.5, 0.95))
                        NATIVE.NETWORK_REQUEST_CONTROL_OF_ENTITY(controls_entity_aimed_at)
                        if NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 323) then
                            higurashi.remove_entity(controls_entity_aimed_at)
                        elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 29) then
                            utils.to_clipboard(NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at))
                            m.n("Copied hash: " .. NATIVE.GET_ENTITY_MODEL(controls_entity_aimed_at) .. "", title, 3, c.blue1)
                        end
                    end
                end
            end
        end
        if not f.on then
            settings["EntityManager"] = false
        end
    end)
    Higurashi.EntityManager.on = settings["EntityManager"]
    Higurashi.EntityManager.hint = "Control aimed entity."


    Higurashi.AntiEmergencyAndGovernment = m.af("Anti Emergency / Government", "toggle", Higurashi.World.id, function(f)
        settings["AntiEmergencyAndGovernment"] = f.on
        local emergency_ped_models = {
            [joaat("s_m_y_swat_01")] = true,
            [joaat("s_m_y_sheriff_01")] = true,
            [joaat("s_m_y_ranger_01")] = true,
            [joaat("s_m_y_cop_01")] = true,
            [joaat("s_f_y_sheriff_01")] = true,
            [joaat("s_f_y_cop_01")] = true,
            [joaat("s_m_y_hwaycop_01")] = true,
            [joaat("s_m_y_fireman_01")] = true,
            [joaat("s_m_m_paramedic_01")] = true,
            [joaat("s_m_y_marine_01")] = true,
            [joaat("s_m_m_marine_01")] = true,
            [joaat("s_m_y_armymech_01")] = true,
            [joaat("s_m_m_marine_02")] = true,
        }

        local emergency_veh_models = {
            [joaat("fbi")] = true,
            [joaat("fbi2")] = true,
            [joaat("police")] = true,
            [joaat("police2")] = true,
            [joaat("police3")] = true,
            [joaat("police4")] = true,
            [joaat("policeb")] = true,
            [joaat("policet")] = true,
            [joaat("pranger")] = true,
            [joaat("riot")] = true,
            [joaat("sheriff")] = true,
            [joaat("sheriff2")] = true,
            [joaat("polmav")] = true,
            [joaat("predator")] = true,
            [joaat("firetruk")] = true,
            [joaat("ambulance")] = true,
            [joaat("crusader")] = true,
            [joaat("barracks2")] = true,
        }

        while f.on do
            for _, ped_entity in ipairs(ped.get_all_peds()) do
                if emergency_ped_models[NATIVE.GET_ENTITY_MODEL(ped_entity)] then
                    higurashi.remove_entity({ ped_entity })
                end
            end

            for _, veh_entity in ipairs(vehicle.get_all_vehicles()) do
                if emergency_veh_models[NATIVE.GET_ENTITY_MODEL(veh_entity)] then
                    local driver_ped = NATIVE.GET_PED_IN_VEHICLE_SEAT(veh_entity, -1, false)
                    if not NATIVE.IS_PED_A_PLAYER(driver_ped) and not NATIVE.DECOR_EXIST_ON(veh_entity, "Player_Vehicle") then
                        higurashi.remove_entity({ veh_entity })
                    end
                end
            end

            wait(100)
        end
    end)

    Higurashi.AntiEmergencyAndGovernment.on = settings["AntiEmergencyAndGovernment"]

    Higurashi.ForceVisibleAllEntities = m.af("Force Visible All Entities", "toggle", Higurashi.World.id, function(f)
        --settings["ForceVisibleAllEntities"] = f.on
        while f.on do
            local all_peds = ped.get_all_peds()
            local all_vehs = vehicle.get_all_vehicles()
            local all_objs = object.get_all_objects()
            for _, entities in ipairs({ all_vehs, all_peds, all_objs }) do
                for _, entity in ipairs(entities) do
                    if not NATIVE.IS_ENTITY_VISIBLE(entity) then
                        NATIVE.SET_ENTITY_VISIBLE(entity, true, false)
                    end
                end
            end
            wait(150)
        end
    end)
    --Higurashi.ForceVisibleAllEntities.on = settings["ForceVisibleAllEntities"]

    Higurashi.DeleteStaleEntities = m.af("Delete Stale Entities", "toggle", Higurashi.World.id, function(f)
        while f.on do
            local all_peds = ped.get_all_peds()
            local all_vehs = vehicle.get_all_vehicles()
            local all_objs = object.get_all_objects()
            for i = #all_peds, 1, -1 do
                if not NATIVE.IS_PED_A_PLAYER(all_peds[i]) and NATIVE.IS_ENTITY_DEAD(all_peds[i]) then
                    higurashi.remove_entity({ all_peds[i] })
                    table.remove(all_peds, i)
                end
            end

            for i = #all_vehs, 1, -1 do
                local driver = NATIVE.GET_PED_IN_VEHICLE_SEAT(all_vehs[i], -1, false)
                if not NATIVE.IS_PED_A_PLAYER(driver) and NATIVE.IS_ENTITY_DEAD(all_vehs[i]) then
                    higurashi.remove_entity({ all_vehs[i] })
                    table.remove(all_vehs, i)
                end
            end

            for i = #all_objs, 1, -1 do
                if NATIVE.IS_ENTITY_DEAD(all_objs[i]) then
                    higurashi.remove_entity({ all_objs[i] })
                    table.remove(all_objs, i)
                end
            end

            settings["DeleteStaleEntities"] = f.on
            wait(250)
        end
    end)
    Higurashi.DeleteStaleEntities.on = settings["DeleteStaleEntities"]
    Higurashi.DeleteStaleEntities.hint = "Deletes entities whose model info has been unloaded because this game is a flawless masterpiece."


    Higurashi.DeleteAllEntities = m.af("Delete All Entities", "action", Higurashi.World.id, function(f)
        local all_peds = ped.get_all_peds()
        local all_vehs = vehicle.get_all_vehicles()
        local all_objs = object.get_all_objects()
        for _, entity in ipairs(all_peds) do
            if not NATIVE.IS_PED_A_PLAYER(entity) then
                higurashi.remove_entity({ entity })
            end
        end
        for _, entity in ipairs(all_vehs) do
            if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(entity, -1, false)) and NATIVE.DECOR_GET_INT(entity, "Player_Vehicle") == 0 then
                higurashi.remove_entity({ entity })
            end
        end
        for _, entity in ipairs(all_objs) do
            higurashi.remove_entity({ entity })
        end
        local all_pickups = object.get_all_pickups()
        for i = 1, #all_pickups do
            higurashi.remove_entity({ all_pickups[i] })
        end

        wait(500)
    end)

    m.af("Apply Random Force To World Entity", "action", Higurashi.World.id, function(f)
        local vel = v3(math.random(1000, 10000), math.random(1000, 10000), math.random(1000, 10000))
        for _, peds in pairs(ped.get_all_peds()) do
            if not NATIVE.IS_PED_A_PLAYER(peds) then
                NATIVE.FREEZE_ENTITY_POSITION(peds, false)
                NATIVE.APPLY_FORCE_TO_ENTITY(peds, 1, vel.x, vel.y, vel.z, 0.0, 0.0, 0.0, true, true, true, true, true)
            end
        end
        for _, vehs in pairs(vehicle.get_all_vehicles()) do
            if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(vehs, -1, false)) and NATIVE.DECOR_GET_INT(vehs, "Player_Vehicle") == 0 then
                NATIVE.FREEZE_ENTITY_POSITION(vehs, false)
                entity.set_entity_gravity(vehs, false)
                NATIVE.SET_ENTITY_VELOCITY(vehs, vel)
            end
        end
        for _, objs in pairs(object.get_all_objects()) do
            NATIVE.FREEZE_ENTITY_POSITION(objs, false)
            NATIVE.APPLY_FORCE_TO_ENTITY(objs, 1, vel.x, vel.y, vel.z, 0.0, 0.0, 0.0, true, true, true, true, true)
        end
    end)


    Higurashi.Miscellaneous2 = m.af("Miscellaneous", "parent", Higurashi.Parent2.id)

    Higurashi.FreeCam = m.af("Free Camera", "parent", Higurashi.Miscellaneous2.id)

    Higurashi.FreecamHideHUD = m.af("Hide HUD", "toggle", Higurashi.FreeCam.id, function(f)
    end)

    Higurashi.FreecamDrawLine = m.af("Draw Line", "toggle", Higurashi.FreeCam.id, function(f)
    end)

    Higurashi.FreecamSpeed = m.af("Cam Speed", "autoaction_value_f", Higurashi.FreeCam.id, function(f)
    end)
    Higurashi.FreecamSpeed.max = 10.0
    Higurashi.FreecamSpeed.min = 0.1
    Higurashi.FreecamSpeed.mod = 0.1
    Higurashi.FreecamSpeed.value = 1.0

    m.af("Free Camera", "toggle", Higurashi.FreeCam.id, function(f)
        if f.on then
            freecam_player_cam = NATIVE.CREATE_CAM_WITH_PARAMS("DEFAULT_SCRIPTED_CAMERA", higurashi.get_user_coords().x, higurashi.get_user_coords().y, higurashi.get_user_coords().z + 2.0, NATIVE.GET_GAMEPLAY_CAM_ROT().x, NATIVE.GET_GAMEPLAY_CAM_ROT().y, NATIVE.GET_GAMEPLAY_CAM_ROT().z, 70.0, false, false)
            NATIVE.SET_CAM_ACTIVE(freecam_player_cam, true)
            NATIVE.RENDER_SCRIPT_CAMS(true, true, 1000, true, true, 0)
            while f.on do
                wait(0)
                NATIVE.DISABLE_ALL_CONTROL_ACTIONS(0)
                for i = 0, 6 do
                    NATIVE.ENABLE_CONTROL_ACTION(0, i, true)
                end
                for i = 199, 202 do
                    NATIVE.ENABLE_CONTROL_ACTION(0, i, true)
                end
                for i = 14, 15 do
                    NATIVE.ENABLE_CONTROL_ACTION(0, i, true)
                end
                NATIVE.ENABLE_CONTROL_ACTION(0, 177, true)
                NATIVE.ENABLE_CONTROL_ACTION(0, 237, true)
                NATIVE.ENABLE_CONTROL_ACTION(0, 20, true)
                NATIVE.ENABLE_CONTROL_ACTION(0, 246, true)
                NATIVE.ENABLE_CONTROL_ACTION(0, 245, true)
                if player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) then
                    NATIVE.REQUEST_ADDITIONAL_COLLISION_AT_COORD(NATIVE.GET_ENTITY_COORDS(higurashi.get_user_vehicle(false), false))
                end
                NATIVE.REQUEST_ADDITIONAL_COLLISION_AT_COORD(higurashi.get_user_coords())
                NATIVE.SET_CAM_ROT(freecam_player_cam, NATIVE.GET_GAMEPLAY_CAM_ROT().x, NATIVE.GET_GAMEPLAY_CAM_ROT().y, NATIVE.GET_GAMEPLAY_CAM_ROT().z, 2)
                if Higurashi.FreecamHideHUD.on then
                    NATIVE.HIDE_HUD_AND_RADAR_THIS_FRAME()
                end
                if Higurashi.FreecamDrawLine.on then
                    ui.draw_line(NATIVE.GET_CAM_COORD(freecam_player_cam) - v3(0.0, 0.0, 1.0), higurashi.get_user_coords(), 255, 255, 255, 255)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 32) then
                    local dir = NATIVE.GET_CAM_ROT(freecam_player_cam, 2)
                    dir:transformRotToDir()
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).z)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 35) then
                    local dir = NATIVE.GET_CAM_ROT(freecam_player_cam, 2) - v3(0.0, 0.0, 90.0)
                    dir:transformRotToDir()
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).z)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 34) then
                    local dir = NATIVE.GET_CAM_ROT(freecam_player_cam, 2) + v3(0.0, 0.0, 90.0)
                    dir:transformRotToDir()
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) + dir * Higurashi.FreecamSpeed.value).z)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 33) then
                    local dir = NATIVE.GET_CAM_ROT(freecam_player_cam, 2)
                    dir:transformRotToDir()
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) - dir * Higurashi.FreecamSpeed.value).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) - dir * Higurashi.FreecamSpeed.value).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) - dir * Higurashi.FreecamSpeed.value).z)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 21) then
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) + v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) + v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) + v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).z)
                end
                if NATIVE.IS_DISABLED_CONTROL_PRESSED(0, 36) then
                    NATIVE.SET_CAM_COORD(freecam_player_cam, (NATIVE.GET_CAM_COORD(freecam_player_cam) - v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).x, (NATIVE.GET_CAM_COORD(freecam_player_cam) - v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).y, (NATIVE.GET_CAM_COORD(freecam_player_cam) - v3(0.0, 0.0, 1 * Higurashi.FreecamSpeed.value)).z)
                end
                NATIVE.SET_FOCUS_POS_AND_VEL(NATIVE.GET_CAM_COORD(freecam_player_cam), 0.0, 0.0, 0.0)
                NATIVE.LOCK_MINIMAP_POSITION(NATIVE.GET_CAM_COORD(freecam_player_cam).x, NATIVE.GET_CAM_COORD(freecam_player_cam).y)
            end
        end
        if not f.on then
            if freecam_player_cam then
                NATIVE.DESTROY_CAM(freecam_player_cam, false)
                NATIVE.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
                freecam_player_cam = nil
            end
            NATIVE.UNLOCK_MINIMAP_POSITION()
            NATIVE.ENABLE_ALL_CONTROL_ACTIONS(0)
            NATIVE.CLEAR_FOCUS()
        end
    end)

    Higurashi.DisableIdleKick = m.af("Disable Idle Kick", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["DisableIdleKick"] = f.on
        while f.on do
            NATIVE.IS_CINEMATIC_IDLE_CAM_RENDERING()
            NATIVE.INVALIDATE_IDLE_CAM()
            NATIVE.PLAYSTATS_IDLE_KICK(0)
            wait(150)
        end
        settings["DisableIdleKick"] = false
    end)
    Higurashi.DisableIdleKick.on = settings["DisableIdleKick"]

    Higurashi.AutoAcceptJoining = m.af("Auto Accept Joining Games", "toggle", Higurashi.Miscellaneous2.id, function(f)
        local warnings = { "NT_INV", "NT_INV_FREE", "NT_INV_PARTY_INVITE", "NT_INV_PARTY_INVITE_MP", "NT_INV_PARTY_INVITE_MP_SAVE", "NT_INV_PARTY_INVITE_SAVE", "NT_INV_MP_SAVE", "NT_INV_SP_SAVE" }
        settings["AutoAcceptJoining"] = true
        if f.on then
            for i = 1, #warnings do
                if (NATIVE.GET_WARNING_SCREEN_MESSAGE_HASH() == joaat(warnings[i])) and not NATIVE.IS_PAUSE_MENU_ACTIVE() then
                    NATIVE.SET_CONTROL_NORMAL(2, 201, 1.0)
                    wait(0)
                end
            end
            wait(25)
        end
        settings["AutoAcceptJoining"] = false
        return HANDLER_CONTINUE
    end)
    Higurashi.AutoAcceptJoining.on = settings["AutoAcceptJoining"]
    Higurashi.AutoAcceptJoining.hint = "Skip warning screen when joining a session."

    Higurashi.AutoAcceptTransactionErrors = m.af("Auto Accept Transaction Errors", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["AutoAcceptTransactionErrors"] = true
        if f.on then
            if (NATIVE.GET_WARNING_SCREEN_MESSAGE_HASH() == joaat("CTALERT_F_4") and not NATIVE.IS_PAUSE_MENU_ACTIVE()) then
                NATIVE.SET_CONTROL_NORMAL(2, 201, 1.0)
                wait(0)
            end
            wait(25)
        end
        settings["AutoAcceptTransactionErrors"] = false
        return HANDLER_CONTINUE
    end)
    Higurashi.AutoAcceptTransactionErrors.on = settings["AutoAcceptTransactionErrors"]

    Higurashi.LockOnToPlayers = m.af("Lock On To Players", "toggle", Higurashi.Miscellaneous2.id, function(f, pid)
        settings["LockOnToPlayers"] = f.on
        while f.on do
            for pid in higurashi.players() do
                NATIVE.ADD_PLAYER_TARGETABLE_ENTITY(NATIVE.PLAYER_ID(), NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid))
                NATIVE.SET_ENTITY_IS_TARGET_PRIORITY(NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid), false, 400.0)
            end
            wait(150)
        end
        for pid in higurashi.players() do
            NATIVE.REMOVE_PLAYER_TARGETABLE_ENTITY(NATIVE.PLAYER_ID(), NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        end
        settings["LockOnToPlayers"] = false
    end)
    Higurashi.LockOnToPlayers.on = settings["LockOnToPlayers"]
    Higurashi.LockOnToPlayers.hint = "Allows you to lock on to players with the homing launcher."

    Higurashi.RevealAllPlayerPed = m.af("Reveal All Player Ped", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["RevealAllPlayerPed"] = f.on
        while f.on do
            for pid in higurashi.players() do
                local player_ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if player_ped ~= NATIVE.PLAYER_PED_ID() and not NATIVE.IS_ENTITY_VISIBLE(player_ped) then
                    NATIVE.SET_ENTITY_VISIBLE(player_ped, true, false)
                end
            end
            wait(100)
        end
        settings["RevealAllPlayerPed"] = false
    end)

    Higurashi.RevealAllPlayerPed.on = settings["RevealAllPlayerPed"]

    Higurashi.GhostModeAll = m.af("Ghost Mode", "toggle", Higurashi.Miscellaneous2.id, function(f, pid)
        for pid in higurashi.players() do
            NATIVE.SET_REMOTE_PLAYER_AS_GHOST(pid, f.on)
        end
    end)
    Higurashi.GhostModeAll.hint = ""

    Higurashi.BlockJoinRequests = m.af("Block Join Requests", "toggle", Higurashi.Miscellaneous2.id, function(f)
        if f.on then
            while f.on do
                if NATIVE.NETWORK_IS_SESSION_STARTED() and NATIVE.NETWORK_IS_HOST() then
                    NATIVE.NETWORK_SESSION_BLOCK_JOIN_REQUESTS(true)
                end
                wait(6000)
            end
        end
        if not f.on then
            if NATIVE.NETWORK_IS_SESSION_STARTED() and NATIVE.NETWORK_IS_HOST() then
                NATIVE.NETWORK_SESSION_BLOCK_JOIN_REQUESTS(false)
            end
        end
    end)
    Higurashi.BlockJoinRequests.hint = "Deny other players' requests to join a session when you are the session host."

    Higurashi.HideSession = m.af("Hide Session", "toggle", Higurashi.Miscellaneous2.id, function(f)
        local function set_session_visibility(visible)
            if NATIVE.NETWORK_IS_SESSION_STARTED() and NATIVE.NETWORK_IS_HOST() then
                if NATIVE.NETWORK_SESSION_IS_VISIBLE() ~= visible then
                    NATIVE.NETWORK_SESSION_MARK_VISIBLE(visible)
                end
            end
        end
        if f.on then
            while f.on do
                set_session_visibility(false)
                wait(6000)
            end
        else
            set_session_visibility(true)
        end
    end)

    m.af("Check Online Friends", "action", Higurashi.Miscellaneous2.id, function()
        local online_friends_count = 0
        for i = 0, NATIVE.NETWORK_GET_FRIEND_COUNT() - 1 do
            local get_name = NATIVE.NETWORK_GET_FRIEND_NAME(i)
            print(string.format("Friend index %s %s (%s) is %s", i, get_name, network.get_friend_scid(get_name), NATIVE.NETWORK_IS_FRIEND_INDEX_ONLINE(i) and "online" or "offline"))

            if NATIVE.NETWORK_IS_FRIEND_INDEX_ONLINE(i) then
                online_friends_count = online_friends_count + 1
                if NATIVE.NETWORK_IS_FRIEND_IN_MULTIPLAYER(get_name) then
                    m.n(get_name .. " is in an online session.", title, 3, c.green1)
                else
                    m.n("Online Friend: " .. get_name, title, 3, c.green1)
                end
                wait(100)
            end
        end

        if online_friends_count == 0 then
            m.n("No friends are currently online.", title, 3, c.red1)
        end
    end)

    m.af("Skip SP Prologue", "action", Higurashi.Miscellaneous2.id, function()
        NATIVE.SET_PROFILE_SETTING_PROLOGUE_COMPLETE()
        m.n("May need to restart your GTA.", title, 3, c.blue1)
    end)

    Higurashi.DisableStuntJumps = m.af("Disable Stunt Jumps", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["DisableStuntJumps"] = f.on
        if f.on then
            NATIVE.SET_STUNT_JUMPS_CAN_TRIGGER(false)
        else
            NATIVE.SET_STUNT_JUMPS_CAN_TRIGGER(true)
        end
    end)
    Higurashi.DisableStuntJumps.on = settings["DisableStuntJumps"]

    Higurashi.DisableSharkCards = m.af("Disable Shark Cards", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["DisableSharkCards"] = f.on
        if f.on then
            NATIVE.SET_STORE_ENABLED(false)
        else
            NATIVE.SET_STORE_ENABLED(true)
        end
    end)
    Higurashi.DisableSharkCards.on = settings["DisableSharkCards"]

    Higurashi.ChangePhoneStyle = m.af("Change Phone Style", "value_str", Higurashi.Miscellaneous2.id, function(f)
        local function is_phone_open()
            return NATIVE.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("cellphone_flashhand")) > 0 or script.get_global_i(20266 + 1) > 3
        end
        local is_open = false
        while f.on do
            if is_phone_open() then
                if f.value ~= 3 then
                    NATIVE.CREATE_MOBILE_PHONE(math.tointeger(f.value))
                end
                is_open = true
            elseif is_open then
                NATIVE.DESTROY_MOBILE_PHONE()
                is_open = false
            end
            wait(0)
        end
        NATIVE.CREATE_MOBILE_PHONE(0)
        NATIVE.DESTROY_MOBILE_PHONE()
    end):set_str_data({ "Michael's Phone", "Trevor's Phone", "Franklin's Phone", "unk", "Prologue Phone" })

    Higurashi.DisableScriptedSound = m.af("Disable Scripted Sound", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["DisableScriptedSound"] = f.on
        if f.on then
            if NATIVE.AUDIO_IS_MUSIC_PLAYING() and not NATIVE.NETWORK_IS_ACTIVITY_SESSION() then
                NATIVE.TRIGGER_MUSIC_EVENT("GLOBAL_KILL_MUSIC")
            end
            wait(50)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)
    Higurashi.DisableScriptedSound.on = settings["DisableScriptedSound"]

    Higurashi.DisablePedSpeech = m.af("Disable Ped Speech", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["DisablePedSpeech"] = f.on
        if f.on then
            for _, peds in pairs(ped.get_all_peds()) do
                if NATIVE.IS_ANY_SPEECH_PLAYING(peds) then
                    NATIVE.STOP_CURRENT_PLAYING_SPEECH(peds)
                end
            end
            wait(50)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)
    Higurashi.DisablePedSpeech.on = settings["DisablePedSpeech"]

    Higurashi.BlockAimAssist = m.af("Block Aim Assist", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["BlockAimAssist"] = f.on
        NATIVE.SET_PED_CAN_BE_TARGETTED(NATIVE.PLAYER_PED_ID(), f.on)
    end)
    Higurashi.BlockAimAssist.on = settings["BlockAimAssist"]


    Higurashi.SetMaxPlayer = m.af("Set Max Players", "autoaction_value_i", Higurashi.Miscellaneous2.id, function(f)
        if player.is_player_host(NATIVE.PLAYER_ID()) then
            NATIVE.NETWORK_SESSION_SET_MATCHMAKING_GROUP_MAX(0, f.value)
        end
    end)
    Higurashi.SetMaxPlayer.min = 0
    Higurashi.SetMaxPlayer.max = 29
    Higurashi.SetMaxPlayer.value = 29

    Higurashi.SetMaxSpectators = m.af("Set Max Spectators", "autoaction_value_i", Higurashi.Miscellaneous2.id, function(f)
        if player.is_player_host(NATIVE.PLAYER_ID()) then
            NATIVE.NETWORK_SESSION_SET_MATCHMAKING_GROUP_MAX(4, f.value)
        end
    end)
    Higurashi.SetMaxSpectators.min = 0
    Higurashi.SetMaxSpectators.max = 4
    Higurashi.SetMaxSpectators.value = 4

    Higurashi.SetMaxPlayer = m.af("Net Change Slot: ", "action_value_i", Higurashi.Miscellaneous2.id, function(f)
        if player.is_player_host(NATIVE.PLAYER_ID()) then
            NATIVE.NETWORK_SESSION_CHANGE_SLOTS(f.value, 32 - f.value)
            wait(0)
        end
    end)

    Higurashi.CreateGhostSession = m.af("Ghost Session", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["CreateGhostSession"] = f.on
        while f.on do
            NATIVE.NETWORK_START_SOLO_TUTORIAL_SESSION()
            wait(0)
        end
        if not f.on then
            NATIVE.NETWORK_END_TUTORIAL_SESSION()
        end
    end)
    Higurashi.CreateGhostSession.hint = "Creates a session within your session where you will not receive other players syncs, and they will not receive yours."
    Higurashi.CreateGhostSession.on = settings["CreateGhostSession"]

    m.af("Force Cloud Save", "action", Higurashi.Miscellaneous2.id, function()
        if NATIVE.NETWORK_IS_PLAYER_CONNECTED(NATIVE.PLAYER_ID()) and NATIVE.NETWORK_IS_SESSION_STARTED() then
            NATIVE.STAT_SAVE(0, false, 3, false)
        end
    end)

    Higurashi.BlockCloudSave = m.af("Block Cloud Save", "toggle", Higurashi.Miscellaneous2.id, function(f)
        settings["BlockCloudSave"] = f.on
        if NATIVE.NETWORK_IS_PLAYER_CONNECTED(NATIVE.PLAYER_ID()) and NATIVE.NETWORK_IS_SESSION_STARTED() then
            NATIVE.STAT_SET_BLOCK_SAVES(f.on)
        end
    end)
    Higurashi.BlockCloudSave.on = settings["BlockCloudSave"]

    m.af("Leave Session", "action_value_str", Higurashi.Miscellaneous2.id, function(f)
        local function bail_if_possible()
            if not NATIVE.NETWORK_CAN_BAIL() then
                m.n("Can't bail right now.", title, 2, c.red1)
            else
                NATIVE.NETWORK_BAIL()
            end
        end

        local actions = {
            bail_if_possible,
            function() NATIVE.NETWORK_SESSION_END(false, true) end,
            function() NATIVE._NETWORK_SESSION_LEAVE_INCLUDING_REASON(2, 3) end,
            function() NATIVE.NETWORK_SESSION_LEAVE_SINGLE_PLAYER() end,
            function() network.force_remove_player(NATIVE.PLAYER_ID()) end,
            function()
                local end_time = utils.time_ms() + 8000
                while utils.time_ms() < end_time do end
            end,
            function() NATIVE.SHUTDOWN_AND_LOAD_MOST_RECENT_SAVE() end,
        }

        if actions[f.value + 1] then
            actions[f.value + 1]()
        end
    end):set_str_data({ "Bail", "2-3", "Session End", "Leave SP", "Desync", "Timeout", "Quit Story Mode" })

    m.af("Restart Game", "action", Higurashi.Miscellaneous2.id, function()
        NATIVE.RESTART_GAME()
    end)

    m.af("Quit Game", "action", Higurashi.Miscellaneous2.id, function()
        NATIVE.FORCE_SOCIAL_CLUB_UPDATE()
    end)

    Higurashi.Utilities = m.af("Utilities", "parent", Higurashi.Parent2.id)

    Higurashi.FeatureSearcher = m.af("Feature Searcher", "parent", Higurashi.Utilities.id)

    local CatNames = { "local", "online", "spawn" }

    local Exclusions = {
        ["local.scripts"] = true,
        ["local.script_features"] = true,
        ["local.asi_plugins"] = true,
        ["online.online_players"] = true,
        ["online.fake_friends"] = true,
    }

    local all_feats = {}
    local table_concat = table.concat
    local string_format = string.format
    local _print = print
    local _tostring = tostring

    local function print(...)
        local args = { ... }
        for i = 1, #args do
            _print(string_format("<%s v%s> %s", "Feature Searcher", "", _tostring(args[i])))
        end
    end

    local function first_to_upper(str) return (str:gsub("^%l", string.upper)) end

    local function process_parent(featsTable, parent, keyTbl, index, lastSleep, namePrefix)
        namePrefix = namePrefix or ""
        namePrefix = namePrefix .. parent.name .. " > "
        for i = 1, parent.child_count do
            local child = parent.children[i]
            local name = child.name:lower()
            keyTbl[index] = name:gsub("[^a-z0-9]", "_")
            local key = table_concat(keyTbl, ".")
            if child.type == 2048 then
                process_parent(featsTable, child, keyTbl, index + 1, lastSleep, namePrefix)
            end
            featsTable[#featsTable + 1] = { Name = namePrefix .. child.name, SearchName = name, Key = key }
            if utils.time_ms() - lastSleep >= 33 then
                lastSleep = utils.time_ms()
                wait(0)
            end
            for i = #keyTbl, index, -1 do keyTbl[i] = nil end
        end
        return lastSleep
    end

    m.ct(function(featsTable)
        local lastSleep = utils.time_ms()
        higurashi.logger("Indexing features...", "", "", "", "Debug.log")
        local startTime = utils.time_ms()
        for i = 1, #CatNames do
            local catname = CatNames[i]
            local keyTbl = { catname }
            local feats = m.gcc(catname)
            if feats == nil then
                higurashi.logger("Error finding children of category: " .. catname, "", "", "", "Debug.log")
            else
                for j = 1, #feats do
                    local feat = feats[j]
                    if feat ~= nil then
                        local name = feat.name:lower()
                        keyTbl[2] = name:gsub("[^a-z0-9]", "_")
                        local key = table_concat(keyTbl, ".")
                        if not Exclusions[key] then
                            catname = first_to_upper(catname)
                            featsTable[#featsTable + 1] = { Name = catname .. " > " .. feat.name, SearchName = name:lower(), Key = key }
                            if feat.type == 2048 then
                                lastSleep = process_parent(featsTable, feat, keyTbl, 3, lastSleep, catname .. " > ")
                            end
                        end
                    end
                end
                if utils.time_ms() - lastSleep >= 33 then
                    lastSleep = utils.time_ms()
                    wait(0)
                end
            end
        end
        local endTime = utils.time_ms()
        local log_text = string.format("Indexed %d features in %.3f seconds.",
            #featsTable, (endTime - startTime) / 1000)
        higurashi.logger(log_text, "", "", "", "Debug.log")
    end, all_feats)

    local function delete_feature(Feat)
        if Feat.type == 2048 then
            for i = 1, Feat.child_count do
                delete_feature(Feat.children[1])
            end
        end
        m.df(Feat.id)
    end

    local function select_feat(f)
        local feat = m.gfbhk(f.data)
        if feat == nil then return end
        if feat.parent then feat.parent:toggle() end
        feat:select()
    end

    local function toggle_feat(f)
        local feat = m.gfbhk(f.data)
        if feat == nil then return end
        feat:toggle()
    end

    Higurashi.FilterFeat = m.af("Filter: <None>", "action", Higurashi.FeatureSearcher.id, function(f)
        local r, s
        repeat
            r, s = input.get("Enter search query.", f.data, 64, 0)
            if r == 2 then return HANDLER_POP end
            wait(0)
        until r == 0
        local threads = {}
        for i = f.parent.child_count, 2, -1 do
            threads[#threads + 1] = m.ct(delete_feature, f.parent.children[i])
        end
        local waiting = true
        while waiting do
            local running = false
            for i = 1, #threads do
                running = running or (not menu.has_thread_finished(threads[i]))
            end
            waiting = running
            wait(0)
        end
        s = higurashi.trim(s)
        if s:len() == 0 then
            f.data = ""
            f.name = "Filter: <None>"
            return HANDLER_POP
        end
        local needle = s:lower()
        local count = 0
        for i = 1, #all_feats do
            local feat = all_feats[i]
            if feat.SearchName:find(needle, w, true) then
                local f = m.gfbhk(feat.Key)
                if f ~= nil then
                    local child
                    if f.type == 2048 then
                        child = m.af(feat.Name, "action", Higurashi.FeatureSearcher.id, toggle_feat)
                    else
                        child = m.af(feat.Name, "action", Higurashi.FeatureSearcher.id, select_feat)
                    end
                    child.data = feat.Key
                    child.hint = f.hint
                    count = count + 1
                end
            end
        end
        f.data = s
        f.name = "Filter: <" .. s .. "> (" .. count .. ")"
    end)
    Higurashi.FilterFeat.data = ""

    local function delete_2t1_files(item_type, path, parent_id)
        m.n("Deleting can't be reverted.", title, 2, c.yellow1)
        local items = utils.get_all_files_in_directory(path .. "\\", "ini")
        local entries = parent_id.children
        for i = 1, #items do
            local add = true
            for y = 1, #entries do
                if entries[y].name == items[i] then
                    add = false
                    break
                end
            end
            if add then
                m.af(items[i], "action", parent_id.id, function(f)
                    if utils.file_exists(path .. "\\" .. items[i]) then
                        if io.remove(path .. "\\" .. items[i]) then
                            logger("Deleted " .. item_type .. ": " .. items[i], "", "Debug.log", true, title, 3, c.green1)
                            return HANDLER_CONTINUE
                        else
                            logger("Error deleting the file, try again.", "", "Debug.log", true, title, 3, c.red1)
                            return HANDLER_POP
                        end
                    end
                    m.df(f.id)
                end)
            end
        end
    end


    Higurashi.DeleteSpooferProfiles = m.af("Delete Spoofer Profiles", "parent", Higurashi.Utilities.id, function()
        delete_2t1_files("spoofer profile", paths.spoofer, Higurashi.DeleteSpooferProfiles)
    end)


    Higurashi.DeleteOutfits = m.af("Delete Custom Outfits", "parent", Higurashi.Utilities.id, function()
        delete_2t1_files("custom outfit", paths.outfits, Higurashi.DeleteOutfits)
    end)


    Higurashi.DeleteVehicles = m.af("Delete Custom Vehicles", "parent", Higurashi.Utilities.id, function()
        delete_2t1_files("custom vehicle", paths.vehicles, Higurashi.DeleteVehicles)
    end)

    Higurashi.Visual = m.af("Visual", "parent", Higurashi.Utilities.id)

    local INI = IniParser(utils.get_appdata_path("PopstarDevs", "2Take1Menu\\scripts\\Project.Higurashi\\datas\\settings.ini"))
    local saved_colors = {}
    if INI:read() then
        for i = 1, #higurashi.hud_components_to_modify do
            local HUD = higurashi.hud_components_to_modify[i].Name
            local rExists, rVal = INI:get_i(HUD, "R")
            local gExists, gVal = INI:get_i(HUD, "G")
            local bExists, bVal = INI:get_i(HUD, "B")
            local aExists, aVal = INI:get_i(HUD, "A")
            if rExists and gExists and bExists and aExists then
                saved_colors[HUD] = { R = rVal, G = gVal, B = bVal, A = aVal }
            end
        end
    end

    Higurashi.EditHUDColors = m.af("Edit HUD Colors", "parent", Higurashi.Visual.id)

    local FilterFeat = m.af("Filter", "action_value_str", Higurashi.EditHUDColors.id, function(f, data)
        local query
        repeat
            local status, input = input.get("Enter search query.", data, 64, 0)
            if status == 2 then return end
            query = higurashi.trim(input)
            wait()
        until query ~= ""
        local parent = f.parent
        if query == "" then
            f.name = "Filter"
            f.data = ""
            f:set_str_data({ "" })
            for i = 2, parent.child_count do
                parent.children[i].hidden = false
            end
            return
        end
        f.data = query
        f:set_str_data({ query:lower() })
        local count = 0
        for i = 2, parent.child_count do
            local child = parent.children[i]
            local match = child.name:lower():find(query:lower(), 1, true)
            child.hidden = not match
            if match then count = count + 1 end
        end
        f.name = string.format("Filter (%d)", count)
    end)

    FilterFeat.data = ""
    FilterFeat:set_str_data({ "" })

    local function handle_hud_color(f)
        local parent = f.parent
        local HUD = parent.data[1]
        local Index = parent.data[2]

        local RFeat = parent.children[1]
        local GFeat = parent.children[2]
        local BFeat = parent.children[3]
        local AFeat = parent.children[4]
        local CurrFeat = parent.children[5]

        local R = RFeat.value
        local G = GFeat.value
        local B = BFeat.value
        local A = AFeat.value

        higurashi.set_hud_index_rgba(Index, R, G, B, A)
        CurrFeat.name = string.format("%s#Current Color#DEFAULT#", higurashi.rgba_to_hex(R, G, B, A))
        saved_colors[HUD] = { R = R, G = G, B = B, A = A }
    end

    for _, hud_component in ipairs(higurashi.hud_components_to_modify) do
        local HUD = hud_component.Name
        local Index = hud_component.Index

        local R, G, B, A
        local Color = saved_colors[HUD]
        if Color then
            R, G, B, A = Color.R, Color.G, Color.B, Color.A
            higurashi.set_hud_index_rgba(Index, R, G, B, A)
        else
            R, G, B, A = higurashi.get_hud_index_rgba(Index)
        end

        local HUDParent = m.af(HUD, "parent", Higurashi.EditHUDColors.id)
        HUDParent.data = { HUD, Index }

        local RFeat = m.af("Red", "autoaction_value_i", HUDParent.id, handle_hud_color)
        RFeat.min, RFeat.max, RFeat.mod, RFeat.value = 0, 255, 1, R

        local GFeat = m.af("Green", "autoaction_value_i", HUDParent.id, handle_hud_color)
        GFeat.min, GFeat.max, GFeat.mod, GFeat.value = 0, 255, 1, G

        local BFeat = m.af("Blue", "autoaction_value_i", HUDParent.id, handle_hud_color)
        BFeat.min, BFeat.max, BFeat.mod, BFeat.value = 0, 255, 1, B

        local AFeat = m.af("Alpha", "autoaction_value_i", HUDParent.id, handle_hud_color)
        AFeat.min, AFeat.max, AFeat.mod, AFeat.value = 0, 255, 1, A

        m.af(string.format("%s#==CURRENT COLOR==#DEFAULT#", higurashi.rgba_to_hex(R, G, B, A)), "action", HUDParent.id)
    end

    m.af("Save HUD Colors", "action", Higurashi.EditHUDColors.id, function(f)
        for HUD, Color in pairs(saved_colors) do
            INI:set_i(HUD, "R", Color.R)
            INI:set_i(HUD, "G", Color.G)
            INI:set_i(HUD, "B", Color.B)
            INI:set_i(HUD, "A", Color.A)
        end
        INI:write()
        m.n("Saved HUD colors.", title, 3, c.green1)
    end)


    Higurashi.PlayerBar = m.af("Player Bar", "toggle", Higurashi.Visual.id, function(f)
        settings["PlayerBar"] = f.on
        if not f.on then
            return
        end
        ui.draw_rect(0.001, 0.02, 2.0, 0.04, 0, 0, 0, 100)
        local pos = v2(0.0001, 0.000001)
        for i = 0, 31 do
            if NATIVE.GET_PLAYER_PED(i) ~= 0 then
                local color = { 255, 255, 255, 255 }
                if player.is_player_host(i) then
                    color = { 220, 185, 75, 255 }
                elseif i == NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT() then
                    color = { 20, 10, 200, 255 }
                elseif player.is_player_modder(i, -1) then
                    color = { 200, 50, 50, 255 }
                elseif player.is_player_friend(i) then
                    color = { 100, 200, 100, 255 }
                end
                ui.set_text_color(table.unpack(color))

                if pos.x > 0.95 then
                    pos.y = 0.025
                    pos.x = 0.0001
                end
                ui.set_text_scale(0.220)
                ui.set_text_font(0)
                ui.set_text_centre(false)
                ui.set_text_outline(false)
                ui.draw_text(higurashi.get_user_name(i), pos)
                pos.x = pos.x + 0.070
            end
        end
        return HANDLER_CONTINUE
    end)
    Higurashi.PlayerBar.on = settings["PlayerBar"]

    Higurashi.DateTime = m.af("Date / Time", "toggle", Higurashi.Visual.id, function(f)
        settings["DateTime"] = f.on
        while f.on do
            local pos = v2(0.5, 0.05)
            local currentTime = os.date("%a %d %b %I:%M:%S %p")

            ui.set_text_scale(0.25)
            ui.set_text_font(0)
            ui.set_text_color(255, 0, 0, 200)
            ui.set_text_centre(true)
            ui.set_text_outline(1)
            ui.draw_text(currentTime, pos)

            wait(1)
        end
        settings["DateTime"] = false
    end)
    Higurashi.DateTime.on = settings["DateTime"]

    Higurashi.DisableHUD = m.af("Disable HUD", "toggle", Higurashi.Visual.id, function(f)
        settings["DisableHUD"] = f.on
        if f.on then
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(1)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(2)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(3)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(4)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(13)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(17)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(21)
            NATIVE.HIDE_HUD_COMPONENT_THIS_FRAME(22)
            NATIVE.HIDE_HUD_AND_RADAR_THIS_FRAME()
            return HANDLER_CONTINUE
        end
        settings["DisableHUD"] = false
    end)
    Higurashi.DisableHUD.on = settings["DisableHUD"]

    Higurashi.Logs = m.af("Logs", "parent", Higurashi.Utilities.id)

    Higurashi.LogNotifyJoiningPlayers = m.af("Log Joining Players", "toggle", Higurashi.Logs.id, function(f)
        local function log_joining_player(event)
            local pid = event.player
            if pid ~= NATIVE.PLAYER_ID() then
                local name = higurashi.get_user_name(pid)
                local scid = higurashi.get_user_rid(pid)
                local hosttoken = player.get_player_host_token(pid)
                local ip = higurashi.get_player_ip(pid)
                higurashi.logger(string.format("Slot:%d | Username:%s | SCID:%s | IP:%s | Host Token:%s joined", pid, name, scid, ip, higurashi.dec_to_hex(hosttoken)), "", "", "", "Players.log")
            end
        end
        if f.on then
            if not player_log["Player_Log"] then
                settings["PlayerLog"] = true
                player_log["Player_Log"] = event.add_event_listener("player_join", log_joining_player)
            end
        else
            if player_log["Player_Log"] then
                event.remove_event_listener("player_join", player_log["Player_Log"])
                player_log["Player_Log"] = nil
            end
            settings["PlayerLog"] = f.on
        end
    end)
    Higurashi.LogNotifyJoiningPlayers.on = settings["PlayerLog"]

    Higurashi.LogGameChat = m.af("Log Game Chat", "toggle", Higurashi.Logs.id, function(f)
        local function chat_logger(text)
            local file = paths.logs .. "\\Chat.log"
            if text then
                local file_handle = io.open(file, "a")
                if file_handle then
                    file_handle:write(higurashi.time_prefix() .. text .. "\n")
                    file_handle:close()
                end
            end
        end
        local function log_chat(event)
            local player_name = higurashi.get_user_name(event.player)
            local player_rid = higurashi.get_user_rid(event.player)
            local chat_text = event.body
            local log_text = string.format("[%s/%s] %s", player_name, player_rid, chat_text)
            print(log_text)
            chat_logger(log_text)
        end
        if f.on then
            if not chat_events["chat_log"] then
                settings["ChatLog"] = true
                chat_events["chat_log"] = event.add_event_listener("chat", log_chat)
            end
        else
            if chat_events["chat_log"] then
                event.remove_event_listener("chat", chat_events["chat_log"])
                chat_events["chat_log"] = nil
            end
            settings["ChatLog"] = f.on
        end
    end)
    Higurashi.LogGameChat.on = settings["ChatLog"]

    m.af("Clear Project Higurashi Logs", "action_value_str", Higurashi.Logs.id, function(f)
        local files = {
            [0] = "Debug.log",
            [1] = "Chat.log",
            [2] = "Players.log",
            [3] = "PlayerInfo.log",
            [4] = { "Debug.log", "Chat.log", "Players.log", "PlayerInfo.log" },
        }
        local function clear_logs(file)
            if type(file) == "table" then
                for _, f in ipairs(file) do
                    higurashi.write(io.open(paths.logs .. "\\" .. f, "w"), "")
                end
            else
                higurashi.write(io.open(paths.logs .. "\\" .. file, "w"), "")
            end
        end
        clear_logs(files[f.value])
        m.n(files[f.value] .. " have been cleared.", title, 3, c.yellow1)
    end):set_str_data({ "Debug.log", "Chat.log", "Players.log", "PlayerInfo.log", "All Logs" })

    m.af("Clear Menu Logs", "action_value_str", Higurashi.Logs.id, function(f)
        local files = {
            [0] = "2Take1Menu.log",
            [1] = "2Take1Prep.log",
            [2] = "notification.log",
            [3] = "player.log",
            [4] = "net_event.log",
            [5] = "script_event.log",
            [6] = { "2Take1Menu.log", "2Take1Prep.log", "notification.log", "player.log", "net_event.log", "script_event.log" },
        }
        local function clear_logs(file)
            if type(file) == "table" then
                for _, f in ipairs(file) do
                    higurashi.write(io.open(paths.root .. "\\" .. f, "w"), "")
                end
            else
                higurashi.write(io.open(paths.root .. "\\" .. file, "w"), "")
            end
        end
        clear_logs(files[f.value])
        m.n(files[f.value] .. " have been cleared.", title, 3, c.yellow1)
    end):set_str_data({ "2Take1Menu.log", "2Take1Prep.log", "notification.log", "player.log", "net_event.log", "script_event.log", "All Logs" })

    if Dev then
        Higurashi.Encrypter = m.af("Encrypt Files", "parent", Higurashi.Utilities.id, function()
            local files = utils.get_all_files_in_directory(paths.dev .. "\\", "lua")
            local entries = Higurashi.Encrypter.children
            local function file_already_added(filename)
                for _, entry in ipairs(entries) do
                    if entry.name == filename then
                        return true
                    end
                end
                return false
            end
            local function encrypt_file(filename)
                if utils.file_exists(paths.dev .. "\\" .. filename) then
                    if io._encrypt(paths.dev .. "\\" .. filename) then
                        logger("Encrypted file: " .. filename, "", "Debug.log", true, title, 3, c.green1)
                    else
                        logger("Failed to encrypt: " .. filename, "", "Debug.log", true, title, 3, c.red1)
                    end
                end
            end
            for _, file in ipairs(files) do
                if not file_already_added(file) then
                    m.af(file, "action", Higurashi.Encrypter.id, function()
                        encrypt_file(file)
                    end)
                end
            end
        end)

        local LogoURL = "https://www.freepnglogos.com/uploads/gta-5-logo-png/gta-v-green-4.png"
        local Settings = {}
        Settings.JoinLeaveWebhook = ""
        Settings.ChatWebhook = ""

        local Toggles = {}
        Toggles.LogJoinLeave = false
        Toggles.LogChat = false

        local INI = IniParser(utils.get_appdata_path("PopstarDevs", "2Take1Menu\\scripts\\Project.Higurashi\\datas\\settings.ini"))
        if INI:read() then
            local exists, val

            for k in pairs(Settings) do
                exists, val = INI:get_s("Settings", k)
                if exists then Settings[k] = val end
            end

            for k in pairs(Toggles) do
                exists, val = INI:get_b("Toggles", k)
                if exists then Toggles[k] = val end
            end
        end

        Higurashi.LogToDiscord = m.af("Log To Discord", "parent", Higurashi.Utilities.id)

        local function SetWebhook(f, data)
            local r, s
            repeat
                r, s = input.get("Enter webhook. ONLY ENTER AFTER 'https://discord.com/api/webhooks/'!", Settings[data] or "", 250, 0)
                if r == 2 then return end
                wait(0)
            until r == 0

            Settings[data] = "https://discord.com/api/webhooks/" .. s
        end

        m.af("Set Join / Leave Webhook", "action", Higurashi.LogToDiscord.id, SetWebhook)
        .data = "JoinLeaveWebhook"

        m.af("Log Join / Leave", "toggle", Higurashi.LogToDiscord.id, function(f)
            if not f.on then
                Toggles.LogJoinLeave = false
                if f.data ~= nil then
                    event.remove_event_listener("player_join", f.data.join)
                    event.remove_event_listener("player_leave", f.data.leave)
                    f.data = nil
                end
                return
            end

            if Settings.JoinLeaveWebhook == nil or Settings.JoinLeaveWebhook ==
                "" then
                Toggles.LogJoinLeave = false
                f.on = false
                if f.data ~= nil then
                    event.remove_event_listener("player_join", f.data.join)
                    event.remove_event_listener("player_leave", f.data.leave)
                    f.data = nil
                end
                m.n("You must set the \"Join/Leave Webhook\" before enabling.",
                    title, 3, c.red1)
                return
            end

            local status, result = pcall(higurashi_discord.new, higurashi_discord, Settings.JoinLeaveWebhook)
            if not status then
                Toggles.LogJoinLeave = false
                f.on = false
                if f.data ~= nil then
                    event.remove_event_listener("player_join", f.data.join)
                    event.remove_event_listener("player_leave", f.data.leave)
                    f.data = nil
                end
                logger("Failed to load Discord Handler:\n" .. result, "", "Debug.log", true, title, 3, c.red1)
                return
            end
            higurashi.logger("Join/Leave Discord Webhook initialised.", "", "", "", "Debug.log")

            local Discord = result
            Toggles.LogJoinLeave = true
            f.data = {}
            f.data.join = event.add_event_listener("player_join", function(e)
                local pid = e.player
                local name = higurashi.get_user_name(pid)
                local scid = player.get_player_scid(pid)
                local ip = (pid == NATIVE.PLAYER_ID() or player.is_player_friend(pid)) and "Hidden"
                    or higurashi.get_player_ip(pid)
                local embed = higurashi_discord.Embed:new()
                embed:SetTitle("Player Joined")
                embed:SetAuthor(name, string.format("https://socialclub.rockstargames.com/member/%s/", name), string.format("https://a.rsg.sc/n/%s/n", name:lower()))
                embed:SetColor(0xFFFFFF)
                embed:SetCurrentTimestamp()
                embed:AddField("SCID", tostring(scid), true)
                embed:AddField("IP", ip, true)
                Discord:SendMessage(nil, title, LogoURL, { embed })
            end)

            f.data.leave = event.add_event_listener("player_leave", function(e)
                local pid = e.player
                local name = e.name
                local scid = e.scid

                local embed = higurashi_discord.Embed:new()
                embed:SetTitle("Player Left")
                embed:SetAuthor(name, string.format("https://socialclub.rockstargames.com/member/%s/", name), string.format("https://a.rsg.sc/n/%s/n", name:lower()))
                embed:SetColor(0x000000)
                embed:SetCurrentTimestamp()
                embed:AddField("SCID", tostring(scid), true)
                Discord:SendMessage(nil, title, LogoURL, { embed })
            end)
        end).on = Toggles.LogJoinLeave

        m.af("Set Chat Webhook", "action", Higurashi.LogToDiscord.id, SetWebhook).data = "ChatWebhook"

        m.af("Log Chat", "toggle", Higurashi.LogToDiscord.id, function(f)
            if not f.on then
                Toggles.LogChat = false
                if f.data ~= nil then
                    event.remove_event_listener("chat", f.data)
                    f.data = nil
                end
                return
            end

            if (Settings.ChatWebhook == nil) or (Settings.ChatWebhook == "") then
                Toggles.LogChat = false
                f.on = false
                if f.data ~= nil then
                    event.remove_event_listener("chat", f.data)
                    f.data = nil
                end
                m.n("You must set the \"Chat Webhook\" before enabling.", title, 3, c.red1)
                return
            end

            local status, result = pcall(higurashi_discord.new, higurashi_discord, Settings.ChatWebhook)
            if not status then
                Toggles.LogChat = false
                f.on = false
                if f.data ~= nil then
                    event.remove_event_listener("chat", f.data)
                    f.data = nil
                end
                logger("Failed to load Discord Handler:\n" .. result, "", "Debug.log", true, title, 3, c.red1)
                return
            end
            higurashi.logger("Chat Discord Webhook initialised.", "", "", "", "Debug.log")
            local Discord = result
            Toggles.LogChat = true
            f.data = event.add_event_listener("chat", function(e)
                local pid = e.player
                local name = higurashi.get_user_name(pid)
                local msg = e.body
                Discord:SendMessage(higurashi_discord.remove_pings(msg), name, string.format("https://a.rsg.sc/n/%s/n", name:lower()))
            end)
        end).on = Toggles.LogChat

        m.af("Save Settings", "action", Higurashi.LogToDiscord.id, function(f)
            for k, v in pairs(Settings) do
                INI:set_s("Settings", k, v)
            end
            for k, v in pairs(Toggles) do INI:set_b("Toggles", k, v) end
            INI:write()
            m.n("Settings saved", title, 3, c.green1)
        end)
    end

    m.af("Clear Menu Notifications", "action", Higurashi.Utilities.id, function()
        menu.clear_visible_notifications()
        wait()
    end)
    Higurashi.HideMenuNotifications = m.af("Hide Menu Notifications", "toggle", Higurashi.Utilities.id, function(f)
        if f.on then menu.clear_all_notifications() end
        settings["HideMenuNotifications"] = f.on
        if not f.on then return HANDLER_POP end

        return HANDLER_CONTINUE
    end)
    Higurashi.HideMenuNotifications.on = settings["HideMenuNotifications"]

    Higurashi.HideGameNotifications = m.af("Hide In-Game Notifications", "toggle", Higurashi.Utilities.id, function(f)
        if f.on then NATIVE.THEFEED_HIDE() end
        settings["HideGameNotifications"] = f.on
        if not f.on then
            NATIVE.THEFEED_SHOW()
            return HANDLER_POP
        end

        return HANDLER_CONTINUE
    end)
    Higurashi.HideGameNotifications.on = settings["HideGameNotifications"]

    Higurashi.HidePhoneNotifications = m.af("Hide Phone Notifications", "toggle", Higurashi.Utilities.id, function(f)
        if f.on then
            NATIVE.THEFEED_REMOVE_ITEM(NATIVE.THEFEED_GET_LAST_SHOWN_PHONE_ACTIVATABLE_FEED_ID())
        end
        settings["HidePhoneNotifications"] = f.on
        if not f.on then return HANDLER_POP end

        return HANDLER_CONTINUE
    end)
    Higurashi.HidePhoneNotifications.on = settings["HidePhoneNotifications"]

    Higurashi.NotifyGuidedMissile = m.af("Notify Submarine Guided Missile", "toggle", Higurashi.Utilities.id, function(f)
        if missile_event_hook == nil then
            missile_event_hook = hook.register_script_event_hook(function(
                source, target, params, count)
                if params[1] == 0x6B40E4E3 then
                    m.n(higurashi.get_user_name(source) .. " launched a guided missile.", "", 3, c.yellow1)
                end
            end)
        else
            hook.remove_script_event_hook(missile_event_hook)
            missile_event_hook = nil
        end
        settings["NotifyGuidedMissile"] = f.on
    end)
    Higurashi.NotifyGuidedMissile.on = settings["NotifyGuidedMissile"]

    Higurashi.NotifyTypingPlayers = m.af("Notify Typing Players", "toggle", Higurashi.Utilities.id, function(f)
        if typing_event_hook == nil then
            typing_event_hook = hook.register_script_event_hook(function(source,
                target,
                params,
                count)
                if params[1] == 0x970E710F then
                    m.n(higurashi.get_user_name(source) .. " is typing.", "", 2, c.black1)
                elseif params[1] == 0x1C6002BD then
                end
            end)
        else
            hook.remove_script_event_hook(typing_event_hook)
            typing_event_hook = nil
        end
        settings["NotifyTypingPlayers"] = f.on
    end)
    Higurashi.NotifyTypingPlayers.on = settings["NotifyTypingPlayers"]

    Higurashi.NotifyHostMigrations = m.af("Notify Session Host Migrations", "toggle", Higurashi.Utilities.id, function(f)
        if f.on then
            local current_host
            local host_name
            if current_host == nil then
                current_host = player.get_host()
                host_name = higurashi.get_user_name(current_host)
            end
            wait(2000)
            local new_host = player.get_host()
            if current_host ~= new_host then
                if higurashi.get_user_rid(new_host) ~= -1 then
                    if host_name == "**Invalid**" then
                        -- logger("Session host migrated to " .. higurashi.get_user_name(new_host), "", "Debug.log", true, "", 3, c.yellow1)
                        host_name = higurashi.get_user_name(current_host)
                    else
                        logger("Session host migrated from " .. host_name .. " to " .. higurashi.get_user_name(new_host), "", "Debug.log", true, "", 3, c.yellow1)
                        host_name = higurashi.get_user_name(current_host)
                    end
                end
            end
        end
        settings["NotifyHostMigrations"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.NotifyHostMigrations.on = settings["NotifyHostMigrations"]

    Higurashi.NotifyScriptHostMigrations = m.af("NotifyScriptHostMigrations", "toggle", Higurashi.Utilities.id, function(f)
        if f.on then
            local current_sh
            local sh_name
            if current_sh == nil then
                current_sh = NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT()
                sh_name = higurashi.get_user_name(current_sh)
            end
            wait(2000)
            local new_sh = NATIVE.NETWORK_GET_HOST_OF_THIS_SCRIPT()
            if current_sh ~= new_sh then
                if higurashi.get_user_rid(new_sh) ~= -1 then
                    if sh_name == "**Invalid**" then
                        -- logger("Script host migrated to " .. higurashi.get_user_name(new_sh), "", "Debug.log", true, "", 3, c.blue1)
                        sh_name = higurashi.get_user_name(current_sh)
                    else
                        logger("Script host migrated from " .. sh_name .. " to " .. higurashi.get_user_name(new_sh), "", "Debug.log", true, "", 3, c.blue1)
                        sh_name = higurashi.get_user_name(current_sh)
                    end
                end
            end
        end
        settings["NotifyScriptHostMigrations"] = f.on
        return HANDLER_CONTINUE
    end)
    Higurashi.NotifyScriptHostMigrations.on = settings["NotifyScriptHostMigrations"]

    Higurashi.GetNameFromHash = m.af("Get Name From Hash Key", "action", Higurashi.Utilities.id, function(f)
        local function hash_log(text)
            local t = os.date("*t")
            local log_message = string.format("[%d-%02d-%02d %02d:%02d:%02d] [Hash Key Request] %s\n",
                t.year, t.month, t.day, t.hour, t.min, t.sec, text)
            local file = io.open(paths.logs .. "\\Debug.log", "a")
            if file then
                file:write(log_message)
                file:close()
            end
        end

        return input_handler("Get Name From Hash Key", "Enter the event hash to send.", function(s)
            local send_event = tostring(s)
            hash_log("String to hash = " .. send_event)
            local hash_key_request = tostring(joaat(send_event))
            hash_log("Hashkey fetched = " .. hash_key_request)

            m.n(string.format("%s : %s", send_event, hash_key_request), "Get Name From Hash Key", 3, c.orange1)
            utils.to_clipboard(hash_key_request)
        end)
    end)

    Higurashi.CurrentSetting = m.af("{!} Current Settings", "action_value_str", Higurashi.Utilities.id, function(f)
        if f.value == 0 then
            SaveScriptSettings()
            higurashi.logger("Save settings successfully.", "", "", "[Settings Save: Successful]", "Debug.log", true, "CHAR_SOCIAL_CLUB", 18)
        elseif f.value == 1 then
            local file = io.open(paths.settings, "w")
            if file then
                file:write("")
                file:close()
                higurashi.logger("Settings reset successfully.", "", "", "[Settings Reset: Successful]", "Debug.log", true, "CHAR_SOCIAL_CLUB", 18)
            end
        end
    end):set_str_data({ "Save", "Reset" })

    Higurashi.Teleport = m.af("Teleport", "parent", Higurashi.Self.id)
    Higurashi.Teleport.hint = "Teleport to virtually anywhere in the map, whether you are on foot or in a vehicle. If you teleport while you are in a vehicle, all passengers will be teleported along with it."

    Higurashi.AutoTeleport = m.af("Auto Teleport To Waypoint", "toggle", Higurashi.Teleport.id, function(f)
        settings["AutoTeleport"] = f.on
        while f.on do
            wait(0)
            if NATIVE.IS_WAYPOINT_ACTIVE() then
                m.gfbhk("local.teleport.waypoint"):toggle()
                NATIVE.SET_WAYPOINT_OFF()
                wait(1000)
            end
        end
        settings["AutoTeleport"] = f.on
    end)
    Higurashi.AutoTeleport.on = settings["AutoTeleport"]

    Higurashi.RespawnAtPositionOfDeath = m.af("Respawn At Position Of Death", "toggle", Higurashi.Teleport.id, function(f)
        settings["RespawnAtPositionOfDeath"] = f.on
        while f.on do
            if NATIVE.IS_PED_DEAD_OR_DYING(NATIVE.PLAYER_PED_ID()) then
                local pos = higurashi.get_user_coords()
                while NATIVE.GET_ENTITY_HEALTH(NATIVE.PLAYER_PED_ID()) ~= NATIVE.GET_PED_MAX_HEALTH(NATIVE.PLAYER_PED_ID()) do
                    wait(0)
                end
                higurashi.teleport_to(pos)
                return
            end
            wait(0)
        end
        settings["RespawnAtPositionOfDeath"] = f.on
    end)
    Higurashi.RespawnAtPositionOfDeath.on = settings["RespawnAtPositionOfDeath"]

    local function TeleportMazeBankTowerTop()
        higurashi.teleport_to(v3(-75.392, -819.270, 328.175))
    end
    m.af("Teleport Maze Bak Tower Top", "action", Higurashi.Teleport.id, TeleportMazeBankTowerTop)

    Higurashi.Miscellaneous = m.af("Miscellaneous", "parent", Higurashi.Self.id)
    Higurashi.Miscellaneous.hint = ""

    m.af("Clear Ped Tasks", "action", Higurashi.Miscellaneous.id, function(f)
        NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
    end)

    Higurashi.Shinobi = m.af("Shinobi Footsteps", "action_value_str", Higurashi.Miscellaneous.id, function(f)
        if f.value == 0 then
            NATIVE.SET_PED_FOOTSTEPS_EVENTS_ENABLED(NATIVE.PLAYER_PED_ID(),
                false)
        elseif f.value == 1 then
            NATIVE.SET_PED_FOOTSTEPS_EVENTS_ENABLED(NATIVE.PLAYER_PED_ID(), true)
        end
    end):set_str_data({ "On", "Off" })

    m.af("Police Ignore Me", "action_value_str", Higurashi.Miscellaneous.id, function(f)
        if f.value == 0 then
            NATIVE.SET_POLICE_IGNORE_PLAYER(NATIVE.PLAYER_ID(), true)
        elseif f.value == 1 then
            NATIVE.SET_POLICE_IGNORE_PLAYER(NATIVE.PLAYER_ID(), false)
        end
    end):set_str_data({ "On", "Off" })

    m.af("Crouch", "value_str", Higurashi.Miscellaneous.id, function(f)
        local Crouching = false
        while f.on do
            NATIVE.DISABLE_CONTROL_ACTION(0, 36, true)
            if NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36) and not Crouching and
                not player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) then
                Crouching = true
                NATIVE.RESET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(), 0.0)
                NATIVE.DISABLE_AIM_CAM_THIS_UPDATE()
                NATIVE.SET_PED_CAN_PLAY_AMBIENT_ANIMS(NATIVE.PLAYER_PED_ID(),
                    false)
                NATIVE.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(
                    NATIVE.PLAYER_PED_ID(), false)
                NATIVE.SET_THIRD_PERSON_AIM_CAM_NEAR_CLIP_THIS_UPDATE(-10.0)
                NATIVE.REQUEST_ANIM_SET("move_ped_crouched")
                NATIVE.SET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(),
                    "move_ped_crouched", (f.value ==
                        0 and 1.0) or
                    (f.value == 1 and 0.0))
                NATIVE.REQUEST_ANIM_SET("move_ped_crouched_strafing")
                NATIVE.SET_PED_STRAFE_CLIPSET(NATIVE.PLAYER_PED_ID(),
                    "move_ped_crouched_strafing")
            elseif NATIVE.IS_DISABLED_CONTROL_JUST_PRESSED(0, 36) and Crouching and
                not player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) then
                Crouching = false
                NATIVE.SET_PED_CAN_PLAY_AMBIENT_ANIMS(NATIVE.PLAYER_PED_ID(),
                    true)
                NATIVE.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(
                    NATIVE.PLAYER_PED_ID(), true)
                NATIVE.REMOVE_ANIM_SET("move_ped_crouched")
                NATIVE.REMOVE_ANIM_SET("move_ped_crouched_strafing")
                NATIVE.RESET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(),
                    (f.value == 0 and 0.5) or
                    (f.value == 1 and 0.0))
                NATIVE.RESET_PED_STRAFE_CLIPSET(NATIVE.PLAYER_PED_ID())
            end
            wait(0)
        end
        NATIVE.SET_PED_CAN_PLAY_AMBIENT_ANIMS(NATIVE.PLAYER_PED_ID(), true)
        NATIVE.SET_PED_CAN_PLAY_AMBIENT_BASE_ANIMS(NATIVE.PLAYER_PED_ID(), true)
        NATIVE.REMOVE_ANIM_SET("move_ped_crouched")
        NATIVE.REMOVE_ANIM_SET("move_ped_crouched_strafing")
        NATIVE.RESET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(),
            (f.value == 0 and 0.5) or
            (f.value == 1 and 0.0))
        NATIVE.RESET_PED_STRAFE_CLIPSET(NATIVE.PLAYER_PED_ID())
        NATIVE.ENABLE_CONTROL_ACTION(0, 36, true)
    end):set_str_data({ "Normal", "Fast" })

    m.af("Prone", "toggle", Higurashi.Miscellaneous.id, function(f)
        if f.on then
            if not player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) and
                not NATIVE.IS_PED_RAGDOLL(NATIVE.PLAYER_PED_ID()) and
                not NATIVE.IS_ENTITY_DEAD(NATIVE.PLAYER_PED_ID()) then
                NATIVE.REQUEST_ANIM_DICT("missfbi3_sniping")
                NATIVE.REQUEST_ANIM_SET("prone_michael")
                NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
                ai.task_play_anim(NATIVE.PLAYER_PED_ID(), "missfbi3_sniping",
                    "prone_michael", 1, 0, 1000, 1, 0, true, true,
                    true)
                wait(100)
                while f.on and not NATIVE.IS_ENTITY_DEAD(NATIVE.PLAYER_PED_ID()) do
                    wait(0)
                end
            end
        end
        f.on = false
        if not player.is_player_in_any_vehicle(NATIVE.PLAYER_ID()) and
            not NATIVE.IS_PED_RAGDOLL(NATIVE.PLAYER_PED_ID()) and
            not NATIVE.IS_ENTITY_DEAD(NATIVE.PLAYER_PED_ID()) then
            NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(NATIVE.PLAYER_PED_ID())
        end
    end)

    m.af("Spinbot", "toggle", Higurashi.Miscellaneous.id, function(f)
        if f.on then
            NATIVE.APPLY_FORCE_TO_ENTITY(NATIVE.PLAYER_PED_ID(), 5, 0.0, 0.0, 150.0, 0, 0, 0, 0, true, false, true, false, true)
            wait(10)
            return HANDLER_CONTINUE
        end
    end)

    Higurashi.AntiGuidedMissile = m.af("Anti Guided Missiles", "toggle", Higurashi.Miscellaneous.id, function(f)
        while f.on do
            wait(0)
            for _, objs in pairs(object.get_all_objects()) do
                if NATIVE.GET_ENTITY_MODEL(objs) == 1262355818 then
                    if NATIVE.GET_BLIP_FROM_ENTITY(objs) == 0 then
                        local proj_blip = NATIVE.ADD_BLIP_FOR_ENTITY(objs)
                        NATIVE.SET_BLIP_SPRITE(proj_blip, 443)
                        NATIVE.SET_BLIP_COLOUR(proj_blip, 75)
                    end
                end
            end
            wait(200)
        end
        return HANDLER_POP
    end)

    m.af("Remove All Air Defense", "toggle", Higurashi.Miscellaneous.id, function(f)
        if f.on then
            NATIVE.REMOVE_ALL_AIR_DEFENCE_SPHERES()
            wait(600)
            return HANDLER_CONTINUE
        end
        return HANDLER_POP
    end)

    Higurashi.RevengeKill = m.af("Revenge Kill", "toggle", Higurashi.Miscellaneous.id, function(f)
        -- settings["RevengeKill"] = true
        while f.on do
            wait(0)
            if NATIVE.IS_PLAYER_DEAD(NATIVE.PLAYER_ID()) then
                local pid
                for i in higurashi.players() do
                    if NATIVE.PLAYER_ID() ~= i and
                        NATIVE.HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(
                            NATIVE.PLAYER_PED_ID(), NATIVE.GET_PLAYER_PED(i),
                            true) then -- entity.has_entity_been_damaged_by_entity(NATIVE.PLAYER_PED_ID(), NATIVE.GET_PLAYER_PED(i))
                        pid = i
                    end
                end
                if pid then
                    local blame = NATIVE.PLAYER_PED_ID()
                    local pos = higurashi.get_player_coords(pid)
                    NATIVE.PLAY_SOUND_FROM_COORD(-1, "DLC_XM_Explosions_Orbital_Cannon", pos.x, pos.y, pos.z, "", true, 100, true)
                    higurashi.set_ptfx_asset("scr_xm_orbital")
                    --NATIVE.USE_PARTICLE_FX_ASSET("scr_xm_orbital")
                    local ptfx1 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("scr_xm_orbital_blast", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 3.0, false, false, false, false)
                    fire.add_explosion(pos, 82, true, false, 2, blame)
                    fire.add_explosion(pos, 47, true, false, 2, blame)
                    fire.add_explosion(pos, 48, true, false, 2, blame)
                    fire.add_explosion(pos, 49, true, false, 2, blame)
                    fire.add_explosion(pos, 59, true, false, 2, blame)
                    fire.add_explosion(pos + v3(-10.0, 0.0, 5.0), 59, true, false, 2, blame)
                    fire.add_explosion(pos + v3(0.0, -10.0, 5.0), 59, true, false, 2, blame)
                    fire.add_explosion(pos + v3(10.0, 0.0, 5.0), 59, true, false, 3, blame)
                    fire.add_explosion(pos + v3(0.0, 10.0, 5.0), 59, true, false, 3, blame)
                    wait(100)
                    higurashi.set_ptfx_asset("scr_xm_submarine")
                    --NATIVE.USE_PARTICLE_FX_ASSET("scr_xm_submarine")
                    local ptfx2 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("scr_xm_submarine_explosion", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 8.0, false, false, false, false)
                    fire.add_explosion(pos, 58, true, false, 2, blame)
                    fire.add_explosion(pos, 82, true, false, 2, blame)
                    fire.add_explosion(pos, 83, true, false, 2, blame)
                    higurashi.set_ptfx_asset("core")
                    --NATIVE.USE_PARTICLE_FX_ASSET("core")
                    local ptfx3 = NATIVE.START_PARTICLE_FX_LOOPED_AT_COORD("exp_grd_molotov", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 6.0, false, false, false, false)
                    wait(1500)
                    NATIVE.REMOVE_NAMED_PTFX_ASSET("scr_xm_orbital")
                    NATIVE.REMOVE_NAMED_PTFX_ASSET("scr_xm_submarine")
                    NATIVE.REMOVE_NAMED_PTFX_ASSET("core")
                    while NATIVE.IS_PLAYER_DEAD(NATIVE.PLAYER_ID()) do
                        wait(0)
                    end
                end
            end
            wait(100)
        end
        settings["RevengeKill"] = f.on
        return HANDLER_CONTINUE
    end)

    Higurashi.RevengeKill = settings["RevengeKill"]

    m.af("Burning Man", "action_value_str", Higurashi.Miscellaneous.id, function(f)
        if f.value == 0 then
            NATIVE.START_ENTITY_FIRE(NATIVE.PLAYER_PED_ID())
        elseif f.value == 1 and NATIVE.IS_ENTITY_ON_FIRE(NATIVE.PLAYER_PED_ID()) then
            NATIVE.STOP_ENTITY_FIRE(NATIVE.PLAYER_PED_ID())
        end
    end):set_str_data({ "On", "Off" })

    m.af("Drunk", "toggle", Higurashi.Miscellaneous.id, function(f)
        if f.on then
            NATIVE.SHAKE_GAMEPLAY_CAM("DRUNK_SHAKE", 1)
            NATIVE.SET_TIMECYCLE_MODIFIER("Drunk")
            NATIVE.REQUEST_ANIM_SET("move_m@drunk@verydrunk")
            while not streaming.has_anim_set_loaded("move_m@drunk@verydrunk") do
                NATIVE.REQUEST_ANIM_SET("move_m@drunk@verydrunk")
                wait(0)
            end
            NATIVE.SET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(), "move_m@drunk@verydrunk", 0.0)
            NATIVE.SET_PED_IS_DRUNK(NATIVE.PLAYER_PED_ID(), true)
            NATIVE.SET_ENTITY_MOTION_BLUR(NATIVE.PLAYER_PED_ID(), true)
            while f.on do
                if not NATIVE.IS_PED_RAGDOLL(NATIVE.PLAYER_PED_ID()) then
                    NATIVE.SET_PED_RAGDOLL_ON_COLLISION(NATIVE.PLAYER_PED_ID(), true)
                else
                    NATIVE.SET_PED_RAGDOLL_ON_COLLISION(NATIVE.PLAYER_PED_ID(), false)
                    wait(5000)
                end
                wait(0)
            end
        end
        if not f.on then
            NATIVE.RESET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(), 0.0)
            NATIVE.SET_TIMECYCLE_MODIFIER("DEFAULT")
            NATIVE.SHAKE_GAMEPLAY_CAM("DRUNK_SHAKE", 0)
            NATIVE.SET_PED_IS_DRUNK(NATIVE.PLAYER_PED_ID(), false)
            NATIVE.SET_PED_RAGDOLL_ON_COLLISION(NATIVE.PLAYER_PED_ID(), false)
            NATIVE.SET_ENTITY_MOTION_BLUR(NATIVE.PLAYER_PED_ID(), false)
        end
    end)

    m.af("Spawn Pets", "action_value_str", Higurashi.Miscellaneous.id, function(f)
        local model_hashes
        if f.value == 0 then
            model_hashes = { 0x1250D7BA, 0xE71D5E68 }
        elseif f.value == 1 then
            model_hashes = { 0x431FC24C, 0x4E8F95A2 }
        elseif f.value == 2 then
            model_hashes = { 0xA8683715, 0xC2D06F53 }
        elseif f.value == 3 then
            higurashi.remove_entity(higurashi.spawned_entities["pet"])
            return
        end
        local me = NATIVE.PLAYER_ID()
        local offset, pos = v3(), v3()
        local pos = higurashi.get_user_coords()
        for _, pets in pairs(model_hashes) do
            higurashi.spawned_entities["pet"][#higurashi.spawned_entities["pet"] + 1] = higurashi.create_ped(26, pets, pos + offset, 0, true, false, true, false)
        end
        NATIVE.TASK_FOLLOW_TO_OFFSET_OF_ENTITY(higurashi.spawned_entities["pet"][1], NATIVE.PLAYER_PED_ID(), pos.x, pos.y, pos.z, 2.0, 1000, 2.5, true)
        NATIVE.SET_PED_AS_GROUP_MEMBER(higurashi.spawned_entities["pet"][1], NATIVE.GET_PLAYER_GROUP(me))
        NATIVE.SET_PED_NEVER_LEAVES_GROUP(higurashi.spawned_entities["pet"][1], true)
        ped.set_ped_can_switch_weapons(higurashi.spawned_entities["pet"][1], true)
        for x in higurashi.players() do
            if x ~= me then
                NATIVE.SET_RELATIONSHIP_BETWEEN_GROUPS(0x522B964A, NATIVE.GET_PLAYER_GROUP(x), NATIVE.GET_PLAYER_GROUP(me))
                NATIVE.SET_RELATIONSHIP_BETWEEN_GROUPS(0x522B964A, NATIVE.GET_PLAYER_GROUP(me), NATIVE.GET_PLAYER_GROUP(x))
            end
        end
    end):set_str_data({ "Cougar / Lion", "Shepherd / Huskey", "Chimp / Rhesus", "Delete All Pets" })

    local walkstyles = {
        { name = "ANIM_GROUP_MOVE_BALLISTIC" },
        { name = "ANIM_GROUP_MOVE_LEMAR_ALLEY" },
        { name = "clipset@move@trash_fast_turn" },
        { name = "FEMALE_FAST_RUNNER" },
        { name = "missfbi4prepp1_garbageman" },
        { name = "move_characters@franklin@fire" },
        { name = "move_characters@Jimmy@slow@" },
        { name = "move_characters@michael@fire" },
        { name = "move_f@flee@a" },
        { name = "move_f@scared" },
        { name = "move_f@sexy@a" },
        { name = "move_heist_lester" },
        { name = "move_injured_generic" },
        { name = "move_lester_CaneUp" },
        { name = "move_m@bag" },
        { name = "MOVE_M@BAIL_BOND_NOT_TAZERED" },
        { name = "MOVE_M@BAIL_BOND_TAZERED" },
        { name = "move_m@brave" },
        { name = "move_m@casual@d" },
        { name = "move_m@drunk@moderatedrunk" },
        { name = "MOVE_M@DRUNK@MODERATEDRUNK" },
        { name = "MOVE_M@DRUNK@MODERATEDRUNK_HEAD_U}" },
        { name = "MOVE_M@DRUNK@SLIGHTLYDRUNK" },
        { name = "MOVE_M@DRUNK@VERYDRUNK" },
        { name = "move_m@fire" },
        { name = "move_m@gangster@var_e" },
        { name = "move_m@gangster@var_f" },
        { name = "move_m@gangster@var_i" },
        { name = "move_m@JOG@" },
        { name = "MOVE_M@PRISON_GAURD" },
        { name = "MOVE_P_M_ONE" },
        { name = "MOVE_P_M_ONE_BRIEFCASE" },
        { name = "move_p_m_zero_janitor" },
        { name = "move_p_m_zero_slow" },
        { name = "move_ped_bucket" },
        { name = "move_ped_crouched" },
        { name = "move_ped_mop" },
        { name = "MOVE_M@FEMME@" },
        { name = "MOVE_F@FEMME@" },
        { name = "MOVE_M@GANGSTER@NG" },
        { name = "MOVE_F@GANGSTER@NG" },
        { name = "MOVE_M@POSH@" },
        { name = "MOVE_F@POSH@" },
        { name = "MOVE_M@TOUGH_GUY@" },
        { name = "MOVE_F@TOUGH_GUY@" },
    }

    Higurashi.WalkStyles = m.af("Walkstyles", "parent", Higurashi.Miscellaneous.id)

    m.af("Reset Walkstyle", "action", Higurashi.WalkStyles.id, function(f)
        NATIVE.RESET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(), 1.0)
    end)

    for k, v in pairs(walkstyles) do
        m.af(v.name, "action", Higurashi.WalkStyles.id, function(f)
            while not NATIVE.HAS_CLIP_SET_LOADED(v.name) do
                NATIVE.REQUEST_CLIP_SET(v.name)
                yield()
            end
            NATIVE.RESET_PED_WEAPON_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID())
            NATIVE.RESET_PED_STRAFE_CLIPSET(NATIVE.PLAYER_PED_ID())
            NATIVE.SET_PED_MOVEMENT_CLIPSET(NATIVE.PLAYER_PED_ID(), v.name, 1.0)
        end)
    end

    Higurashi.Movement = m.af("Movement", "parent", Higurashi.Miscellaneous.id)
    Higurashi.Movement.hint = ""

    Higurashi.FastRoll = m.af("Fast Roll", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            local stat_hash = joaat(higurashi.get_last_mp("SHOOTING_ABILITY"))
            stats.stat_set_int(stat_hash, 200, true)
            wait(200)
        end
        settings["FastRoll"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastRoll.on = settings["FastRoll"]

    Higurashi.FastClimb = m.af("Fast Climb", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 1) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastClimb"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastClimb.on = settings["FastClimb"]

    Higurashi.FastVehicleTasks = m.af("Fast Vehicle Enter/Exit", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if (NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 160) or
                    NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 167) or
                    NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 165)) and
                not NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 195) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastVehicleTasks"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastVehicleTasks.on = settings["FastVehicleTasks"]

    Higurashi.FastThermalSwap = m.af("Fast Thermal Swap", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 92) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastThermalSwap"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastThermalSwap.on = settings["FastThermalSwap"]

    Higurashi.FastWeaponSwap = m.af("Fast Weapon Swap", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 56) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastWeaponSwap"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastWeaponSwap.on = settings["FastWeaponSwap"]

    Higurashi.FastMelee = m.af("Fast Melee", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 130) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastMelee"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastMelee.on = settings["FastMelee"]

    Higurashi.FastMount = m.af("Fast Mount", "toggle", Higurashi.Movement.id, function(f)
        if f.on then
            if NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 50) or
                NATIVE.GET_IS_TASK_ACTIVE(NATIVE.PLAYER_PED_ID(), 51) then
                NATIVE.FORCE_PED_AI_AND_ANIMATION_UPDATE(NATIVE.PLAYER_PED_ID())
            end
        end
        settings["FastMount"] = f.on
        if not f.on then return HANDLER_POP end
        return HANDLER_CONTINUE
    end)
    Higurashi.FastMount.on = settings["FastMount"]

    if Dev then
        Higurashi.DeveloperFeatures2 = m.af(c.green2 .. "Developer Features", "parent", Higurashi.Parent2.id)
        Higurashi.CustomAnimation = m.af("Custom Animation", "parent", Higurashi.DeveloperFeatures2.id)

        local selected_animdict, selected_anim = nil, nil

        m.af("Set Custom Anim dict", "action", Higurashi.CustomAnimation.id, function(f)
            return input_handler("Set Custom Anim dict", "Input Anim Dict.", function(s)
                selected_animdict = s
            end)
        end)

        m.af("Set Custom Anim", "action", Higurashi.CustomAnimation.id, function(f)
            return input_handler("Set Custom Anim", "Input Anim Name.", function(s)
                selected_anim = s
            end)
        end)

        m.af("Selected Animation", "action_value_str", Higurashi.CustomAnimation.id, function(f)
            if f.value == 0 then
                if selected_animdict and selected_anim then
                    higurashi.request_anim_dict(selected_animdict)
                    NATIVE.TASK_PLAY_ANIM(NATIVE.PLAYER_PED_ID(), selected_animdict, selected_anim, 1.0, 1.0, -1, 3, 100.0, false, false, false)
                    NATIVE.REMOVE_ANIM_DICT(selected_animdict)
                else
                    m.n("Invalid animation.", title, 3, c.red1)
                end
            elseif f.value == 1 then
                NATIVE.CLEAR_PED_TASKS(NATIVE.PLAYER_PED_ID())
                higurashi.delete_obj_from_player(NATIVE.PLAYER_ID())
            end
        end):set_str_data({ "Play", "Stop" })

        Higurashi.EntitySpawner = m.af("Entity Spawner", "parent", Higurashi.DeveloperFeatures2.id)

        local custom_ped, custom_veh, custom_obj, custom_world_obj = {}, {}, {}, {}

        m.af("Custom Pedestrian", "action_value_str", Higurashi.EntitySpawner.id, function(f)
            if f.value == 0 then
                return input_handler("Enter the name of the ped.", "Input Anim Name.", function(s)
                    selected_ped = s
                    custom_ped = higurashi.create_ped(-1, joaat(selected_ped), higurashi.get_user_coords(), 0, true, false, true, false)
                    if NATIVE.DOES_ENTITY_EXIST(custom_ped) then
                        m.n("Spawned " .. selected_ped, title, 3, c.green1)
                    else
                        m.n("Failed to spawn " .. selected_ped, title, 3, c.red1)
                    end
                end)
            elseif f.value == 1 then
                higurashi.remove_entity({ custom_ped })
                if not NATIVE.DOES_ENTITY_EXIST(custom_ped) then
                    m.n("Deleted " .. selected_ped, title, 3, c.green1)
                else
                    m.n("Failed to delete " .. selected_ped, title, 3, c.red1)
                    higurashi.remove_entity({ custom_ped })
                end
            elseif f.value == 2 then
                local ped_pos = NATIVE.GET_ENTITY_COORDS(custom_ped, false)
                m.n(string.format("%f, %f, %f", ped_pos.x, ped_pos.y, ped_pos.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", ped_pos.x, ped_pos.y, ped_pos.z))
            elseif f.value == 3 then
                local ped_rot = NATIVE.GET_ENTITY_ROTATION(custom_ped, 5)
                m.n(string.format("%f, %f, %f", ped_rot.x, ped_rot.y, ped_rot.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", ped_rot.x, ped_rot.y, ped_rot.z))
            end
        end):set_str_data({ "Spawn", "Delete", "Get Ped Coords", "Get Ped Rotation" })

        m.af("Custom Vehicle", "action_value_str", Higurashi.EntitySpawner.id, function(f)
            if f.value == 0 then
                local r, s = input.get("Enter the name of the vehicle.", "", 250, 0)
                if r == 1 then
                    return HANDLER_CONTINUE
                end
                if r == 2 then
                    m.n("Input canceled.", title, 3, c.yellow1)
                    return HANDLER_POP
                end
                selected_veh = s
                custom_veh = higurashi.create_vehicle(joaat(selected_veh), higurashi.get_user_coords(), 0, true, false, false)
                if NATIVE.DOES_ENTITY_EXIST(custom_veh) then
                    m.n("Spawned " .. selected_veh, title)
                else
                    m.n("Failed to spawn " .. selected_veh, title, 3, c.red1)
                end
            elseif f.value == 1 then
                higurashi.remove_entity({ custom_veh })
                if not NATIVE.DOES_ENTITY_EXIST(custom_veh) then
                    m.n("Deleted " .. selected_veh, title, 3, c.green1)
                else
                    m.n("Failed to delete " .. selected_veh, title, 3, c.red1)
                    higurashi.remove_entity({ custom_veh })
                end
            elseif f.value == 2 then
                local veh_pos = NATIVE.GET_ENTITY_COORDS(custom_veh, false)
                m.n(string.format("%f, %f, %f", veh_pos.x, veh_pos.y, veh_pos.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", veh_pos.x, veh_pos.y, veh_pos.z))
            elseif f.value == 3 then
                local veh_rot = NATIVE.GET_ENTITY_ROTATION(custom_veh, 5)
                m.n(string.format("%f, %f, %f", veh_rot.x, veh_rot.y, veh_rot.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", veh_rot.x, veh_rot.y, veh_rot.z))
            end
        end):set_str_data({ "Spawn", "Delete", "Get Vehicle Coords", "Get Vehicle Rotation" })

        m.af("Custom Object", "action_value_str", Higurashi.EntitySpawner.id, function(f)
            if f.value == 0 then
                local r, s = input.get("Enter the name of the object.", "", 250, 0)
                if r == 1 then
                    return HANDLER_CONTINUE
                end
                if r == 2 then
                    m.n("Input canceled.", title, 3, c.yellow1)
                    return HANDLER_POP
                end
                selected_obj = s
                custom_obj = higurashi.create_object(joaat(selected_obj), higurashi.get_user_coords(), true, false, false, true, false)
                NATIVE.SET_ENTITY_INVINCIBLE(custom_obj, true)
                if NATIVE.DOES_ENTITY_EXIST(custom_obj) then
                    m.n("Spawned " .. selected_obj, title, 3, c.green1)
                else
                    m.n("Failed to spawn " .. selected_obj, title, 3, c.red1)
                end
            elseif f.value == 1 then
                higurashi.remove_entity({ custom_obj })
                if not NATIVE.DOES_ENTITY_EXIST(custom_obj) then
                    m.n("Deleted " .. selected_obj, title, 3, c.green1)
                else
                    m.n("Failed to delete " .. selected_obj, title, 3, c.red1)
                    higurashi.remove_entity({ custom_obj })
                end
            elseif f.value == 2 then
                local obj_pos = NATIVE.GET_ENTITY_COORDS(custom_obj, false)
                m.n(string.format("%f, %f, %f", obj_pos.x, obj_pos.y, obj_pos.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", obj_pos.x, obj_pos.y, obj_pos.z))
            elseif f.value == 3 then
                local obj_rot = NATIVE.GET_ENTITY_ROTATION(custom_obj, 5)
                m.n(string.format("%f, %f, %f", obj_rot.x, obj_rot.y, obj_rot.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", obj_rot.x, obj_rot.y, obj_rot.z))
            end
        end):set_str_data({ "Spawn", "Delete", "Get Object Coords", "Get Object Rotation" })

        m.af("Custom World Object", "action_value_str", Higurashi.EntitySpawner.id, function(f)
            if f.value == 0 then
                local r, s = input.get("Enter the name of the world object.", "", 250, 0)
                if r == 1 then
                    return HANDLER_CONTINUE
                end
                if r == 2 then
                    m.n("Input canceled.", title, 3, c.yellow1)
                    return HANDLER_POP
                end
                selected_world_obj = s
                custom_world_obj = higurashi.create_world_object(joaat(selected_world_obj), higurashi.get_user_coords(), true, false, true, false)
                if NATIVE.DOES_ENTITY_EXIST(custom_world_obj) then
                    m.n("Spawned " .. selected_world_obj, title, 3, c.green1)
                else
                    m.n("Failed to spawn " .. selected_world_obj, title, 3, c.red1)
                end
            elseif f.value == 1 then
                higurashi.remove_entity({ custom_world_obj })
                if not NATIVE.DOES_ENTITY_EXIST(custom_world_obj) then
                    m.n("Deleted " .. selected_world_obj, title, 3, c.green1)
                else
                    m.n("Failed to delete " .. selected_world_obj, title, 3, c.red1)
                    higurashi.remove_entity({ custom_world_obj })
                end
            elseif f.value == 2 then
                local obj_pos = NATIVE.GET_ENTITY_COORDS(custom_world_obj, false)
                m.n(string.format("%f, %f, %f", obj_pos.x, obj_pos.y, obj_pos.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", obj_pos.x, obj_pos.y, obj_pos.z))
            elseif f.value == 3 then
                local obj_rot = NATIVE.GET_ENTITY_ROTATION(custom_world_obj, 5)
                m.n(string.format("%f, %f, %f", obj_rot.x, obj_rot.y, obj_rot.z), title, 3, c.blue1)
                utils.to_clipboard(string.format("%f, %f, %f", obj_rot.x, obj_rot.y, obj_rot.z))
            end
        end):set_str_data({ "Spawn", "Delete", "Get Object Coords", "Get Object Rotation" })

        Higurashi.FriendLists = m.af("Friend List", "parent", Higurashi.DeveloperFeatures2.id)
        m.ct(function()
            for i = 0, NATIVE.NETWORK_GET_FRIEND_COUNT() - 1 do
                local friendName = NATIVE.NETWORK_GET_FRIEND_NAME_FROM_INDEX(i)
                Higurashi.FriendName = m.af(tostring(friendName), "parent", Higurashi.FriendLists.id)

                FriendName = function(f, data)
                    while f.on do
                        local featData = {
                            { "Online:", tostring(NATIVE.NETWORK_IS_FRIEND_INDEX_ONLINE(i)) },
                            { "SCID:", tostring(NATIVE.NETWORK_GET_FRIEND_SCID(i)) },
                        }
                        m.n(featData)
                        wait(0)
                    end
                end

                m.af("Join Session", "action", Higurashi.FriendName.id, function(f)
                    if NATIVE.NETWORK_IS_FRIEND_INDEX_ONLINE(i) then
                        local friendSCID = NATIVE.NETWORK_GET_FRIEND_SCID(i)
                        if friendSCID ~= 0 then
                            NATIVE.NETWORK_JOIN_TRANSITION(friendSCID)
                            m.n("Joining friend's session: " .. friendName)
                        else
                            m.n("Failed to get a valid SCID for: " .. friendName)
                        end
                    else
                        m.n("Player is not online: " .. friendName)
                    end
                end)

                m.af("Invite To Session", "action", Higurashi.FriendName.id, function(f)
                    local friendSCID = NATIVE.NETWORK_GET_FRIEND_SCID(i)
                    if friendSCID ~= 0 then
                        local success = NATIVE.NETWORK_SEND_INVITE_VIA_PRESENCE(friendSCID)
                        if success then
                            m.n("Invitation successfully sent to: " .. friendName)
                        else
                            m.n("Failed to send invitation to: " .. friendName)
                        end
                    else
                        m.n("Failed to get SCID for: " .. friendName)
                    end
                end)
            end
        end)

        Higurashi.BlockControlVehicle = m.af("Block Control Owned Vehicle", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local veh = higurashi.get_user_vehicle(false)
            if veh ~= 0 then
                if higurashi.request_control_of_entity(veh) then
                    local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
                    NATIVE.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
                    NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, false)
                    NATIVE.SET_NETWORK_ID_CAN_BE_REASSIGNED(net_id, false)
                else
                    m.n("Control timeout.")
                end
            end
        end)

        m.af("SET_IGNORE_LOW_PRIORITY_SHOCKING_EVENTS", "toggle", Higurashi.Account.id, function(f)
            while f.on do
                NATIVE.SET_IGNORE_LOW_PRIORITY_SHOCKING_EVENTS(NATIVE.PLAYER_ID(), f.on)
                wait(250)
            end
        end)

        AIDrivingStart = m.af("Spawn Taxi", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            local veh, driver_ped

            if f.on then
                -- タクシーをプレイヤーの近くにスポーン
                veh = higurashi.create_vehicle(joaat("taxi"), higurashi.get_user_coords() + v3(2.0, 0.0, 0.0), higurashi.user_ped_heading(), true, false, false, false, false, false)
                wait(0)
                -- ドライバーをスポーン
                driver_ped = higurashi.create_ped(-1, joaat("G_M_M_Zombie_01"), higurashi.get_user_coords() + v3(2.0, 0.0, 0.0), higurashi.user_ped_heading(), true, false, false, false, false, false)

                -- ドライバーをタクシーに乗せる
                NATIVE.SET_PED_INTO_VEHICLE(driver_ped, veh, -1)

                -- 運転席に乗れなくするためにドアをロックする
                NATIVE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, NATIVE.PLAYER_ID(), true)

                -- 運転手の設定
                NATIVE.TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(driver_ped, true)
                NATIVE.SET_PED_CAN_BE_TARGETTED(driver_ped, false)
                NATIVE.SET_PED_CAN_RAGDOLL(driver_ped, false)
                NATIVE.SET_DRIVER_ABILITY(driver_ped, 1.0)
                NATIVE.SET_DRIVER_AGGRESSIVENESS(driver_ped, 0.0)

                -- ウェイポイントが設定されているか確認
                if NATIVE.GET_BLIP_INFO_ID_TYPE(8) ~= 4 then
                    -- ウェイポイントが設定されていない場合はランダムにドライブ
                    NATIVE.TASK_VEHICLE_DRIVE_WANDER(driver_ped, veh, 20.0, 786603)
                else
                    -- ウェイポイントが設定されている場合はその地点にドライブ
                    local waypoint = NATIVE.GET_BLIP_INFO_ID_COORD(8)
                    NATIVE.TASK_VEHICLE_DRIVE_TO_COORD(driver_ped, veh, waypoint.x, waypoint.y, waypoint.z, 20.0, 0, NATIVE.GET_ENTITY_MODEL(veh), 786603, 1.0, true)
                end

                -- ウェイポイント到達後の処理（オプション）
                while f.on do
                    if NATIVE.GET_BLIP_INFO_ID_TYPE(8) == 4 then
                        local waypoint = NATIVE.GET_BLIP_INFO_ID_COORD(8)
                        if NATIVE.GET_DISTANCE_BETWEEN_COORDS(waypoint.x, waypoint.y, waypoint.z, NATIVE.GET_ENTITY_COORDS(veh, false)) < 10.0 then
                            -- ウェイポイントに到達した場合の処理
                            NATIVE.TASK_VEHICLE_PARK(driver_ped, veh, waypoint.x, waypoint.y, waypoint.z, NATIVE.GET_ENTITY_HEADING(veh), 0, 20.0, true)
                            f.on = false
                            break
                        end
                    end
                    wait(500)
                end
            else
                -- タクシーとドライバーを削除
                if veh then
                    NATIVE.SET_ENTITY_AS_NO_LONGER_NEEDED(veh)
                    higurashi.remove_entity({ veh })
                end

                if driver_ped then
                    NATIVE.SET_ENTITY_AS_NO_LONGER_NEEDED(driver_ped)
                    higurashi.remove_entity({ driver_ped })
                end
            end
            return HANDLER_CONTINUE
        end)
        function higurashi.exterminate_attacking_players()
            local player_ped = NATIVE.PLAYER_PED_ID()
            local player_pos = NATIVE.GET_ENTITY_COORDS(player_ped, true)

            for pid in higurashi.players() do
                local attacker_ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                if NATIVE.DOES_ENTITY_EXIST(attacker_ped) and attacker_ped ~= player_ped then
                    if NATIVE.IS_PED_IN_MELEE_COMBAT(attacker_ped) and NATIVE.GET_MELEE_TARGET_FOR_PED(attacker_ped) == player_ped then
                        higurashi.shoot_bullet(higurashi.get_player_bone_coords(pid, 11816), higurashi.get_player_bone_coords(pid, 39317), 1, true, joaat("WEAPON_SNOWLAUNCHER"), higurashi.get_random_ped() or -1, true, false, 10000.0)
                    end
                end
            end
        end

        m.af("Exterminate Attacking Players", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            while f.on do
                higurashi.exterminate_attacking_players()
                wait(500)
            end
        end)
        m.af("Voice Chat Detection", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            while f.on do
                wait(0)
                for pid in higurashi.players() do
                    if NATIVE.NETWORK_IS_PLAYER_TALKING(pid) then
                        m.n(higurashi.get_user_name(pid) .. " is talking.")
                    end
                end
                wait(100)
            end
        end)

        m.af("Clear Projectiles", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            if f.on then
                NATIVE.CLEAR_AREA_OF_PROJECTILES(higurashi.get_user_coords(), 5000, 0)
                wait(60)
            end
            if not f.on then
                wait(60)
                return HANDLER_POP
            end
            return HANDLER_CONTINUE
        end)

        Higurashi.ClearTraffic = m.af("Clear Traffic", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            local pop_multiplier_id
            if f.on then
                local user_coords = higurashi.get_user_coords()
                pop_multiplier_id = NATIVE.ADD_POP_MULTIPLIER_SPHERE(user_coords.x, user_coords.y, user_coords.z, 5000.0, 0.0, 0.0, false, true)
                NATIVE.CLEAR_AREA(user_coords.x, user_coords.y, user_coords.z, 5000.0, true, false, false, true)
                wait(60)
            end
            if not f.on then
                if pop_multiplier_id then
                    NATIVE.REMOVE_POP_MULTIPLIER_SPHERE(pop_multiplier_id, false)
                end
                wait(60)
                return HANDLER_POP
            end
            return HANDLER_CONTINUE
        end)


        m.af("Delete Nearby Vehs", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local pos = higurashi.get_user_coords()
            local count = 0
            for _, veh in ipairs(vehicle.get_all_vehicles()) do
                if not NATIVE.IS_PED_A_PLAYER(NATIVE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)) then
                    local pos2 = NATIVE.GET_ENTITY_COORDS(veh, true)
                    local dist = NATIVE.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                    if dist <= 10000.0 then
                        higurashi.remove_entity({ veh })
                        count = count + 1
                    end
                end
            end
            m.n("Deleted " .. count .. " vehs", title, 3, c.blue1)
        end)


        m.af("Delete Nearby Peds", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local pos = higurashi.get_user_coords()
            local count = 0
            for _, ped in ipairs(ped.get_all_peds()) do
                if not NATIVE.IS_PED_A_PLAYER(ped) then
                    local pos2 = NATIVE.GET_ENTITY_COORDS(ped, true)
                    local dist = NATIVE.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                    if dist <= 10000.0 then
                        higurashi.remove_entity({ ped })
                        count = count + 1
                    end
                end
            end
            m.n("Deleted " .. count .. " peds", title, 3, c.blue1)
        end)

        m.af("Delete Nearby Objects", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local pos = higurashi.get_user_coords()
            local count = 0
            for _, objs in ipairs(object.get_all_objects()) do
                local pos2 = NATIVE.GET_ENTITY_COORDS(objs, 1)
                local dist = NATIVE.VDIST2(pos.x, pos.y, pos.z, pos2.x, pos2.y, pos2.z)
                if dist <= 10000.0 then
                    higurashi.remove_entity({ objs })
                    count = count + 1
                end
            end
            m.n("Deleted " .. count .. " objs", title, 3, c.blue1)
        end)

        Higurashi.StunIntruders = m.af("Stun Intruders", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            settings["StunIntruders"] = f.on
            while f.on do
                local playerVeh = NATIVE.GET_VEHICLE_PED_IS_IN(NATIVE.PLAYER_PED_ID(), false)
                if playerVeh ~= 0 then
                    for pid in higurashi.players() do
                        local ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
                        local veh = NATIVE.GET_VEHICLE_PED_IS_USING(ped)
                        if veh == playerVeh and NATIVE.GET_IS_TASK_ACTIVE(ped, 160) then --NATIVE.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(Pedped)
                            --NATIVE.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                            --NATIVE.SET_PED_TO_RAGDOLL(ped, 5000, 5000, 0, true, true, false)
                            NATIVE.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(higurashi.get_player_bone_coords(pid, 0, v3(0.0, 0.0, -0.5)), higurashi.get_player_bone_coords(pid, 0, v3(0.0, 0.0, 0.5)), 0, true, joaat("WEAPON_STUNGUN"), higurashi.get_random_ped(), false, true, 1.0)
                            m.n("Player " .. higurashi.get_user_name(pid) .. " was stunned for trying to enter your vehicle.", title, 3, c.yelow1)
                        end
                    end
                end
                wait(500)
            end
            settings["StunIntruders"] = false
        end)

        Higurashi.StunIntruders.on = settings["StunIntruders"]

        m.af("Take Control of Unowned Vehicles", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local player_id = NATIVE.PLAYER_ID()
            local all_vehicles = vehicle.get_all_vehicles()
            local unowned_vehicle_count = 0
            for _, veh in ipairs(all_vehicles) do
                if network.get_entity_net_owner(veh) == -1 then
                    unowned_vehicle_count = unowned_vehicle_count + 1
                    higurashi.force_control_of_entity(veh)
                    if not NATIVE.NETWORK_GET_ENTITY_IS_NETWORKED(veh) then
                        NATIVE.NETWORK_REGISTER_ENTITY_AS_NETWORKED(veh)
                    end
                    -- local net_id = NATIVE.NETWORK_GET_NETWORK_ID_FROM_ENTITY(veh)
                    local net_id = NATIVE.VEH_TO_NET(veh)
                    if net_id ~= 0 then
                        NATIVE.SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(net_id, player_id, true)
                        NATIVE.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES(net_id, true)
                        NATIVE.SET_NETWORK_ID_CAN_MIGRATE(net_id, true)
                    end
                end
            end

            m.n("Number of vehicles with no owner: " .. unowned_vehicle_count, title, 3, c.blue1)
        end)
        m.af("Enable Removed Vehicles", "action", Higurashi.DeveloperFeatures2.id, function(f)
            local offsets = {
                22565, 14708, 34371, 34373, 34451, 34349, 34527, 34533, 17356, 17372,
                34589, 35492, 34415, 34417, 34465, 34573, 34499, 34495, 34493, 34511,
                28191, 34501, 34333, 34551, 34553, 34409, 34365, 34569, 34571, 23726,
                34401, 17230, 25367, 34335, 34337, 34339, 34341, 34325, 18947, 18948,
                22564, 17229, 34367, 34331, 21603, 17364, 25369, 34431, 34453, 34497,
                25387, 34455, 34403, 17355, 34399, 34323, 34437, 23717, 17358, 17370,
                34467, 34433, 34435, 34351, 34411, 34587, 34565, 34523, 34369, 34563,
                34559, 34481, 19951, 34581, 34577, 22556, 34585, 34473, 25386, 22563,
                34457, 34513, 22557, 28201, 34405, 34541, 34459, 34535, 34429, 25383,
                34439, 34387, 34361, 34557, 34503, 34583, 28830, 28190, 25379, 17232,
                34353, 34555, 34597, 23729, 14703, 25385, 34471, 25396, 34443, 34441,
                25397, 34591, 34475, 34561, 25389, 34485, 34567, 34427, 34529, 34595,
                22560, 34505, 34355, 34357, 21607, 17363, 17373, 34483, 17223, 34507,
                34531, 21606, 22558, 22562, 34593, 34521, 34377, 34393, 34469, 34489,
                19953, 34509, 25393, 34463, 34461, 17366, 34515, 22561, 22554, 34519,
                34345, 34347, 34547, 34579, 28831, 34445, 34575, 34359, 34479, 23781,
                34539, 34383, 34381, 34379, 34545, 22551, 34343, 34549, 34525, 23780,
                34537, 34327, 29156, 20830, 17371, 25370, 17221, 34407, 34477, 26330,
                34375, 29605, 34487, 22566, 34397, 34543, 34517, 17369, 20828, 34423,
                34425, 34395, 34447, 34449, 25384, 17354, 25381, 34599,
            }

            for _, offset in ipairs(offsets) do
                script.set_global_i(262145 + offset, 1)
            end
        end)
        function SessionChanger(session)
            script.set_global_i(1575035, session)
            if session == -1 then
                script.set_global_i(1574591, -1) -- 1574589 + 2
            end
            yield(500)                           -- 0.5秒の待機
            script.set_global_i(1574589, 1)
            yield(500)                           -- 0.5秒の待機
            script.set_global_i(1574589, 0)
        end

        menu.add_feature("Switch to Session", "action_value_str", Higurashi.DeveloperFeatures2.id, function(f)
            if f.value == 0 then
                SessionChanger(-1)
            elseif f.value == 1 then
                SessionChanger(0)
            elseif f.value == 2 then
                SessionChanger(1)
            elseif f.value == 3 then
                SessionChanger(2)
            end
        end):set_str_data({ "Back To SP", "Find Public Session", "Create Public Session", "Find Crew Session" })

        Higurashi.DontWaitForMissionLauncher = m.af("Don't Wait For Mission Launcher", "toggle", Higurashi.DeveloperFeatures2.id, function(f)
            --settings["DontWaitForMissionLauncher"] = f.on
            while f.on do
                local player_id = NATIVE.PLAYER_ID()
                if not higurashi_globals.is_main_game_state_running(player_id) and higurashi_globals.get_transition_state() == 26 and higurashi_globals.is_freemode_active(player_id) then
                    script.set_global_i(157011, 27)
                end
                wait()
            end
        end)
        --Higurashi.DontWaitForMissionLauncher.on = settings["DontWaitForMissionLauncher"]
        Higurashi.DontWaitForMissionLauncher.hint = "This may cause some issues such as having no weapons when you spawn in or not being able to enter interiors."
    end

    m.af(c.orange2 .. "Script Information" .. c.default, "action", Higurashi.Parent2.id, function(f)
        NATIVE.PLAY_SOUND_FROM_ENTITY(-1, "FestiveGift", NATIVE.PLAYER_PED_ID(), "Feed_Message_Sounds", false, 50)
        higurashi.notify_map(title, "~v~Version: " .. script_version, "~v~Developer: Cynical Higurashi", "CHAR_SOCIAL_CLUB", 164)
    end)

    local function unload_hooks()
        if was_in_spectate then
            NATIVE.FREEZE_ENTITY_POSITION(NATIVE.PLAYER_PED_ID(), false)
            NATIVE.SET_MINIMAP_IN_SPECTATOR_MODE(true, NATIVE.PLAYER_PED_ID())
            NATIVE.CLEAR_FOCUS()
        end
        for i = 0, 31 do
            if player_script_hooks[i] then
                hook.remove_script_event_hook(player_script_hooks[i])
                player_script_hooks[i] = nil
            end
        end
        for i = 0, 31 do
            if player_net_hooks[i] then
                hook.remove_net_event_hook(player_net_hooks[i])
                player_net_hooks[i] = nil
            end
        end
        if karma_se_hook then
            hook.remove_script_event_hook(karma_se_hook)
            karma_se_hook = nil
        end
        if missile_event_hook then
            hook.remove_net_event_hook(missile_event_hook)
            missile_event_hook = nil
        end
        if typing_event_hook then
            hook.remove_net_event_hook(typing_event_hook)
            typing_event_hook = nil
        end
        for _, listener in pairs(player_log) do
            event.remove_event_listener("player_join", listener)
        end
        for _, listener in pairs(chat_events) do
            event.remove_event_listener("chat", listener)
        end
        higurashi.logger(title .. " Unloaded.", "", "", "[Unload Successful]", "Debug.log", true, "CHAR_SOCIAL_CLUB", 2)
        menu.exit()
    end
    m.af(c.red2 .. "Unload Project Higurashi" .. c.default, "action", Higurashi.Parent2.id, unload_hooks)
    local exit_listener = event.add_event_listener("exit", unload_hooks)
end
