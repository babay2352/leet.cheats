local COMMIT = "7e2e709c06e1ab27dd06c08139f4e2f46134756e"
local REPO_RAW = "https://raw.githubusercontent.com/babay2352/leet.cheats/" .. COMMIT
local BUILD = "5"
local LIB_BYTES = 147735

print("leet.cheats: apr2 build " .. BUILD)

getgenv().LEET_FONT_URL = REPO_RAW .. "/fonts/fs-tahoma-8px.ttf"

local lib_src = game:HttpGet(REPO_RAW .. "/lib.lua")

if #lib_src ~= LIB_BYTES then
	print(string.format(
		"leet.cheats: lib.lua serves %d bytes instead of %d, that is a stale cdn copy, wait a minute",
		#lib_src,
		LIB_BYTES
	))
end

local leet = loadstring(lib_src)()
local flags = leet.flags

local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local lighting = game:GetService("Lighting")
local uis = game:GetService("UserInputService")
local collection = game:GetService("CollectionService")
local replicated = game:GetService("ReplicatedStorage")
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

	Env.identity = 0

	for _, level in next, { 3, 2 } do
		local ok = pcall(function()
			setthreadidentity(level)
		end)

		if ok then
			Env.identity = level

			break
		end
	end

	local named, executor = pcall(identifyexecutor)
	Env.executor = named and tostring(executor) or "unknown"
	Env.mouse_rel = has("mousemoverel")
	Env.click = has("mouse1click")
	Env.clipboard = has("setclipboard")
	Env.hui = has("gethui") or has("getplayergui")
	Env.server = run_service:IsServer()

	print(string.format(
		"leet.cheats: executor=%s identity=%d drawing=%s highlight=%s mouse=%s click=%s hui=%s",
		Env.executor,
		Env.identity,
		tostring(Env.drawing),
		tostring(Env.highlight),
		tostring(Env.mouse_rel),
		tostring(Env.click),
		tostring(Env.hui)
	))
end

local Game = {}

do
	local cache = {}

	function Game.module(...)
		local names = { ... }
		local key = table.concat(names, ".")
		local slot = cache[key]

		if slot then
			return slot.value
		end

		local node = replicated
		local value = nil

		for _, name in next, names do
			if typeof(node) == "Instance" then
				node = node:FindFirstChild(name)
			else
				node = nil
			end
		end

		if node and node:IsA("ModuleScript") then
			local ok, result = pcall(require, node)

			if ok then
				value = result
			end
		end

		cache[key] = { value = value }

		return value
	end
end

do
	local config = Game.module("WeaponSystemAssets", "GameConfig") or {}
	local zombie = config.zombieDamage or {}

	Game.config = config
	Game.zombie_folder = zombie.folderName or "Zombies"
	Game.health_attr = zombie.healthAttribute or "Health"
	Game.dead_attr = zombie.deadAttribute or "Dead"
	Game.zombie_zones = zombie.partMultipliers or {}
	Game.meter = tonumber(config.meterMultiplier) or 3.5
	Game.balance = Game.module("WeaponSystemAssets", "WeaponBalance") or {}
	Game.stats = Game.module("WeaponSystemAssets", "Modules", "WeaponStats")
	Game.faction = Game.module("Shared", "FactionMapConfig")
	Game.crash = Game.module("Shared", "HeliCrashConfig")
	Game.walk_speed = tonumber(config.walkSpeed) or 14
	Game.sprint_speed = tonumber(config.sprintSpeed) or 24
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
		local key = entry.key
		local ok, pressed = pcall(function()
			if key == nil then
				return false
			end

			if typeof(key) == "EnumItem" and key.EnumType == Enum.UserInputType then
				return uis:IsMouseButtonPressed(key)
			end

			return uis:IsKeyDown(key)
		end)

		return (ok and pressed == true) or entry.active == true
	end

	return entry.active == true
end

function Util.first(model, ...)
	if not model then
		return
	end

	for _, name in next, { ... } do
		local found = model:FindFirstChild(name)

		if found then
			return found
		end
	end
end

function Util.humanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

function Util.root(model)
	return Util.first(model, "HumanoidRootPart", "Torso", "UpperTorso")
end

function Util.rig_of(model)
	if model and model:FindFirstChild("HumanoidRootPart") and model:FindFirstChild("LowerTorso") then
		return "R15"
	end

	return "R6"
end

function Util.attr_number(node, name)
	local ok, value = pcall(function()
		return node:GetAttribute(name)
	end)

	if ok and type(value) == "number" then
		return value
	end
end

function Util.attr_bool(node, name)
	local ok, value = pcall(function()
		return node:GetAttribute(name)
	end)

	if ok and type(value) == "boolean" then
		return value
	end
end

function Util.attr_vector(node, name)
	local ok, value = pcall(function()
		return node:GetAttribute(name)
	end)

	if ok and typeof(value) == "Vector3" then
		return value
	end
end

function Util.alive(model)
	local humanoid = Util.humanoid(model)

	if humanoid then
		return humanoid.Health > 0
	end

	return false
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

local ray_params = nil

local function ignore_list()
	return { workspace.CurrentCamera, lp.Character }
end

function Util.sees(camera, point, model)
	if not ray_params then
		ray_params = RaycastParams.new()

		if not pcall(function()
			ray_params.FilterType = Enum.RaycastFilterType.Exclude
		end) then
			pcall(function()
				ray_params.FilterType = Enum.RaycastFilterType.Blacklist
			end)
		end

		pcall(function()
			ray_params.IgnoreWater = true
		end)
	end

	ray_params.FilterDescendantsInstances = ignore_list()

	local hit = workspace:Raycast(camera.CFrame.Position, point - camera.CFrame.Position, ray_params)

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

function Util.press_fire()
	if Env.click then
		pcall(getgenv().mouse1click)
	end
end

function Util.meters(studs)
	return studs / Game.meter
end

function Util.clamp_rotation(from, to, max_degrees)
	local look = to.LookVector
	local origin = from.Position

	if max_degrees <= 0 then
		return CFrame.lookAt(origin, look)
	end

	local step = math.rad(max_degrees)
	local current = from.LookVector
	local dot = math.clamp(current:Dot(look), -1, 1)
	local angle = math.acos(dot)

	if angle <= step or angle < 0.0001 then
		return CFrame.lookAt(origin, look)
	end

	local t = step / angle

	return CFrame.lookAt(origin, current:Lerp(look, t))
end

function Util.zone_parts(rig, zones)
	local r6 = {
		head = { "Head" },
		torso = { "Torso", "HumanoidRootPart" },
		body = { "Torso", "HumanoidRootPart" },
		arms = { "Left Arm", "Right Arm" },
		legs = { "Left Leg", "Right Leg" },
	}
	local r15 = {
		head = { "Head" },
		torso = { "UpperTorso", "LowerTorso" },
		body = { "UpperTorso", "LowerTorso", "HumanoidRootPart" },
		arms = { "LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm" },
		legs = { "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg" },
	}

	local table_for = rig == "R15" and r15 or r6
	local seen = {}
	local out = {}

	for _, zone in next, zones do
		local names = table_for[tostring(zone):lower()] or {}

		for _, name in next, names do
			seen[name] = true
		end
	end

	return seen
end

local Catalog = {}

do
	local index = nil
	local kinds = {
		weapons = { kind = "weapon", color = Color3.fromRGB(255, 196, 64) },
		ammo = { kind = "ammo", color = Color3.fromRGB(255, 138, 46) },
		consumables = { kind = "consumable", color = Color3.fromRGB(103, 199, 125) },
		backpack = { kind = "backpack", color = Color3.fromRGB(86, 200, 255) },
		misc = { kind = "misc", color = Color3.fromRGB(200, 200, 200) },
	}

	function Catalog.build()
		if index then
			return index
		end

		index = {}

		local items = Game.module("Shared", "Items")

		if type(items) ~= "table" then
			return index
		end

		for id, entry in next, items do
			if type(entry) == "table" then
				if type(entry.name) == "string" then
					index[entry.name:lower()] = entry
				end

				if type(id) == "string" then
					index[id:lower()] = entry
				end
			end
		end

		return index
	end

	function Catalog.entry(label)
		if type(label) ~= "string" then
			return
		end

		local map = Catalog.build()

		return map[label:lower()] or map[(label:gsub("^%s+", "")):lower()]
	end

	function Catalog.kind(entry, label)
		if entry and entry.itemtype and kinds[entry.itemtype] then
			return kinds[entry.itemtype].kind
		end

		if type(label) == "string" and Game.balance[label] then
			return "weapon"
		end

		if entry and entry.itemtype == "backpacks" then
			return "backpack"
		end

		return "misc"
	end
end

local Sources = {}

