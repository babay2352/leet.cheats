local COMMIT = "7e2e709c06e1ab27dd06c08139f4e2f46134756e"
local REPO_RAW = "https://raw.githubusercontent.com/babay2352/leet.cheats/" .. COMMIT
local BUILD = "1"
local LIB_BYTES = 147735

print("leet.cheats: starter build " .. BUILD)

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
local flags = leet.flags

local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local uis = game:GetService("UserInputService")
local lp = players.LocalPlayer

local Env = {}

do
	local function has(name)
		local ok, value = pcall(function()
			return getgenv()[name]
		end)

		return ok and type(value) == "function"
	end

	Env.drawing = pcall(function()
		Drawing.new("Line"):Remove()
	end)

	Env.highlight = pcall(function()
		Instance.new("Highlight"):Destroy()
	end)

	Env.mouse_rel = has("mousemoverel")
	Env.click = has("mouse1click")
	Env.closure = has("getrawmetatable") and has("setreadonly") and has("getnamecallmethod")
	Env.check_caller = has("checkcaller")
	Env.hui = has("gethui") or has("getplayergui")

	print(string.format(
		"leet.cheats: drawing=%s highlight=%s mouse=%s namecall=%s hui=%s",
		tostring(Env.drawing),
		tostring(Env.highlight),
		tostring(Env.mouse_rel),
		tostring(Env.closure),
		tostring(Env.hui)
	))
end

local Util = {}

function Util.on(flag)
	return flags[flag] == true
end

function Util.number(flag, fallback)
	return tonumber(flags[flag]) or fallback
end

function Util.color(flag, fallback)
	local entry = flags[flag]

	if type(entry) == "table" and typeof(entry.Color) == "Color3" then
		local alpha = tonumber(entry.Transparency)
		return entry.Color, alpha or 1
	end

	return fallback or Color3.new(1, 1, 1), 1
end

function Util.pick(flag, fallback)
	local entry = flags[flag]

	if type(entry) == "table" then
		return entry[1] or fallback
	end

	return entry or fallback
end

function Util.list(flag)
	local entry = flags[flag]

	if type(entry) == "table" then
		return entry
	end

	if entry == nil then
		return {}
	end

	return { entry }
end

function Util.key_active(flag)
	local entry = flags[flag]

	if type(entry) ~= "table" then
		return false
	end

	if entry.mode == "always" then
		return true
	end

	if entry.mode == "hold" then
		local ok, pressed = pcall(function()
			return entry.key ~= nil and uis:IsKeyDown(entry.key)
		end)

		return ok and pressed == true
	end

	return entry.active == true
end

function Util.first(model, ...)
	for _, name in next, { ... } do
		local found = model and model:FindFirstChild(name)

		if found then
			return found
		end
	end
end

function Util.rig_of(model)
	if model and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("LowerTorso") then
		return "R15"
	end

	return "R6"
end

function Util.humanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

function Util.root(model)
	return Util.first(model, "HumanoidRootPart", "Torso", "UpperTorso")
end

function Util.alive(model)
	local humanoid = Util.humanoid(model)
	return humanoid ~= nil and humanoid.Health > 0
end

function Util.project(camera, point)
	local ok, screen = pcall(function()
		return camera:WorldToViewportPoint(point)
	end)

	if not ok or screen.Z <= 0 then
		return
	end

	return screen
end

local params = nil

local function ray_params(camera)
	if not params then
		params = RaycastParams.new()

		local ok = pcall(function()
			params.FilterType = Enum.RaycastFilterType.Exclude
		end)

		if not ok then
			pcall(function()
				params.FilterType = Enum.RaycastFilterType.Blacklist
			end)
		end

		pcall(function()
			params.IgnoreWater = true
		end)
	end

	params.FilterDescendantsInstances = { camera, lp.Character }

	return params
end

function Util.can_see(camera, point, model)
	local origin = camera.CFrame.Position
	local hit = workspace:Raycast(origin, point - origin, ray_params(camera))

	if not hit then
		return true
	end

	local node = hit.Instance

	while node do
		if node == model then
			return true
		end

		node = node.Parent
	end

	return false
end

function Util.move_mouse(delta)
	if Env.mouse_rel then
		pcall(getgenv().mousemoverel, delta.X, delta.Y)
	end
end

local Adapter = {}

Adapter.title = "unnamed"
Adapter.team_attribute = "Team"
Adapter.fire_names = { "Fire", "Shoot", "FireWeapon", "Attack", "Use", "Punch", "Hit" }

function Adapter.character_of(player)
	return player.Character
end

function Adapter.is_self(player)
	return player == lp
end

function Adapter.team_tag(player)
	local ok, value = pcall(function()
		return player:GetAttribute(Adapter.team_attribute)
	end)

	if ok and type(value) == "string" then
		return value
	end

	local team = player.Team

	if team then
		return team.Name
	end
end

function Adapter.is_enemy(player)
	if Adapter.is_self(player) then
		return false
	end

	if not Util.alive(Adapter.character_of(player)) then
		return false
	end

	local mine = Adapter.team_tag(lp)
	local theirs = Adapter.team_tag(player)

	if mine == nil or theirs == nil then
		return true
	end

	return mine ~= theirs
end

function Adapter.valid_targets()
	local out = {}

	for _, player in next, players:GetPlayers() do
		local model = Adapter.character_of(player)
		local root = Util.root(model)
		local humanoid = Util.humanoid(model)

		if model and root and humanoid and Util.alive(model) then
			table.insert(out, {
				player = player,
				model = model,
				root = root,
				humanoid = humanoid,
				enemy = Adapter.is_enemy(player),
			})
		end
	end

	return out
