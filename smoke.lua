local REPO_RAW = "https://raw.githubusercontent.com/OWNER/leet-cheats/main"

getgenv().LEET_FONT_URL = REPO_RAW .. "/fonts/fs-tahoma-8px.ttf"

local leet = loadstring(game:HttpGet(REPO_RAW .. "/lib.lua"))()

local window = leet:window({
	name = "leet.cheats",
	size = UDim2.fromOffset(520, 640),
})

local combat = window:tab({ name = "combat" })
local visuals = window:tab({ name = "visuals" })
local config = window:tab({ name = "config" })

do
	local aa = combat:section({ name = "aim assist" })

	aa:label({
		name = "Everything below runs on rage defaults until you touch it.",
		tooltip = "Labels are text rows. They take no flag.",
	})

	aa:toggle({
		name = "enabled",
		flag = "aa_enabled",
		default = false,
		tooltip = "Master switch for the aim assist.",
	})

	aa:toggle({
		name = "smoothing on",
		flag = "aa_smoothing",
		default = true,
		tooltip = "Default true needs no enabled field anymore.",
	})

	aa:slider({
		name = "speed",
		suffix = "%",
		flag = "aa_speed",
		default = 45,
		min = 0,
		max = 100,
		interval = 1,
		tooltip = "How fast the cursor is pulled to the target.",
	})

	aa:dropdown({
		name = "activation",
		flag = "aa_activation",
		items = { "mouse 1", "mouse 2", "always" },
		multi = false,
		tooltip = "Which input turns the assist on.",
	})

	aa:dropdown({
		name = "hitboxes",
		flag = "aa_points",
		items = { "head", "body", "arms", "legs" },
		multi = true,
		tooltip = "Multi dropdown keeps a table in the flag.",
	})

	local sa = combat:section({ name = "silent aim", side = "right" })

	sa:toggle({
		name = "silent aim",
		flag = "sa_enabled",
		default = false,
		tooltip = "Redirects the round after it is fired.",
	})

	sa:colorpicker({
		name = "target color",
		flag = "sa_color",
		color = Color3.fromRGB(255, 60, 60),
		alpha = 1,
		tooltip = "Alpha is the transparency field here, 1 = opaque.",
	})

	sa:keybind({
		name = "silent bind",
		flag = "sa_bind",
		default = Enum.KeyCode.Q,
		display = "silent",
		mode = "toggle",
		tooltip = "Left click to rebind, right click for the mode menu.",
	})

	combat:hitpart_picker({
		name = "hitparts",
		flag = "sa_hitparts",
		side = "right",
		type = "R15",
		multi = true,
		default = { "Head" },
		tooltip = "R15 body part picker. It hangs off the tab, not a section.",
	})
end

do
	local esp = visuals:section({ name = "esp" })

	esp
		:toggle({
			name = "bounding box",
			flag = "esp_box",
			default = false,
			tooltip = "Box around every enemy.",
		})
		:colorpicker({ flag = "esp_boxcolor", color = Color3.new(1, 0, 0) })

	esp:slider({
		name = "no flag slider",
		default = 10,
		min = 0,
		max = 50,
		tooltip = "No flag given: the fork gives it a unique auto flag instead of sharing inf.",
	})

	local misc = visuals:section({ name = "misc", side = "right" })

	misc:button({
		name = "ping",
		tooltip = "Prints the current flags table to the console.",
		callback = function()
			for flag, value in next, leet.flags do
				print(flag, typeof(value) == "table" and "|table|" or value)
			end
		end,
	})

	misc:textbox({
		name = "watermark text",
		flag = "wm_text",
		placeholder = "text",
		default = "leet.cheats",
		tooltip = "Plain textbox, stored as a string.",
	})

	misc:panel({
		name = "preset",
		options = { "legit", "rage", "off" },
		callback = function(choice)
			leet:notification({ text = "preset " .. tostring(choice), time = 3 })
		end,
	})
end

do
	local cfg_section = config:section({ name = "configs" })

	local list = cfg_section:dropdown({
		name = "config list",
		flag = "config_list",
		items = {},
		multi = false,
	})

	leet.config_holder = list

	cfg_section:button({
		name = "refresh list",
		callback = function()
			leet:config_list_update()
		end,
	})

	cfg_section:button({
		name = "save as autoload",
		tooltip = "Writes current flags into configs/<window name>.cfg. Set leet.autoload to rename it.",
		callback = function()
			if leet:save_last_config() then
				leet:notification({ text = "autoload saved", time = 3 })
			else
				leet:notification({ text = "no file access on this executor", time = 3 })
			end
		end,
	})

	cfg_section:button({
		name = "load autoload",
		callback = function()
			if leet:load_last_config() then
				leet:notification({ text = "autoload applied", time = 3 })
			else
				leet:notification({ text = "autoload not found", time = 3 })
			end
		end,
	})

	cfg_section:toggle({
		name = "player list",
		flag = "player_list",
		default = false,
		callback = function(bool)
			window.toggle_playerlist(bool)
		end,
	})

	cfg_section:toggle({
		name = "keybind list",
		flag = "keybind_list",
		default = true,
		callback = function(bool)
			window.toggle_list(bool)
		end,
	})

	cfg_section:toggle({
		name = "watermark",
		flag = "watermark",
		default = true,
		callback = function(bool)
			window.toggle_watermark(bool)
		end,
	})

	cfg_section:slider({
		name = "accent",
		flag = "accent_hue",
		default = 0.66,
		min = 0,
		max = 1,
		interval = 0.01,
		callback = function(hue)
			leet:update_theme("accent", Color3.fromHSV(hue, 1, 1))
		end,
	})

	cfg_section:keybind({
		name = "ui bind",
		flag = "ui_bind",
		default = Enum.KeyCode.RightShift,
		display = "menu",
		callback = function()
			leet:set_visibility(not leet.menu_visible)
		end,
	})
end

if not leet:load_last_config() then
	print("leet.cheats: no autoload config yet")
end

leet:enable_autosave()

print("leet.cheats smoke loaded, font:", tostring(leet.font), "files:", leet.has_files)