do
	function Sources.character(player)
		if player == lp then
			return player.Character
		end

		local folder = workspace:FindFirstChild("Players")
		local model = folder and folder:FindFirstChild(player.Name)

		if model and model:IsA("Model") then
			return model
		end

		model = workspace:FindFirstChild(player.Name)

		if model and model:IsA("Model") then
			return model
		end

		return player.Character
	end

	function Sources.faction(player)
		if Game.faction and Game.faction.GetFaction then
			local ok, value = pcall(Game.faction.GetFaction, player)

			if ok and type(value) == "string" then
				return value
			end
		end

		local ok, team = pcall(function()
			return player.Team
		end)

		if ok and team then
			return team.Name
		end
	end

	local roles_module = Game.module("Shared", "GroupRoles")
	local faction_config = Game.module("Shared", "common", "config", "factionConfig")
	local universal_group = tonumber(faction_config and faction_config.universalGroupId)
	local rank_cache = {}
	local rank_queue = {}
	local rank_waiting = {}

	function Sources.rank(player)
		return rank_cache[player.UserId]
	end

	function Sources.rank_request(player)
		local id = player.UserId

		if not (roles_module and universal_group) or rank_cache[id] ~= nil or rank_waiting[id] then
			return
		end

		rank_waiting[id] = true

		table.insert(rank_queue, id)
	end

	task.spawn(function()
		while leet and not leet.dead do
			local id = table.remove(rank_queue, 1)

			if id then
				local ok, rank, name = pcall(roles_module.GetHighestRank, id, universal_group)
				local value = ""

				if ok and rank ~= nil and type(name) == "string" and name ~= "" then
					value = name

					if Game.faction and Game.faction.ShortRank then
						local short, mapped = pcall(Game.faction.ShortRank, name)

						if short and type(mapped) == "string" then
							value = mapped
						end
					end
				end

				rank_cache[id] = value
				rank_waiting[id] = nil

				task.wait(0.3)
			else
				task.wait(0.5)
			end
		end
	end)

	function Sources.relation(player)
		if player == lp then
			return "self"
		end

		local mine = Sources.faction(lp)
		local theirs = Sources.faction(player)

		if mine ~= nil and theirs ~= nil and mine == theirs then
			return "team"
		end

		if theirs == nil then
			return Util.pick("esp_neutral_bucket", "neutral")
		end

		return "enemy"
	end

	function Sources.deployed(player)
		local ok, value = pcall(function()
			return player:GetAttribute("MenuStatus")
		end)

		return ok and value == "deployed"
	end

	local function new_entity(key, model, part, position)
		return {
			key = key,
			model = model,
			root = part,
			position = position or (part and part.Position),
			humanoid = Util.humanoid(model),
			rig = Util.rig_of(model),
			text = {},
		}
	end

	function Sources.players()
		local out = {}

		for _, player in next, players:GetPlayers() do
			if player ~= lp then
				local model = Sources.character(player)
				local humanoid = Util.humanoid(model)
				local root = Util.root(model)

				if model and humanoid and root and humanoid.Health > 0 then
					if not Util.on("esp_only_deployed") or Sources.deployed(player) then
						local entry = new_entity("p_" .. player.Name, model, root)

						entry.player = player
						entry.relation = Sources.relation(player)
						entry.prefix = entry.relation
						entry.humanoid = humanoid
						entry.health = humanoid.Health
						entry.maxhealth = humanoid.MaxHealth
						entry.text.name = player.DisplayName ~= "" and player.DisplayName or player.Name
						entry.text.sub = Sources.faction(player) or "CIVILIAN"
						entry.text.extra = Sources.rank(player) or ""
						entry.text.health = string.format("%.0f", humanoid.Health)
						entry.tool = model:FindFirstChildOfClass("Tool")

						Sources.rank_request(player)

						if entry.tool then
							entry.text.weapon = entry.tool.Name
						end

						local ok, value = pcall(function()
							return model:GetAttribute("Stance")
						end)

						if ok and type(value) == "string" then
							entry.text.stance = value
						end

						table.insert(out, entry)
					end
				end
			end
		end

		return out
	end

	function Sources.zombies()
		local out = {}
		local folder = workspace:FindFirstChild(Game.zombie_folder) or workspace:FindFirstChild("zombiers")

		if not folder then
			return out
		end

		for _, model in next, folder:GetChildren() do
			if model:IsA("Model") then
				local root = Util.root(model)
				local humanoid = Util.humanoid(model)
				local health = Util.attr_number(model, Game.health_attr)
				local dead = Util.attr_bool(model, Game.dead_attr)

				if humanoid and health == nil then
					health = humanoid.Health
				end

				if root and health ~= nil and not (dead == true) and health > 0 then
					local entry = new_entity("z_" .. model.Name, model, root)
					local _, _, kind = model.Name:find("^Zombie_(%d+)_(.+)$")

					entry.kind = kind or model.Name
					entry.prefix = "zombie"
					entry.health = health
					entry.maxhealth = humanoid and humanoid.MaxHealth or Util.attr_number(model, "MaxHealth")
					entry.text.name = entry.kind
					entry.text.sub = string.format("hp %.0f", health)
					entry.text.health = string.format("%.0f", health)

					table.insert(out, entry)
				end
			end
		end

		return out
	end

	local function split_label(name)
		local guid, label = name:match("^(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)(.+)$")

		if guid then
			return label, guid
		end

		return name, nil
	end

	function Sources.loot()
		local out = {}
		local folder = workspace:FindFirstChild("grounditems")

		if not folder then
			return out
		end

		for _, node in next, folder:GetChildren() do
			local part, model = nil, nil

			if node:IsA("BasePart") then
				part = node
				model = node
			elseif node:IsA("Model") then
				model = node
				part = Util.root(node) or node:FindFirstChildOfClass("BasePart")
			end

			if part and model then
				local label = split_label(node.Name)
				local entry = Catalog.entry(label)
				local item = new_entity("l_" .. node.Name, model, part)

				item.prefix = "loot"
				item.kind = Catalog.kind(entry, label)
				item.label = label
				item.entry = entry
				item.text.name = label
				item.text.sub = item.kind
				item.text.extra = entry and entry.itemtype or "?"

				table.insert(out, item)
			end
		end

		return out
	end

	function Sources.vehicles()
		local out = {}
		local seen = {}

		local function push(model)
			if not model or seen[model] or not model:IsA("Model") then
				return
			end

			seen[model] = true

			local part = Util.root(model) or model:FindFirstChildOfClass("BasePart")

			if not part then
				return
			end

			local destroyed = Util.attr_bool(model, "Vehicle_Destroyed")
			local health = Util.attr_number(model, "Vehicle_HP")
			local maxhealth = Util.attr_number(model, "Vehicle_MaxHP")
			local fuel = Util.attr_number(model, "Fuel_Current")
			local maxfuel = Util.attr_number(model, "Fuel_Max")
			local name = nil

			local ok, value = pcall(function()
				return model:GetAttribute("Vehicle_Name")
			end)

			if ok and type(value) == "string" then
				name = value
			end

			local entry = new_entity("v_" .. model:GetFullName(), model, part)

			entry.prefix = "vehicle"
			entry.health = health
			entry.maxhealth = maxhealth
			entry.destroyed = destroyed == true
			entry.text.name = name or model.Name
			entry.text.sub = health and string.format("%.0f/%.0f", health, maxhealth or 100) or nil
			entry.text.extra = fuel and maxfuel and string.format("fuel %.0f%%", (fuel / math.max(1, maxfuel)) * 100) or nil

			local seats = model:FindFirstChildWhichIsA("VehicleSeat") or model:FindFirstChildWhichIsA("Seat")

			if seats and seats.Occupant then
				entry.text.state = "occupied"
			elseif destroyed == true then
				entry.text.state = "wreck"
			else
				entry.text.state = "empty"
			end

			table.insert(out, entry)
		end

		local tagged = nil

		pcall(function()
			tagged = collection:GetTagged("Vehicle_Chassis")
		end)

		if tagged then
			for _, model in next, tagged do
				push(model)
			end
		end

		local folder = workspace:FindFirstChild("Vehicles")

		if folder then
			for _, model in next, folder:GetChildren() do
				push(model)
			end
		end

		return out
	end

	function Sources.corpses()
		local out = {}

		local function push(model, prefix, label)
			local part = Util.root(model) or model:FindFirstChild("Head") or model:FindFirstChildOfClass("BasePart")

			if not part then
				return
			end

			local entry = new_entity("c_" .. model:GetFullName(), model, part)

			entry.prefix = prefix
			entry.text.name = label
			entry.dead = true

			table.insert(out, entry)
		end

		local folder = workspace:FindFirstChild("PlayerCorpses")

		if folder then
			for _, model in next, folder:GetChildren() do
				if model:IsA("Model") then
					push(model, "corpse", (model.Name:gsub("'s corpse$", "")))
				end
			end
		end

		local zombies = workspace:FindFirstChild("ZombieCorpses")

		if zombies then
			for _, model in next, zombies:GetChildren() do
				if model:IsA("Model") then
					push(model, "corpse", "zombie corpse")
				end
			end
		end

		for _, model in next, workspace:GetChildren() do
			if model:IsA("Model") and model.Name:match("_Dead$") then
				push(model, "corpse", (model.Name:gsub("_Dead$", "")))
			end
		end

		return out
	end

	function Sources.events()
		local out = {}
		local specs = {
			{ "Airdrop", "AIRDROP", "Airdrops" },
			{ "Convoy", "CONVOY", "Convoy" },
			{ "HeliCrash", "HELI CRASH", "HeliCrash" },
		}

		for _, spec in next, specs do
			local token, label, folder_name = spec[1], spec[2], spec[3]
			local position = Util.attr_vector(workspace, token .. "Position")
			local state = nil
			local ok, value = pcall(function()
				return workspace:GetAttribute(token .. "State")
			end)

			if ok then
				state = value
			end

			if position then
				local entry = new_entity("e_" .. token, nil, nil, position)

				entry.prefix = "event"
				entry.text.name = label
				entry.text.sub = state and tostring(state) or nil
				entry.text.extra = Sources.nearest(position)

				table.insert(out, entry)
			else
				local folder = workspace:FindFirstChild(folder_name)

				if folder then
					for _, node in next, folder:GetChildren() do
						local part = node:IsA("BasePart") and node or (node:IsA("Model") and (Util.root(node) or node:FindFirstChildOfClass("BasePart")))

						if part then
							local entry = new_entity("e_" .. token .. "_" .. node.Name, node, part)

							entry.prefix = "event"
							entry.text.name = label
							entry.text.extra = Sources.nearest(part.Position)

							table.insert(out, entry)
						end
					end
				end
			end
		end

		return out
	end

	function Sources.containers()
		local out = {}
		local folder = workspace:FindFirstChild("_ClientPrefabVisuals")

		if not folder then
			return out
		end

		for _, model in next, folder:GetChildren() do
			if model:IsA("Model") then
				local part = Util.root(model) or model:FindFirstChildOfClass("BasePart")

				if part then
					local entry = new_entity("b_" .. model:GetFullName(), model, part)

					entry.prefix = "container"
					entry.text.name = (model.Name:gsub("_Model_ClientVisual$", "")):gsub("^_", "")

					table.insert(out, entry)
				end
			end
		end

		return out
	end

	function Sources.nearest(position)
		local areas = Game.crash and Game.crash.Areas

		if type(areas) ~= "table" then
			return
		end

		local best, best_dist

		for _, area in next, areas do
			if type(area) == "table" and type(area[2]) == "number" and type(area[3]) == "number" then
				local dx = position.X - area[2]
				local dz = position.Z - area[3]
				local dist = math.sqrt(dx * dx + dz * dz)

				if not best_dist or dist < best_dist then
					best_dist = dist
					best = area[1]
				end
			end
		end

		if best and best_dist then
			return string.format("%s  %.0fm", tostring(best), Util.meters(best_dist))
		end
	end
end

local Scene = { list = {}, built = 0, seen = {}, painted = 0 }

local CATS = {
	{
		prefix = "enemy",
		title = "enemy players",
		master = "esp_enemy",
		rows = { "box", "fill", "skeleton", "headdot", "healthbar", "healthnumber", "name", "sub", "distance", "weapon", "stance", "snaplines", "tracers", "chams", "visible" },
		color = Color3.new(1, 0, 0),
	},
	{
		prefix = "team",
		title = "teammates",
		master = "esp_team",
		rows = { "box", "fill", "skeleton", "headdot", "healthbar", "healthnumber", "name", "sub", "distance", "weapon", "stance", "tracers", "chams", "visible" },
		color = Color3.new(0, 1, 0),
	},
	{
		prefix = "neutral",
		title = "unaffiliated",
		master = "esp_neutral",
		rows = { "box", "fill", "skeleton", "headdot", "healthbar", "healthnumber", "name", "sub", "distance", "weapon", "tracers", "chams" },
		color = Color3.fromRGB(0, 219, 255),
	},
	{
		prefix = "zombie",
		title = "zombies",
		master = "esp_zombie",
		rows = { "box", "fill", "skeleton", "headdot", "healthbar", "healthnumber", "name", "distance", "tracers", "chams" },
		color = Color3.fromRGB(255, 140, 0),
	},
	{
		prefix = "loot",
		title = "ground loot",
		master = "esp_loot",
		rows = { "marker", "box", "name", "sub", "distance", "tracers" },
		color = Color3.fromRGB(255, 196, 64),
	},
	{
		prefix = "vehicle",
		title = "vehicles",
		master = "esp_vehicle",
		rows = { "box", "fill", "name", "sub", "state", "distance", "chams" },
		color = Color3.fromRGB(220, 220, 60),
	},
	{
		prefix = "corpse",
		title = "corpses",
		master = "esp_corpse",
		rows = { "marker", "name", "distance" },
		color = Color3.fromRGB(160, 160, 160),
	},
	{
		prefix = "event",
		title = "events",
		master = "esp_event",
		rows = { "marker", "name", "sub", "extra", "distance", "tracers" },
		color = Color3.fromRGB(255, 60, 200),
	},
	{
		prefix = "container",
		title = "buildings",
		master = "esp_container",
		rows = { "box", "name", "distance" },
		color = Color3.fromRGB(120, 150, 255),
	},
}

local ROW_TIPS = {
	box = "rectangular outline",
	fill = "solid fill inside the box",
	skeleton = "joint lines through the rig",
	headdot = "circle on the head",
	healthbar = "vertical bar beside the box",
	healthnumber = "raw health value",
	name = "main label above the box",
	sub = "faction / type under the name",
	extra = "third line, per category",
	weapon = "held tool name",
	stance = "standing, crouch, prone attribute",
	distance = "distance in meters",
	snaplines = "line from the crosshair",
	tracers = "line from the bottom of the screen",
	chams = "see the body through walls",
	marker = "dot at the entity position",
	visible = "writes visible when the camera can see it",
	state = "occupied, empty or wreck",
}