end

function Adapter.hitboxes(model, names)
	local out = {}

	for _, name in next, names do
		local part = model:FindFirstChild(name)

		if part and part:IsA("BasePart") then
			table.insert(out, part)
		end
	end

	if #out == 0 then
		local root = Util.root(model)

		if root then
			table.insert(out, root)
		end
	end

	return out
end

function Adapter.aim_point(entry, names, camera, prediction)
	local best, best_dist
	local center = camera.ViewportSize * 0.5

	for _, part in next, Adapter.hitboxes(entry.model, names) do
		local screen = Util.project(camera, part.Position)

		if screen then
			local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude

			if not best_dist or dist < best_dist then
				best_dist = dist
				best = part.Position
			end
		end
	end

	if best and prediction > 0 then
		best = best + entry.root.AssemblyLinearVelocity * math.clamp(prediction / 1000, 0, 0.5)
	end

	return best
end

function Adapter.world_entities()
	return {}
end

function Adapter.zero(camera, name)
	return pcall(function()
		if camera[name] ~= nil then
			camera[name] = 0
		end
	end)
end

function Adapter.is_fire_remote(node)
	local name = node and node.Name or ""

	for _, token in next, Adapter.fire_names do
		if string.find(name, token, 1, true) then
			return true
		end
	end

	return false
end

local window = leet:window({
	name = "leet.cheats",
	size = UDim2.fromOffset(560, 660),
})

local visuals_tab = window:tab({ name = "visuals" })
local combat_tab = window:tab({ name = "combat" })
local settings_tab = window:tab({ name = "settings" })

local FONT_NAMES = { "Arial", "Gotham", "SourceSans", "Code" }
local FONT_IDS = { Arial = 0, Gotham = 1, SourceSans = 2, Code = 3 }

local ESP_ROWS = {
	{ key = "box", kind = "box", tip = "rectangular outline around the player" },
	{ key = "filledbox", kind = "fill", alpha = true, tip = "solid fill inside the bounding box" },
	{ key = "skeleton", kind = "skeleton", tip = "joint lines through the rig" },
	{ key = "headdot", kind = "head", tip = "circle on the head" },
	{ key = "snaplines", kind = "snap", tip = "line from screen center to the player" },
	{ key = "tracers", kind = "tracer", tip = "line from the bottom of the screen to the player" },
	{ key = "healthbar", kind = "healthbar", tip = "vertical health bar next to the box" },
	{ key = "name", kind = "text", slot = "name", place = "above", tip = "player username" },
	{ key = "rank", kind = "text", slot = "rank", place = "above", tip = "team tag" },
	{ key = "distance", kind = "text", slot = "distance", place = "below", tip = "distance in studs" },
	{ key = "heldweapon", kind = "text", slot = "weapon", place = "below", tip = "equipped tool name" },
	{ key = "healthnumber", kind = "text", slot = "health", place = "below", tip = "health value" },
	{ key = "chams", kind = "chams", tip = "see the body through walls" },
}

do
	local enemy = visuals_tab:section({ name = "enemy" })
	local team = visuals_tab:section({ name = "team", side = "right" })
	local world = visuals_tab:section({ name = "world", side = "right" })
	local esp_settings = visuals_tab:section({ name = "esp settings", side = "right" })

	for _, group in next, {
		{ prefix = "enemy", section = enemy, master = "enables enemy esp" },
		{ prefix = "team", section = team, master = "enables teammate esp" },
	} do
		group.section:toggle({
			name = "enabled",
			flag = group.prefix .. "_esp",
			default = false,
			tooltip = group.master,
		})

		for _, row in next, ESP_ROWS do
			if row.kind == "text" then
				group.section
					:toggle({
						name = row.key,
						flag = group.prefix .. "_" .. row.key,
						default = false,
						tooltip = row.tip,
					})
					:colorpicker({
						flag = group.prefix .. "_" .. row.key .. "color",
						color = Color3.new(1, 1, 1),
					})
			elseif row.kind == "chams" then
				group.section:toggle({
					name = "chams",
					flag = group.prefix .. "_chams",
					default = false,
					tooltip = row.tip,
				})

				group.section
					:toggle({
						name = "chams visible only",
						flag = group.prefix .. "_chamsonlyvisible",
						default = false,
						tooltip = "drops chams while the body is behind cover",
					})
					:colorpicker({
						flag = group.prefix .. "_innerchamcolor",
						color = Color3.fromRGB(100, 0, 0),
						alpha = 0.4,
					})
					:colorpicker({
						flag = group.prefix .. "_outerchamcolor",
						color = Color3.new(1, 0, 0),
					})
			elseif row.kind == "healthbar" then
				group.section
					:toggle({
						name = "health bar",
						flag = group.prefix .. "_healthbar",
						default = false,
						tooltip = row.tip,
					})
					:colorpicker({
						flag = group.prefix .. "_lowhealth",
						color = Color3.fromRGB(255, 100, 100),
					})
					:colorpicker({
						flag = group.prefix .. "_fullhealth",
						color = Color3.fromRGB(100, 255, 100),
					})
			else
				local element = group.section:toggle({
					name = row.key,
					flag = group.prefix .. "_" .. row.key,
					default = false,
					tooltip = row.tip,
				})

				if row.alpha then
					element:colorpicker({
						flag = group.prefix .. "_" .. row.key .. "color",
						color = Color3.new(1, 0, 0),
						alpha = 0.2,
					})
				else
					element:colorpicker({
						flag = group.prefix .. "_" .. row.key .. "color",
						color = row.kind == "skeleton" and Color3.fromRGB(236, 251, 136) or Color3.new(1, 0, 0),
					})
				end
			end
		end
	end

	world:toggle({
		name = "world esp",
		flag = "world_esp",
		default = false,
		tooltip = "labels whatever Adapter.world_entities returns",
	})

	world
		:toggle({
			name = "world names",
			flag = "world_name",
			default = false,
			tooltip = "shows the entity label",
		})
		:colorpicker({ flag = "world_namecolor", color = Color3.fromRGB(0, 219, 255) })

	world
		:toggle({
			name = "world distance",
			flag = "world_distance",
			default = false,
			tooltip = "shows distance to the entity",
		})
		:colorpicker({ flag = "world_distancecolor", color = Color3.new(1, 1, 1) })

	world:slider({
		name = "world limit",
		flag = "world_limit",
		default = 60,
		min = 1,
		max = 400,
		interval = 1,
	})

	esp_settings:dropdown({
		name = "main font",
		flag = "espsettings_font",
		items = FONT_NAMES,
		default = "SourceSans",
	})

	esp_settings:slider({
		name = "main size",
		flag = "espsettings_size",
		default = 13,
		min = 8,
		max = 32,
		interval = 1,
	})

	esp_settings:dropdown({
		name = "main case",
		flag = "espsettings_case",
		items = { "none", "UPPERCASE", "lowercase" },
		default = "none",
	})

	esp_settings:dropdown({
		name = "flag font",
		flag = "espsettings_flagfont",
		items = FONT_NAMES,
		default = "Code",
	})

	esp_settings:slider({
		name = "flag size",
		flag = "espsettings_flagsize",
		default = 13,
		min = 8,
		max = 32,
		interval = 1,
	})

	esp_settings:dropdown({
		name = "flag case",
		flag = "espsettings_flagcase",
		items = { "none", "UPPERCASE", "lowercase" },
		default = "none",
	})

	esp_settings:toggle({
		name = "visible only",
		flag = "espsettings_visibleonly",
		default = false,
		tooltip = "drops esp for anyone the camera cannot see",
	})

	esp_settings
		:toggle({
			name = "fov circle",
			flag = "world_showfov",
			default = false,
			tooltip = "draws the aimbot fov ring around the crosshair",
		})
		:colorpicker({
			flag = "world_fovringcolor",
			color = Color3.fromRGB(127, 72, 163),
		})
