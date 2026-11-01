local COMMIT = "7e2e709c06e1ab27dd06c08139f4e2f46134756e"
local REPO_RAW = "https://raw.githubusercontent.com/babay2352/leet.cheats/" .. COMMIT
local BUILD = "5"
local LIB_BYTES = 147735

print("leet.cheats: visuals build " .. BUILD)

getgenv().LEET_FONT_URL = REPO_RAW .. "/fonts/fs-tahoma-8px.ttf"

local lib_src = game:HttpGet(REPO_RAW .. "/lib.lua")

if #lib_src ~= LIB_BYTES then
	print(string.format(
		"leet.cheats: lib.lua отдаёт %d байт вместо %d — это старый образ с cdn, подожди пару минут",
		#lib_src,
		LIB_BYTES
	))
end

local leet = loadstring(lib_src)()

local window = leet:window({
	name = "leet.cheats",
	size = UDim2.fromOffset(560, 660),
})

local esp = window:tab({ name = "esp" })
local visuals = window:tab({ name = "visuals" })

do
	local enemy = esp:section({ name = "enemy" })
	local dropped = esp:section({ name = "dropped" })
	local team = esp:section({ name = "team", side = "right" })
	local esp_settings = esp:section({ name = "esp settings", side = "right" })

	enemy:toggle({
		name = "enabled",
		flag = "enemy_esp",
		default = false,
		tooltip = "enables enemy esp",
	})

	enemy
		:toggle({
			name = "bounding box",
			flag = "enemy_box",
			default = false,
			tooltip = "shows enemy boxes",
		})
		:colorpicker({ flag = "enemy_boxcolor", color = Color3.new(1, 0, 0) })

	enemy
		:toggle({
			name = "filled bounding box",
			flag = "enemy_filledbox",
			default = false,
			tooltip = "fills enemy boxes",
		})
		:colorpicker({
			flag = "enemy_filledboxcolor",
			color = Color3.new(1, 0, 0),
			alpha = 0.2,
		})

	enemy
		:toggle({
			name = "health bar",
			flag = "enemy_healthbar",
			default = false,
			tooltip = "shows enemy health bars",
		})
		:colorpicker({
			name = "low health",
			flag = "enemy_lowhealth",
			color = Color3.fromRGB(255, 100, 100),
		})
		:colorpicker({
			name = "full health",
			flag = "enemy_fullhealth",
			color = Color3.fromRGB(100, 255, 100),
		})

	enemy:toggle({
		name = "gradient health bar",
		flag = "enemy_gradienthealthbar",
		default = false,
		tooltip = "health bars will appear as gradients",
	})

	enemy
		:toggle({
			name = "health number",
			flag = "enemy_healthnumber",
			default = false,
			tooltip = "shows enemy health values",
		})
		:colorpicker({
			flag = "enemy_healthnumbercolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "display name",
			flag = "enemy_name",
			default = false,
			tooltip = "shows enemy names",
		})
		:colorpicker({ flag = "enemy_namecolor", color = Color3.new(1, 1, 1) })

	enemy
		:toggle({
			name = "rank",
			flag = "enemy_rank",
			default = false,
			tooltip = "shows enemy ranks",
		})
		:colorpicker({
			flag = "enemy_rankcolor",
			color = Color3.fromRGB(0, 219, 255),
		})

	enemy
		:toggle({
			name = "held weapon",
			flag = "enemy_heldweapon",
			default = false,
			tooltip = "shows the enemies held weapon",
		})
		:colorpicker({
			flag = "enemy_heldweaponcolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "distance",
			flag = "enemy_distance",
			default = false,
			tooltip = "shows the distance to the enemy",
		})
		:colorpicker({
			flag = "enemy_distancecolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "exploiting",
			flag = "enemy_exploit",
			default = false,
			tooltip = "shows when an enemy is using a time exploit: delta is the gap between packet times, delay is how far the packet stamp is behind, choke is when the last packet was sent",
		})
		:colorpicker({
			flag = "enemy_exploitcolor",
			color = Color3.new(1, 0, 0),
		})

	enemy
		:toggle({
			name = "stance",
			flag = "enemy_stance",
			default = false,
			tooltip = "shows what stance a enemy has",
		})
		:colorpicker({
			flag = "enemy_stancecolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "visible",
			flag = "enemy_visible",
			default = false,
			tooltip = "shows if a enemy is visible",
		})
		:colorpicker({
			flag = "enemy_visiblecolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "chams",
			flag = "enemy_chams",
			default = false,
			tooltip = "shows enemy chams",
		})
		:colorpicker({
			name = "inner cham",
			flag = "enemy_innerchamcolor",
			color = Color3.fromRGB(100, 0, 0),
			alpha = 1 - 155 / 255,
		})
		:colorpicker({
			name = "outer cham",
			flag = "enemy_outerchamcolor",
			color = Color3.fromRGB(255, 0, 0),
		})

	enemy
		:toggle({
			name = "skeleton",
			flag = "enemy_skeleton",
			default = false,
			tooltip = "shows enemy skeletons",
		})
		:colorpicker({
			flag = "enemy_skeletoncolor",
			color = Color3.fromRGB(236, 251, 136),
		})

	enemy
		:toggle({
			name = "snap lines",
			flag = "enemy_snaplines",
			default = false,
			tooltip = "shows enemy snap lines",
		})
		:colorpicker({
			flag = "enemy_snaplinescolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "view angle",
			flag = "enemy_viewangle",
			default = false,
			tooltip = "shows a line in the direction the enemy is looking",
		})
		:colorpicker({
			flag = "enemy_viewanglecolor",
			color = Color3.new(1, 1, 1),
		})

	enemy
		:toggle({
			name = "head dot",
			flag = "enemy_headdot",
			default = false,
			tooltip = "shows a circle at which shooting at will result in a headshot",
		})
		:colorpicker({
			flag = "enemy_headdotcolor",
			color = Color3.new(1, 0, 0),
		})

	enemy
		:toggle({
			name = "out of view",
			flag = "enemy_oov",
			default = false,
			tooltip = "shows an arrow pointing towards an enemy if they are not in view",
		})
		:colorpicker({
			flag = "enemy_oovcolor",
			color = Color3.new(1, 1, 1),
		})

	enemy:slider({
		name = "arrow distance",
		suffix = "%",
		flag = "arrow_distance",
		default = 30,
		min = 1,
		max = 100,
	})

	enemy:slider({
		name = "arrow size",
		suffix = "%",
		flag = "arrow_size",
		default = 30,
		min = 1,
		max = 100,
	})

	enemy:toggle({
		name = "dynamic arrow size",
		flag = "enemy_dynamicarrowsize",
		default = false,
		tooltip = "sizes the arrows based on distance",
	})

	enemy
		:toggle({
			name = "show resolved flag",
			flag = "enemy_showresolvedflag",
			default = false,
			tooltip = "highlights enemies that have been successfully resolved",
		})
		:colorpicker({
			name = "resolved",
			flag = "enemy_resolvedflagcolor",
			color = Color3.fromRGB(237, 229, 62),
		})

	dropped
		:toggle({
			name = "grenade warning",
			flag = "dropped_grenadewarning",
			default = false,
			tooltip = "predicts where nades will land and will display the danger level",
		})
		:colorpicker({
			name = "low time",
			flag = "dropped_grenadehighcolor",
			color = Color3.fromRGB(255, 0, 0),
		})
		:colorpicker({
			name = "high time",
			flag = "dropped_grenadelowcolor",
			color = Color3.fromRGB(0, 255, 0),
		})

	dropped
		:toggle({
			name = "grenade lines",
			flag = "dropped_grenadelines",
			default = false,
			tooltip = "displays a line that maps how a grenade will travel",
		})
		:colorpicker({
			name = "line start",
			flag = "dropped_grenadealinecolor",
			color = Color3.fromRGB(81, 75, 242),
		})
		:colorpicker({
			name = "line end",
			flag = "dropped_grenadeblinecolor",
			color = Color3.fromRGB(237, 85, 103),
		})

	dropped
		:toggle({
			name = "weapon names",
			flag = "dropped_weaponnames",
			default = false,
			tooltip = "shows weapon names",
		})
		:colorpicker({
			flag = "dropped_weaponnamecolor",
			color = Color3.fromRGB(255, 255, 255),
		})

	team:toggle({
		name = "enabled",
		flag = "team_esp",
		default = false,
		tooltip = "enables team esp",
	})

	team
		:toggle({
			name = "bounding box",
			flag = "team_box",
			default = false,
			tooltip = "shows team boxes",
		})
		:colorpicker({ flag = "team_boxcolor", color = Color3.new(0, 1, 0) })

	team
		:toggle({
			name = "filled bounding box",
			flag = "team_filledbox",
			default = false,
			tooltip = "fills team boxes",
		})
		:colorpicker({
			flag = "team_filledboxcolor",
			color = Color3.new(0, 1, 0),
			alpha = 0.2,
		})

	team
		:toggle({
			name = "health bar",
			flag = "team_healthbar",
			default = false,
			tooltip = "shows team health bars",
		})
		:colorpicker({
			name = "low health",
			flag = "team_lowhealth",
			color = Color3.fromRGB(255, 100, 100),
		})
		:colorpicker({
			name = "full health",
			flag = "team_fullhealth",
			color = Color3.fromRGB(100, 255, 100),
		})

	team:toggle({
		name = "gradient health bar",
		flag = "team_gradienthealthbar",
		default = false,
		tooltip = "health bars will appear as gradients",
	})

	team
		:toggle({
			name = "health number",
			flag = "team_healthnumber",
			default = false,
			tooltip = "shows team health values",
		})
		:colorpicker({
			flag = "team_healthnumbercolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "display name",
			flag = "team_name",
			default = false,
			tooltip = "shows team names",
		})
		:colorpicker({ flag = "team_namecolor", color = Color3.new(1, 1, 1) })

	team
		:toggle({
			name = "rank",
			flag = "team_rank",
			default = false,
			tooltip = "shows team ranks",
		})
		:colorpicker({
			flag = "team_rankcolor",
			color = Color3.fromRGB(0, 219, 255),
		})

	team
		:toggle({
			name = "held weapon",
			flag = "team_heldweapon",
			default = false,
			tooltip = "shows teammate held weapon",
		})
		:colorpicker({
			flag = "team_heldweaponcolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "distance",
			flag = "team_distance",
			default = false,
			tooltip = "shows the distance to teammate",
		})
		:colorpicker({
			flag = "team_distancecolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "exploiting",
			flag = "team_exploit",
			default = false,
			tooltip = "shows when a teammate is using a time exploit: delta is the gap between packet times, delay is how far the packet stamp is behind, choke is when the last packet was sent",
		})
		:colorpicker({
			flag = "team_exploitcolor",
			color = Color3.new(1, 0, 0),
		})

	team
		:toggle({
			name = "stance",
			flag = "team_stance",
			default = false,
			tooltip = "shows what stance a teammate has",
		})
		:colorpicker({
			flag = "team_stancecolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "visible",
			flag = "team_visible",
			default = false,
			tooltip = "shows if a teammate is visible",
		})
		:colorpicker({
			flag = "team_visiblecolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "chams",
			flag = "team_chams",
			default = false,
			tooltip = "shows teammate chams",
		})
		:colorpicker({
			name = "inner cham",
			flag = "team_innerchamcolor",
			color = Color3.fromRGB(0, 100, 0),
			alpha = 1 - 155 / 255,
		})
		:colorpicker({
			name = "outer cham",
			flag = "team_outerchamcolor",
			color = Color3.fromRGB(0, 255, 0),
		})

	team
		:toggle({
			name = "skeleton",
			flag = "team_skeleton",
			default = false,
			tooltip = "shows teammate skeletons",
		})
		:colorpicker({
			flag = "team_skeletoncolor",
			color = Color3.fromRGB(236, 251, 136),
		})

	team
		:toggle({
			name = "view angle",
			flag = "team_viewangle",
			default = false,
			tooltip = "shows a line in the direction the teammate is looking",
		})
		:colorpicker({
			flag = "team_viewanglecolor",
			color = Color3.new(1, 1, 1),
		})

	team
		:toggle({
			name = "head dot",
			flag = "team_headdot",
			default = false,
			tooltip = "shows a circle at which shooting at will result in a headshot",
		})
		:colorpicker({
			flag = "team_headdotcolor",
			color = Color3.new(0, 1, 0),
		})

	esp_settings:slider({
		name = "max hp visibility cap",
		suffix = "hp",
		flag = "espsettings_maxhp",
		default = 98,
		min = 0,
		max = 100,
		tooltip = "the highest a health value can be before showing health numbers",
	})

	esp_settings:dropdown({
		name = "text font",
		flag = "espsettings_font",
		items = { "Plex", "Monospace", "System", "UI" },
		multi = false,
		tooltip = "the font of the main text",
	})

	esp_settings:dropdown({
		name = "text case",
		flag = "espsettings_case",
		items = { "lowercase", "UPPERCASE", "Normal" },
		multi = false,
		tooltip = "the case of the main text",
	})

	esp_settings:slider({
		name = "text size",
		flag = "espsettings_size",
		default = 13,
		min = 1,
		max = 40,
		tooltip = "the size of the main text",
	})

	esp_settings:dropdown({
		name = "flag text font",
		flag = "espsettings_flagfont",
		items = { "Plex", "Monospace", "System", "UI" },
		multi = false,
		tooltip = "the font of the flag text",
	})

	esp_settings:dropdown({
		name = "flag text case",
		flag = "espsettings_flagcase",
		items = { "lowercase", "UPPERCASE", "Normal" },
		multi = false,
		tooltip = "the case of the flag text",
	})

	esp_settings:slider({
		name = "flag text size",
		flag = "espsettings_flagsize",
		default = 13,
		min = 1,
		max = 40,
		tooltip = "the size of the flag text",
	})

	esp_settings
		:toggle({
			name = "highlight aimbot target",
			flag = "espsettings_showaimbottarget",
			default = false,
			tooltip = "shows the current aimbot target",
		})
		:colorpicker({
			name = "aimbot target",
			flag = "espsettings_showaimbottargetcolor",
			color = Color3.new(1, 0, 0),
		})

	esp_settings
		:toggle({
			name = "highlight friendlies",
			flag = "espsettings_showfriendlies",
			default = false,
			tooltip = "tints teammates that match the highlight rule",
		})
		:colorpicker({
			name = "friendlies",
			flag = "espsettings_showfriendliescolor",
			color = Color3.fromRGB(120, 189, 245),
		})

	esp_settings
		:toggle({
			name = "highlight priorities",
			flag = "espsettings_showpriorities",
			default = false,
			tooltip = "tints the hitscan priority targets",
		})
		:colorpicker({
			name = "priorities",
			flag = "espsettings_showprioritiescolor",
			color = Color3.fromRGB(245, 239, 120),
		})