local FONT_NAMES = { "Arial", "Gotham", "SourceSans", "Code" }
local FONT_IDS = { Arial = 0, Gotham = 1, SourceSans = 2, Code = 3 }

local Options = {}

do
	local applied = {}
	local toggle_names = {
		off = "off",
		on = "on",
		low = "low",
		medium = "medium",
		high = "high",
		full = "full",
	}

	local function enum_value(name)
		if name == nil then
			return nil
		end

		if type(name) == "number" then
			return name
		end

		local values = Game.module("Shared", "common", "enums", "ToggleValues")

		if type(values) == "table" and values[name] then
			return values[name]
		end

		return name
	end

	local function setting_key(name)
		local settings = Game.module("Shared", "common", "enums", "Setting")

		if type(settings) == "table" and settings[name] then
			return settings[name]
		end

		return "setting." .. tostring(name)
	end

	local function controller()
		return Game.module("Shared", "Systems", "ClientSettingsController")
	end

	function Options.apply(key_name, value, want)
		local node = controller()

		if type(node) ~= "table" or type(node.Set) ~= "function" then
			if want then
				print("leet.cheats: ClientSettingsController unavailable, " .. key_name .. " stays as is")
			end

			return false
		end

		local key = setting_key(key_name)

		if not want then
			local stored = applied[key]

			if stored ~= nil then
				pcall(node.Set, key, stored)
				applied[key] = nil
			end

			return true
		end

		local target = enum_value(value)
		local ok_now, current = pcall(node.Get, key)

		if ok_now and current == target then
			return true
		end

		if ok_now and applied[key] == nil then
			applied[key] = current
		end

		local ok_set, accepted = pcall(node.Set, key, target)

		if ok_set and accepted == false then
			local stored = applied[key]

			if stored ~= nil then
				pcall(node.Set, key, stored)
				applied[key] = nil
			end

			print("leet.cheats: game refused " .. key_name .. ", value is not in its own list")

			return false
		end

		return true
	end

	function Options.multiply(name, value)
		local node = controller()

		if type(node) ~= "table" or type(node[name]) ~= "function" then
			return false
		end

		local state = Options.overrides

		if state[name] == nil then
			state[name] = node[name]
		end

		if value == nil then
			node[name] = state[name]
			state[name] = nil

			return true
		end

		node[name] = function()
			return value
		end

		return true
	end

	Options.overrides = {}
	Options.applied = applied
	Options.names = toggle_names
end

local Recon = {}