end

do
	local aim = combat_tab:section({ name = "aimbot" })
	local silent = combat_tab:section({ name = "silent", side = "right" })
	local trigger = combat_tab:section({ name = "trigger", side = "right" })
	local gun = combat_tab:section({ name = "gun", side = "right" })

	aim:toggle({
		name = "enabled",
		flag = "aimbot_enabled",
		default = false,
		tooltip = "holds the crosshair on the closest valid target",
	})

	aim:keybind({
		name = "key",
		flag = "aimbot_key",
		mode = "hold",
		default = Enum.KeyCode.E,
	})

	aim:dropdown({
		name = "method",
		flag = "aimbot_method",
		items = { "mouse", "camera" },
		default = "mouse",
		tooltip = "mouse moves the cursor, camera writes the cframe",
	})

	aim:slider({
		name = "fov",
		suffix = "px",
		flag = "aimbot_fov",
		default = 180,
		min = 0,
		max = 900,
		interval = 1,
	})

	aim:slider({
		name = "smoothing",
		flag = "aimbot_smooth",
		default = 6,
		min = 1,
		max = 40,
		interval = 1,
		tooltip = "higher is slower and reads less robotic",
	})

	aim:slider({
		name = "prediction",
		suffix = "ms",
		flag = "aimbot_prediction",
		default = 0,
		min = 0,
		max = 500,
		interval = 1,
	})

	aim:dropdown({
		name = "priority",
		flag = "aimbot_priority",
		items = { "crosshair", "closest", "lowest health" },
		default = "crosshair",
	})

	aim:toggle({
		name = "team check",
		flag = "combat_team_check",
		default = true,
		tooltip = "never aims at your own team",
	})

	aim:toggle({
		name = "visibility check",
		flag = "aimbot_visible",
		default = true,
		tooltip = "skips targets behind geometry",
	})

	combat_tab:hitpart_picker({
		name = "hitparts",
		flag = "aimbot_hitparts",
		type = "R15",
		default = { "Head" },
		multi = true,
		side = "left",
	})

	silent:toggle({
		name = "silent aim",
		flag = "silent_enabled",
		default = false,
		tooltip = "rewrites the aim vector handed to the fire remote",
	})

	silent:slider({
		name = "silent fov",
		suffix = "px",
		flag = "silent_fov",
		default = 320,
		min = 0,
		max = 1200,
		interval = 1,
	})

	silent:toggle({
		name = "silent through walls",
		flag = "silent_wallbang",
		default = false,
		tooltip = "ignores the visibility raycast when picking a silent target",
	})

	silent:toggle({
		name = "rewrite any vector",
		flag = "silent_anyvector",
		default = false,
		tooltip = "off means only remotes named like a fire call get rewritten",
	})

	silent
		:toggle({
			name = "target indicator",
			flag = "silent_indicator",
			default = false,
			tooltip = "draws a line from the crosshair to the silent target",
		})
		:colorpicker({
			flag = "silent_indicatorcolor",
			color = Color3.fromRGB(255, 60, 0),
		})

	trigger:toggle({
		name = "triggerbot",
		flag = "trigger_enabled",
		default = false,
		tooltip = "fires as soon as a valid target enters the fov",
	})

	trigger:keybind({
		name = "key",
		flag = "trigger_key",
		mode = "hold",
		default = Enum.KeyCode.Q,
	})

	trigger:slider({
		name = "trigger fov",
		suffix = "px",
		flag = "trigger_fov",
		default = 60,
		min = 0,
		max = 600,
		interval = 1,
	})

	trigger:slider({
		name = "delay",
		suffix = "ms",
		flag = "trigger_delay",
		default = 40,
		min = 0,
		max = 500,
		interval = 1,
	})

	gun:toggle({
		name = "no recoil",
		flag = "gun_norecoil",
		default = false,
		tooltip = "zeroes the recoil property on the camera every frame",
	})

	gun:toggle({
		name = "no spread",
		flag = "gun_nospread",
		default = false,
		tooltip = "zeroes the spread property on the camera every frame",
	})

	gun:toggle({
		name = "rapid fire",
		flag = "gun_rapidfire",
		default = false,
		tooltip = "clicks for you while the fire button is held",
	})

	gun:slider({
		name = "fire rate",
		suffix = "rpm",
		flag = "gun_fireRate",
		default = 600,
		min = 60,
		max = 3000,
		interval = 30,
	})