end

do
	local local_section = visuals:section({ name = "local" })
	local camera = visuals:section({ name = "camera", side = "right" })
	local world = visuals:section({ name = "world", side = "right" })
	local viewmodel = visuals:section({ name = "viewmodel" })

	local_section:toggle({
		name = "Toggle",
		flag = "ToggleFlag",
		default = false,
	})

	local_section:slider({
		name = "arm reflectance",
		flag = "visuals_armreflectance",
		min = 0,
		max = 100,
		default = 0,
		interval = 1,
	})

	local_section:dropdown({
		name = "arm material",
		flag = "visuals_armmaterial",
		items = { "ghost", "solid", "wireframe" },
		default = "ghost",
	})

	local_section:toggle({
		name = "weapon chams",
		flag = "visuals_weaponchams",
		default = false,
	})

	local_section:slider({
		name = "weapon reflectance",
		flag = "visuals_weaponreflectance",
		min = 0,
		max = 100,
		default = 0,
		interval = 1,
	})

	local_section:dropdown({
		name = "weapon material",
		flag = "visuals_weaponmaterial",
		items = { "ghost", "solid", "wireframe" },
		default = "ghost",
	})

	local_section:toggle({
		name = "local chams",
		flag = "visuals_localchams",
		default = false,
	})

	local_section:dropdown({
		name = "local material",
		flag = "visuals_localmaterial",
		items = { "ghost", "solid", "wireframe" },
		default = "ghost",
	})

	local_section:dropdown({
		name = "arm animation",
		flag = "visuals_armanimation",
		items = { "off", "wave", "spin" },
		default = "off",
	})

	local_section:dropdown({
		name = "weapon animation",
		flag = "visuals_weaponanimation",
		items = { "off", "wave", "spin" },
		default = "off",
	})

	local_section:dropdown({
		name = "local animation",
		flag = "visuals_localanimation",
		items = { "off", "wave", "spin" },
		default = "off",
	})

	camera:slider({
		name = "camera fov",
		flag = "camera_fov",
		min = 0,
		max = 120,
		default = 90,
		interval = 1,
	})

	camera:slider({
		name = "horizontal aspect ratio",
		flag = "camera_aspect_h",
		min = 0,
		max = 200,
		default = 100,
		interval = 1,
	})

	camera:slider({
		name = "vertical aspect ratio",
		flag = "camera_aspect_v",
		min = 0,
		max = 200,
		default = 100,
		interval = 1,
	})

	camera:toggle({
		name = "remove camera bob",
		flag = "camera_nobob",
		default = false,
	})

	camera:toggle({
		name = "remove ads fov",
		flag = "camera_noadsfov",
		default = false,
	})

	camera:toggle({
		name = "remove visual suppression",
		flag = "camera_nosuppression",
		default = false,
	})

	camera:toggle({
		name = "reduce camera recoil",
		flag = "camera_recoilreduce",
		default = false,
	})

	camera:slider({
		name = "camera recoil reduction",
		suffix = "%",
		flag = "camera_recoilamount",
		min = 0,
		max = 100,
		default = 0,
		interval = 1,
	})

	camera:toggle({
		name = "third person",
		flag = "camera_thirdperson",
		default = false,
	})

	camera:slider({
		name = "third person distance",
		flag = "camera_thirdpersondistance",
		min = 0,
		max = 200,
		default = 100,
		interval = 1,
	})

	world
		:toggle({
			name = "ambient",
			flag = "world_ambient",
			default = false,
		})
		:colorpicker({
			name = "ambient color",
			flag = "world_ambientcolor",
			color = Color3.fromRGB(128, 128, 255),
		})
		:colorpicker({
			name = "outdoor ambient",
			flag = "world_outdoorambientcolor",
			color = Color3.fromRGB(128, 128, 255),
		})

	world:slider({
		name = "time of day",
		flag = "world_timeofday",
		min = 0,
		max = 24,
		default = 6,
		interval = 1,
	})

	world
		:toggle({
			name = "local bullet tracers",
			flag = "world_localtracers",
			default = false,
		})
		:colorpicker({
			flag = "world_localtracercolor",
			color = Color3.fromHex("#C94536"),
		})

	world
		:toggle({
			name = "enemy bullet tracers",
			flag = "world_enemytracers",
			default = false,
		})
		:colorpicker({
			flag = "world_enemytracercolor",
			color = Color3.fromHex("#C94536"),
		})

	world:slider({
		name = "bullet tracer time",
		flag = "world_tracertime",
		min = 0,
		max = 10,
		default = 4,
		interval = 1,
	})

	world:toggle({
		name = "hit chams",
		flag = "world_hitchams",
		default = false,
	})

	world:slider({
		name = "hit cham time",
		flag = "world_hitchamtime",
		min = 0,
		max = 10,
		default = 2,
		interval = 1,
	})

	world:dropdown({
		name = "hit chams material",
		flag = "world_hitchammaterial",
		items = { "ghost", "solid", "wireframe" },
		default = "ghost",
	})

	world:dropdown({
		name = "brightness mode",
		flag = "world_brightness",
		items = { "dimmed", "bright", "default" },
		default = "dimmed",
	})

	world
		:toggle({
			name = "teleporting lines",
			flag = "world_teleportlines",
			default = false,
		})
		:colorpicker({
			flag = "world_teleportlinescolor",
			color = Color3.fromRGB(168, 232, 65),
		})

	world:toggle({
		name = "show fake position",
		flag = "world_fakeposition",
		default = false,
	})

	world
		:toggle({
			name = "show fov",
			flag = "world_showfov",
			default = false,
		})
		:colorpicker({
			name = "fov ring",
			flag = "world_fovringcolor",
			color = Color3.fromHex("#7F48A3"),
		})
		:colorpicker({
			name = "fov outline",
			flag = "world_fovoutlinecolor",
			color = Color3.fromHex("#646464"),
		})
		:colorpicker({
			name = "fov fill",
			flag = "world_fovfillcolor",
			color = Color3.fromHex("#A3487F"),
		})
		:colorpicker({
			name = "fov center",
			flag = "world_fovcentercolor",
			color = Color3.fromHex("#FF3C00"),
		})

	world:toggle({
		name = "custom skybox",
		flag = "world_customskybox",
		default = false,
	})

	viewmodel:toggle({
		name = "offset viewmodel",
		flag = "vm_offset",
		default = false,
	})

	viewmodel:slider({
		name = "offset x",
		flag = "vm_offset_x",
		min = -200,
		max = 200,
		default = 0,
		interval = 1,
	})

	viewmodel:slider({
		name = "offset y",
		flag = "vm_offset_y",
		min = -200,
		max = 200,
		default = 0,
		interval = 1,
	})

	viewmodel:slider({
		name = "offset z",
		flag = "vm_offset_z",
		min = -200,
		max = 200,
		default = 0,
		interval = 1,
	})

	viewmodel:slider({
		name = "pitch",
		flag = "vm_pitch",
		min = -180,
		max = 180,
		default = 0,
		interval = 1,
	})

	viewmodel:slider({
		name = "yaw",
		flag = "vm_yaw",
		min = -180,
		max = 180,
		default = 0,
		interval = 1,
	})

	viewmodel:slider({
		name = "roll",
		flag = "vm_roll",
		min = -180,
		max = 180,
		default = 0,
		interval = 1,
	})