do
	local function folder_inventory(name)
		local folder = workspace:FindFirstChild(name)

		if not folder then
			print("leet.cheats recon: workspace." .. name .. " = missing")
			return
		end

		local children = folder:GetChildren()

		print(string.format("leet.cheats recon: workspace.%s = %d children, first = %s", name, #children, tostring(children[1] and children[1].Name)))

		return children
	end

	local function attributes(node, label)
		if not node then
			return
		end

		local names = {}

		for name, value in next, node:GetAttributes() do
			table.insert(names, name .. "=" .. tostring(value))
		end

		table.sort(names)

		print("leet.cheats recon: " .. label .. " attributes: " .. table.concat(names, ", "))
	end

	function Recon.run()
		print("leet.cheats recon: place " .. tostring(game.PlaceId) .. " job " .. tostring(game.JobId))
		print("leet.cheats recon: build " .. BUILD .. " server=" .. tostring(Env.server))

		folder_inventory("Players")
		folder_inventory(Game.zombie_folder)
		folder_inventory("grounditems")
		folder_inventory("Vehicles")
		folder_inventory("PlayerCorpses")
		folder_inventory("ZombieCorpses")
		folder_inventory("_ClientPrefabVisuals")
		folder_inventory("Airdrops")
		folder_inventory("Convoy")
		folder_inventory("HeliCrash")

		local names = {}

		for _, node in next, workspace:GetChildren() do
			table.insert(names, node.ClassName .. " " .. node.Name)
		end

		print("leet.cheats recon: workspace top = " .. table.concat(names, " | "))

		local zombie = workspace:FindFirstChild(Game.zombie_folder)

		attributes(zombie and zombie:FindFirstChildOfClass("Model"), "zombie")

		local loot = workspace:FindFirstChild("grounditems")
		local first_loot = loot and loot:FindFirstChildOfClass("BasePart")

		if first_loot then
			print("leet.cheats recon: loot sample name = " .. first_loot.Name)
			print("leet.cheats recon: loot class = " .. first_loot.ClassName)
		end

		local vehicle = workspace:FindFirstChild("Vehicles")

		attributes(vehicle and vehicle:FindFirstChildOfClass("Model"), "vehicle")

		print("leet.cheats recon: airdrop position = " .. tostring(Util.attr_vector(workspace, "AirdropPosition")))
		print("leet.cheats recon: convoy position = " .. tostring(Util.attr_vector(workspace, "ConvoyPosition")))
		print("leet.cheats recon: heli crash position = " .. tostring(Util.attr_vector(workspace, "HeliCrashPosition")))

		local modules = {
			{ "GameConfig", Game.config },
			{ "FactionMapConfig", Game.faction },
			{ "HeliCrashConfig", Game.crash },
			{ "WeaponStats", Game.stats },
			{ "WeaponBalance", Game.balance },
		}

		for _, spec in next, modules do
			print("leet.cheats recon: module " .. spec[1] .. " = " .. (spec[2] and "ok" or "missing"))
		end

		print("leet.cheats recon: Items entries = " .. (Catalog.build() and #Catalog.build() or 0))
		print("leet.cheats recon: meterMultiplier = " .. tostring(Game.meter) .. " walkSpeed = " .. tostring(Game.walk_speed))

		local character = Sources.character(lp)

		print("leet.cheats recon: my rig = " .. Util.rig_of(character) .. " character = " .. tostring(character and character:GetFullName()))
		print("leet.cheats recon: my faction = " .. tostring(Sources.faction(lp)))

		for _, player in next, players:GetPlayers() do
			print(string.format(
				"leet.cheats recon: %s faction=%s relation=%s deployed=%s model=%s",
				player.Name,
				tostring(Sources.faction(player)),
				tostring(Sources.relation(player)),
				tostring(Sources.deployed(player)),
				tostring(Sources.character(player) and "ok" or "none")
			))
		end

		local camera = workspace.CurrentCamera

		if camera then
			for _, name in next, { "Recoil", "Spread", "Bob", "Sway", "CameraAngle", "FieldOfView" } do
				local ok, value = pcall(function()
					return camera[name]
				end)

				if ok and value ~= nil then
					print(string.format("leet.cheats recon: camera.%s = %s", name, tostring(value)))
				end
			end
		end

		local tool = character and character:FindFirstChildOfClass("Tool")

		if tool then
			local stats = (function()
				local ok, value = pcall(function()
					return Game.stats and Game.stats.Get(tool)
				end)

				return ok and value
			end)()

			print("leet.cheats recon: tool = " .. tool.Name .. " stats = " .. (stats and "ok" or "nil"))

			if type(stats) == "table" then
				print("leet.cheats recon: recoil table = " .. tostring(stats.recoil and stats.recoil.vertical))
				print("leet.cheats recon: hipFireSpread = " .. tostring(stats.hipFireSpread))
			end
		else
			print("leet.cheats recon: no tool equipped, weapon handling stays untested")
		end

		local remote_names = {}

		for _, node in next, replicated:GetChildren() do
			if node.ClassName == "RemoteEvent" or node.ClassName == "RemoteFunction" or node:IsA("Folder") then
				table.insert(remote_names, node.ClassName .. " " .. node.Name)
			end
		end

		print("leet.cheats recon: replicatedstorage top = " .. table.concat(remote_names, " | "))

		local serde = replicated:FindFirstChild("AutoSerde")

		if serde then
			local list = {}

			for _, node in next, serde:GetChildren() do
				table.insert(list, node.Name)
			end

			table.sort(list)

			print("leet.cheats recon: AutoSerde messages = " .. #list .. " -> " .. table.concat(list, ", "))
		end

		print("leet.cheats recon: _RMH present = " .. tostring(replicated:FindFirstChild("_RMH") ~= nil))
		print("leet.cheats recon: scene entries this frame = " .. #Scene.list)
		print("leet.cheats recon: done")
	end
end

local window = leet:window({
	name = "leet.cheats | AR2",
	size = UDim2.fromOffset(600, 680),
})

local esp_tab = window:tab({ name = "esp" })
local legit_tab = window:tab({ name = "legit" })
local visuals_tab = window:tab({ name = "visuals" })
local configs_tab = window:tab({ name = "configs" })

do
	local by_prefix = {}

	for _, spec in next, CATS do
		by_prefix[spec.prefix] = spec
	end

	Scene.spec = by_prefix

	local sections = {}

	for _, spec in next, CATS do
		sections[spec.prefix] = esp_tab:section({
			name = spec.title,
			side = spec.prefix == "team" and "right" or (spec.prefix == "enemy" and "left" or "right"),
		})
	end

	local settings = esp_tab:section({ name = "esp settings", side = "right" })

	for _, spec in next, CATS do
		local section = sections[spec.prefix]

		section:toggle({
			name = "enabled",
			flag = spec.master,
			default = false,
			tooltip = "master switch for " .. spec.title .. " esp",
		})

		for _, row in next, spec.rows do
			if row == "healthbar" then
				section
					:toggle({
						name = "health bar",
						flag = spec.prefix .. "_healthbar",
						default = false,
						tooltip = ROW_TIPS.healthbar,
					})
					:colorpicker({ flag = spec.prefix .. "_lowhealth", color = Color3.fromRGB(255, 100, 100) })
					:colorpicker({ flag = spec.prefix .. "_fullhealth", color = Color3.fromRGB(100, 255, 100) })
			elseif row == "chams" then
				section:toggle({
					name = "chams",
					flag = spec.prefix .. "_chams",
					default = false,
					tooltip = ROW_TIPS.chams,
				})

				section
					:toggle({
						name = "chams visible only",
						flag = spec.prefix .. "_chamsonlyvisible",
						default = false,
						tooltip = "drops chams while the body is behind cover",
					})
					:colorpicker({
						flag = spec.prefix .. "_innerchamcolor",
						color = spec.color,
						alpha = 0.4,
					})
					:colorpicker({
						flag = spec.prefix .. "_outerchamcolor",
						color = spec.color,
					})
			elseif row == "fill" then
				section
					:toggle({
						name = row,
						flag = spec.prefix .. "_" .. row,
						default = false,
						tooltip = ROW_TIPS[row],
					})
					:colorpicker({
						flag = spec.prefix .. "_" .. row .. "color",
						color = spec.color,
						alpha = 0.2,
					})
			else
				section
					:toggle({
						name = row == "sub" and "faction / type" or (row == "extra" and "detail line" or row),
						flag = spec.prefix .. "_" .. row,
						default = false,
						tooltip = ROW_TIPS[row] or row,
					})
					:colorpicker({
						flag = spec.prefix .. "_" .. row .. "color",
						color = row == "name" and Color3.new(1, 1, 1) or spec.color,
					})
			end
		end

		section:slider({
			name = "max distance",
			suffix = "m",
			flag = spec.prefix .. "_maxdistance",
			default = spec.prefix == "container" and 400 or 1200,
			min = 10,
			max = 4000,
			interval = 10,
			tooltip = "studs are converted with the game's own meterMultiplier",
		})

		section:slider({
			name = "screen limit",
			flag = spec.prefix .. "_limit",
			default = spec.prefix == "loot" and 40 or 120,
			min = 1,
			max = 400,
			interval = 1,
			tooltip = "closest entities drawn, keeps the frame cheap in town",
		})

		if spec.prefix == "loot" then
			section:toggle({
				name = "weapons only",
				flag = "loot_only_weapon",
				default = false,
				tooltip = "hides food, materials and junk",
			})

			section:toggle({
				name = "hide junk",
				flag = "loot_hide_misc",
				default = false,
				tooltip = "skips the misc category entirely",
			})
		end
	end

	settings:dropdown({
		name = "factionless players",
		flag = "esp_neutral_bucket",
		items = { "neutral", "enemy", "team" },
		default = "neutral",
		tooltip = "civilians have no Team, this decides which esp group they land in",
	})

	settings:toggle({
		name = "deployed only",
		flag = "esp_only_deployed",
		default = false,
		tooltip = "reads the MenuStatus attribute, skips players still in the lobby",
	})

	settings:toggle({
		name = "visible only",
		flag = "espsettings_visibleonly",
		default = false,
		tooltip = "drops esp for anyone behind geometry",
	})

	settings:toggle({
		name = "team esp sees through walls",
		flag = "espsettings_teampierce",
		default = false,
		tooltip = "keeps teammate esp on even when occluded",
	})

	settings:toggle({
		name = "show destroyed vehicles",
		flag = "espsettings_wrecks",
		default = false,
		tooltip = "keeps wrecks in the vehicle esp list, hidden by default",
	})

	settings:dropdown({
		name = "main font",
		flag = "espsettings_font",
		items = FONT_NAMES,
		default = "SourceSans",
	})

	settings:slider({
		name = "main size",
		flag = "espsettings_size",
		default = 13,
		min = 8,
		max = 32,
		interval = 1,
	})

	settings:dropdown({
		name = "main case",
		flag = "espsettings_case",
		items = { "none", "UPPERCASE", "lowercase" },
		default = "none",
	})

	settings:dropdown({
		name = "flag font",
		flag = "espsettings_flagfont",
		items = FONT_NAMES,
		default = "Code",
	})

	settings:slider({
		name = "flag size",
		flag = "espsettings_flagsize",
		default = 12,
		min = 8,
		max = 32,
		interval = 1,
	})

	settings:dropdown({
		name = "flag case",
		flag = "espsettings_flagcase",
		items = { "none", "UPPERCASE", "lowercase" },
		default = "none",
	})

	settings:slider({
		name = "line thickness",
		flag = "espsettings_thickness",
		default = 1,
		min = 1,
		max = 6,
		interval = 1,
	})
end

do
	local aim = legit_tab:section({ name = "aim assist" })
	local trigger = legit_tab:section({ name = "trigger bot", side = "right" })
	local handling = legit_tab:section({ name = "weapon handling", side = "right" })

	aim:toggle({
		name = "enabled",
		flag = "aim_enabled",
		default = false,
		tooltip = "rotates the camera toward the closest legal target",
	})

	aim:keybind({
		name = "key",
		flag = "aim_key",
		mode = "hold",
		default = Enum.UserInputType.MouseButton2,
		tooltip = "hold to assist, the game already uses this for aiming",
	})

	aim:dropdown({
		name = "method",
		flag = "aim_method",
		items = { "camera", "mouse" },
		default = "camera",
		tooltip = "camera writes the cframe, mouse uses mousemoverel",
	})

	aim:slider({
		name = "fov",
		suffix = "px",
		flag = "aim_fov",
		default = 140,
		min = 0,
		max = 900,
		interval = 1,
	})

	aim:slider({
		name = "smoothing",
		flag = "aim_smooth",
		default = 8,
		min = 1,
		max = 40,
		interval = 1,
		tooltip = "higher is slower and reads less robotic",
	})

	aim:slider({
		name = "max turn",
		suffix = "deg",
		flag = "aim_maxturn",
		default = 6,
		min = 0,
		max = 90,
		interval = 1,
		tooltip = "caps how far the camera may rotate in one frame, 0 disables the cap",
	})

	aim:slider({
		name = "prediction",
		suffix = "ms",
		flag = "aim_predict",
		default = 60,
		min = 0,
		max = 400,
		interval = 10,
	})

	aim:dropdown({
		name = "priority",
		flag = "aim_priority",
		items = { "crosshair", "closest", "lowest health" },
		default = "crosshair",
	})

	aim:dropdown({
		name = "targets",
		flag = "aim_targets",
		items = { "players", "zombies" },
		multi = true,
		default = { "players" },
		tooltip = "zombies have no Humanoid, their health comes from the Health attribute",
	})

	aim:dropdown({
		name = "hit zones",
		flag = "aim_zones",
		items = { "head", "torso", "arms", "legs" },
		multi = true,
		default = { "head", "torso" },
		tooltip = "mapped to R6 or R15 part names per model",
	})

	aim:toggle({
		name = "team check",
		flag = "aim_team_check",
		default = true,
		tooltip = "never aims at your own faction",
	})

	aim:toggle({
		name = "visibility check",
		flag = "aim_visible",
		default = true,
		tooltip = "skips targets behind geometry",
	})

	aim:toggle({
		name = "lock fov circle",
		flag = "aim_showfov",
		default = false,
		tooltip = "draws the assist fov ring",
	})

	aim:colorpicker({
		name = "fov color",
		flag = "aim_fovcolor",
		color = Color3.fromRGB(127, 72, 163),
	})

	trigger:toggle({
		name = "enabled",
		flag = "trig_enabled",
		default = false,
		tooltip = "clicks the moment a legal target sits under the crosshair",
	})

	trigger:keybind({
		name = "key",
		flag = "trig_key",
		mode = "hold",
		default = Enum.KeyCode.P,
		tooltip = "P is free in the game keybind list",
	})

	trigger:slider({
		name = "fov",
		suffix = "px",
		flag = "trig_fov",
		default = 40,
		min = 0,
		max = 400,
		interval = 1,
	})

	trigger:slider({
		name = "delay",
		suffix = "ms",
		flag = "trig_delay",
		default = 60,
		min = 0,
		max = 500,
		interval = 5,
		tooltip = "reaction time, 0 is humanly impossible",
	})

	trigger:dropdown({
		name = "targets",
		flag = "trig_targets",
		items = { "players", "zombies" },
		multi = true,
		default = { "players" },
	})

	trigger:toggle({
		name = "require scope",
		flag = "trig_require_ads",
		default = true,
		tooltip = "only fires while the aiming key is held",
	})

	trigger:toggle({
		name = "team check",
		flag = "trig_team_check",
		default = true,
	})

	handling:toggle({
		name = "no recoil",
		flag = "wh_norecoil",
		default = false,
		tooltip = "zeroes the recoil table the client reads from WeaponStats",
	})

	handling:slider({
		name = "recoil removed",
		suffix = "%",
		flag = "wh_recoil_amount",
		default = 100,
		min = 0,
		max = 100,
		interval = 5,
	})

	handling:toggle({
		name = "no hipfire spread",
		flag = "wh_nospread",
		default = false,
		tooltip = "zeroes hipFireSpread and move spread on the equipped tool",
	})

	handling:toggle({
		name = "no view bob",
		flag = "wh_nobob",
		default = false,
		tooltip = "overrides the game's own GetViewBobMultiplier",
	})

	handling:toggle({
		name = "no flinch shake",
		flag = "wh_noflinch",
		default = false,
		tooltip = "overrides GetCameraShakeMultiplier used by IncomingFireFeedback",
	})

	handling:toggle({
		name = "no camera shake from own shots",
		flag = "wh_nocamshake",
		default = false,
		tooltip = "zeroes recoil.camShake in the weapon stats table",
	})

	handling:label({
		name = "hits are computed by the server, so silent aim is not available here",
	})
end

do
	local world = visuals_tab:section({ name = "world" })
	local camera = visuals_tab:section({ name = "camera", side = "right" })
	local crosshair = visuals_tab:section({ name = "crosshair", side = "right" })
	local options = visuals_tab:section({ name = "game options", side = "right" })

	world:toggle({
		name = "fullbright",
		flag = "vis_fullbright",
		default = false,
		tooltip = "re-applies every frame, the server writes lighting for the day cycle",
	})

	world:slider({
		name = "brightness",
		flag = "vis_bright",
		default = 3,
		min = 1,
		max = 12,
		interval = 0.1,
	})

	world:toggle({
		name = "no fog",
		flag = "vis_nofog",
		default = false,
		tooltip = "pushes fog end out and disables Atmosphere",
	})

	world:toggle({
		name = "no shadows",
		flag = "vis_noshadows",
		default = false,
	})

	world:toggle({
		name = "time of day",
		flag = "vis_time_on",
		default = false,
		tooltip = "writes Lighting.ClockTime, midday is easiest to read",
	})

	world:slider({
		name = "clock",
		suffix = "h",
		flag = "vis_time",
		default = 13,
		min = 0,
		max = 24,
		interval = 0.5,
	})

	world:toggle({
		name = "kill post effects",
		flag = "vis_nopost",
		default = false,
		tooltip = "removes Blur, ColorCorrection and Bloom inside Lighting",
	})

	camera:toggle({
		name = "fov override",
		flag = "vis_fov_on",
		default = false,
		tooltip = "the game clamps its own fov setting to 1..120",
	})

	camera:slider({
		name = "fov",
		flag = "vis_fov",
		default = 90,
		min = 40,
		max = 120,
		interval = 1,
	})

	camera:toggle({
		name = "keep fov while aiming",
		flag = "vis_fov_hold",
		default = false,
		tooltip = "re-applies the fov every frame instead of only on change",
	})

	camera:toggle({
		name = "third person distance",
		flag = "vis_tp_on",
		default = false,
		tooltip = "raises CameraMaxZoomDistance, the game itself owns the perspective key",
	})

	camera:slider({
		name = "distance",
		suffix = "studs",
		flag = "vis_tp_distance",
		default = 20,
		min = 3,
		max = 60,
		interval = 1,
	})

	local function add_crosshair_line(section, index)
		section
			:toggle({
				name = index,
				flag = "cross_" .. index,
				default = false,
				tooltip = "crosshair " .. index .. " line",
			})
			:colorpicker({
				flag = "cross_" .. index .. "color",
				color = Color3.new(1, 1, 1),
			})
	end

	crosshair:toggle({
		name = "custom crosshair",
		flag = "cross_enabled",
		default = false,
		tooltip = "replaces the game crosshair visually, does not touch the game hud",
	})

	crosshair:dropdown({
		name = "style",
		flag = "cross_style",
		items = { "cross", "dot", "circle", "corner" },
		default = "cross",
	})

	crosshair:slider({
		name = "length",
		flag = "cross_length",
		default = 8,
		min = 1,
		max = 40,
		interval = 1,
	})

	crosshair:slider({
		name = "gap",
		flag = "cross_gap",
		default = 4,
		min = 0,
		max = 30,
		interval = 1,
	})

	crosshair:slider({
		name = "thickness",
		flag = "cross_thickness",
		default = 1,
		min = 1,
		max = 6,
		interval = 1,
	})

	crosshair
		:toggle({
			name = "outline",
			flag = "cross_outline",
			default = false,
			tooltip = "draws a dark copy behind every line",
		})
		:colorpicker({
			flag = "cross_outlinecolor",
			color = Color3.new(0, 0, 0),
		})

	crosshair:colorpicker({
		name = "color",
		flag = "cross_color",
		color = Color3.new(0, 1, 0),
	})

	local function option_toggle(section, name, flag, key, off_value, on_value, tip)
		section:toggle({
			name = name,
			flag = flag,
			default = false,
			tooltip = tip,
			callback = function(bool)
				Options.apply(key, bool and on_value or off_value, bool)
			end,
		})
	end

	option_toggle(
		options,
		"hit markers",
		"go_hitmarkers",
		"hitMarkers",
		"off",
		"on",
		"the game's own hit marker option"
	)

	option_toggle(
		options,
		"show fps",
		"go_showfps",
		"showFps",
		"off",
		"on",
		"writes the game setting, not our watermark"
	)

	option_toggle(
		options,
		"show ping",
		"go_showping",
		"showPing",
		"off",
		"on",
		"game hud stat"
	)

	option_toggle(
		options,
		"show player count",
		"go_showcount",
		"showPlayerCount",
		"off",
		"on",
		"game hud stat"
	)

	option_toggle(
		options,
		"auto reload",
		"go_autoreload",
		"autoReload",
		"off",
		"on",
		"game's own automatic reload option"
	)

	option_toggle(
		options,
		"auto chamber",
		"go_autochamber",
		"autoChamber",
		"off",
		"on",
		"game's own chamber-on-scope option"
	)

	option_toggle(
		options,
		"interiors always loaded",
		"go_interiors",
		"interiorLoadDistance",
		75,
		600,
		"raises the interior load distance to the config maximum"
	)

	option_toggle(
		options,
		"louisville interiors",
		"go_interiors_louisville",
		"louisvilleInteriorLoadDistance",
		75,
		600,
		"same option for the louisville interiors"
	)

	option_toggle(options, "shadows in game options", "go_shadows", "shadows", "off", "on", "writes the game setting instead of Lighting")

	local zombie_updates = 0

	options:dropdown({
		name = "zombie visual update",
		flag = "go_zombie_update",
		items = { "low", "medium", "high", "full" },
		default = "full",
		tooltip = "how often zombie visuals refresh, full keeps animated zombies readable",
		callback = function(bool)
			if zombie_updates == 0 then
				zombie_updates = 1

				return
			end

			Options.apply("zombieVisualUpdating", Util.pick("go_zombie_update", "full"), true)
		end,
	})

	options:label({
		name = "these are the game's own options written through its own controller, they persist to your profile",
	})
end

do
	local theming = configs_tab:section({ name = "theming system" })
	local configs = configs_tab:section({ name = "configuration system", side = "right" })
	local session = configs_tab:section({ name = "session", side = "right" })
	local about = configs_tab:section({ name = "about", side = "right" })

	theming:toggle({
		name = "keybind list",
		flag = "keybind_list",
		default = false,
		tooltip = "floating list of every bound key",
		callback = function(bool)
			window.toggle_list(bool)
		end,
	})

	theming:toggle({
		name = "player list",
		flag = "player_list",
		default = false,
		tooltip = "side panel with every player in the server",
		callback = function(bool)
			window.toggle_playerlist(bool)
		end,
	})

	theming:toggle({
		name = "watermark",
		flag = "watermark",
		default = false,
		tooltip = "corner banner with fps, round state and live modes",
	})

	theming:toggle({
		name = "keybind hints",
		flag = "ui_hints",
		default = false,
		tooltip = "lists the live modes on the watermark",
	})

	local ui_binds = 0

	theming:keybind({
		name = "ui bind",
		flag = "ui_bind",
		display = "menu",
		default = Enum.KeyCode.End,
		tooltip = "shows or hides the whole menu",
		callback = function(bool)
			ui_binds = ui_binds + 1

			if ui_binds == 1 then
				return
			end

			window.set_menu_visibility(not bool)
		end,
	})

	theming:slider({
		name = "colorpicker animation",
		flag = "color_picker_anim_speed",
		default = 2,
		min = 0,
		max = 5,
		interval = 0.01,
		tooltip = "pulse speed inside open colorpickers",
	})

	theming:colorpicker({
		name = "accent color",
		flag = "accent",
		color = Color3.fromHex("#6464FF"),
		tooltip = "retints the whole menu",
		callback = function(color)
			leet:update_theme("accent", color)
		end,
	})

	window.toggle_watermark(false)

	local dir = leet.directory .. "/configs/"
	local reset_config = ""

	local function notify(text)
		leet:notification({ text = text, time = 3 })
	end

	local function refresh_list()
		if not pcall(leet.config_list_update, leet) then
			notify("config list unreadable on this executor")
		end
	end

	leet.config_holder = configs:dropdown({
		name = "configs",
		items = {},
		flag = "config_name_list",
		tooltip = "saved configs on disk, the buttons act on the one picked here",
	})

	configs:textbox({
		placeholder = "new config name",
		flag = "config_name_text_box",
		tooltip = "name create writes to, letters digits _ - . only",
	})

	local function chosen()
		if not leet.has_files then
			notify("executor has no file access")
			return
		end

		local entry = flags["config_name_list"]
		local name = type(entry) == "table" and entry[1] or entry

		if type(name) ~= "string" or #name == 0 then
			notify("pick a config from the dropdown first")
			return
		end

		return name
	end

	local function typed()
		if not leet.has_files then
			notify("executor has no file access")
			return
		end

		local name = flags["config_name_text_box"]

		if type(name) ~= "string" then
			notify("type a config name first")
			return
		end

		name = name:gsub("[^%w_%-%.]", "")

		if #name == 0 or name == "." or name == ".." then
			notify("type a config name first")
			return
		end

		return name
	end

	configs:button({
		name = "create",
		tooltip = "writes a new cfg from the name in the box",
		callback = function()
			local name = typed()

			if not name then
				return
			end

			if pcall(writefile, dir .. name .. ".cfg", leet:get_config()) then
				refresh_list()
				notify("created " .. name)
			else
				notify("create failed")
			end
		end,
	})

	configs:button({
		name = "delete",
		tooltip = "removes the picked cfg after asking",
		callback = function()
			local name = chosen()

			if not name then
				return
			end

			leet:panel({
				name = "delete " .. name .. " ?",
				options = { "Yes", "No" },
				callback = function(option)
					if option ~= "Yes" then
						return
					end

					if pcall(delfile, dir .. name .. ".cfg") then
						refresh_list()
						notify("deleted " .. name)
					else
						notify("delete failed")
					end
				end,
			})
		end,
	})

	configs:button({
		name = "load",
		tooltip = "applies the picked cfg to every flag right now",
		callback = function()
			local name = chosen()

			if not name then
				return
			end

			local ok, body = pcall(readfile, dir .. name .. ".cfg")

			if ok and pcall(function()
				leet:load_config(body)
			end) then
				notify("loaded " .. name)
			else
				notify("load failed")
			end
		end,
	})

	configs:button({
		name = "save",
		tooltip = "overwrites the picked cfg with the current flags",
		callback = function()
			local name = chosen()

			if not name then
				return
			end

			if pcall(writefile, dir .. name .. ".cfg", leet:get_config()) then
				refresh_list()
				notify("saved " .. name)
			else
				notify("save failed")
			end
		end,
	})

	configs:button({
		name = "reload autoload",
		tooltip = "reads the ar2.cfg this menu loads on boot again",
		callback = function()
			if leet:load_last_config() then
				notify("reloaded " .. leet.autoload)
			else
				notify("no autoload cfg on disk yet")
			end
		end,
	})

	configs:button({
		name = "reset to defaults",
		tooltip = "puts every flag back the way the menu shipped",
		callback = function()
			if pcall(leet.load_config, leet, reset_config) then
				notify("reset to defaults")
			else
				notify("reset failed")
			end
		end,
	})

	configs:button({
		name = "unload menu",
		tooltip = "saves the autoload config, kills the menu and every thread",
		callback = function()
			leet:unload()
		end,
	})

	session:button({
		name = "recon dump",
		tooltip = "prints folders, attributes and module availability into the console",
		callback = function()
			Recon.run()
		end,
	})

	session:button({
		name = "copy jobid",
		tooltip = "job id of this server instance",
		callback = function()
			if Env.clipboard then
				pcall(setclipboard, tostring(game.JobId))
				notify("jobid copied")
			else
				notify("executor has no clipboard")
			end
		end,
	})

	session:button({
		name = "copy placeid",
		tooltip = "place id, confirms which game this is",
		callback = function()
			if Env.clipboard then
				pcall(setclipboard, tostring(game.PlaceId))
				notify("placeid copied")
			else
				notify("executor has no clipboard")
			end
		end,
	})

	session:button({
		name = "rejoin",
		tooltip = "leaves and comes straight back into this server",
		callback = function()
			local ok = pcall(function()
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
			end)

			if not ok then
				notify("rejoin failed, empty jobid?")
			end
		end,
	})

	about:label({
		name = "apocalypse rising 2: hits are resolved by the server, so silent aim and hit claiming are off the table",
	})

	about:label({
		name = "entities read straight from replication: Players folder, Zombies attributes, grounditem names, vehicle attributes",
	})

	about:label({
		name = "run recon dump on the first live round and send me the console output",
	})

	reset_config = leet:get_config()

	refresh_list()
end

local Weapon = { patched = setmetatable({}, { __mode = "k" }), last = 0, dirty = false }

do
	local function tools()
		local out = {}

		local function grab(container)
			if not container then
				return
			end

			for _, tool in next, container:GetChildren() do
				if tool:IsA("Tool") then
					table.insert(out, tool)
				end
			end
		end

		grab(lp.Character)
		grab(lp:FindFirstChild("Backpack"))

		return out
	end

	local function stats_for(tool)
		if type(Game.stats) ~= "table" or type(Game.stats.Get) ~= "function" then
			return
		end

		local ok, value = pcall(Game.stats.Get, tool)

		if ok and type(value) == "table" then
			return value
		end
	end

	local function remember(table_hit)
		if not Weapon.patched[table_hit] then
			Weapon.patched[table_hit] = {
				recoil = table.clone(table_hit.recoil or {}),
				gunRecoil = table.clone(table_hit.gunRecoil or {}),
				hipFireSpread = table_hit.hipFireSpread,
				hipFireMoveSpread = table_hit.hipFireMoveSpread,
				hipFireSpreadMultiplier = table_hit.hipFireSpreadMultiplier,
			}
		end
	end

	local function restore(table_hit)
		local stored = Weapon.patched[table_hit]

		if not stored then
			return
		end

		table_hit.recoil = stored.recoil
		table_hit.gunRecoil = stored.gunRecoil
		table_hit.hipFireSpread = stored.hipFireSpread
		table_hit.hipFireMoveSpread = stored.hipFireMoveSpread
		table_hit.hipFireSpreadMultiplier = stored.hipFireSpreadMultiplier

		Weapon.patched[table_hit] = nil
	end

	function Weapon.sweep()
		local no_recoil = Util.on("wh_norecoil")
		local no_spread = Util.on("wh_nospread")
		local no_camshake = Util.on("wh_nocamshake")
		local any = no_recoil or no_spread or no_camshake
		local keep = 1 - math.clamp(Util.number("wh_recoil_amount", 100), 0, 100) / 100

		for _, tool in next, tools() do
			local stats = stats_for(tool)

			if stats then
				if Weapon.patched[stats] then
					restore(stats)
				end

				if any then
					remember(stats)

					local base = Weapon.patched[stats]

					if type(stats.recoil) == "table" and type(base.recoil) == "table" then
						if no_recoil then
							stats.recoil.vertical = (base.recoil.vertical or 0) * keep
							stats.recoil.horizontal = (base.recoil.horizontal or 0) * keep
						end

						if no_camshake then
							stats.recoil.camShake = 0
						end
					end

					if no_recoil and type(stats.gunRecoil) == "table" and type(base.gunRecoil) == "table" then
						stats.gunRecoil.vertical = (base.gunRecoil.vertical or 0) * keep
						stats.gunRecoil.horizontal = (base.gunRecoil.horizontal or 0) * keep
						stats.gunRecoil.punchMultiplier = (base.gunRecoil.punchMultiplier or 1) * keep
					end

					if no_spread then
						stats.hipFireSpread = 0
						stats.hipFireMoveSpread = 0
						stats.hipFireSpreadMultiplier = 0
					end
				end
			end
		end

		Weapon.dirty = any
	end

	function Weapon.restore_all()
		for stats in next, Weapon.patched do
			restore(stats)
		end

		Weapon.patched = setmetatable({}, { __mode = "k" })
		Weapon.dirty = false
	end

	function Weapon.enabled_now()
		return Weapon.dirty or Util.on("wh_norecoil") or Util.on("wh_nospread") or Util.on("wh_nocamshake")
	end
end

local Visual = {
	records = {},
	host = nil,
	chams = {},
	cham_busy = {},
	pool = {},
	kind = setmetatable({}, { __mode = "k" }),
	busy = setmetatable({}, { __mode = "k" }),
}

do
	if not Env.drawing then
		print("leet.cheats: Drawing unavailable, esp renderer stays off")
	end

	local POOL_SIZE = { Line = 512, Square = 192, Circle = 96, Text = 256 }

	local function new_node(class)
		if not Env.drawing then
			return
		end

		local stack = Visual.pool[class]
		local node = stack and table.remove(stack)

		if node then
			Visual.busy[node] = true

			return node
		end

		local ok, created = pcall(Drawing.new, class)

		if not ok or not created then
			return
		end

		Visual.kind[created] = class
		Visual.busy[created] = true

		return created
	end

	function Visual.init_pool()
		for class, count in next, POOL_SIZE do
			local stack = {}

			for _ = 1, count do
				local node = new_node(class)

				if node then
					pcall(function()
						node.Visible = false
					end)

					Visual.busy[node] = nil
					stack[#stack + 1] = node
				end
			end

			Visual.pool[class] = stack
		end

		return #Visual.pool.Line > 0
	end

	Visual.new = new_node

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
		if not node then
			return
		end

		pcall(function()
			node.Visible = false
		end)

		local class = Visual.kind[node]
		local stack = class and Visual.pool[class]

		if stack then
			if not Visual.busy[node] then
				return
			end

			Visual.busy[node] = nil
			stack[#stack + 1] = node

			return
		end

		Visual.kind[node] = nil
		Visual.busy[node] = nil

		pcall(function()
			node:Remove()
		end)
	end

	Visual.kill = kill
	Visual.slot = slot
	Visual.show = show

	function Visual.free(rec)
		if rec.chams then
			Visual.release(rec.chams)

			rec.chams = nil
		end

		for _, value in next, rec do
			if type(value) == "table" then
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

	function Visual.acquire()
		for index, node in next, Visual.chams do
			if not Visual.cham_busy[index] then
				local ok = pcall(function()
					node.Parent = Visual.host
				end)

				if ok then
					Visual.cham_busy[index] = true

					return node
				end
			end
		end
	end

	function Visual.release(node)
		pcall(function()
			node.Enabled = false
			node.Adornee = nil
			node.Parent = nil
		end)

		for index, other in next, Visual.chams do
			if other == node then
				Visual.cham_busy[index] = nil

				break
			end
		end
	end

	function Visual.init_chams()
		local ok, host = pcall(function()
			local folder = Instance.new("Folder")

			folder.Name = "leet_esp"
			folder.Parent = workspace

			return folder
		end)

		if not ok then
			return false
		end

		Visual.host = host

		for _ = 1, 64 do
			local good, node = pcall(function()
				local light = Instance.new("Highlight")

				light.Name = "leet_cham"
				light.Enabled = false
				light.FillTransparency = 0.4
				light.OutlineTransparency = 0
				light.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

				return light
			end)

			if good and node then
				Visual.chams[#Visual.chams + 1] = node
			end
		end

		return #Visual.chams > 0
	end

	local function corners(ent, camera)
		local node = ent.model
		local center, size

		if node then
			if node:IsA("Model") then
				local ok, bound, extent = pcall(function()
					return node:GetBoundingBox()
				end)

				if not ok then
					return
				end

				center, size = bound, extent
			elseif node:IsA("BasePart") then
				center, size = node.CFrame, node.Size
			else
				return
			end
		elseif ent.position then
			center = CFrame.new(ent.position)
			size = Vector3.new(4, 4, 4)
		else
			return
		end

		local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
		local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge

		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local point = center:PointToWorldSpace(Vector3.new(sx * hx, sy * hy, sz * hz))
					local screen = Util.project(camera, point)

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

	local LINKS_R6 = {
		{ "Head", "Torso" },
		{ "Torso", "Left Arm" },
		{ "Torso", "Right Arm" },
		{ "Torso", "Left Leg" },
		{ "Torso", "Right Leg" },
	}

	local LINKS_R15 = {
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

	local function styled(text, case_mode)
		if case_mode == "UPPERCASE" then
			return string.upper(text)
		end

		if case_mode == "lowercase" then
			return string.lower(text)
		end

		return text
	end

	local function put_text(node, value, position, color, font_name, size, thickness)
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
		node.OutlineSize = 1
		node.Transparency = 0
		node.Visible = value ~= ""
	end

	local function line(node, a, b, color, thickness)
		if not node then
			return
		end

		node.From = a
		node.To = b
		node.Color = color
		node.Thickness = thickness
		node.Transparency = 0
	end

	local TEXT_SLOTS = { "name", "sub", "extra", "weapon", "stance", "health", "state", "distance" }

	function Visual.draw(ent, camera, center, viewport)
		local spec = Scene.spec[ent.prefix]

		if not spec then
			return
		end

		local prefix = ent.prefix
		local rec = Visual.records[ent.key]

		if not rec then
			rec = {}
			Visual.records[ent.key] = rec
		end

		local rows = {}

		for _, row in next, spec.rows do
			rows[row] = true
		end

		local x0, y0, x1, y1 = corners(ent, camera)
		local thickness = math.max(1, Util.number("espsettings_thickness", 1))
		local seen = true

		if Util.on("espsettings_visibleonly") then
			seen = Util.sees(camera, ent.position, ent.model)
		end

		if prefix == "team" and Util.on("espsettings_teampierce") then
			seen = true
		end

		local height = y1 and (y1 - y0) or 0
		local width = x1 and (x1 - x0) or 0
		local cx = x0 and ((x0 + x1) * 0.5) or center.X
		local above = y0 and (y0 - 4) or center.Y
		local below = y1 and (y1 + 6) or center.Y
		local main_font = Util.pick("espsettings_font", "SourceSans")
		local main_size = Util.number("espsettings_size", 13)
		local flag_font = Util.pick("espsettings_flagfont", "Code")
		local flag_size = Util.number("espsettings_flagsize", 12)

		if rows.marker then
			local want = seen and Util.on(prefix .. "_marker")
			local circle = slot(rec, "marker", "Circle")

			if circle then
				local screen = Util.project(camera, ent.position)

				if screen then
					circle.Position = Vector2.new(screen.X, screen.Y)
					circle.Radius = math.max(3, math.min(12, height * 0.08))
					circle.NumSides = 12
					circle.Filled = false
					circle.Thickness = thickness
					circle.Color = Util.color(prefix .. "_markercolor", spec.color)
					circle.Transparency = 0
				end

				show(circle, want and circle.Position ~= nil)
			end
		end

		if x0 and rows.box then
			local want = seen and Util.on(prefix .. "_box")
			local color = Util.color(prefix .. "_boxcolor", spec.color)
			local lines = rec.box_lines or {}

			rec.box_lines = lines

			line(slot(lines, 1, "Line"), Vector2.new(x0, y0), Vector2.new(x1, y0), color, thickness)
			line(slot(lines, 2, "Line"), Vector2.new(x1, y0), Vector2.new(x1, y1), color, thickness)
			line(slot(lines, 3, "Line"), Vector2.new(x1, y1), Vector2.new(x0, y1), color, thickness)
			line(slot(lines, 4, "Line"), Vector2.new(x0, y1), Vector2.new(x0, y0), color, thickness)

			for index = 1, 4 do
				show(lines[index], want)
			end
		end

		if x0 and rows.fill then
			local want = seen and Util.on(prefix .. "_fill")
			local color, alpha = Util.color(prefix .. "_fillcolor", spec.color)
			local square = slot(rec, "fill", "Square")

			if square then
				square.Position = Vector2.new(x0, y0)
				square.Size = Vector2.new(width, height)
				square.Filled = true
				square.Color = color
				square.Thickness = 0
				square.Transparency = 1 - alpha
			end

			show(square, want)
		end

		if x0 and ent.model and rows.skeleton then
			local want = seen and Util.on(prefix .. "_skeleton")
			local color = Util.color(prefix .. "_skeletoncolor", Color3.fromRGB(236, 251, 136))
			local links = ent.rig == "R15" and LINKS_R15 or LINKS_R6
			local lines = rec.skel_lines or {}

			rec.skel_lines = lines

			for index, link in next, links do
				local a = ent.model:FindFirstChild(link[1])
				local b = ent.model:FindFirstChild(link[2])
				local pa = a and Util.project(camera, a.Position)
				local pb = b and Util.project(camera, b.Position)
				local node = slot(lines, index, "Line")

				if pa and pb then
					line(node, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), color, thickness)
				end

				show(node, want and pa ~= nil and pb ~= nil)
			end
		end

		if x0 and ent.model and rows.headdot then
			local want = seen and Util.on(prefix .. "_headdot")
			local head = ent.model:FindFirstChild("Head")
			local screen = head and Util.project(camera, head.Position)
			local circle = slot(rec, "head", "Circle")

			if circle and screen then
				circle.Position = Vector2.new(screen.X, screen.Y)
				circle.Radius = math.max(2, height * 0.045)
				circle.NumSides = 12
				circle.Filled = true
				circle.Thickness = thickness
				circle.Color = Util.color(prefix .. "_headdotcolor", Color3.new(1, 0, 0))
				circle.Transparency = 0
			end

			show(circle, want and screen ~= nil)
		end

		if x0 and rows.healthbar and ent.health then
			local want = seen and Util.on(prefix .. "_healthbar")
			local maxhealth = ent.maxhealth or 100
			local ratio = math.clamp((ent.health or 0) / math.max(1, maxhealth), 0, 1)
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

			show(back, want)
			show(fill, want)
		end

		if rows.snaplines then
			local want = seen and Util.on(prefix .. "_snaplines")
			local node = slot(rec, "snap", "Line")

			line(node, center, Vector2.new(cx, y0 and (y0 + height * 0.5) or center.Y), Util.color(prefix .. "_snaplinescolor", Color3.new(1, 1, 1)), thickness)
			show(node, want)
		end

		if rows.tracers then
			local want = seen and Util.on(prefix .. "_tracers")
			local node = slot(rec, "tracer", "Line")

			line(node, Vector2.new(center.X, viewport.Y), Vector2.new(cx, y1 or center.Y), Util.color(prefix .. "_tracerscolor", Color3.new(1, 1, 1)), thickness)
			show(node, want)
		end

		if rows.chams then
			local want = seen and Util.on(prefix .. "_chams")
			local highlight = rec.chams

			if not highlight and want and Env.highlight and ent.model then
				highlight = Visual.acquire()

				if highlight then
					highlight.Adornee = ent.model
					rec.chams = highlight
				end
			end

			if highlight then
				if want and Util.on(prefix .. "_chamsonlyvisible") then
					want = Util.sees(camera, ent.position, ent.model)
				end

				if want then
					local inner, inner_alpha = Util.color(prefix .. "_innerchamcolor", spec.color)
					local outer = Util.color(prefix .. "_outerchamcolor", spec.color)

					highlight.FillColor = inner
					highlight.FillTransparency = 1 - inner_alpha
					highlight.OutlineColor = outer
					highlight.Enabled = true
				else
					Visual.release(highlight)

					rec.chams = nil
				end
			end
		end

		for _, which in next, TEXT_SLOTS do
			if rows[which] or (which == "distance" and rows.distance) then
				local is_flag = which ~= "name" and which ~= "sub"
				local font = is_flag and flag_font or main_font
				local size = is_flag and flag_size or main_size
				local case = is_flag and flags.espsettings_flagcase or flags.espsettings_case
				local want = seen and Util.on(prefix .. "_" .. (which == "health" and "healthnumber" or which))
				local node = slot(rec, "txt_" .. which, "Text")
				local value = ""

				if want then
					if which == "distance" then
						local camera_position = camera.CFrame.Position

						value = string.format("%.0fm", Util.meters((camera_position - ent.position).Magnitude))
					else
						value = styled(tostring(ent.text[which] or ""), case)
					end
				end

				local color = Util.color(
					prefix .. "_" .. (which == "health" and "healthnumber" or which) .. "color",
					which == "name" and Color3.new(1, 1, 1) or spec.color
				)

				if which == "name" or which == "sub" or which == "extra" then
					put_text(node, value, Vector2.new(cx, above), color, font, size, thickness)
					above = above - (size + 2)
				else
					put_text(node, value, Vector2.new(cx, below), color, font, size, thickness)
					below = below + (size + 2)
				end
			end
		end

		if not rows.visible and rec.txt_visible then
			show(rec.txt_visible, false)
		end

		if rows.visible then
			local want = Util.on(prefix .. "_visible")
			local node = slot(rec, "txt_visible", "Text")
			local value = ""

			if want then
				value = Util.sees(camera, ent.position, ent.model) and "visible" or "hidden"
			end

			put_text(node, value, Vector2.new(cx, below), Util.color(prefix .. "_visiblecolor", Color3.new(1, 1, 1)), flag_font, flag_size, thickness)
		end

		Visual.records[ent.key] = rec
	end

	function Visual.gc(keep)
		for key, rec in next, Visual.records do
			if not keep[key] then
				Visual.free(rec)
				Visual.records[key] = nil
			end
		end
	end

	function Visual.teardown()
		for _, rec in next, Visual.records do
			Visual.free(rec)
		end

		Visual.records = {}

		kill(Visual.fov_ring)
		kill(Visual.indicator)

		Visual.fov_ring = nil
		Visual.indicator = nil

		for _, node in next, Visual.crosshair do
			kill(node)
		end

		Visual.crosshair = {}

		for class, stack in next, Visual.pool do
			for index, node in next, stack do
				Visual.kind[node] = nil
				Visual.busy[node] = nil
				stack[index] = nil

				pcall(function()
					node:Remove()
				end)
			end

			Visual.pool[class] = {}
		end

		if Visual.host then
			pcall(function()
				Visual.host:Destroy()
			end)

			Visual.host = nil
		end

		Visual.chams = {}
		Visual.cham_busy = {}
	end

	Visual.crosshair = {}

	function Visual.draw_crosshair(camera)
		if not Env.drawing then
			return
		end

		local want = Util.on("cross_enabled")
		local center = camera.ViewportSize * 0.5
		local style = Util.pick("cross_style", "cross")
		local length = Util.number("cross_length", 8)
		local gap = Util.number("cross_gap", 4)
		local thickness = Util.number("cross_thickness", 1)
		local color = Util.color("cross_color", Color3.new(0, 1, 0))
		local parts = {}

		if want then
			if style == "dot" then
				table.insert(parts, { "dot", center, center })
			elseif style == "circle" then
				table.insert(parts, { "circle", center })
			else
				table.insert(parts, { "line", Vector2.new(center.X - gap - length, center.Y), Vector2.new(center.X - gap, center.Y) })
				table.insert(parts, { "line", Vector2.new(center.X + gap, center.Y), Vector2.new(center.X + gap + length, center.Y) })
				table.insert(parts, { "line", Vector2.new(center.X, center.Y - gap - length), Vector2.new(center.X, center.Y - gap) })
				table.insert(parts, { "line", Vector2.new(center.X, center.Y + gap), Vector2.new(center.X, center.Y + gap + length) })

				if style == "corner" then
					table.insert(parts, { "line", Vector2.new(center.X - gap - length, center.Y - gap - length), Vector2.new(center.X - gap - length, center.Y - gap) })
					table.insert(parts, { "line", Vector2.new(center.X + gap + length, center.Y - gap - length), Vector2.new(center.X + gap + length, center.Y - gap) })
				end
			end
		end

		local used = 0

		for index, spec in next, parts do
			used = used + 1
			local outline = Util.on("cross_outline")

			for pass = 1, outline and 2 or 1 do
				local is_shadow = pass == 1 and outline
				local tint = is_shadow and Util.color("cross_outlinecolor", Color3.new(0, 0, 0)) or color

				if spec[1] == "circle" then
					local node = slot(Visual.crosshair, index .. "_" .. pass, "Circle")

					if node then
						node.Position = spec[2]
						node.Radius = gap + length
						node.NumSides = 48
						node.Filled = false
						node.Thickness = thickness
						node.Color = tint
						node.Transparency = 0
						node.Visible = true
					end
				elseif spec[1] == "dot" then
					local node = slot(Visual.crosshair, index .. "_" .. pass, "Circle")

					if node then
						node.Position = spec[2]
						node.Radius = thickness
						node.NumSides = 12
						node.Filled = true
						node.Thickness = thickness
						node.Color = tint
						node.Transparency = 0
						node.Visible = true
					end
				else
					local node = slot(Visual.crosshair, index .. "_" .. pass, "Line")

					line(node, spec[2], spec[3], tint, thickness)

					node.Visible = true
				end
			end
		end

		for index = 1, 16 do
			for pass = 1, 2 do
				local node = Visual.crosshair[index .. "_" .. pass]

				if node and index > used then
					show(node, false)
				end
			end
		end
	end

	if not Visual.init_pool() then
		print("leet.cheats: drawing pool came up empty, esp will not render")
	end

	Env.highlight = Visual.init_chams()

	if not Env.highlight then
		print("leet.cheats: highlight blocked, chams stays off")
	end
end

local Legit = { target = nil, last_click = 0, mouse_delta = Vector2.new(0, 0) }

do
	local function zones_for(ent)
		local zones = Util.list("aim_zones")

		if #zones == 0 then
			zones = { "head", "torso" }
		end

		local names = Util.zone_parts(ent.rig, zones)
		local out = {}

		for name in next, names do
			local part = ent.model:FindFirstChild(name)

			if part and part:IsA("BasePart") then
				table.insert(out, part)
			end
		end

		if #out == 0 and ent.root then
			table.insert(out, ent.root)
		end

		return out
	end

	local function candidates()
		local out = {}
		local want_players = false
		local want_zombies = false
		local names = Util.list("aim_targets")

		for _, name in next, names do
			if tostring(name) == "players" then
				want_players = true
			elseif tostring(name) == "zombies" then
				want_zombies = true
			end
		end

		if want_players then
			for _, ent in next, Scene.list do
				if ent.prefix == "enemy" or ent.prefix == "neutral" then
					table.insert(out, ent)
				elseif ent.prefix == "team" and not Util.on("aim_team_check") then
					table.insert(out, ent)
				end
			end
		end

		if want_zombies then
			for _, ent in next, Scene.list do
				if ent.prefix == "zombie" then
					table.insert(out, ent)
				end
			end
		end

		return out
	end

	local function trigger_candidates()
		local out = {}
		local names = Util.list("trig_targets")

		for _, name in next, names do
			if tostring(name) == "players" then
				for _, ent in next, Scene.list do
					if ent.prefix == "enemy" or ent.prefix == "neutral" then
						table.insert(out, ent)
					elseif ent.prefix == "team" and not Util.on("trig_team_check") then
						table.insert(out, ent)
					end
				end
			elseif tostring(name) == "zombies" then
				for _, ent in next, Scene.list do
					if ent.prefix == "zombie" then
						table.insert(out, ent)
					end
				end
			end
		end

		return out
	end

	local function score(camera, center, ent, point, priority)
		if priority == "closest" then
			return (camera.CFrame.Position - point).Magnitude
		end

		if priority == "lowest health" then
			return (ent.health or 100) - 1000
		end

		local screen = Util.project(camera, point)

		if not screen then
			return
		end

		return (Vector2.new(screen.X, screen.Y) - center).Magnitude
	end

	function Legit.pick(radius, source, need_visible, predict, priority)
		local camera = workspace.CurrentCamera

		if not camera or radius <= 0 then
			return
		end

		local center = camera.ViewportSize * 0.5
		local best, best_score

		for _, ent in next, source do
			if ent.position and ent.model and ent.model.Parent then
				for _, part in next, zones_for(ent) do
					local point = part.Position

					if predict > 0 and part.AssemblyLinearVelocity then
						point = point + part.AssemblyLinearVelocity * math.clamp(predict / 1000, 0, 0.4)
					end

					local value = score(camera, center, ent, point, priority)
					local visible = not need_visible or Util.sees(camera, point, ent.model)

					if value and value <= radius and visible and (not best_score or value < best_score) then
						best_score = value
						best = { ent = ent, point = point, screen = Util.project(camera, point) }
					end
				end
			end
		end

		return best
	end

	function Legit.fov_ring(center, radius, color)
		if not Env.drawing then
			return
		end

		local node = Visual.fov_ring or Visual.new("Circle")

		Visual.fov_ring = node

		if not node then
			return
		end

		node.Position = center
		node.Radius = radius
		node.NumSides = 64
		node.Filled = false
		node.Thickness = 1
		node.Color = color
		node.Transparency = 0
		node.Visible = radius > 0
	end

	function Legit.frame()
		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local center = camera.ViewportSize * 0.5
		local want_aim = Util.on("aim_enabled") and Util.key_active("aim_key")
		local radius = Util.number("aim_fov", 140)

		if Util.on("aim_showfov") then
			Legit.fov_ring(center, radius, Util.color("aim_fovcolor", Color3.fromRGB(127, 72, 163)))
		elseif Visual.fov_ring then
			Visual.fov_ring.Visible = false
		end

		Legit.target = nil

		if want_aim then
			local target = Legit.pick(
				radius,
				candidates(),
				Util.on("aim_visible"),
				Util.number("aim_predict", 60),
				Util.pick("aim_priority", "crosshair")
			)

			if target then
				Legit.target = target

				local smooth = math.max(1, Util.number("aim_smooth", 8))
				local max_turn = Util.number("aim_maxturn", 6)

				if Util.pick("aim_method", "camera") == "camera" then
					local goal = CFrame.lookAt(camera.CFrame.Position, target.point)
					local limited = Util.clamp_rotation(camera.CFrame, goal, max_turn)

					camera.CFrame = limited:Lerp(goal, 1 / smooth)
				else
					Util.move_mouse(Vector2.new(
						(target.screen.X - center.X) / smooth,
						(target.screen.Y - center.Y) / smooth
					))
				end
			end
		end

		local want_trigger = Util.on("trig_enabled") and Util.key_active("trig_key")

		if want_trigger and not (Util.on("trig_require_ads") and not Util.key_active("aim_key")) then
			local target = Legit.pick(
				Util.number("trig_fov", 40),
				trigger_candidates(),
				true,
				0,
				"crosshair"
			)

			local interval = Util.number("trig_delay", 60) / 1000

			if target and (os.clock() - Legit.last_click) >= interval then
				Legit.last_click = os.clock()
				Util.press_fire()
			end
		end

		if Util.on("wh_nobob") then
			Options.multiply("GetViewBobMultiplier", 0)
		else
			Options.multiply("GetViewBobMultiplier", nil)
		end

		if Util.on("wh_noflinch") then
			Options.multiply("GetCameraShakeMultiplier", 0)
		else
			Options.multiply("GetCameraShakeMultiplier", nil)
		end
	end
end

local Overrides = {
	saved = nil,
	clock = 0,
	watching = {},
	state = {},
	fov_written = nil,
	fov_base = nil,
	applied_clock = 0,
}

do
	function Overrides.snapshot()
		if Overrides.saved then
			return
		end

		Overrides.saved = {
			Brightness = lighting.Brightness,
			Ambient = lighting.Ambient,
			OutdoorAmbient = lighting.OutdoorAmbient,
			GlobalShadows = lighting.GlobalShadows,
			FogEnd = lighting.FogEnd,
			FogStart = lighting.FogStart,
			FogColor = lighting.FogColor,
			ClockTime = lighting.ClockTime,
			CameraMaxZoom = lp.CameraMaxZoomDistance,
			CameraMinZoom = lp.CameraMinZoomDistance,
		}
	end

	local written = {}

	local function put(node, property, value)
		local key = node:GetFullName() .. "." .. property
		local entry = written[key]

		if entry == nil then
			local ok, current = pcall(function()
				return node[property]
			end)

			if not ok then
				written[key] = { dead = true }

				return
			end

			entry = { value = current }
			written[key] = entry
		end

		if entry.dead then
			return
		end

		if value == nil then
			pcall(function()
				node[property] = entry.value
			end)

			written[key] = nil

			return
		end

		pcall(function()
			node[property] = value
		end)
	end

	local function watch(node, property)
		local key = node:GetFullName() .. "." .. property

		if Overrides.watching[key] then
			return
		end

		Overrides.watching[key] = true

		leet:connection(node:GetPropertyChangedSignal(property), function()
			if Overrides.active(property) then
				pcall(Overrides.apply)
			end
		end)
	end

	function Overrides.active(property)
		if property == "Brightness" or property == "Ambient" or property == "OutdoorAmbient" then
			return Util.on("vis_fullbright")
		end

		if property == "FogEnd" or property == "FogStart" then
			return Util.on("vis_nofog")
		end

		if property == "GlobalShadows" then
			return Util.on("vis_noshadows")
		end

		if property == "ClockTime" then
			return Util.on("vis_time_on")
		end

		return false
	end

	local function set_atmosphere(off)
		local node = lighting:FindFirstChildOfClass("Atmosphere")

		if not node then
			return
		end

		if off then
			put(node, "Density", 0)
		else
			put(node, "Density", nil)
		end
	end

	local function set_effects(off)
		for _, node in next, lighting:GetChildren() do
			if node:IsA("BlurEffect") or node:IsA("ColorCorrectionEffect") or node:IsA("BloomEffect") or node:IsA("SunRaysEffect") then
				if off then
					put(node, "Enabled", false)
				else
					put(node, "Enabled", nil)
				end
			end
		end
	end

	function Overrides.apply()
		Overrides.snapshot()

		local fullbright = Util.on("vis_fullbright")
		local nofog = Util.on("vis_nofog")
		local noshadows = Util.on("vis_noshadows")
		local time_on = Util.on("vis_time_on")
		local nopost = Util.on("vis_nopost")
		local state = Overrides.state

		if fullbright then
			local level = math.clamp(Util.number("vis_bright", 3), 1, 12)

			put(lighting, "Brightness", level)
			put(lighting, "Ambient", Color3.fromRGB(200, 200, 200))
			put(lighting, "OutdoorAmbient", Color3.fromRGB(220, 220, 220))
		elseif state.fullbright then
			put(lighting, "Brightness", nil)
			put(lighting, "Ambient", nil)
			put(lighting, "OutdoorAmbient", nil)
		end

		if nofog then
			put(lighting, "FogEnd", 1000000)
			put(lighting, "FogStart", 1000000)
			set_atmosphere(true)
		elseif state.nofog then
			put(lighting, "FogEnd", nil)
			put(lighting, "FogStart", nil)
			set_atmosphere(false)
		end

		if noshadows then
			put(lighting, "GlobalShadows", false)
		elseif state.noshadows then
			put(lighting, "GlobalShadows", nil)
		end

		if time_on then
			put(lighting, "ClockTime", math.clamp(Util.number("vis_time", 13), 0, 24))
		elseif state.time then
			put(lighting, "ClockTime", nil)
		end

		if nopost ~= state.post then
			set_effects(nopost)
		end

		state.fullbright = fullbright
		state.nofog = nofog
		state.noshadows = noshadows
		state.time = time_on
		state.post = nopost
	end

	function Overrides.camera(camera, dt)
		local want = math.clamp(Util.number("vis_fov", 90), 1, 120)

		if Util.on("vis_fov_on") then
			if Util.on("vis_fov_hold") or want ~= Overrides.fov_written then
				if Overrides.fov_base == nil then
					Overrides.fov_base = camera.FieldOfView
				end

				camera.FieldOfView = want

				Overrides.fov_written = want
			end
		else
			Overrides.fov_written = nil
		end

		if Util.on("vis_tp_on") then
			pcall(function()
				camera.CameraMode = Enum.CameraMode.Classic
				lp.CameraMinZoomDistance = 0.5
				lp.CameraMaxZoomDistance = Util.number("vis_tp_distance", 20)
			end)
		end
	end

	function Overrides.reset()
		local saved = Overrides.saved

		set_effects(false)
		set_atmosphere(false)

		if Overrides.fov_base and workspace.CurrentCamera then
			pcall(function()
				workspace.CurrentCamera.FieldOfView = Overrides.fov_base
			end)
		end

		Overrides.fov_base = nil
		Overrides.fov_written = nil

		if not saved then
			Overrides.state = {}

			return
		end

		pcall(function()
			lighting.Brightness = saved.Brightness
			lighting.Ambient = saved.Ambient
			lighting.OutdoorAmbient = saved.OutdoorAmbient
			lighting.GlobalShadows = saved.GlobalShadows
			lighting.FogEnd = saved.FogEnd
			lighting.FogStart = saved.FogStart
			lighting.FogColor = saved.FogColor
			lighting.ClockTime = saved.ClockTime
			lp.CameraMaxZoomDistance = saved.CameraMaxZoom
			lp.CameraMinZoomDistance = saved.CameraMinZoom
		end)

		Overrides.saved = nil
		Overrides.state = {}
	end

	watch(lighting, "Brightness")
	watch(lighting, "Ambient")
	watch(lighting, "OutdoorAmbient")
	watch(lighting, "FogEnd")
	watch(lighting, "GlobalShadows")
	watch(lighting, "ClockTime")
end

local Watermark = { fps = 0, frames = 0, clock = time(), label = nil, shell = nil }

do
	local function parent()
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
		Parent = parent(),
		Name = "leet_watermark",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local shell = leet:new_item("Frame", {
		Parent = gui,
		Name = "",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.fromOffset(220, 20),
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
		Text = "leet.cheats | AR2",
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
		Watermark.shell.Visible = Util.on("watermark")

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

		local text = string.format("leet.cheats | AR2  %d fps  %d ent  %d drawn", Watermark.fps, #Scene.list, Scene.painted)

		if Util.on("ui_hints") then
			local hints = {}

			if Util.on("aim_enabled") and Util.key_active("aim_key") then
				table.insert(hints, "aim")
			end

			if Util.on("trig_enabled") then
				table.insert(hints, "trig")
			end

			if Util.on("wh_norecoil") then
				table.insert(hints, "norecoil")
			end

			if Util.on("wh_nospread") then
				table.insert(hints, "nospread")
			end

			if Util.on("vis_fullbright") then
				table.insert(hints, "bright")
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
			Watermark.gui:Destroy()
		end)
	end
end

local Frame = {}

function Frame.rebuild()
	local out = {}

	local function extend(list)
		for _, ent in next, list do
			if ent.prefix and Scene.spec[ent.prefix] and Util.on(Scene.spec[ent.prefix].master) then
				table.insert(out, ent)
			end
		end
	end

	extend(Sources.players())
	extend(Sources.zombies())
	extend(Sources.loot())
	extend(Sources.vehicles())
	extend(Sources.corpses())
	extend(Sources.events())
	extend(Sources.containers())

	local camera = workspace.CurrentCamera

	if camera then
		local origin = camera.CFrame.Position

		table.sort(out, function(a, b)
			local da = a.position and (origin - a.position).Magnitude or 1e9
			local db = b.position and (origin - b.position).Magnitude or 1e9

			return da < db
		end)
	end

	Scene.list = out
end

local draw_fault = ""

function Frame.draw(camera)
	local viewport = camera.ViewportSize
	local center = viewport * 0.5
	local keep = {}
	local per_kind = {}
	local painted = 0
	local origin = camera.CFrame.Position

	for _, ent in next, Scene.list do
		local spec = Scene.spec[ent.prefix]
		local count = (per_kind[ent.prefix] or 0) + 1

		per_kind[ent.prefix] = count

		local dist = ent.position and Util.meters((origin - ent.position).Magnitude) or 0
		local loot_filter = ent.prefix == "loot" and (
			(Util.on("loot_hide_misc") and ent.kind == "misc")
			or (Util.on("loot_only_weapon") and ent.kind ~= "weapon" and ent.kind ~= "ammo")
		)
		local wreck_filter = ent.prefix == "vehicle" and ent.destroyed == true and not Util.on("espsettings_wrecks")
		local allowed = spec ~= nil
			and count <= Util.number(spec.prefix .. "_limit", 120)
			and dist <= Util.number(spec.prefix .. "_maxdistance", 1200)
			and not loot_filter
			and not wreck_filter

		if allowed then
			keep[ent.key] = true
			painted = painted + 1

			local ok, err = xpcall(Visual.draw, debug.traceback, ent, camera, center, viewport)

			if not ok then
				local text = tostring(err)
				local head = text:match("^(.-)\n") or text

				if head ~= draw_fault then
					draw_fault = head
					print("leet.cheats: esp draw fault: " .. text)
				end
			end
		end
	end

	Visual.gc(keep)
	Visual.draw_crosshair(camera)
	Scene.painted = painted
end

local cleaned = false

local last_fault = ""

local function guarded(fn)
	local ok, err = xpcall(fn, debug.traceback)

	if ok then
		return
	end

	local text = tostring(err)
	local head = text:match("^(.-)\n") or text

	if head ~= last_fault then
		last_fault = head
		print("leet.cheats: " .. text)
	end
end

local function teardown()
	if cleaned then
		return
	end

	cleaned = true

	Visual.teardown()
	Weapon.restore_all()
	Overrides.reset()
	Watermark.teardown()

	print("leet.cheats: apr2 unloaded")
end

local frame_clock = os.clock()
local scan_clock = 0

local function tick_frame()
	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local now = os.clock()
	local dt = math.min(0.25, now - frame_clock)

	frame_clock = now

	if now - scan_clock >= 0.1 then
		scan_clock = now
		guarded(Frame.rebuild)
	end

	guarded(function()
		Frame.draw(camera)
	end)
	guarded(Legit.frame)
	guarded(Watermark.tick)

	if Weapon.enabled_now() and now - Weapon.last > 0.4 then
		Weapon.last = now
		guarded(Weapon.sweep)
	end

	if now - (Overrides.applied_clock or 0) > 0.2 then
		Overrides.applied_clock = now
		guarded(Overrides.apply)
	end

	guarded(function()
		Overrides.camera(camera, dt)
	end)
end

local function loop()
	while not leet.dead do
		guarded(tick_frame)
		task.wait()
	end

	teardown()
end

if type(task) == "table" and type(task.spawn) == "function" then
	task.spawn(loop)
else
	leet:connection(run_service.RenderStepped, function()
		if leet.dead then
			teardown()

			return
		end

		guarded(tick_frame)
	end)
end

leet:connection(players.PlayerRemoving, function(player)
	guarded(function()
		local rec = Visual.records["p_" .. player.Name]

		if rec then
			Visual.free(rec)
			Visual.records["p_" .. player.Name] = nil
		end
	end)
end)

leet.autoload = "ar2"

if not leet:load_last_config() then
	print("leet.cheats: no ar2.cfg yet, defaults stay active")
end

leet:enable_autosave()

leet:notification({
	text = "leet.cheats AR2 build " .. BUILD .. " loaded, run recon dump",
	time = 5,
})

esp_tab.open_tab()

print("leet.cheats: apr2 ready, ui bind is [end], aim assist holds [mouse2]")