end

do
	local info = settings_tab:section({ name = "recon" })
	local about = settings_tab:section({ name = "about", side = "right" })

	info:button({
		name = "scan game",
		callback = function()
			Adapter.report()
		end,
	})

	info:toggle({
		name = "watermark",
		flag = "ui_watermark",
		default = true,
		tooltip = "small fps banner in the corner",
	})

	info:toggle({
		name = "keybind hints",
		flag = "ui_hints",
		default = false,
		tooltip = "lists active combat modes on the watermark",
	})

	about:label({
		name = "adapter block at the top of the file is the only part that changes per game: team attribute, fire remote names, camera properties, world entities.",
	})

	about:label({
		name = "every combat mode ships off. run scan game before touching the code.",
	})
end

function Adapter.report()
	print("leet.cheats recon: place " .. tostring(game.PlaceId) .. " / " .. tostring(game.Name))

	local attributes = {}
	local roots = {}
	local remotes = {}

	for _, player in next, players:GetPlayers() do
		for name in next, player:GetAttributes() do
			attributes[name] = true
		end

		local root = Util.root(player.Character)

		if root then
			roots[root.Name] = (roots[root.Name] or 0) + 1
		end
	end

	local function keys(set)
		local out = {}

		for name in next, set do
			table.insert(out, name)
		end

		table.sort(out)

		return out
	end

	print("leet.cheats recon: player attributes = " .. table.concat(keys(attributes), ", "))
	print("leet.cheats recon: local rig = " .. Util.rig_of(lp.Character))

	for name, count in next, roots do
		print(string.format("leet.cheats recon: root %s seen %d", name, count))
	end

	local camera = workspace.CurrentCamera

	if camera then
		for _, name in next, { "Recoil", "Spread", "Bob", "Sway", "CameraAngle" } do
			local ok, value = pcall(function()
				return camera[name]
			end)

			if ok and value ~= nil then
				print(string.format("leet.cheats recon: camera.%s = %s", name, tostring(value)))
			end
		end
	end

	local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")

	if tool then
		print("leet.cheats recon: tool = " .. tool.Name)

		for _, child in next, tool:GetDescendants() do
			if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
				print("leet.cheats recon:   module " .. child:GetFullName())
			end
		end
	end

	for _, descendant in next, workspace:GetDescendants() do
		local class = descendant.ClassName

		if class == "RemoteEvent" or class == "UnrepeatedRemoteEvent" or class == "RemoteFunction" or class == "UnrepeatedRemoteFunction" then
			remotes[#remotes + 1] = class .. "  " .. descendant:GetFullName()
		end
	end

	print("leet.cheats recon: remotes = " .. #remotes)

	for index = 1, math.min(#remotes, 80) do
		print("leet.cheats recon:   " .. remotes[index])
	end

	local names = {}

	for _, entry in next, workspace:GetChildren() do
		table.insert(names, entry.ClassName .. " " .. entry.Name)
	end

	print("leet.cheats recon: workspace top level = " .. table.concat(names, " | "))
	print("leet.cheats recon: done")
end

local Combat = { silent_target = nil, last_click = 0 }

local Visual = { records = {}, world_records = {}, fov = nil, indicator = nil }

do
	if not Env.drawing then
		print("leet.cheats: Drawing unavailable, esp renderer stays off")
	end

	local function new_node(class)
		if not Env.drawing then
			return
		end

		local ok, node = pcall(function()
			return Drawing.new(class)
		end)

		return ok and node or nil
	end

	local function slot(owner, key, class)
		local node = owner[key]

		if node then
			return node
		end

		node = new_node(class)
		owner[key] = node

		return node
	end

	local function show(node, visible)
		if node then
			node.Visible = visible == true
		end
	end

	local function kill(node)
		if node then
			pcall(function()
				node:Remove()
			end)
		end
	end

	local function free(rec)
		for key, value in next, rec do
			if typeof(value) == "Instance" then
				pcall(function()
					value:Destroy()
				end)
			elseif type(value) == "table" then
				for _, child in next, value do
					kill(child)
				end

				table.clear(value)
			else
				kill(value)
			end
		end

		table.clear(rec)
	end

	Visual.free = free

	local chams_folder = nil

	local function chams_host()
		if chams_folder and chams_folder.Parent then
			return chams_folder
		end

		chams_folder = Instance.new("Folder")
		chams_folder.Name = "leet_esp"
		chams_folder.Parent = workspace

		return chams_folder
	end

	local function box_of(model, camera)
		local ok, center, size = pcall(function()
			local bound, extent = model:GetBoundingBox()
			return bound, extent
		end)

		if not ok then
			return
		end

		local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge

		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local screen = Util.project(camera, center:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz)))

					if screen then
						x0 = math.min(x0, screen.X)
						y0 = math.min(y0, screen.Y)
						x1 = math.max(x1, screen.X)
						y1 = math.max(y1, screen.Y)
					end
				end
			end
		end

		if x0 > x1 or y0 > y1 then
			return
		end

		return x0, y0, x1, y1
	end

	local function skeleton_links(rig)
		if rig == "R15" then
			return {
				{ "Head", "UpperTorso" },
				{ "UpperTorso", "LowerTorso" },
				{ "UpperTorso", "LeftUpperArm" },
				{ "LeftUpperArm", "LeftLowerArm" },
				{ "LeftLowerArm", "LeftHand" },
				{ "UpperTorso", "RightUpperArm" },
				{ "RightUpperArm", "RightLowerArm" },
				{ "RightLowerArm", "RightHand" },
				{ "LowerTorso", "LeftUpperLeg" },
				{ "LeftUpperLeg", "LeftLowerLeg" },
				{ "LeftLowerLeg", "LeftFoot" },
				{ "LowerTorso", "RightUpperLeg" },
				{ "RightUpperLeg", "RightLowerLeg" },
				{ "RightLowerLeg", "RightFoot" },
			}
		end

		return {
			{ "Head", "Torso" },
			{ "Torso", "Left Arm" },
			{ "Torso", "Right Arm" },
			{ "Torso", "Left Leg" },
			{ "Torso", "Right Leg" },
		}
	end

	local function text_for(which, entry)
		if which == "name" then
			return entry.player.Name
		elseif which == "rank" then
			return Adapter.team_tag(entry.player) or ""
		elseif which == "distance" then
			local camera = workspace.CurrentCamera
			local mine = Util.root(lp.Character)

			if camera and mine then
				return string.format("%.0fm", (camera.CFrame.Position - entry.root.Position).Magnitude)
			end

			return ""
		elseif which == "weapon" then
			local tool = entry.model:FindFirstChildOfClass("Tool")
			return tool and tool.Name or ""
		elseif which == "health" then
			return string.format("%.0f", math.max(0, entry.humanoid.Health))
		end

		return ""
	end

	local function styled(text, case_mode)
		if case_mode == "UPPERCASE" then
			return string.upper(text)
		elseif case_mode == "lowercase" then
			return string.lower(text)
		end

		return text
	end

	local function put_text(node, value, position, color, font_name, size)
		if not node then
			return
		end

		node.Text = value
		node.Position = position
		node.Color = color
		node.Size = size
		node.Font = FONT_IDS[font_name] or 2
		node.Center = true
		node.Outline = true
		node.Transparency = 0
		node.Visible = value ~= ""
	end

	local function line_between(node, a, b, color)
		if not node then
			return
		end

		node.From = a
		node.To = b
		node.Color = color
		node.Thickness = 1
		node.Transparency = 0
	end

	function Visual.frame()
		if not Env.drawing then
			return
		end

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport = camera.ViewportSize
		local center = viewport * 0.5
		local main_font = Util.pick("espsettings_font", "SourceSans")
		local main_size = Util.number("espsettings_size", 13)
		local main_case = flags.espsettings_case
		local flag_font = Util.pick("espsettings_flagfont", "Code")
		local flag_size = Util.number("espsettings_flagsize", 13)
		local flag_case = flags.espsettings_flagcase
		local visible_only = Util.on("espsettings_visibleonly")
		local keep = {}

		for _, entry in next, Adapter.valid_targets() do
			if not Adapter.is_self(entry.player) then
				local prefix = entry.enemy and "enemy" or "team"

				if Util.on(prefix .. "_esp") then
					local rec = Visual.records[entry.player]

					if not rec then
						rec = {}
						Visual.records[entry.player] = rec
					end

					keep[entry.player] = true

					local x0, y0, x1, y1 = box_of(entry.model, camera)

					if x0 then
						local height = y1 - y0
						local width = x1 - x0
						local cx = (x0 + x1) * 0.5
						local above = y0 - 4
						local below = y1 + 6
						local seen = not visible_only or Util.can_see(camera, entry.root.Position, entry.model)

						for _, row in next, ESP_ROWS do
							if row.kind ~= "healthbar" then
								local want = seen and Util.on(prefix .. "_" .. row.key)

								if row.kind == "box" then
									local color = Util.color(prefix .. "_boxcolor", Color3.new(1, 0, 0))
									local lines = rec.box_lines

									if not lines then
										lines = {}
										rec.box_lines = lines
									end

									line_between(slot(lines, 1, "Line"), Vector2.new(x0, y0), Vector2.new(x1, y0), color)
									line_between(slot(lines, 2, "Line"), Vector2.new(x1, y0), Vector2.new(x1, y1), color)
									line_between(slot(lines, 3, "Line"), Vector2.new(x1, y1), Vector2.new(x0, y1), color)
									line_between(slot(lines, 4, "Line"), Vector2.new(x0, y1), Vector2.new(x0, y0), color)

									for index = 1, 4 do
										show(lines[index], want)
									end
								elseif row.kind == "fill" then
									local color, alpha = Util.color(prefix .. "_filledboxcolor", Color3.new(1, 0, 0))
									local square = slot(rec, "fill", "Square")

									if square then
										square.Position = Vector2.new(x0, y0)
										square.Size = Vector2.new(width, height)
										square.Filled = true
										square.Color = color
										square.Transparency = 1 - alpha
									end

									show(square, want)
								elseif row.kind == "skeleton" then
									local color = Util.color(prefix .. "_skeletoncolor", Color3.fromRGB(236, 251, 136))
									local lines = rec.skel_lines

									if not lines then
										lines = {}
										rec.skel_lines = lines
									end

									local links = skeleton_links(Util.rig_of(entry.model))

									for index, link in next, links do
										local a = entry.model:FindFirstChild(link[1])
										local b = entry.model:FindFirstChild(link[2])
										local pa = a and Util.project(camera, a.Position)
										local pb = b and Util.project(camera, b.Position)
										local line = slot(lines, index, "Line")

										if pa and pb then
											line_between(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), color)
										end

										show(line, want and pa ~= nil and pb ~= nil)
									end

									for index = #links + 1, 20 do
										show(lines[index], false)
									end
								elseif row.kind == "head" then
									local color = Util.color(prefix .. "_headdotcolor", Color3.new(1, 0, 0))
									local head = entry.model:FindFirstChild("Head")
									local screen = head and Util.project(camera, head.Position)
									local circle = slot(rec, "head", "Circle")

									if circle and screen then
										circle.Position = Vector2.new(screen.X, screen.Y)
										circle.Radius = math.max(2, height * 0.045)
										circle.NumSides = 12
										circle.Filled = true
										circle.Color = color
										circle.Thickness = 1
										circle.Transparency = 0
									end

									show(circle, want and screen ~= nil)
								elseif row.kind == "snap" then
									local line = slot(rec, "snap", "Line")
									line_between(line, center, Vector2.new(cx, y0 + height * 0.5), Util.color(prefix .. "_snaplinescolor", Color3.new(1, 1, 1)))
									show(line, want)
								elseif row.kind == "tracer" then
									local line = slot(rec, "tracer", "Line")
									line_between(line, Vector2.new(center.X, viewport.Y), Vector2.new(cx, y1), Util.color(prefix .. "_tracerscolor", Color3.new(1, 1, 1)))
									show(line, want)
								elseif row.kind == "chams" then
									local highlight = rec.chams

									if not highlight and Env.highlight then
										highlight = Instance.new("Highlight")
										highlight.Name = ""
										highlight.Adornee = entry.model
										highlight.FillTransparency = 0.4
										highlight.OutlineTransparency = 0
										highlight.Parent = chams_host()

										rec.chams = highlight
									end

									if highlight then
										local inner, inner_alpha = Util.color(prefix .. "_innerchamcolor", Color3.fromRGB(100, 0, 0))
										local outer = Util.color(prefix .. "_outerchamcolor", Color3.new(1, 0, 0))

										highlight.FillColor = inner
										highlight.FillTransparency = 1 - inner_alpha
										highlight.OutlineColor = outer

										local gate = want

										if gate and Util.on(prefix .. "_chamsonlyvisible") then
											gate = Util.can_see(camera, entry.root.Position, entry.model)
										end

										highlight.Enabled = gate
									end
								elseif row.kind == "text" then
									local is_flag = row.slot ~= "name" and row.slot ~= "rank"
									local font = is_flag and flag_font or main_font
									local size = is_flag and flag_size or main_size
									local case = is_flag and flag_case or main_case
									local color = Util.color(prefix .. "_" .. row.key .. "color", Color3.new(1, 1, 1))
									local node = slot(rec, "txt_" .. row.slot, "Text")
									local value = want and styled(text_for(row.slot, entry), case) or ""

									if row.place == "above" then
										put_text(node, value, Vector2.new(cx, above), color, font, size)
										above = above - (size + 2)
									else
										put_text(node, value, Vector2.new(cx, below), color, font, size)
										below = below + (size + 2)
									end
								end
							end
						end

						local bar = seen and Util.on(prefix .. "_healthbar")
						local ratio = math.clamp(entry.humanoid.Health / math.max(1, entry.humanoid.MaxHealth), 0, 1)
						local back = slot(rec, "hp_back", "Square")
						local fill = slot(rec, "hp_fill", "Square")

						if back then
							back.Position = Vector2.new(x0 - 6, y0)
							back.Size = Vector2.new(3, height)
							back.Filled = true
							back.Color = Color3.fromRGB(14, 14, 16)
							back.Transparency = 0
						end

						if fill then
							local low = Util.color(prefix .. "_lowhealth", Color3.fromRGB(255, 100, 100))
							local full = Util.color(prefix .. "_fullhealth", Color3.fromRGB(100, 255, 100))

							fill.Position = Vector2.new(x0 - 6, y1 - height * ratio)
							fill.Size = Vector2.new(3, height * ratio)
							fill.Filled = true
							fill.Color = low:Lerp(full, ratio)
							fill.Transparency = 0
						end

						show(back, bar)
						show(fill, bar)
					end
				end
			end
		end

		for player, rec in next, Visual.records do
			if not keep[player] then
				free(rec)
				Visual.records[player] = nil
			end
		end

		local world_keep = {}

		if Util.on("world_esp") then
			local limit = Util.number("world_limit", 60)
			local flag_font_name = Util.pick("espsettings_flagfont", "Code")
			local flag_size_value = Util.number("espsettings_flagsize", 13)

			for _, item in next, Adapter.world_entities() do
				local key = item.key or item.name

				if limit <= 0 then
					break
				end

				if key and typeof(item.position) == "Vector3" then
					limit = limit - 1

					local node = Visual.world_records[key]

					if not node then
						node = {}
						Visual.world_records[key] = node
					end

					world_keep[key] = true

					local screen = Util.project(camera, item.position)

					if screen then
						if Util.on("world_name") then
							local text = slot(node, "label", "Text")

							put_text(
								text,
								styled(tostring(item.label or item.name or ""), flags.espsettings_flagcase),
								Vector2.new(screen.X, screen.Y - 10),
								Util.color("world_namecolor", Color3.fromRGB(0, 219, 255)),
								flag_font_name,
								flag_size_value
							)
						else
							show(node.label, false)
						end

						if Util.on("world_distance") then
							local text = slot(node, "dist", "Text")

							put_text(
								text,
								string.format("%.0fm", (camera.CFrame.Position - item.position).Magnitude),
								Vector2.new(screen.X, screen.Y + 6),
								Util.color("world_distancecolor", Color3.new(1, 1, 1)),
								flag_font_name,
								flag_size_value
							)
						else
							show(node.dist, false)
						end
					end
				end
			end
		end

		for key, node in next, Visual.world_records do
			local alive_now = world_keep[key] ~= nil

			if not alive_now or not Util.on("world_esp") then
				free(node)
				Visual.world_records[key] = nil
			end
		end

		local fov_on = Util.on("world_showfov")

		if fov_on and not Visual.fov then
			Visual.fov = new_node("Circle")
		end

		if Visual.fov then
			Visual.fov.Position = center
			Visual.fov.Radius = Util.number("aimbot_fov", 180)
			Visual.fov.NumSides = 60
			Visual.fov.Filled = false
			Visual.fov.Thickness = 1
			Visual.fov.Color = Util.color("world_fovringcolor", Color3.fromRGB(127, 72, 163))
			Visual.fov.Transparency = 0
			Visual.fov.Visible = fov_on
		end

		local want_indicator = Util.on("silent_indicator") and Combat.silent_target ~= nil

		if want_indicator and not Visual.indicator then
			Visual.indicator = new_node("Line")
		end

		if Visual.indicator then
			local screen = Combat.silent_target and Util.project(camera, Combat.silent_target)

			if screen then
				line_between(
					Visual.indicator,
					center,
					Vector2.new(screen.X, screen.Y),
					Util.color("silent_indicatorcolor", Color3.fromRGB(255, 60, 0))
				)
			end

			show(Visual.indicator, want_indicator and screen ~= nil)
		end
	end

	function Visual.teardown()
		for _, rec in next, Visual.records do
			free(rec)
		end

		for _, rec in next, Visual.world_records do
			free(rec)
		end

		Visual.records = {}
		Visual.world_records = {}

		kill(Visual.fov)
		kill(Visual.indicator)

		Visual.fov = nil
		Visual.indicator = nil

		if chams_folder then
			pcall(function()
				chams_folder:Destroy()
			end)

			chams_folder = nil
		end
	end