end

do
	local run_service = game:GetService("RunService")
	local flags = leet.flags

	local preview = esp:section({ name = "esp preview", side = "right" })

	local preview_toggle = preview:toggle({
		name = "preview",
		flag = "preview_enabled",
		default = true,
		tooltip = "Рендерит 3D-манекен во вьюпорте прямо в меню со всеми включёнными esp-флагами.",
	})

	preview:toggle({
		name = "preview teammate",
		flag = "preview_teammate",
		default = false,
		tooltip = "Меняет фигурку на team_* флаги. Нужен включённый team enabled, иначе остаётся enemy.",
	})

	preview:toggle({
		name = "animate",
		flag = "preview_animate",
		default = true,
		tooltip = "Крутит манекен и качает хп, дистанцию и пакетные тайминги вокруг значений со слайдеров.",
	})

	preview:slider({
		name = "health",
		suffix = "%",
		flag = "preview_health",
		default = 62,
		min = 0,
		max = 100,
		interval = 1,
	})

	preview:slider({
		name = "distance",
		suffix = "m",
		flag = "preview_distance",
		default = 48,
		min = 1,
		max = 500,
		interval = 1,
	})

	preview:dropdown({
		name = "stance",
		flag = "preview_stance",
		items = { "stand", "crouch", "prone" },
		multi = false,
		tooltip = "Текст стэнка в превью. Позу манекена не меняет.",
	})

	preview:dropdown({
		name = "visibility",
		flag = "preview_visible",
		items = { "visible", "occluded" },
		multi = false,
		tooltip = "occluded ставит перед манекеном стену: видно, как esp и chams читаются сквозь укрытие.",
	})

	local CANVAS_W, CANVAS_H = 206, 250
	local PIVOT = CFrame.new(0, 3, 0)
	local CROSS_X, CROSS_Y = CANVAS_W * 0.5, CANVAS_H * 0.5
	local FOV_D = 104

	local FONTS = {
		Plex = Enum.Font.SourceSans,
		Monospace = Enum.Font.Code,
		System = Enum.Font.Arial,
		UI = Enum.Font.GothamMedium,
	}

	local cache = {}

	local function once(key, value)
		if cache[key] == value then
			return false
		end

		cache[key] = value
		return true
	end

	local function on(flag)
		return flags[flag] == true
	end

	local function color_of(flag, fallback)
		local entry = flags[flag]

		if type(entry) == "table" and typeof(entry.Color) == "Color3" then
			local alpha = tonumber(entry.Transparency)
			return entry.Color, alpha or 1
		end

		return fallback or Color3.new(1, 1, 1), 1
	end

	local function new_frame(parent, w, h, z)
		return leet:new_item("Frame", {
			Parent = parent,
			Name = "",
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = z or 5,
		})
	end

	local function new_stroke(parent, color)
		return leet:new_item("UIStroke", {
			Parent = parent,
			Color = color or Color3.new(1, 0, 0),
			Transparency = 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
	end

	local function new_line(parent, z)
		return leet:new_item("TextLabel", {
			Parent = parent,
			Name = "",
			Text = "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = z or 6,
		})
	end

	local function place_line(node, x1, y1, x2, y2, thickness)
		local dx = x2 - x1
		local dy = y2 - y1

		node.Position = UDim2.fromOffset(x1 + dx * 0.5, y1 + dy * 0.5)
		node.Size = UDim2.fromOffset(math.max(1, math.sqrt(dx * dx + dy * dy)), thickness)
		node.Rotation = math.deg(math.atan(dy, dx))
	end

	local function new_text(parent, caption, z)
		return leet:new_item("TextLabel", {
			Parent = parent,
			Name = "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(190, 13),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = caption,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13,
			Font = Enum.Font.SourceSans,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextStrokeTransparency = 0.6,
			ZIndex = z or 8,
		})
	end

	local function try_set(node, property, value)
		pcall(function()
			node[property] = value
		end)
	end

	local function try_new(class, properties)
		local ok, node = pcall(leet.new_item, leet, class, properties)
		return ok and node or nil
	end

	local PANEL_W = CANVAS_W + 20
	local PANEL_H = CANVAS_H + 34

	local panel = leet:new_item("Frame", {
		Parent = leet.gui,
		Name = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 405, 0.5, -60),
		Size = UDim2.fromOffset(PANEL_W, PANEL_H),
		BackgroundColor3 = Color3.fromRGB(13, 13, 15),
		BorderSizePixel = 0,
		Active = true,
		Draggable = true,
		ZIndex = 20,
	})

	leet:new_item("UICorner", { Parent = panel, CornerRadius = UDim.new(0, 4) })
	leet:new_item("UIStroke", {
		Parent = panel,
		Color = Color3.fromRGB(64, 66, 74),
		Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local title = leet:new_item("Frame", {
		Parent = panel,
		Name = "",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = Color3.fromRGB(22, 22, 26),
		BorderSizePixel = 0,
		ZIndex = 21,
	})

	leet:new_item("UICorner", { Parent = title, CornerRadius = UDim.new(0, 4) })

	leet:new_item("TextLabel", {
		Parent = title,
		Name = "",
		Position = UDim2.new(0, 9, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "player view",
		TextColor3 = Color3.fromRGB(196, 196, 202),
		TextSize = 12,
		Font = Enum.Font.SourceSans,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	})

	local close = leet:new_item("TextButton", {
		Parent = title,
		Name = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "x",
		TextColor3 = Color3.fromRGB(226, 96, 96),
		TextSize = 14,
		Font = Enum.Font.SourceSans,
		AutoButtonColor = false,
		ZIndex = 22,
	})

	close.MouseButton1Click:Connect(function()
		preview_toggle.set(false)
	end)

	local viewport = leet:new_item("ViewportFrame", {
		Parent = panel,
		Name = "",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 28),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H),
		BackgroundColor3 = Color3.fromRGB(38, 40, 48),
		BorderSizePixel = 0,
		ZIndex = 20,
	})

	try_set(viewport, "Ambient", Color3.fromRGB(98, 98, 110))
	try_set(viewport, "ColorShift_Top", Color3.fromRGB(140, 140, 150))
	try_set(viewport, "ColorShift_Bottom", Color3.fromRGB(0, 0, 0))
	try_set(viewport, "LightColor", Color3.fromRGB(255, 255, 255))
	try_set(viewport, "LightDirection", Vector3.new(0.4, -0.7, -0.6))
	try_set(viewport, "GlobalShadows", false)

	leet:new_item("UICorner", { Parent = viewport, CornerRadius = UDim.new(0, 3) })
	leet:new_item("UIStroke", {
		Parent = viewport,
		Color = Color3.fromRGB(120, 124, 134),
		Transparency = 0.15,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local camera = leet:new_item("Camera", { Parent = viewport, Name = "" })
	camera.FieldOfView = 52
	camera.CFrame = CFrame.new(Vector3.new(0, 3.1, -9.4), Vector3.new(0, 2.95, 0))
	viewport.CurrentCamera = camera

	local scenery = leet:new_item("Model", { Parent = viewport, Name = "leet_preview_scenery" })
	local dummy = leet:new_item("Model", { Parent = viewport, Name = "leet_preview_dummy" })

	local function rig_part(parent, name, size, position, color, material)
		return leet:new_item("Part", {
			Parent = parent,
			Name = name,
			Size = size,
			CFrame = CFrame.new(position),
			Color = color,
			Material = material or Enum.Material.SmoothPlastic,
			Anchored = true,
			CanCollide = false,
			CastShadow = false,
			TopSurface = Enum.SurfaceType.Smooth,
			BottomSurface = Enum.SurfaceType.Smooth,
		})
	end

	rig_part(scenery, "Floor", Vector3.new(28, 0.4, 28), Vector3.new(0, -0.2, 0), Color3.fromRGB(24, 24, 28))
	local wall = rig_part(
		scenery,
		"Wall",
		Vector3.new(14, 14, 1),
		Vector3.new(0, 5, -3.6),
		Color3.fromRGB(74, 74, 80),
		Enum.Material.Concrete
	)
	wall.Transparency = 1

	local SKIN = Color3.fromRGB(245, 228, 96)
	local SHIRT = Color3.fromRGB(58, 96, 168)
	local PANTS = Color3.fromRGB(74, 152, 74)

	local head = rig_part(dummy, "Head", Vector3.new(2, 2, 2), Vector3.new(0, 5, 0), SKIN)
	leet:new_item("SpecialMesh", {
		Parent = head,
		Name = "",
		MeshType = Enum.MeshType.Head,
		Scale = Vector3.new(1, 1, 1),
	})

	local torso = rig_part(dummy, "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), SHIRT)
	local arm_l = rig_part(dummy, "Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), SKIN)
	local arm_r = rig_part(dummy, "Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), SKIN)
	local leg_l = rig_part(dummy, "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), PANTS)
	local leg_r = rig_part(dummy, "Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), PANTS)
	dummy.PrimaryPart = torso

	local cham = try_new("Highlight", { Parent = dummy, Name = "" })
	if cham then
		try_set(cham, "Adornee", dummy)
		cham.Enabled = false
		try_set(cham, "FillTransparency", 0.4)
		try_set(cham, "OutlineTransparency", 0)
	end

	local overlay = leet:new_item("Frame", {
		Parent = panel,
		Name = "",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 28),
		Size = UDim2.fromOffset(CANVAS_W, CANVAS_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 21,
	})

	try_set(overlay, "ClipsVisible", true)

	local fov_holder = new_frame(overlay, CANVAS_W, CANVAS_H, 3)
	fov_holder.Visible = false

	local function new_circle(parent, diameter, color, transparency, z)
		local node = leet:new_item("Frame", {
			Parent = parent,
			Name = "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(CROSS_X, CROSS_Y),
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundColor3 = color,
			BackgroundTransparency = transparency,
			BorderSizePixel = 0,
			ZIndex = z,
		})

		leet:new_item("UICorner", { Parent = node, CornerRadius = UDim.new(1, 0) })
		return node
	end

	local fov_fill = new_circle(fov_holder, FOV_D, Color3.fromRGB(163, 72, 127), 0.85, 3)
	local fov_ring = new_circle(fov_holder, FOV_D, Color3.new(1, 1, 1), 1, 4)
	local fov_ring_stroke = new_stroke(fov_ring, Color3.fromRGB(127, 72, 163))
	local fov_outline = new_circle(fov_holder, FOV_D + 10, Color3.new(1, 1, 1), 1, 4)
	local fov_outline_stroke = new_stroke(fov_outline, Color3.fromRGB(100, 100, 100))
	local fov_center = new_circle(fov_holder, 5, Color3.fromRGB(255, 60, 0), 0, 5)

	local filled = new_frame(overlay, 10, 10, 4)
	filled.BackgroundTransparency = 0
	filled.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

	local box = new_frame(overlay, 10, 10, 5)
	local box_stroke = new_stroke(box, Color3.new(1, 0, 0))

	local hp_holder = new_frame(overlay, CANVAS_W, CANVAS_H, 6)
	hp_holder.Visible = false

	leet:new_item("Frame", {
		Parent = hp_holder,
		Name = "hp_back",
		Size = UDim2.fromOffset(3, 10),
		BackgroundColor3 = Color3.fromRGB(14, 14, 16),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(40, 40, 44),
		ZIndex = 6,
	})

	local hp_back = hp_holder:FindFirstChild("hp_back")

	local hp_fill = leet:new_item("Frame", {
		Parent = hp_holder,
		Name = "hp_fill",
		AnchorPoint = Vector2.new(0, 1),
		Size = UDim2.fromOffset(3, 6),
		BackgroundColor3 = Color3.fromRGB(100, 255, 100),
		BorderSizePixel = 0,
		ZIndex = 7,
	})

	local hp_gradient = leet:new_item("UIGradient", {
		Parent = hp_fill,
		Name = "",
		Rotation = 90,
		Enabled = false,
	})

	local skel_holder = new_frame(overlay, CANVAS_W, CANVAS_H, 6)
	skel_holder.Visible = false

	local skel_lines = {}

	for _ = 1, 6 do
		table.insert(skel_lines, new_line(skel_holder, 6))
	end

	local head_dot = new_frame(overlay, 5, 5, 7)
	head_dot.BackgroundTransparency = 0
	head_dot.BackgroundColor3 = Color3.new(1, 0, 0)
	leet:new_item("UICorner", { Parent = head_dot, CornerRadius = UDim.new(1, 0) })

	local view_angle = new_line(overlay, 7)
	local snap = new_line(overlay, 7)
	local oov = new_line(overlay, 7)

	local resolved = new_frame(overlay, 5, 5, 7)
	resolved.BackgroundTransparency = 0
	resolved.BackgroundColor3 = Color3.fromRGB(237, 229, 62)
	leet:new_item("UICorner", { Parent = resolved, CornerRadius = UDim.new(1, 0) })

	local name = new_text(overlay, "dummy")
	local rank = new_text(overlay, "rank 42")
	local distance = new_text(overlay, "48m")
	local weapon = new_text(overlay, "rifle")
	local stance = new_text(overlay, "stand")
	local exploit = new_text(overlay, "delta 10  delay 28  choke 0.04")
	local visible = new_text(overlay, "visible")
	local hp_number = new_text(overlay, "62")

	local info_rows = { distance, weapon, stance, exploit, visible }

	local rows = {
		{ suffix = "box", node = box, stroke = box_stroke, color = "boxcolor", mode = "stroke", fallback = Color3.new(1, 0, 0) },
		{ suffix = "filledbox", node = filled, color = "filledboxcolor", mode = "bg", fallback = Color3.new(1, 0, 0), use_alpha = true },
		{ suffix = "skeleton", color = "skeletoncolor", mode = "lines", fallback = Color3.fromRGB(236, 251, 136) },
		{ suffix = "viewangle", node = view_angle, color = "viewanglecolor", mode = "bg", fallback = Color3.new(1, 1, 1) },
		{ suffix = "headdot", node = head_dot, color = "headdotcolor", mode = "bg", fallback = Color3.new(1, 0, 0) },
		{ suffix = "snaplines", node = snap, color = "snaplinescolor", mode = "bg", fallback = Color3.new(1, 1, 1) },
		{ suffix = "oov", node = oov, color = "oovcolor", mode = "bg", fallback = Color3.new(1, 1, 1) },
		{ suffix = "showresolvedflag", node = resolved, color = "resolvedflagcolor", mode = "bg", fallback = Color3.fromRGB(237, 229, 62) },
		{ suffix = "name", node = name, color = "namecolor", mode = "text", fallback = Color3.new(1, 1, 1) },
		{ suffix = "rank", node = rank, color = "rankcolor", mode = "text", fallback = Color3.fromRGB(0, 219, 255) },
		{ suffix = "heldweapon", node = weapon, color = "heldweaponcolor", mode = "text", fallback = Color3.new(1, 1, 1) },
		{ suffix = "distance", node = distance, color = "distancecolor", mode = "text", fallback = Color3.new(1, 1, 1) },
		{ suffix = "exploit", node = exploit, color = "exploitcolor", mode = "text", fallback = Color3.new(1, 0, 0) },
		{ suffix = "stance", node = stance, color = "stancecolor", mode = "text", fallback = Color3.new(1, 1, 1) },
		{ suffix = "visible", node = visible, color = "visiblecolor", mode = "text", fallback = Color3.new(1, 1, 1) },
	}

	for _, row in next, rows do
		if row.mode == "lines" then
			skel_holder.Visible = false
		else
			row.node.Visible = false
		end
	end

	local joints = {
		head = head,
		arm_l = arm_l,
		arm_r = arm_r,
		leg_l = leg_l,
		leg_r = leg_r,
	}

	local links = {
		{ "head", "neck" },
		{ "neck", "arm_l" },
		{ "neck", "arm_r" },
		{ "neck", "hips" },
		{ "hips", "leg_l" },
		{ "hips", "leg_r" },
	}

	local function joint(name_key)
		if name_key == "neck" then
			return torso.CFrame:PointToWorldSpace(Vector3.new(0, 1, 0))
		elseif name_key == "hips" then
			return torso.CFrame:PointToWorldSpace(Vector3.new(0, -1, 0))
		end

		return joints[name_key].Position
	end

	local function paint(row, color)
		if row.mode == "stroke" then
			row.stroke.Color = color
		elseif row.mode == "lines" then
			for _, line in next, skel_lines do
				line.BackgroundColor3 = color
			end
		elseif row.mode == "text" then
			row.node.TextColor3 = color
		else
			row.node.BackgroundColor3 = color
		end
	end

	local function apply_text(node, key, font, size, case_mode, caption)
		if once("sz:" .. key, size) then
			node.TextSize = size
		end

		if once("fn:" .. key, font) then
			node.Font = font
		end

		local shown = caption

		if case_mode == "UPPERCASE" then
			shown = string.upper(caption)
		elseif case_mode == "lowercase" then
			shown = string.lower(caption)
		end

		if once("tx:" .. key, shown) then
			node.Text = shown
		end
	end

	local clock = time()

	local function render()
		local elapsed = time() - clock
		local prefix = on("preview_teammate") and on("team_esp") and "team" or "enemy"
		local master = on(prefix .. "_esp")
		local animated = on("preview_animate")

		local yaw = animated and math.rad(38 * math.sin(elapsed * 0.45)) or math.rad(18)
		dummy:PivotTo(PIVOT * CFrame.Angles(0, yaw, 0))

		local occluded = flags.preview_visible == "occluded"
		if once("wall", occluded) then
			wall.Transparency = occluded and 0.4 or 1
		end

		local center, size = dummy:GetBoundingBox()
		local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge

		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local world = center:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz))
					local sp = camera:WorldToViewportPoint(world)

					x0 = math.min(x0, sp.X)
					y0 = math.min(y0, sp.Y)
					x1 = math.max(x1, sp.X)
					y1 = math.max(y1, sp.Y)
				end
			end
		end

		local cx = (x0 + x1) * 0.5
		local box_h = math.max(1, y1 - y0)

		for _, row in next, rows do
			local want = master and on(prefix .. "_" .. row.suffix)

			if once("v:" .. row.suffix, want) then
				if row.mode == "lines" then
					skel_holder.Visible = want
				else
					row.node.Visible = want
				end
			end

			if want then
				local color, alpha = color_of(prefix .. "_" .. row.color, row.fallback)

				if once("pc:" .. row.color, color) then
					paint(row, color)
				end

				if row.use_alpha and once("pa:" .. row.color, alpha) then
					row.node.BackgroundTransparency = 1 - alpha
				end
			end
		end

		box.Position = UDim2.fromOffset(x0, y0)
		box.Size = UDim2.fromOffset(x1 - x0, box_h)
		filled.Position = box.Position
		filled.Size = box.Size

		for index, link in next, links do
			local a = camera:WorldToViewportPoint(joint(link[1]))
			local b = camera:WorldToViewportPoint(joint(link[2]))
			place_line(skel_lines[index], a.X, a.Y, b.X, b.Y, 1)
		end

		local head_sp = camera:WorldToViewportPoint(head.Position)
		local look_sp = camera:WorldToViewportPoint(head.CFrame:PointToWorldSpace(Vector3.new(0, 0, 3)))

		head_dot.Position = UDim2.fromOffset(head_sp.X - 2, head_sp.Y - 2)
		resolved.Position = UDim2.fromOffset(x1 + 3, y0 + 2)
		place_line(view_angle, head_sp.X, head_sp.Y, look_sp.X, look_sp.Y, 1)
		place_line(snap, CROSS_X, CROSS_Y, cx, y0 + box_h * 0.5, 1)
		place_line(oov, head_sp.X, head_sp.Y, 14, head_sp.Y, 2)

		local chams = cham ~= nil and master and on(prefix .. "_chams")

		if cham then
			if once("v:chams", chams) then
				cham.Enabled = chams
			end

			if chams then
				local inner, inner_alpha = color_of(prefix .. "_innerchamcolor", Color3.fromRGB(100, 0, 0))
				local outer, _ = color_of(prefix .. "_outerchamcolor", Color3.new(1, 0, 0))

				if once("pc:innerchamcolor", inner) or once("pa:innerchamcolor", inner_alpha) then
					cham.FillColor = inner
					cham.FillTransparency = 1 - inner_alpha
				end

				if once("pc:outerchamcolor", outer) then
					cham.OutlineColor = outer
				end
			end
		end

		local center_hp = tonumber(flags.preview_health) or 62
		local hp = animated and math.clamp(center_hp + 26 * math.sin(elapsed * 0.7), 0, 100) or center_hp

		hp_back.Position = UDim2.fromOffset(x0 - 7, y0)
		hp_back.Size = UDim2.fromOffset(3, box_h)
		hp_fill.Position = UDim2.fromOffset(x0 - 7, y1)
		hp_fill.Size = UDim2.fromOffset(3, box_h * (hp / 100))

		local bar = master and on(prefix .. "_healthbar")
		if once("v:healthbar", bar) then
			hp_holder.Visible = bar
		end

		if bar then
			local low, _ = color_of(prefix .. "_lowhealth", Color3.fromRGB(255, 100, 100))
			local full, _ = color_of(prefix .. "_fullhealth", Color3.fromRGB(100, 255, 100))
			local gradient = on(prefix .. "_gradienthealthbar")

			if once("g:gradient", gradient) then
				hp_gradient.Enabled = gradient
			end

			if gradient then
				if once("gc:health", tostring(low) .. tostring(full)) then
					hp_gradient.Color =
						ColorSequence.new({
							ColorSequenceKeypoint.new(0, low),
							ColorSequenceKeypoint.new(1, full),
						})
				end
			elseif once("hc:health", tostring(low) .. tostring(full)) then
				hp_fill.BackgroundColor3 = low:Lerp(full, hp / 100)
			end
		end

		local main_font = FONTS[flags.espsettings_font] or Enum.Font.SourceSans
		local main_size = tonumber(flags.espsettings_size) or 13
		local main_case = flags.espsettings_case
		local flag_font = FONTS[flags.espsettings_flagfont] or Enum.Font.SourceSans
		local flag_size = tonumber(flags.espsettings_flagsize) or 13
		local flag_case = flags.espsettings_flagcase

		local center_dist = tonumber(flags.preview_distance) or 48
		local dist = animated and math.max(1, center_dist + 18 * math.sin(elapsed * 0.3)) or center_dist

		apply_text(name, "name", main_font, main_size, main_case, "dummy")
		apply_text(rank, "rank", main_font, main_size, main_case, "rank 42")
		apply_text(distance, "distance", main_font, main_size, main_case, string.format("%.0fm", dist))
		apply_text(weapon, "weapon", main_font, main_size, main_case, "rifle")
		apply_text(stance, "stance", flag_font, flag_size, flag_case, tostring(flags.preview_stance or "stand"))
		apply_text(visible, "visible", flag_font, flag_size, flag_case, tostring(flags.preview_visible or "visible"))
		apply_text(
			exploit,
			"exploit",
			flag_font,
			flag_size,
			flag_case,
			string.format(
				"delta %.0f  delay %.0f  choke %.2f",
				animated and 10 + 5 * math.sin(elapsed * 3) or 10,
				animated and 28 + 12 * math.sin(elapsed * 1.7) or 28,
				animated and 0.04 + 0.04 * math.abs(math.sin(elapsed * 0.9)) or 0.04
			)
		)

		local above = y0 - 8

		if name.Visible then
			name.Position = UDim2.fromOffset(cx, above)
			above = above - 11
		end

		if rank.Visible then
			rank.Position = UDim2.fromOffset(cx, above)
		end

		local below = y1 + 10

		for _, node in next, info_rows do
			if node.Visible then
				node.Position = UDim2.fromOffset(cx, below)
				below = below + 11
			end
		end

		local number = master and on(prefix .. "_healthnumber") and hp <= (tonumber(flags.espsettings_maxhp) or 100)
		if once("v:healthnumber", number) then
			hp_number.Visible = number
		end

		if number then
			hp_number.Position = UDim2.fromOffset(x1 + 13, y0 + box_h * 0.5)
			apply_text(hp_number, "hpnumber", main_font, main_size, main_case, string.format("%.0f", hp))

			local health_color, _ = color_of(prefix .. "_healthnumbercolor", Color3.new(1, 1, 1))
			if once("pc:healthnumbercolor", health_color) then
				hp_number.TextColor3 = health_color
			end
		end

		local fov_on = on("world_showfov")
		if once("v:world_showfov", fov_on) then
			fov_holder.Visible = fov_on
		end

		if fov_on then
			local ring, _ = color_of("world_fovringcolor", Color3.fromRGB(127, 72, 163))
			local outline, _ = color_of("world_fovoutlinecolor", Color3.fromRGB(100, 100, 100))
			local fill, fill_alpha = color_of("world_fovfillcolor", Color3.fromRGB(163, 72, 127))
			local center_dot, _ = color_of("world_fovcentercolor", Color3.fromRGB(255, 60, 0))

			if once("pc:world_fovringcolor", ring) then
				fov_ring_stroke.Color = ring
			end

			if once("pc:world_fovoutlinecolor", outline) then
				fov_outline_stroke.Color = outline
			end

			if once("pc:world_fovfillcolor", fill) or once("pa:world_fovfillcolor", fill_alpha) then
				fov_fill.BackgroundColor3 = fill
				fov_fill.BackgroundTransparency = 1 - fill_alpha
			end

			if once("pc:world_fovcentercolor", center_dot) then
				fov_center.BackgroundColor3 = center_dot
			end
		end
	end

	local broken = false

	leet:connection(run_service.RenderStepped, function()
		if leet.dead or broken then
			return
		end

		local enabled = leet.menu_visible and on("preview_enabled")
		if once("panel", enabled) then
			panel.Visible = enabled
		end

		if not enabled then
			return
		end

		local ok, err = pcall(render)

		if not ok then
			broken = true
			panel.Visible = false
			print("leet.cheats: preview disabled, " .. tostring(err))
		end
	end)

	print("leet.cheats: player view panel built")
end

if not leet:load_last_config() then
	print("leet.cheats: no autoload config yet")
end

leet:enable_autosave()

esp.open_tab()

print("leet.cheats visuals port loaded, font:", tostring(leet.font), "files:", leet.has_files)