end

do
	local function best_target(radius, names, need_visible, prediction)
		local camera = workspace.CurrentCamera

		if not camera or radius <= 0 then
			return
		end

		local center = camera.ViewportSize * 0.5
		local priority = Util.pick("aimbot_priority", "crosshair")
		local best, best_score

		for _, entry in next, Adapter.valid_targets() do
			local allowed = entry.enemy or not Util.on("combat_team_check")

			if allowed and not Adapter.is_self(entry.player) then
				local point = Adapter.aim_point(entry, names, camera, prediction)

				if point then
					local screen = Util.project(camera, point)

					if screen then
						local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude

						if dist <= radius and (not need_visible or Util.can_see(camera, point, entry.model)) then
							local score = dist

							if priority == "closest" then
								score = (camera.CFrame.Position - point).Magnitude
							elseif priority == "lowest health" then
								score = entry.humanoid.Health
							end

							if not best_score or score < best_score then
								best_score = score
								best = { entry = entry, point = point, screen = screen }
							end
						end
					end
				end
			end
		end

		return best
	end

	Combat.best_target = best_target

	function Combat.frame()
		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		Combat.silent_target = nil

		local names = Util.list("aimbot_hitparts")

		if #names == 0 then
			names = { "Head" }
		end

		if Util.on("gun_norecoil") then
			Adapter.zero(camera, "Recoil")
		end

		if Util.on("gun_nospread") then
			Adapter.zero(camera, "Spread")
		end

		if Util.on("silent_enabled") then
			local target = best_target(
				Util.number("silent_fov", 320),
				names,
				not Util.on("silent_wallbang"),
				0
			)

			if target then
				Combat.silent_target = target.point
			end
		end

		if Util.on("aimbot_enabled") and Util.key_active("aimbot_key") then
			local target = best_target(
				Util.number("aimbot_fov", 180),
				names,
				Util.on("aimbot_visible"),
				Util.number("aimbot_prediction", 0)
			)

			if target then
				local center = camera.ViewportSize * 0.5
				local smooth = math.max(1, Util.number("aimbot_smooth", 6))

				if Util.pick("aimbot_method", "mouse") == "camera" then
					local goal = CFrame.lookAt(camera.CFrame.Position, target.point)
					camera.CFrame = camera.CFrame:Lerp(goal, 1 / smooth)
				else
					Util.move_mouse(Vector2.new(
						(target.screen.X - center.X) / smooth,
						(target.screen.Y - center.Y) / smooth
					))
				end
			end
		end

		local want_trigger = Util.on("trigger_enabled") and Util.key_active("trigger_key")
		local want_rapid = Util.on("gun_rapidfire")

		if (want_trigger or want_rapid) and Env.click then
			local ok_held, down = pcall(function()
				return uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			end)

			local held = ok_held and down == true

			local interval

			if want_rapid then
				interval = 60 / math.max(60, Util.number("gun_fireRate", 600))
			else
				interval = Util.number("trigger_delay", 40) / 1000
			end

			local due = (os.clock() - Combat.last_click) >= interval

			if want_trigger then
				local target = best_target(Util.number("trigger_fov", 60), names, true, 0)

				if target and due then
					Combat.last_click = os.clock()
					pcall(getgenv().mouse1click)
				end
			elseif want_rapid and held and due then
				Combat.last_click = os.clock()
				pcall(getgenv().mouse1click)
			end
		end
	end

	local function fire_like(node)
		if Util.on("silent_anyvector") then
			return true
		end

		return Adapter.is_fire_remote(node)
	end

	Combat.fire_like = fire_like

	if Env.closure then
		local metatable = getrawmetatable(game)
		local old_namecall = metatable.__namecall

		setreadonly(metatable, false)

		metatable.__namecall = newcclosure(function(self, ...)
			local ok, method = pcall(getnamecallmethod)

			if not (ok and method == "FireServer" and Util.on("silent_enabled") and Combat.silent_target) then
				return old_namecall(self, ...)
			end

			if Env.check_caller and checkcaller() then
				return old_namecall(self, ...)
			end

			if not fire_like(self) then
				return old_namecall(self, ...)
			end

			local args = { ... }

			for index, value in next, args do
				if typeof(value) == "Vector3" then
					args[index] = Combat.silent_target
				end
			end

			return old_namecall(self, unpack(args, 1, #args))
		end)

		setreadonly(metatable, true)

		Combat.restore = function()
			setreadonly(metatable, false)
			metatable.__namecall = old_namecall
			setreadonly(metatable, true)
		end
	else
		print("leet.cheats: no namecall access, silent aim stays off")
	end

	function Combat.teardown()
		if Combat.restore then
			pcall(Combat.restore)
		end
	end
end

local Watermark = { fps = 0, clock = time(), frames = 0 }

do
	local function gui_parent()
		if Env.hui then
			local getter = getgenv().gethui or getgenv().getplayergui
			local ok, node = pcall(getter)

			if ok and node then
				return node
			end
		end

		return game:GetService("CoreGui")
	end

	local gui = leet:new_item("ScreenGui", {
		Parent = gui_parent(),
		Name = "leet_watermark",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local shell = leet:new_item("Frame", {
		Parent = gui,
		Name = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.fromOffset(190, 20),
		BackgroundColor3 = Color3.fromRGB(8, 8, 8),
		BorderSizePixel = 0,
		ZIndex = 50,
	})

	local body = leet:new_item("Frame", {
		Parent = shell,
		Name = "",
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Color3.fromRGB(22, 22, 22),
		BorderColor3 = Color3.fromRGB(56, 56, 56),
		BorderSizePixel = 1,
		ZIndex = 51,
	})

	local label = leet:new_item("TextLabel", {
		Parent = body,
		Name = "",
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -10, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "leet.cheats",
		FontFace = leet.font,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 12,
		TextStrokeTransparency = 0.5,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
	})

	Watermark.gui = gui
	Watermark.shell = shell
	Watermark.label = label

	function Watermark.tick()
		Watermark.shell.Visible = Util.on("ui_watermark")

		if not Watermark.shell.Visible then
			return
		end

		Watermark.frames = Watermark.frames + 1

		local now = time()
		local span = now - Watermark.clock

		if span >= 0.5 then
			Watermark.fps = math.floor(Watermark.frames / span + 0.5)
			Watermark.frames = 0
			Watermark.clock = now
		end

		local text = string.format("leet.cheats  %d fps", Watermark.fps)

		if Util.on("ui_hints") then
			local hints = {}

			if Util.on("aimbot_enabled") and Util.key_active("aimbot_key") then
				table.insert(hints, "aim")
			end

			if Util.on("silent_enabled") then
				table.insert(hints, "silent")
			end

			if Util.on("trigger_enabled") then
				table.insert(hints, "trigger")
			end

			if Util.on("gun_norecoil") then
				table.insert(hints, "norecoil")
			end

			if #hints > 0 then
				text = text .. "  " .. table.concat(hints, " ")
			end
		end

		if Watermark.label.Text ~= text then
			Watermark.label.Text = text
		end
	end

	function Watermark.teardown()
		pcall(function()
			gui:Destroy()
		end)
	end
end

local cleaned = false

local last_fault = ""

local function guarded(fn)
	local ok, err = pcall(fn)

	if ok then
		return
	end

	if err ~= last_fault then
		last_fault = err
		print("leet.cheats: " .. tostring(err))
	end
end

local function teardown()
	if cleaned then
		return
	end

	cleaned = true

	Visual.teardown()
	Combat.teardown()
	Watermark.teardown()

	print("leet.cheats: starter unloaded")
end

leet:connection(run_service.RenderStepped, function()
	if leet.dead then
		teardown()
		return
	end

	guarded(Visual.frame)
	guarded(Combat.frame)
	guarded(Watermark.tick)
end)

leet:connection(players.PlayerRemoving, function(player)
	local rec = Visual.records[player]

	if rec then
		Visual.free(rec)
		Visual.records[player] = nil
	end
end)

if not leet:load_last_config() then
	print("leet.cheats: no autoload config yet")
end

leet:enable_autosave()

leet:notification({
	text = "leet.cheats starter loaded",
	time = 4,
})

visuals_tab.open_tab()

print("leet.cheats: starter ready, run scan game in settings first")
