local COMMIT = "7e2e709c06e1ab27dd06c08139f4e2f46134756e"
local REPO_RAW = "https://raw.githubusercontent.com/babay2352/leet.cheats/" .. COMMIT
local BUILD = "9"
local LIB_BYTES = 147735
local SIGN_COOLDOWN = 3
local SIGN_RESCAN = 20
local JOIN_COOLDOWN = 1

print("leet.cheats: rp build " .. BUILD .. " (items learned once stay named everywhere, no need to walk up to them)")

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

local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local replicated = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")

local Env = {}

Env.drawing = pcall(function()
	Drawing.new("Line"):Remove()
end)

print(string.format("leet.cheats: drawing=%s place=%s job=%s", tostring(Env.drawing), game.PlaceId, game.JobId))

local FONT_NAMES = { "Arial", "Gotham", "SourceSans", "Code" }
local FONT_IDS = { Arial = 0, Gotham = 1, SourceSans = 2, Code = 3 }

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
		return entry.Color
	end

	return fallback or Color3.new(1, 1, 1)
end

function Util.pick(flag, fallback)
	local entry = flags[flag]

	if type(entry) == "table" then
		return entry[1] or fallback
	end

	return entry or fallback
end

function Util.count_keys(map)
	local total = 0

	for _ in next, map do
		total = total + 1
	end

	return total
end

function Util.project(camera, point)
	local screen = camera:WorldToViewportPoint(point)

	if screen.Z <= 0 then
		return
	end

	return screen
end

function Util.digits(value)
	if type(value) ~= "string" then
		return
	end

	return tonumber(string.match(value, "%d+"))
end

function Util.stripped(value)
	return Util.digits((string.gsub(tostring(value), "[^%d]", "")))
end

function Util.money(value)
	local number_value = math.floor(tonumber(value) or 0)
	local negative = number_value < 0
	local text = tostring(math.abs(number_value))
	local out = ""
	local group = 0

	for index = #text, 1, -1 do
		group = group + 1
		out = string.sub(text, index, index) .. out

		if group % 3 == 0 and index > 1 then
			out = " " .. out
		end
	end

	return (negative and "-" or "") .. out
end

function Util.clip(text, length)
	local value = tostring(text or "")

	if #value <= length then
		return value
	end

	return string.sub(value, 1, length - 1) .. "…"
end

function Util.case(text, mode)
	if mode == "UPPERCASE" then
		return string.upper(text)
	elseif mode == "lowercase" then
		return string.lower(text)
	end

	return text
end

function Util.set_flag(flag, value)
	local setter = leet.config_flags[flag]

	if setter then
		pcall(setter, value)

		return true
	end

	flags[flag] = value

	return false
end

local Rarity = {
	order = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		TokyoExclusive = 5,
		ParisExclusive = 6,
		Exclusive = 7,
		Legendary = 8,
		RickOwens = 9,
		RickOwensLegendary = 10,
	},
	colors = {
		Common = Color3.fromRGB(140, 140, 145),
		Uncommon = Color3.fromRGB(80, 200, 80),
		Rare = Color3.fromRGB(60, 140, 255),
		Epic = Color3.fromRGB(180, 70, 255),
		TokyoExclusive = Color3.fromRGB(255, 255, 255),
		ParisExclusive = Color3.fromRGB(212, 175, 55),
		Exclusive = Color3.fromRGB(138, 43, 226),
		Legendary = Color3.fromRGB(255, 180, 30),
		RickOwens = Color3.fromRGB(200, 200, 200),
		RickOwensLegendary = Color3.fromRGB(220, 220, 220),
	},
	labels = {
		Common = "common",
		Uncommon = "uncommon",
		Rare = "rare",
		Epic = "epic",
		TokyoExclusive = "tokyo",
		ParisExclusive = "paris",
		Exclusive = "exclusive",
		Legendary = "legendary",
		RickOwens = "rick owens",
		RickOwensLegendary = "rick owens l",
	},
}

Rarity.NAMES = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"TokyoExclusive",
	"ParisExclusive",
	"Exclusive",
	"Legendary",
	"RickOwens",
	"RickOwensLegendary",
}

local Catalog = {
	by_number = {},
	by_key = {},
	by_name = {},
	by_model = {},
	records = {},
	loaded = {},
	bands = { low = 0.7, high = 0.9 },
}

do
	local function require_module(path)
		local current = nil

		for index = 1, #path do
			local ok, child = pcall(function()
				if current then
					return current:FindFirstChild(path[index])
				end

				return replicated:FindFirstChild(path[index])
			end)

			if not ok or child == nil then
				return nil
			end

			current = child
		end

		local ok, value = pcall(require, current)

		if ok and type(value) == "table" then
			return value
		end
	end

	local function looks_like_item(entry)
		if type(entry) ~= "table" or type(entry.name) ~= "string" then
			return false
		end

		return entry.rarity ~= nil
			or entry.fairPrice ~= nil
			or entry.price ~= nil
			or entry.assetId ~= nil
			or entry.id ~= nil
	end

	local function add_item(entry, hint)
		local record = {
			name = entry.name,
			rarity = type(entry.rarity) == "string" and entry.rarity or nil,
			fair = tonumber(entry.fairPrice) or tonumber(entry.price),
			brand = type(entry.brand) == "string"
				and entry.brand
				or (type(hint) == "string" and #hint < 24 and not looks_like_item(entry[hint]) and hint or nil),
			type = type(entry.type) == "string" and entry.type or nil,
			accessory_type = type(entry.accessoryType) == "string" and entry.accessoryType or nil,
			model = type(entry.customModelName) == "string" and entry.customModelName or nil,
			retired = entry.retired == true,
			id = entry.id,
		}

		if record.rarity == nil and record.fair == nil then
			return
		end

		local known = false

		if type(record.id) == "number" then
			if Catalog.by_number[record.id] then
				known = true
			else
				Catalog.by_number[record.id] = record
			end
		end

		if type(record.id) == "string" then
			local key = string.lower(record.id)

			if Catalog.by_key[key] then
				known = true
			else
				Catalog.by_key[key] = record
			end
		end

		if type(entry.assetId) == "number" then
			if Catalog.by_number[entry.assetId] then
				known = true
			else
				Catalog.by_number[entry.assetId] = record
			end
		end

		if type(entry.templateId) == "number" and not Catalog.by_number[entry.templateId] then
			Catalog.by_number[entry.templateId] = record
		end

		if type(entry.assetIds) == "table" then
			for _, id in next, entry.assetIds do
				if type(id) == "number" and not Catalog.by_number[id] then
					Catalog.by_number[id] = record
				end
			end
		end

		if record.model and not Catalog.by_model[record.model] then
			Catalog.by_model[record.model] = record
		end

		if known then
			return
		end

		local name_key = string.lower(record.name)

		if not Catalog.by_name[name_key] then
			Catalog.by_name[name_key] = record
		end

		Catalog.records[#Catalog.records + 1] = record
	end

	local function harvest(node, depth, hint)
		if type(node) ~= "table" or depth > 7 then
			return
		end

		for key, value in next, node do
			if type(value) == "table" then
				if looks_like_item(value) then
					add_item(value, type(key) == "string" and key or hint)
				else
					harvest(value, depth + 1, type(key) == "string" and key or hint)
				end
			end
		end
	end

	local PATHS = {
		{ "ClothingConfig" },
		{ "Configs", "AccessoryConfig" },
		{ "Configs", "ParisClothingConfig" },
		{ "Configs", "ParisAccessoryConfig" },
		{ "Configs", "TokyoClothingConfig" },
		{ "Configs", "TokyoAccessoryConfig" },
		{ "TokyoClothingConfig" },
		{ "TokyoAccessoryConfig" },
		{ "BlackMarketConfig" },
		{ "SecondHandConfig" },
		{ "ShopConfig" },
		{ "ItemIndexConfig" },
		{ "PromoItemConfigMirror" },
		{ "SaintLaurentCaseConfig" },
		{ "StreetCaseConfig" },
		{ "CaseConfig" },
	}

	function Catalog.load()
		for _, path in next, PATHS do
			local module = require_module(path)

			if module then
				local tag = table.concat(path, ".")

				if not Catalog.loaded[tag] then
					Catalog.loaded[tag] = module

					if tag ~= "ItemIndexConfig" then
						harvest(module, 0, nil)
					end
				end
			end
		end

		local index_config = Catalog.loaded["ItemIndexConfig"]

		if index_config then
			if type(index_config.RARITY_ORDER) == "table" then
				for name, rank in next, index_config.RARITY_ORDER do
					if type(name) == "string" and type(rank) == "number" then
						Rarity.order[name] = rank
					end
				end
			end

			if type(index_config.RARITY_COLORS) == "table" then
				for name, color in next, index_config.RARITY_COLORS do
					if type(name) == "string" and typeof(color) == "Color3" then
						Rarity.colors[name] = color
					end
				end
			end
		end

		local low, high = nil, nil

		local function absorb(range)
			if type(range) ~= "table" then
				return
			end

			local first, second = tonumber(range[1]), tonumber(range[2])

			if first and second then
				low = (low and math.min(low, first)) or first
				high = (high and math.max(high, second)) or second
			end
		end

		local function absorb_single(value)
			if type(value) ~= "number" then
				return
			end

			low = (low and math.min(low, value)) or value
			high = (high and math.max(high, value)) or value
		end

		local function walk_ranges(node, depth)
			if type(node) ~= "table" or depth > 5 then
				return
			end

			absorb(node.priceRange)
			absorb_single(node.priceMultiplier)

			for _, value in next, node do
				if type(value) == "table" then
					walk_ranges(value, depth + 1)
				end
			end
		end

		walk_ranges(Catalog.loaded["ShopConfig"], 0)
		walk_ranges(Catalog.loaded["SecondHandConfig"], 0)

		if low and high and high >= low then
			Catalog.bands = { low = low, high = high }
		end

		return #Catalog.records
	end

	function Catalog.pick(entry)
		if entry == nil then
			return nil
		end

		local record = Catalog.find(entry.id, entry.name, entry.model)

		if record ~= nil then
			return record
		end

		local assets = entry.assets

		if type(assets) == "table" then
			for index = 1, #assets do
				local hit = Catalog.by_number[assets[index]]

				if hit ~= nil then
					return hit
				end
			end
		end
	end

	function Catalog.find(id, name, model)
		if type(id) == "number" and Catalog.by_number[id] then
			return Catalog.by_number[id]
		end

		if type(id) == "string" then
			local record = Catalog.by_key[string.lower(id)]

			if record then
				return record
			end
		end

		if type(model) == "string" and Catalog.by_model[model] then
			return Catalog.by_model[model]
		end

		if type(name) == "string" then
			return Catalog.by_name[string.lower(name)]
		end
	end

	function Catalog.merge(target, source)
		if target == nil or source == nil then
			return target
		end

		target.rarity = target.rarity or source.rarity
		target.fair = target.fair or source.fair
		target.brand = target.brand or source.brand
		target.name = target.name or source.name
		target.retired = target.retired or source.retired

		if source.type or source.accessory_type then
			target.kind = target.kind or source.type or source.accessory_type
		end

		return target
	end
end

local Market = {
	slots = {},
	roots = {},
	pushed = {},
	ledger = {},
	tags = {},
	van = {},
	listings = {},
	taps = {},
	connections = {},
	dirty = true,
	queued = {},
	queued_roots = {},
	sketched = {},
	zones = {},
	signs_dirty = false,
	join_dirty = false,
	sign_census = { three_d = 0, gui = 0, junk = 0, objects = 0, labels = 0, skipped = 0 },
	stats = {
		slots = 0,
		pushed = 0,
		pinned = 0,
		tags = 0,
		van = 0,
		listings = 0,
		fair = 0,
		items = 0,
		exact = 0,
		memory = 0,
		recalled = 0,
	},
}

do
	local function part_frame(host)
		local ok, position, size = pcall(function()
			local parts = {}

			if host:IsA("BasePart") then
				parts[1] = host
			elseif host:IsA("Model") then
				for _, part in next, host:GetDescendants() do
					if part:IsA("BasePart") and #parts < 96 then
						parts[#parts + 1] = part
					end
				end
			else
				local part = host:FindFirstChildWhichIsA("BasePart", true)

				if part ~= nil then
					parts[1] = part
				end
			end

			if #parts == 0 then
				return
			end

			local sum = Vector3.new(0, 0, 0)

			for _, part in next, parts do
				sum = sum + part.Position
			end

			local center = sum / #parts
			local reach = Vector3.new(1, 1, 1)

			for _, part in next, parts do
				local offset = part.Position - center + part.Size * 0.5

				reach = Vector3.new(
					math.max(reach.X, math.abs(offset.X)),
					math.max(reach.Y, math.abs(offset.Y)),
					math.max(reach.Z, math.abs(offset.Z))
				)
			end

			return center, reach * 2
		end)

		if ok then
			return position, size
		end
	end

	local function part_anchor(host)
		local position = part_frame(host)

		if position ~= nil then
			return position
		end

		local ok, pivot = pcall(function()
			return host:GetPivot().Position
		end)

		if ok then
			return pivot
		end
	end

	local function position_of(host)
		return part_anchor(host)
	end

	local function full_name(host)
		local ok, name = pcall(function()
			return host:GetFullName()
		end)

		if ok then
			return name
		end

		return tostring(host.Name)
	end

	local function label_of(host, name)
		local ok, text = pcall(function()
			local direct = host:FindFirstChild(name, true)

			if direct and direct:IsA("TextLabel") then
				return direct.Text
			end
		end)

		if ok then
			return text
		end
	end

	local function absorb_child(entry, child)
		pcall(function()
			if (child:IsA("IntValue") or child:IsA("NumberValue"))
				and (child.Name == "Price" or child.Name == "Cost") then
				entry.price = tonumber(child.Value) or entry.price
			elseif child:IsA("StringValue") then
				if child.Name == "Rarity" then
					entry.rarity = child.Value
				elseif child.Name == "ItemName" then
					entry.name = child.Value
				elseif child.Name == "ItemId" or child.Name == "TemplateId" then
					entry.id = Util.digits(child.Value) or child.Value
				end
			elseif child:IsA("BillboardGui") and child.Name == "PriceTag" then
				entry.name = entry.name or label_of(child, "ItemName")

				if entry.price == nil then
					entry.price = Util.stripped(label_of(child, "Price"))
				end
			elseif child:IsA("ProximityPrompt")
				and (child.Name == "TakePrompt" or child.ActionText == "Взять") then
				local object_text = tostring(child.ObjectText or "")

				if #object_text > 0 then
					local left = string.match(object_text, "^(.-)%s*%$")

					if left and #left > 1 and #left < 48 then
						entry.name = entry.name or left
					end

					if entry.price == nil then
						entry.price = Util.stripped(string.match(object_text, "%$[%d%.]+[%a]*"))
					end
				end
			elseif child:IsA("Decal") then
				entry.id = entry.id or Util.digits(child.Texture)
			elseif child:IsA("Shirt") then
				entry.id = entry.id or Util.digits(child.ShirtTemplate)
				entry.kind = "Shirt"
			elseif child:IsA("Pants") then
				entry.id = entry.id or Util.digits(child.PantsTemplate)
				entry.kind = "Pants"
			elseif child:IsA("ObjectValue") and child.Name == "__ShopVisualRef" then
				entry.visual = child.Value
			end
		end)
	end

	local function absorb_attributes(entry, instance)
		local ok, attributes = pcall(function()
			return instance:GetAttributes()
		end)

		if not ok or type(attributes) ~= "table" then
			return
		end

		for key, value in next, attributes do
			local lower = string.lower(key)

			if lower == "price" or lower == "cost" or lower == "amount" then
				entry.price = tonumber(value) or entry.price
			elseif lower == "rarity" then
				if type(value) == "string" then
					entry.rarity = value
				end
			elseif lower == "itemname" or lower == "name" or lower == "title" or lower == "label" then
				if type(value) == "string" and #value > 1 then
					entry.name = value
				end
			elseif lower == "itemid" or lower == "templateid" or lower == "assetid" or lower == "id" then
				entry.id = tonumber(value) or (type(value) == "string" and Util.digits(value)) or entry.id
			elseif lower == "brand" then
				if type(value) == "string" then
					entry.brand = value
				end
			elseif lower == "fairprice" or lower == "fair" or lower == "baseprice" then
				entry.fair = tonumber(value) or entry.fair
			end
		end
	end

	local function slot_identity(host)
		local node = host

		for _ = 1, 4 do
			if node == nil then
				break
			end

			local parent = node.Parent

			if parent == nil then
				break
			end

			if parent.Name == "ItemSlots" or parent.Name == "AccessorySlots" or string.match(parent.Name, "Slots$") then
				local zone = parent.Parent
				local index = tonumber(string.match(node.Name, "%d+"))

				if zone and index then
					return tostring(zone.Name) .. "|" .. tostring(index)
				end

				return nil
			end

			node = parent
		end

		return nil
	end

	local function asset_digit(text)
		if type(text) ~= "string" then
			return nil
		end

		local digits = string.match(text, "%d+")

		if digits == nil or #digits < 5 then
			return nil
		end

		return tonumber(digits)
	end

	local function collect_assets(node, out)
		local ok, parts = pcall(function()
			return node:GetDescendants()
		end)

		if not ok or type(parts) ~= "table" then
			return
		end

		local total = #parts

		if total > 120 then
			total = 120
		end

		for index = 1, total do
			local part = parts[index]

			if #out >= 10 then
				return
			end

			pcall(function()
				if part:IsA("MeshPart") then
					out[#out + 1] = asset_digit(part.MeshId) or asset_digit(part.Texture)
				elseif part:IsA("BaseMesh") then
					out[#out + 1] = asset_digit(part.MeshId) or asset_digit(part.TextureId)
				elseif part:IsA("Shirt") then
					out[#out + 1] = asset_digit(part.ShirtTemplate)
				elseif part:IsA("Pants") then
					out[#out + 1] = asset_digit(part.PantsTemplate)
				elseif part:IsA("Decal") then
					out[#out + 1] = asset_digit(part.Texture)
				end
			end)

			local skin = part:FindFirstChildOfClass("SurfaceAppearance")

			if skin ~= nil then
				pcall(function()
					out[#out + 1] = asset_digit(skin.MaterialTexture)
						or asset_digit(skin.DecalTexture)
						or asset_digit(skin.Geometry)
				end)
			end
		end
	end

	local ASSET_CACHE = setmetatable({}, { __mode = "k" })

	function Market.mesh_assets(node)
		if node == nil or typeof(node) ~= "Instance" then
			return nil
		end

		local cached = ASSET_CACHE[node]

		if cached ~= nil then
			if #cached == 0 then
				return nil
			end

			return cached
		end

		local out = {}

		collect_assets(node, out)
		ASSET_CACHE[node] = out

		if #out == 0 then
			return nil
		end

		return out
	end

	local TYPE_KEYS = { m = true, i = true, n = true, x = true }
	local SLOT_TTL = 180

	local function model_number(name)
		if type(name) ~= "string" then
			return nil
		end

		return tonumber(string.match(name, "^M_(%d+)$"))
	end

	local function ref_number(value)
		if value == nil or typeof(value) ~= "Instance" then
			return nil
		end

		local node = value

		for _ = 1, 4 do
			local number = model_number(node.Name)

			if number ~= nil then
				return number
			end

			local ok, parent = pcall(function()
				return node.Parent
			end)

			if not ok or parent == nil then
				return nil
			end

			node = parent
		end
	end

	local function ledger_keys(entry)
		local keys = {}

		local model = entry.model
			or ref_number(entry.visual_ref)
			or ref_number(entry.slot_ref)
			or (entry.host ~= nil and model_number(entry.host.Name) or nil)

		if type(model) == "number" then
			keys[#keys + 1] = "m:" .. model
		end

		if type(entry.id) == "number" then
			keys[#keys + 1] = "i:" .. entry.id
		elseif type(entry.id) == "string" then
			keys[#keys + 1] = "i:" .. string.lower(entry.id)
		end

		if type(entry.slot_key) == "string" then
			keys[#keys + 1] = "k:" .. entry.slot_key
		end

		if type(entry.slot_id) == "string" then
			keys[#keys + 1] = "s:" .. string.lower(entry.slot_id)
		end

		if type(entry.shop) == "string" and entry.slot_index ~= nil then
			keys[#keys + 1] = "z:" .. string.lower(entry.shop) .. "|" .. tostring(entry.slot_index)
		end

		if type(entry.name) == "string" then
			keys[#keys + 1] = "n:" .. string.lower(entry.name)
		end

		if typeof(entry.position) == "Vector3" then
			keys[#keys + 1] = "p:" .. math.floor(entry.position.X) .. "," .. math.floor(entry.position.Z)
		end

		local assets = entry.assets

		if type(assets) == "table" then
			local limit = #assets

			if limit > 4 then
				limit = 4
			end

			for index = 1, limit do
				keys[#keys + 1] = "x:" .. assets[index]
			end
		end

		return keys
	end

	local function key_is_type(key)
		return TYPE_KEYS[string.sub(key, 1, 1)] == true
	end

	function Market.remember(entry, type_only)
		if entry == nil or (entry.name == nil and entry.price == nil and entry.rarity == nil) then
			return false
		end

		local keys = ledger_keys(entry)
		local stamp = os.clock()
		local wrote = false

		for index = 1, #keys do
			local key = keys[index]
			local typed = key_is_type(key)

			if not type_only or typed then
				local record = Market.ledger[key]

				if record == nil then
					record = {}
					Market.ledger[key] = record
					Market.stats.memory = Market.stats.memory + 1
				end

				if type(entry.name) == "string" then
					record.name = entry.name
				end

				if not typed and type(entry.price) == "number" then
					record.price = entry.price
				end

				if type(entry.rarity) == "string" then
					record.rarity = entry.rarity
				end

				if type(entry.brand) == "string" then
					record.brand = entry.brand
				end

				if type(entry.fair) == "number" then
					record.fair = entry.fair
				end

				if type(entry.kind) == "string" then
					record.kind = entry.kind
				end

				if type(entry.seller) == "string" then
					record.seller = entry.seller
				end

				if entry.catalogued == true then
					record.catalogued = true
				end

				record.stamp = stamp
				wrote = true
			end
		end

		return wrote
	end

	function Market.recall(entry)
		if entry == nil then
			return false
		end

		if entry.name ~= nil and entry.price ~= nil and entry.rarity ~= nil then
			return false
		end

		local keys = ledger_keys(entry)
		local stamp = os.clock()
		local filled = false

		for index = 1, #keys do
			local key = keys[index]
			local record = Market.ledger[key]

			if record ~= nil and (key_is_type(key) or stamp - (record.stamp or 0) < SLOT_TTL) then
				if entry.name == nil and type(record.name) == "string" then
					entry.name = record.name
					filled = true
				end

				if entry.price == nil and not key_is_type(key) and type(record.price) == "number" then
					entry.price = record.price
					filled = true
				end

				if entry.rarity == nil and type(record.rarity) == "string" then
					entry.rarity = record.rarity
					filled = true
				end

				if entry.brand == nil and type(record.brand) == "string" then
					entry.brand = record.brand
					filled = true
				end

				if entry.fair == nil and type(record.fair) == "number" then
					entry.fair = record.fair
					filled = true
				end

				if entry.kind == nil and type(record.kind) == "string" then
					entry.kind = record.kind
					filled = true
				end

				if entry.seller == nil and type(record.seller) == "string" then
					entry.seller = record.seller
					filled = true
				end

				if record.catalogued == true then
					entry.catalogued = true
				end
			end
		end

		if filled then
			entry.memory = true
			entry.bare = (entry.price == nil and entry.rarity == nil and entry.name == nil)
			Market.stats.recalled = Market.stats.recalled + 1
		end

		return filled
	end

	function Market.forget_slot(entry)
		local keys = ledger_keys(entry)

		for index = 1, #keys do
			if not key_is_type(keys[index]) then
				Market.ledger[keys[index]] = nil
			end
		end
	end

	Market.model_number = model_number
	Market.ref_number = ref_number
	Market.ledger_keys = ledger_keys

	function Market.read_host(host)
		if host == nil or host.Parent == nil then
			return
		end

		if not host:IsA("BasePart") and not host:IsA("Model") then
			return
		end

		local entry = {
			source = "shop",
			host = host,
			key = "slot:" .. full_name(host),
		}

		entry.slot_key = slot_identity(host)

		if entry.slot_key then
			entry.zone_number = tonumber(string.match(entry.slot_key, "(%d+)|"))
			entry.slot_index = tonumber(string.match(entry.slot_key, "|(%d+)$"))
		end

		absorb_attributes(entry, host)

		local ok, children = pcall(function()
			return host:GetChildren()
		end)

		if not ok then
			return
		end

		for _, child in next, children do
			absorb_child(entry, child)
			absorb_attributes(entry, child)

			if child:IsA("Model") or child:IsA("BillboardGui") or child.Name == "ItemInfo" then
				local ok_nested, nested_children = pcall(function()
					return child:GetChildren()
				end)

				if ok_nested then
					for _, grand in next, nested_children do
						absorb_child(entry, grand)
						absorb_attributes(entry, grand)
					end
				end
			end
		end

		entry.position = position_of(host)

		if entry.position == nil and entry.visual ~= nil then
			entry.position = position_of(entry.visual)
		end

		if entry.position == nil then
			return
		end

		local assets = Market.mesh_assets(host)
		local extra = Market.mesh_assets(entry.visual)

		if assets ~= nil and extra ~= nil then
			local merged = {}

			for index = 1, #assets do
				merged[#merged + 1] = assets[index]
			end

			for index = 1, #extra do
				if #merged >= 10 then
					break
				end

				merged[#merged + 1] = extra[index]
			end

			entry.assets = merged
		else
			entry.assets = assets or extra
		end

		local record = Catalog.pick(entry)

		if record then
			Catalog.merge(entry, record)
			entry.catalogued = true
		end

		Market.recall(entry)
		Market.remember(entry)

		entry.bare = (entry.price == nil and entry.rarity == nil and entry.name == nil)

		return entry
	end

	local function looks_like_slot(instance)
		local ok, result = pcall(function()
			if instance:IsA("IntValue") or instance:IsA("NumberValue") or instance:IsA("StringValue") then
				return instance.Name == "Price"
					or instance.Name == "Cost"
					or instance.Name == "Rarity"
					or instance.Name == "ItemName"
					or instance.Name == "ItemId"
			end

			if instance:IsA("BillboardGui") then
				return instance.Name == "PriceTag"
			end

			if instance:IsA("ProximityPrompt") then
				return instance.Name == "TakePrompt" or instance.ActionText == "Взять"
			end

			if instance:IsA("Model") then
				return instance.Name == "Mannequin"
			end

			if instance:IsA("BasePart") then
				if string.match(instance.Name, "^Slot_?%d+$") ~= nil then
					return true
				end

				local parent = instance.Parent

				if parent and (parent.Name == "ItemSlots" or parent.Name == "AccessorySlots") then
					return true
				end
			end

			if instance:IsA("ObjectValue") then
				return instance.Name == "__ShopVisualRef"
			end

			return false
		end)

		if ok then
			return result
		end

		return false
	end

	local function slot_host(instance)
		local ok, host = pcall(function()
			if instance:IsA("BasePart") then
				local parent = instance.Parent

				if string.match(instance.Name, "^Slot_?%d+$") ~= nil then
					return instance
				end

				if parent ~= nil
					and (parent.Name == "ItemSlots" or parent.Name == "AccessorySlots") then
					return instance
				end
			end

			return instance.Parent
		end)

		if ok then
			return host
		end
	end

	function Market.rebuild()
		local found = {}
		local roots = {}
		local total = 0
		local items = 0

		local ok, all = pcall(function()
			return workspace:GetDescendants()
		end)

		if not ok then
			return 0
		end

		for _, instance in next, all do
			if Market.is_visual_root(instance) then
				if roots[instance] == nil then
					local entry = Market.read_root(instance)

					if entry then
						roots[instance] = entry
						items = items + 1
					end
				end
			elseif looks_like_slot(instance) then
				local host = slot_host(instance)

				if host and found[host] == nil then
					local entry = Market.read_host(host)

					if entry then
						Market.enrich(entry)
						found[host] = entry
						total = total + 1
					end
				end
			end
		end

		Market.roots = roots
		Market.slots = found
		Market.stats.slots = total
		Market.stats.items = items
		Market.replay_pushes()
		Market.adopt_tags()

		Market.dirty = false
		table.clear(Market.queued)
		table.clear(Market.queued_roots)

		return total
	end

	function Market.replay_pushes()
		local replay = {}

		for _, pushed in next, Market.pushed do
			replay[#replay + 1] = pushed
		end

		if #replay == 0 then
			return
		end

		table.clear(Market.pushed)

		local pinned = 0

		for _, pushed in next, replay do
			if Market.attach(pushed) then
				pinned = pinned + 1
			end

			Market.pushed[pushed.key] = pushed
		end

		Market.stats.pushed = Util.count_keys(Market.pushed)
		Market.stats.pinned = pinned
	end

	function Market.flush()
		if not Market.dirty then
			return
		end

		if Util.count_keys(Market.slots) == 0 or Util.count_keys(Market.queued) > 40 then
			Market.rebuild()

			return
		end

		local total = 0

		for host, entry in next, Market.slots do
			if host.Parent == nil or entry.host == nil then
				Market.slots[host] = nil
			else
				total = total + 1
			end
		end

		for host in next, Market.queued do
			local entry = Market.read_host(host)

			if entry then
				Market.slots[host] = entry
				Market.enrich(entry)
				total = total + 1
			else
				Market.slots[host] = nil
			end
		end

		table.clear(Market.queued)
		Market.stats.slots = total

		for host in next, Market.queued_roots do
			local entry = Market.read_root(host)

			if entry then
				Market.roots[host] = entry
			end
		end

		table.clear(Market.queued_roots)

		for host in next, Market.roots do
			if host.Parent == nil then
				Market.roots[host] = nil
			end
		end

		Market.stats.items = Util.count_keys(Market.roots)

		Market.adopt_tags()

		Market.dirty = false
	end

	function Market.watch()
		local ok, added = pcall(function()
			return workspace.DescendantAdded:Connect(function(instance)
				if looks_like_slot(instance) then
					local host = slot_host(instance)

					if host ~= nil then
						Market.queued[host] = true
						Market.dirty = true
					end
				end

				if Market.is_visual_root(instance) then
					Market.queued_roots[instance] = true
					Market.dirty = true
				end

				if instance.Name == "ThreeDTextParams" then
					Market.signs_dirty = true
				end
			end)
		end)

		if ok and added then
			Market.connections[#Market.connections + 1] = added
		end

		local ok_removed, removed = pcall(function()
			return workspace.DescendantRemoving:Connect(function(instance)
				local host = instance.Parent

				if host and Market.slots[host] then
					Market.slots[host] = nil
					Market.stats.slots = Util.count_keys(Market.slots)
				end

				if Market.slots[instance] then
					Market.slots[instance] = nil
					Market.stats.slots = Util.count_keys(Market.slots)
				end

				if Market.roots[instance] ~= nil then
					Market.roots[instance] = nil
					Market.stats.items = Util.count_keys(Market.roots)
				end
			end)
		end)

		if ok_removed and removed then
			Market.connections[#Market.connections + 1] = removed
		end
	end

	function Market.enrich(entry)
		if entry == nil then
			return
		end

		local record = Catalog.pick(entry)

		if record then
			Catalog.merge(entry, record)
			entry.catalogued = true
		end

		Market.apply_pushes(entry)
	end

	Market.part_frame = part_frame
	Market.part_anchor = part_anchor
	Market.full_name = full_name
	Market.absorb_child = absorb_child
	Market.absorb_attributes = absorb_attributes
end

do
	local CHANNELS = {
		{ "ShopRemotes", "SlotInfoUpdate" },
		{ "ShopRemotes", "SlotInfoPatch" },
		{ "ShopRemotes", "SlotPriceReveal" },
		{ "ShopRemotes", "SlotInfoClear" },
		{ "ShopRemotes", "ShopStateChanged" },
		{ "ShopAssets", "Remotes", "UpdateShopDisplay" },
		{ "BlackMarketRemotes", "BlackMarketStatusUpdate" },
	}

	local KEYS = {
		price = true,
		Price = true,
		cost = true,
		Cost = true,
		amount = true,
		Amount = true,
		rarity = true,
		Rarity = true,
		rarityName = true,
		name = true,
		Name = true,
		itemName = true,
		ItemName = true,
		displayName = true,
		title = true,
		itemId = true,
		ItemId = true,
		templateId = true,
		TemplateId = true,
		assetId = true,
		AssetId = true,
		asset = true,
		id = true,
		Id = true,
		brand = true,
		Brand = true,
		sellerName = true,
		listingId = true,
		slot = true,
		Slot = true,
		slotId = true,
		SlotId = true,
		slotIndex = true,
		SlotIndex = true,
		index = true,
		shop = true,
		Shop = true,
		shopName = true,
		ShopName = true,
		shopZone = true,
		fairPrice = true,
		FairPrice = true,
		fair = true,
		basePrice = true,
		marketPrice = true,
		brandName = true,
		customModelName = true,
		stock = true,
		Stock = true,
		count = true,
		quantity = true,
		ownerName = true,
		playerName = true,
		Seller = true,
	}

	local SLOT_KEYS = { "slot", "Slot", "slotId", "SlotId", "slotIndex", "SlotIndex", "index", "slotNum", "number" }
	local SHOP_KEYS = { "shop", "Shop", "shopName", "ShopName", "shopZone", "zone", "store", "rack" }
	local ID_KEYS = { "itemId", "ItemId", "templateId", "TemplateId", "assetId", "AssetId", "asset", "id", "Id" }
	local NAME_KEYS = { "name", "Name", "itemName", "ItemName", "displayName", "title" }
	local PRICE_KEYS = { "price", "Price", "cost", "Cost", "amount", "Amount" }
	local RARITY_KEYS = { "rarity", "Rarity", "rarityName" }
	local BRAND_KEYS = { "brand", "Brand", "brandName" }
	local FAIR_KEYS = { "fairPrice", "FairPrice", "fair", "basePrice", "marketPrice" }
	local STOCK_KEYS = { "stock", "Stock", "count", "quantity", "amount" }
	local SELLER_KEYS = { "sellerName", "seller", "Seller", "ownerName", "playerName" }
	local POSITION_KEYS = {
		"position",
		"Position",
		"worldPosition",
		"pos",
		"cframe",
		"CFrame",
		"cf",
		"part",
		"Part",
		"instance",
		"target",
		"visual",
		"model",
		"anchor",
		"slotRef",
		"SlotRef",
		"visualRef",
		"VisualRef",
		"itemRef",
		"rootRef",
	}

	local function field(raw, keys)
		for _, key in next, keys do
			local value = raw[key]

			if value ~= nil then
				return value
			end
		end
	end

	local function key_hint(key)
		local slot = tonumber(key)
		local id

		if slot ~= nil then
			if slot > 1000000 then
				id = slot
				slot = nil
			elseif slot < 1 then
				slot = nil
			end
		elseif type(key) == "string" then
			slot = tonumber(string.match(key, "^Slot_?(%d+)$"))
			id = tonumber(string.match(key, "^rbxassetid://(%d+)$"))
		end

		local shop

		if type(key) == "string" then
			if string.find(key, "[Ss]hop") or string.find(key, "[Zz]one") then
				shop = key
			end
		end

		return slot, shop, id
	end

	local function instance_ref(value)
		if value ~= nil and typeof(value) == "Instance" then
			return value
		end
	end

	local function value_position(value)
		if value == nil then
			return
		end

		if typeof(value) == "Vector3" then
			return value
		end

		if typeof(value) == "CFrame" then
			return value.Position
		end

		if typeof(value) ~= "Instance" then
			return
		end

		local ok, position = pcall(function()
			if value:IsA("BasePart") then
				return value.Position
			end

			if value:IsA("Model") then
				local anchor = Market.part_frame(value)

				if anchor ~= nil then
					return anchor
				end

				return value:GetPivot().Position
			end

			if value:IsA("Vector3Value") or value:IsA("CFrameValue") then
				local inner = value.Value

				if typeof(inner) == "CFrame" then
					return inner.Position
				end

				return inner
			end

			if value:IsA("ObjectValue") and value.Value ~= nil then
				local inner = value.Value

				if inner:IsA("BasePart") then
					return inner.Position
				end

				if inner:IsA("Model") then
					local anchor = Market.part_frame(inner)

					if anchor ~= nil then
						return anchor
					end

					return inner:GetPivot().Position
				end
			end
		end)

		if ok then
			return position
		end
	end

	local function harvest(node, depth, out, hint_slot, hint_shop, hint_id)
		if type(node) ~= "table" or depth > 5 then
			return
		end

		local informative = 0

		for key in next, node do
			if KEYS[key] then
				informative = informative + 1
			end
		end

		local position = field(node, POSITION_KEYS)

		if informative >= 2 or (informative >= 1 and position ~= nil) then
			out[#out + 1] = {
				raw = node,
				slot = hint_slot,
				shop = hint_shop,
				id = hint_id,
				position = value_position(position),
			}

			return
		end

		for key, value in next, node do
			if type(value) == "table" then
				local slot, shop, id = key_hint(key)

				harvest(value, depth + 1, out, slot or hint_slot, shop or hint_shop, id or hint_id)
			end
		end
	end

	local function describe(value, depth)
		local kind = type(value)

		if kind == "string" then
			local sample = string.gsub(value, "%d+", "#")

			if #sample > 26 then
				sample = string.sub(sample, 1, 26)
			end

			return "Str(\"" .. sample .. "\")"
		end

		if kind == "number" then
			return "Num(" .. tostring(value) .. ")"
		end

		if kind == "boolean" then
			return "Bool(" .. tostring(value) .. ")"
		end

		if kind == "userdata" then
			local ok, class = pcall(function()
				return value.ClassName
			end)

			if ok then
				return "Inst(" .. class .. "/" .. tostring(value.Name) .. ")"
			end

			return "UD(" .. kind .. ")"
		end

		if kind ~= "table" or depth > 3 then
			return kind
		end

		local parts = {}
		local seen = 0

		for key, item in next, value do
			seen = seen + 1

			if seen <= 10 then
				parts[#parts + 1] = tostring(key) .. "=" .. describe(item, depth + 1)
			end
		end

		if seen > 10 then
			parts[#parts + 1] = "+" .. tostring(seen - 10) .. "more"
		end

		return "{" .. table.concat(parts, ", ") .. "}"
	end

	function Market.sketch(channel, args)
		local count = (Market.sketched[channel] or 0) + 1

		Market.sketched[channel] = count

		if count > 3 then
			return
		end

		local parts = {}

		for index = 1, #args do
			parts[#parts + 1] = "a" .. index .. "=" .. describe(args[index], 1)
		end

		print("leet.cheats sketch[" .. channel .. "] #" .. count .. ": " .. table.concat(parts, " | "))
	end

	function Market.absorb(channel, args)
		Market.sketch(channel, args)

		local context_shop
		local context_index
		local context_position

		for _, value in next, args do
			local position = value_position(value)

			if position ~= nil and context_position == nil then
				context_position = position
			elseif type(value) == "string" and context_shop == nil and string.find(value, "[Ss]hop") then
				context_shop = value
			elseif type(value) == "number" and context_index == nil and value >= 1 and value <= 4096 then
				context_index = value
			end
		end

		local found = {}

		for _, value in next, args do
			if type(value) == "table" then
				harvest(value, 0, found)
			end
		end

		for _, bag in next, found do
			local raw = bag.raw
			local raw_id = field(raw, ID_KEYS)
			local raw_shop = field(raw, SHOP_KEYS)
			local raw_slot = field(raw, SLOT_KEYS)
			local raw_name = field(raw, NAME_KEYS)
			local raw_price = field(raw, PRICE_KEYS)
			local raw_rarity = field(raw, RARITY_KEYS)
			local raw_brand = field(raw, BRAND_KEYS)
			local raw_fair = field(raw, FAIR_KEYS)
			local raw_stock = field(raw, STOCK_KEYS)
			local raw_seller = field(raw, SELLER_KEYS)

			local id = tonumber(raw_id)
				or (type(raw_id) == "string" and (Util.digits(raw_id) or raw_id) or nil)
				or bag.id

			local shop = (type(raw_shop) == "string" and raw_shop)
				or (type(raw_shop) == "number" and ("Shop_" .. tostring(raw_shop)))
				or bag.shop
				or context_shop

			local slot_index = tonumber(raw_slot)
				or (type(raw_slot) == "string" and Util.digits(raw_slot))
				or bag.slot
				or context_index

			local position = bag.position or context_position

			local entry = {
				source = channel,
				key = (shop and slot_index)
						and ("slot:" .. tostring(shop) .. "|" .. tostring(slot_index))
						or ("push:"
							.. channel
							.. ":"
							.. tostring(id or raw_name or "?")
							.. ":"
							.. tostring(raw_price or "")
							.. (position and ("@" .. math.floor(position.X) .. "," .. math.floor(position.Z)) or "")),
				shop = type(shop) == "string" and shop or nil,
				slot_index = slot_index,
				position = position,
				slot_ref = instance_ref(raw.slotRef or raw.SlotRef),
				visual_ref = instance_ref(raw.visualRef or raw.VisualRef or raw.itemRef or raw.rootRef),
				name = type(raw_name) == "string" and raw_name or nil,
				price = tonumber(raw_price) or (type(raw_price) == "string" and Util.stripped(raw_price) or nil),
				rarity = type(raw_rarity) == "string" and raw_rarity or nil,
				brand = type(raw_brand) == "string" and raw_brand or nil,
				fair = tonumber(raw_fair) or (type(raw_fair) == "string" and Util.stripped(raw_fair) or nil),
				stock = tonumber(raw_stock),
				seller = type(raw_seller) == "string" and raw_seller or nil,
				id = id,
				slot_id = (type(raw.slotId) == "string" and raw.slotId)
					or (type(raw.SlotId) == "string" and raw.SlotId or nil),
			}

			local record = Catalog.find(entry.id, entry.name, raw.customModelName)

			if record then
				Catalog.merge(entry, record)
				entry.catalogued = true
			end

			entry.model = Market.ref_number(entry.visual_ref) or Market.ref_number(entry.slot_ref)
			entry.assets = Market.mesh_assets(entry.visual_ref) or Market.mesh_assets(entry.slot_ref)

			if entry.catalogued ~= true then
				local extra = Catalog.pick(entry)

				if extra ~= nil then
					Catalog.merge(entry, extra)
					entry.catalogued = true
				end
			end

			if channel == "SlotInfoClear" then
				Market.forget_slot(entry)
			end

			Market.recall(entry)
			Market.remember(entry)

			if (entry.slot_ref ~= nil or entry.visual_ref ~= nil) and Market.ref_logged ~= true then
				Market.ref_logged = true

				print("leet.cheats: pushes carry live refs, first one: "
					.. tostring(entry.name)
					.. " at "
					.. tostring(entry.position))
			end

			if entry.name or entry.price or entry.rarity then
				if Market.attach(entry) then
					Market.stats.pinned = Market.stats.pinned + 1
				end

				Market.pushed[entry.key] = entry
				Market.join_dirty = true
			end
		end

		Market.stats.pushed = Util.count_keys(Market.pushed)

		return #found
	end

	local function zone_number(text)
		if type(text) ~= "string" then
			return nil
		end

		return tonumber(string.match(text, "(%d+)%s*$"))
	end

	local function push_matches(slot, entry)
		if entry.position ~= nil and slot.position ~= nil then
			if (entry.position - slot.position).Magnitude < 3 then
				return true
			end
		end

		if entry.slot_index ~= nil and entry.shop ~= nil and slot.slot_index == entry.slot_index then
			local number = zone_number(entry.shop)

			if number == nil or slot.zone_number == nil or number == slot.zone_number then
				return true
			end
		end

		if entry.id ~= nil and slot.id == entry.id then
			return true
		end

		if entry.name ~= nil and slot.name ~= nil and string.lower(entry.name) == string.lower(slot.name) then
			return true
		end

		return false
	end

	function Market.attach(entry)
		local pinned = false

		for _, slot in next, Market.slots do
			if push_matches(slot, entry) then
				slot.price = entry.price or slot.price
				slot.rarity = entry.rarity or slot.rarity
				slot.name = slot.name or entry.name
				slot.brand = slot.brand or entry.brand
				slot.fair = slot.fair or entry.fair
				slot.id = slot.id or entry.id
				slot.bare = false
				slot.catalogued = slot.catalogued or entry.catalogued
				entry.key = slot.key
				Market.remember(slot)
				pinned = true
			end
		end

		return pinned
	end

	function Market.apply_pushes(entry)
		for _, pushed in next, Market.pushed do
			if push_matches(entry, pushed) then
				entry.price = pushed.price or entry.price
				entry.rarity = pushed.rarity or entry.rarity
				entry.name = entry.name or pushed.name
				entry.brand = entry.brand or pushed.brand
				entry.fair = entry.fair or pushed.fair
				entry.id = entry.id or pushed.id
				entry.bare = false
				entry.catalogued = entry.catalogued or pushed.catalogued
			end
		end

		Market.remember(entry)
	end

	function Market.zone_anchor(shop)
		if type(shop) ~= "string" then
			return nil
		end

		local cached = Market.zones[shop]

		if cached ~= nil then
			if cached == false then
				return nil
			end

			return cached
		end

		local ok, position = pcall(function()
			local needle = string.lower(shop)

			for _, child in next, workspace:GetChildren() do
				if string.find(string.lower(child.Name), needle, 1, true) then
					local part = child:FindFirstChildWhichIsA("BasePart", true)

					if part then
						return part.Position
					end
				end
			end
		end)

		Market.zones[shop] = (ok and position) or false

		if not ok or position == nil then
			return nil
		end

		return position
	end

	function Market.arm_taps()
		local armed = {}

		for _, path in next, CHANNELS do
			local ok, remote = pcall(function()
				local node = replicated

				for index = 1, #path do
					node = node:FindFirstChild(path[index])

					if node == nil then
						return nil
					end
				end

				return node
			end)

			if ok and remote and remote:IsA("RemoteEvent") then
				local connected = pcall(function()
					return remote.OnClientEvent:Connect(function(...)
						Market.absorb(remote.Name, { ... })
					end)
				end)

				if connected then
					armed[#armed + 1] = remote:GetFullName()
				end
			end
		end

		Market.taps = armed

		return armed
	end
end

do
	local part_frame = Market.part_frame
	local part_anchor = Market.part_anchor
	local full_name = Market.full_name
	local absorb_child = Market.absorb_child
	local absorb_attributes = Market.absorb_attributes

	function Market.admin_call(verb, arguments)
		local ok, remote = pcall(function()
			local group = replicated:FindFirstChild("TsumRemotes")

			if group == nil then
				return nil
			end

			return group:FindFirstChild("Admin")
		end)

		if not ok or remote == nil or not remote:IsA("RemoteFunction") then
			return nil, "TsumRemotes/Admin is not here"
		end

		local called, result = pcall(function()
			return remote:InvokeServer(verb, arguments or {})
		end)

		if not called then
			return nil, "server refused " .. verb
		end

		if type(result) ~= "table" then
			return nil, verb .. " gave no table"
		end

		if result.error ~= nil then
			return nil, tostring(result.error)
		end

		return result, nil
	end

	local function find_anchor(needles)
		local ok, position = pcall(function()
			for _, instance in next, workspace:GetDescendants() do
				if instance:IsA("Model") or instance:IsA("BasePart") then
					local name = string.lower(instance.Name)

					for _, needle in next, needles do
						if string.find(name, needle, 1, true) then
							if instance:IsA("BasePart") then
								return instance.Position
							end

							return instance:GetPivot().Position
						end
					end
				end
			end
		end)

		if ok then
			return position
		end
	end

	function Market.probe_van()
		local ok, reply = pcall(function()
			local group = replicated:FindFirstChild("BlackMarketRemotes")
			local remote = group and group:FindFirstChild("GetBlackMarketData")

			if remote == nil then
				return nil
			end

			return remote:InvokeServer({})
		end)

		if not ok or reply == nil then
			return nil, "GetBlackMarketData is not answering"
		end

		if type(reply) ~= "table" then
			return nil, "van gave no table"
		end

		local position = find_anchor({ "blackmarket", "блекмаркет", "блек", "van" })
		local list = nil

		if type(reply.items) == "table" then
			list = reply.items
		elseif type(reply.stock) == "table" then
			list = reply.stock
		elseif type(reply.data) == "table" then
			list = reply.data
		else
			Market.absorb("van", reply)
		end

		if list == nil then
			Market.stats.van = 0

			return 0, nil
		end

		table.clear(Market.van)

		local count = 0

		local function collect(raw)
			if type(raw) ~= "table" then
				return
			end

			local name = type(raw.name) == "string" and raw.name or nil
			local id = tonumber(raw.id) or tonumber(raw.itemId) or (type(raw.id) == "string" and raw.id or nil)
			local record = Catalog.find(id, name, raw.customModelName)

			if name or record then
				count = count + 1

				local entry = {
					source = "van",
					key = "van:" .. tostring(count),
					name = name or record.name,
					price = tonumber(raw.price) or tonumber(raw.cost) or (record and record.fair),
					rarity = (type(raw.rarity) == "string" and raw.rarity) or (record and record.rarity),
					brand = (type(raw.brand) == "string" and raw.brand) or (record and record.brand),
					fair = record and record.fair,
					retired = record and record.retired,
					position = position,
					offset = count - 1,
					catalogued = record ~= nil,
				}

				Market.van[entry.key] = entry
				Market.remember(entry, true)
			end
		end

		for _, raw in next, list do
			collect(raw)

			if type(raw) == "table" then
				for _, nested in next, raw do
					if type(nested) == "table" and type(nested.name) == "string" then
						collect(nested)
					end
				end
			end
		end

		Market.stats.van = count

		return count, nil
	end

	function Market.probe_grayled()
		local reply, err = Market.admin_call("grayledListings", { refresh = true })

		if err then
			return nil, err
		end

		local list = type(reply.listings) == "table" and reply.listings or nil

		if list == nil then
			Market.absorb("grayled", reply)

			return nil, "no listings in the reply"
		end

		table.clear(Market.listings)

		local per_seller = {}
		local count = 0

		for index, raw in next, list do
			if type(raw) == "table" then
				local name = type(raw.name) == "string" and raw.name or nil
				local seller_id = tonumber(raw.sellerId)
				local seller_player = nil

				if seller_id then
					pcall(function()
						seller_player = players:GetPlayerByUserId(seller_id)
					end)
				end

				local record = Catalog.find(tonumber(raw.itemId), name, raw.customModelName)
				local position = nil

				if seller_player and seller_player.Character then
					pcall(function()
						local root = seller_player.Character:FindFirstChild("HumanoidRootPart")

						if root then
							position = root.Position
						end
					end)
				end

				local seller_key = tostring(seller_id or raw.sellerName or index)
				per_seller[seller_key] = (per_seller[seller_key] or 0) + 1

				count = count + 1

				local entry = {
					source = "listing",
					key = "listing:" .. tostring(raw.id or index),
					name = name or (record and record.name) or "listing",
					price = tonumber(raw.price),
					rarity = (type(raw.rarity) == "string" and raw.rarity) or (record and record.rarity),
					brand = (type(raw.brand) == "string" and raw.brand) or (record and record.brand),
					fair = record and record.fair,
					seller = type(raw.sellerName) == "string" and raw.sellerName
						or (seller_player and seller_player.Name or nil),
					auction_bids = type(raw.auction) == "table" and tonumber(raw.auction.bids) or nil,
					boosted = raw.boosted == true,
					official = raw.official == true,
					mystery = raw.mystery == true,
					position = position,
					online = seller_player ~= nil,
					offset = per_seller[seller_key] - 1,
					catalogued = record ~= nil,
				}

				Market.listings[entry.key] = entry
				Market.remember(entry, true)
			end
		end

		Market.stats.listings = count

		return count, nil
	end

	local PRICE_MARKS = { "₽", "руб", "P ", "₽", "$" }
	local SIGN_GAP = 10
	local SIGN_STUDS = 9
	local ITEM_GAP = 16

	local function json_text(raw)
		if type(raw) ~= "string" then
			return
		end

		local text = string.match(raw, '"text":"(.-)"')

		if text == nil then
			return
		end

		text = string.gsub(text, "\\n", " ")
		text = string.gsub(text, '\\"', '"')

		if #text < 2 or #text > 96 then
			return
		end

		return text
	end

	local function spelled(host)
		local ok, children = pcall(function()
			return host:GetChildren()
		end)

		if not ok then
			return
		end

		local letters = ""

		for _, part in next, children do
			if #tostring(part.Name) == 1 then
				letters = letters .. part.Name
			end
		end

		if #letters >= 3 then
			return letters
		end
	end

	local function price_in(text)
		local digits = Util.stripped(text)

		if digits == nil or digits <= 0 then
			return
		end

		if string.match(text, "^[%d%s.,]+%s*[P₽]$") ~= nil then
			return digits
		end

		if string.match(text, "^[P₽]%s*[%d%s.,]+$") ~= nil then
			return digits
		end

		for _, mark in next, PRICE_MARKS do
			if string.find(text, mark, 1, true) then
				return digits
			end
		end

		if string.match(text, "^[%s%d.,]+$") ~= nil then
			return digits
		end
	end

	local function zone_of(host)
		local node = host

		for _ = 1, 5 do
			if node == nil then
				break
			end

			if string.find(node.Name, "ShopZone", 1, true) then
				return node.Name
			end

			node = node.Parent
		end

		return host.Name
	end

	local function shop_of(host)
		local node = host

		for _ = 1, 8 do
			if node == nil then
				break
			end

			if string.find(node.Name, "ShopZone", 1, true) then
				return node.Name
			end

			node = node.Parent
		end
	end

	local function clean_text(text)
		if text == nil then
			return
		end

		local out = string.gsub(tostring(text), "<[^>]->", " ")

		out = string.gsub(out, "%{C2}%{A0}", " ")
		out = string.gsub(out, "%s+", " ")

		return string.match(out, "^%s*(.-)%s*$")
	end

	local function reseller_text(text)
		if text == nil then
			return false
		end

		return string.find(text, "@", 1, true) ~= nil
	end

	local function model_anchor(host)
		return part_anchor(host)
	end

	local function gui_anchor(label)
		local node = label.Parent

		for _ = 1, 6 do
			if node == nil then
				return
			end

			local ok, collector = pcall(function()
				return node:IsA("LayerCollector")
			end)

			if ok and collector then
				return
			end

			local anchored

			local ok3d, base = pcall(function()
				return node:IsA("GuiBase3d")
			end)

			if ok3d and base then
				local ok_ad, adornee = pcall(function()
					return node.Adornee
				end)

				if ok_ad and adornee ~= nil then
					anchored = model_anchor(adornee)
				end

				if anchored ~= nil then
					return anchored
				end
			else
				anchored = model_anchor(node)

				if anchored ~= nil then
					return anchored
				end
			end

			node = node.Parent
		end
	end

	local CollectionService = game:GetService("CollectionService")

	local function inside_tree(model, node)
		local probe = node

		for _ = 1, 10 do
			if probe == nil then
				break
			end

			if probe == model then
				return true
			end

			probe = probe.Parent
		end

		return false
	end

	function Market.is_visual_root(instance)
		local ok, result = pcall(function()
			if not instance:IsA("Model") then
				return false
			end

			if string.match(instance.Name, "^M_%d+$") == nil then
				return false
			end

			if CollectionService:HasTag(instance, "__ShopRotatingItem") then
				return true
			end

			if instance:GetAttributes()["__ShopVisualRoot"] == true then
				return true
			end

			return shop_of(instance) ~= nil
		end)

		if ok then
			return result == true
		end

		return false
	end

	function Market.read_root(model)
		local position, size = part_frame(model)

		if position == nil then
			return
		end

		local entry = {
			source = "item",
			item = true,
			host = model,
			key = "item:" .. full_name(model),
			position = position,
			size = size,
			zone = zone_of(model),
			shop = shop_of(model),
			id = tonumber(string.match(model.Name, "^M_(%d+)$")),
		}

		absorb_attributes(entry, model)

		local ok, children = pcall(function()
			return model:GetChildren()
		end)

		if ok then
			for _, child in next, children do
				absorb_child(entry, child)
				absorb_attributes(entry, child)
			end
		end

		entry.assets = Market.mesh_assets(model)

		local record = Catalog.pick(entry)

		if record ~= nil then
			Catalog.merge(entry, record)
			entry.catalogued = true
		end

		Market.apply_pushes(entry)
		Market.recall(entry)
		Market.remember(entry)

		entry.bare = (entry.price == nil and entry.rarity == nil and entry.name == nil)

		return entry
	end

	function Market.bind_items()
		local by_price = Market.push_by_price()

		local function entry_for(store, value, steps)
			if value == nil or typeof(value) ~= "Instance" then
				return
			end

			local node = value

			for _ = 1, steps do
				local entry = store[node]

				if entry ~= nil then
					return entry
				end

				local ok, parent = pcall(function()
					return node.Parent
				end)

				if not ok or parent == nil then
					return
				end

				node = parent
			end
		end

		local function pour(target, pushed)
			if target == nil then
				return
			end

			target.price = pushed.price or target.price
			target.rarity = pushed.rarity or target.rarity
			target.name = target.name or pushed.name
			target.brand = target.brand or pushed.brand
			target.fair = target.fair or pushed.fair
			target.kind = target.kind or pushed.kind
			target.id = target.id or pushed.id
			target.catalogued = target.catalogued or pushed.catalogued
			target.bare = false
			Market.remember(target)
		end

		local exact = 0

		for _, pushed in next, Market.pushed do
			if pushed.slot_ref ~= nil or pushed.visual_ref ~= nil then
				local slot = entry_for(Market.slots, pushed.slot_ref, 2)
					or entry_for(Market.slots, pushed.visual_ref, 2)

				local root = entry_for(Market.roots, pushed.visual_ref, 1)
					or (slot ~= nil and slot.visual ~= nil and Market.roots[slot.visual])
					or (slot ~= nil and slot.host ~= nil and Market.roots[slot.host])

				pour(slot, pushed)
				pour(root, pushed)

				if root ~= nil then
					exact = exact + 1
					root.exact = true

					if root.source == "item" then
						root.source = "item+push"
					end

					if slot ~= nil then
						slot.item_key = slot.item_key or root.key
						root.slot_key = root.slot_key or slot.slot_key
					end
				end
			end
		end

		Market.stats.exact = exact

		for _, slot in next, Market.slots do
			if slot.visual ~= nil then
				local root = Market.roots[slot.visual]

				if root ~= nil then
					root.name = root.name or slot.name
					root.price = root.price or slot.price
					root.rarity = root.rarity or slot.rarity
					root.brand = root.brand or slot.brand
					root.fair = root.fair or slot.fair
					root.kind = root.kind or slot.kind
					root.catalogued = root.catalogued or slot.catalogued
					root.slot_key = root.slot_key or slot.slot_key
					slot.item_key = root.key
					Market.remember(root)
				end
			end
		end

		for _, root in next, Market.roots do
			local named, priced
			local name_gap, price_gap = ITEM_GAP, ITEM_GAP

			for _, tag in next, Market.tags do
				if tag.reseller ~= true and tag.position ~= nil then
					local away = (tag.position - root.position).Magnitude

					if away < ITEM_GAP then
						if inside_tree(root.host, tag.host) then
							away = 0
						end

						if tag.name ~= nil and away < name_gap then
							name_gap = away
							named = tag
						end

						if tag.price ~= nil and away < price_gap then
							price_gap = away
							priced = tag
						end
					end
				end
			end

			if named ~= nil then
				root.rarity = root.rarity or named.rarity
				root.brand = root.brand or named.brand
				root.fair = root.fair or named.fair

				if root.name == nil then
					root.name = named.name
					named.dup = true
				elseif named.price == nil and root.price ~= nil then
					named.dup = true
				end
			end

			if priced ~= nil then
				if root.price == nil then
					root.price = priced.price
					priced.dup = true
				elseif priced.price == root.price then
					priced.dup = true
				end
			end

			if root.name ~= nil then
				if root.catalogued ~= true then
					local record = Catalog.find(nil, root.name, nil)

					if record ~= nil then
						Catalog.merge(root, record)
						root.catalogued = true
					end
				end

				for _, pushed in next, Market.pushed do
					if pushed.name ~= nil and string.lower(pushed.name) == string.lower(root.name) then
						root.price = root.price or pushed.price
						root.rarity = root.rarity or pushed.rarity
						root.brand = root.brand or pushed.brand
						root.fair = root.fair or pushed.fair
						root.source = "item+push"

						break
					end
				end
			elseif root.price ~= nil then
				local twin = by_price[root.price]

				if type(twin) == "table" then
					root.name = twin.name
					root.rarity = root.rarity or twin.rarity
					root.brand = root.brand or twin.brand
					root.fair = root.fair or twin.fair
					root.catalogued = root.catalogued or twin.catalogued
					root.source = "item+pricetag"
				end
			end

			Market.recall(root)
			Market.remember(root)
			root.bare = (root.price == nil and root.rarity == nil and root.name == nil and root.id == nil)
			root.useful = true
		end

		Market.stats.items = Util.count_keys(Market.roots)
	end

	function Market.push_by_price()
		local index = {}

		for _, pushed in next, Market.pushed do
			local price = pushed.price

			if price ~= nil and price > 0 and pushed.name ~= nil then
				if index[price] == nil then
					index[price] = pushed
				else
					index[price] = false
				end
			end
		end

		return index
	end

	local GRID_CELL = 10
	local OFFSETS = {}

	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				OFFSETS[#OFFSETS + 1] = dx
				OFFSETS[#OFFSETS + 1] = dy
				OFFSETS[#OFFSETS + 1] = dz
			end
		end
	end

	local function grid_of(source)
		local cells = {}

		for entry in next, source do
			local position = entry.position

			if position ~= nil then
				local key = string.format(
					"%d|%d|%d",
					math.floor(position.X / GRID_CELL),
					math.floor(position.Y / GRID_CELL),
					math.floor(position.Z / GRID_CELL)
				)
				local bucket = cells[key]

				if bucket == nil then
					bucket = {}
					cells[key] = bucket
				end

				bucket[#bucket + 1] = entry
			end
		end

		return cells
	end

	local function fits(entry, mode)
		if mode == "name_only" then
			return entry.name ~= nil and entry.price == nil
		end

		if mode == "named_plain" then
			return entry.name ~= nil and entry.reseller ~= true
		end

		if mode == "slot_name" then
			return entry.name ~= nil and entry.useful == true and entry.reseller ~= true
		end

		if mode == "slot_price" then
			return entry.price ~= nil and entry.reseller ~= true
		end

		return false
	end

	local function nearest(cells, position, gap, mode)
		local cx = math.floor(position.X / GRID_CELL)
		local cy = math.floor(position.Y / GRID_CELL)
		local cz = math.floor(position.Z / GRID_CELL)
		local best
		local best_gap = gap
		local cursor = 1
		local span = #OFFSETS

		while cursor <= span do
			local bucket = cells[string.format(
				"%d|%d|%d",
				cx + OFFSETS[cursor],
				cy + OFFSETS[cursor + 1],
				cz + OFFSETS[cursor + 2]
			)]

			if bucket ~= nil then
				for _, entry in next, bucket do
					if fits(entry, mode) then
						local vector = entry.position - position
						local away = vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z

						if away < best_gap * best_gap then
							best_gap = math.sqrt(away)
							best = entry
						end
					end
				end
			end

			cursor = cursor + 3
		end

		return best
	end

	local function mark_dups(cells, source)
		local square = SIGN_GAP * SIGN_GAP

		for entry in next, source do
			if entry.name ~= nil and entry.dup ~= true and entry.position ~= nil then
				local cx = math.floor(entry.position.X / GRID_CELL)
				local cy = math.floor(entry.position.Y / GRID_CELL)
				local cz = math.floor(entry.position.Z / GRID_CELL)
				local cursor = 1
				local span = #OFFSETS

				while cursor <= span do
					local bucket = cells[string.format(
						"%d|%d|%d",
						cx + OFFSETS[cursor],
						cy + OFFSETS[cursor + 1],
						cz + OFFSETS[cursor + 2]
					)]

					if bucket ~= nil then
						for _, other in next, bucket do
							if other ~= entry and other.dup ~= true then
								if other.name == entry.name and other.price == entry.price then
									local vector = other.position - entry.position

									if vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z < square then
										other.dup = true
									end
								end
							end
						end
					end

					cursor = cursor + 3
				end
			end
		end
	end

	function Market.adopt_tags()
		local found = Market.tags
		local by_price = Market.push_by_price()
		local cells = grid_of(found)
		local by_name = {}

		for _, pushed in next, Market.pushed do
			if pushed.name ~= nil then
				local needle = string.lower(pushed.name)

				if by_name[needle] == nil then
					by_name[needle] = pushed
				end
			end
		end

		for _, entry in next, found do
			if entry.position ~= nil then
				if entry.price ~= nil and entry.name == nil then
					local donor = nearest(cells, entry.position, SIGN_GAP, "name_only")

					if donor ~= nil then
						entry.name = donor.name
						entry.rarity = entry.rarity or donor.rarity
						entry.brand = entry.brand or donor.brand
						entry.fair = entry.fair or donor.fair
						entry.reseller = entry.reseller or donor.reseller
						donor.dup = true
					end
				end

				if entry.reseller == true then
					local item = nearest(cells, entry.position, SIGN_GAP, "named_plain")

					if item ~= nil then
						entry.name = item.name
						entry.rarity = entry.rarity or item.rarity
						entry.brand = entry.brand or item.brand
						entry.fair = entry.fair or item.fair
						entry.reseller = false
					end
				end

				if entry.name ~= nil then
					local record = Catalog.find(nil, entry.name, nil)

					if record ~= nil then
						Catalog.merge(entry, record)
						entry.catalogued = true
					end

					local pushed = by_name[string.lower(entry.name)]

					if pushed ~= nil then
						entry.price = pushed.price or entry.price
						entry.rarity = pushed.rarity or entry.rarity
						entry.brand = pushed.brand or entry.brand
						entry.fair = pushed.fair or entry.fair
						entry.source = entry.source == "gui" and "gui+push" or "label+push"
					end
				end
			end

			if entry.name == nil and entry.price ~= nil then
				local twin = by_price[entry.price]

				if type(twin) == "table" then
					entry.name = twin.name
					entry.rarity = entry.rarity or twin.rarity
					entry.brand = entry.brand or twin.brand
					entry.fair = entry.fair or twin.fair
					entry.catalogued = entry.catalogued or twin.catalogued
					entry.source = entry.source .. "+pricetag"
				end
			end

			entry.bare = (entry.price == nil and entry.rarity == nil and entry.name == nil)
			entry.useful = (entry.price ~= nil or entry.catalogued == true or entry.rarity ~= nil)
		end

		mark_dups(cells, found)

		for _, slot in next, Market.slots do
			if slot.position ~= nil then
				local named = nearest(cells, slot.position, SIGN_STUDS, "slot_name")
				local priced = nearest(cells, slot.position, SIGN_STUDS, "slot_price")

				if named ~= nil and slot.name == nil then
					slot.name = named.name
					slot.rarity = slot.rarity or named.rarity
					slot.fair = slot.fair or named.fair
					slot.brand = slot.brand or named.brand
					slot.catalogued = slot.catalogued or named.catalogued
				end

				if priced ~= nil then
					slot.price = slot.price or priced.price

					if named ~= nil and slot.rarity == nil then
						slot.rarity = named.rarity
					end
				end

				if slot.name == nil and slot.price ~= nil then
					local twin = by_price[slot.price]

					if type(twin) == "table" then
						slot.name = twin.name
						slot.rarity = slot.rarity or twin.rarity
						slot.brand = slot.brand or twin.brand
						slot.fair = slot.fair or twin.fair
						slot.catalogued = slot.catalogued or twin.catalogued
					end
				end

				if named ~= nil then
					named.dup = true
				end

				if priced ~= nil then
					priced.dup = true
				end

				if named ~= nil or priced ~= nil then
					slot.bare = (slot.price == nil and slot.rarity == nil and slot.name == nil)
				end

				Market.recall(slot)
				Market.remember(slot)
			end
		end

		local known = 0

		for _, entry in next, Market.slots do
			if entry.fair ~= nil then
				known = known + 1
			end
		end

		for _, entry in next, found do
			if entry.fair ~= nil then
				known = known + 1
			end
		end

		Market.stats.fair = known

		local ok_bind, bind_error = pcall(Market.bind_items)

		if not ok_bind and Market.bind_error_shown ~= true then
			Market.bind_error_shown = true
			print("leet.cheats: item bind failed: " .. tostring(bind_error))
		end

		Market.join_dirty = false
	end

	function Market.scan_tags()
		local found = {}

		local ok, all = pcall(function()
			return workspace:GetDescendants()
		end)

		if not ok then
			return 0
		end

		local function split_text(text)
			local head, tail = string.match(text, "^(.-)%s*([%d][%d%s.,]*)%s*[₽P$]?%s*$")

			if head == nil then
				return
			end

			head = string.gsub(head, "%s+$", "")

			if #head < 3 then
				return nil, Util.stripped(tail)
			end

			return head, Util.stripped(tail)
		end

		local function push_named(text)
			local lower = string.lower(text)

			for _, pushed in next, Market.pushed do
				if pushed.name ~= nil and string.lower(pushed.name) == lower then
					return true
				end
			end

			return false
		end

		local census = { three_d = 0, gui = 0, junk = 0, objects = 0, labels = 0 }
		Market.sign_census = census

		local seq = 0

		local function uid_of(node)
			local ok, full = pcall(function()
				return node:GetFullName()
			end)

			if ok and type(full) == "string" then
				return full
			end

			seq = seq + 1

			return "node" .. seq
		end

		local function record(host, position, text, kind, uid)
			text = clean_text(text)

			if text == nil or string.len(text) < 2 then
				census.junk = census.junk + 1

				return
			end

			census[kind] = census[kind] + 1

			local head, tail_number = split_text(text)
			local entry = {
				source = kind == "gui" and "gui" or "label",
				key = (kind == "gui" and "gui:" or "label:") .. uid,
				uid = uid,
				host = host,
				text = text,
				position = position,
				price = price_in(text) or tail_number,
				zone = zone_of(host),
				shop = shop_of(host),
				reseller = reseller_text(text),
			}

			if head ~= nil then
				entry.name = head
			elseif entry.price == nil then
				entry.name = text
			end

			if found[entry.key] ~= nil then
				seq = seq + 1
				entry.key = entry.key .. "#" .. seq
			end

			found[entry.key] = entry
		end

		for _, instance in next, all do
			if string.find(instance.Name, "ThreeDText", 1, true) then
				census.objects = census.objects + 1
			end

			if instance:IsA("StringValue") and instance.Name == "ThreeDTextParams" then
				local host = instance.Parent
				local text = json_text(instance.Value)

				if text == nil and host ~= nil then
					local alt = spelled(host)

					if alt ~= nil and (Catalog.by_name[string.lower(alt)] ~= nil or push_named(alt)) then
						text = alt
					end
				end

				local position = host ~= nil and model_anchor(host) or nil

				if text ~= nil and position ~= nil then
					record(host, position, text, "three_d", uid_of(instance))
				else
					census.junk = census.junk + 1
				end
			elseif instance:IsA("TextLabel") then
				census.labels = census.labels + 1
				local text = Util.clip(clean_text(instance.Text) or "", 96)

				if #text >= 2 then
					local wanted = price_in(text) ~= nil
						or split_text(text) ~= nil
						or Catalog.by_name[string.lower(text)] ~= nil
						or push_named(text)

					local position = wanted and gui_anchor(instance) or nil

					if position ~= nil then
						record(instance.Parent, position, text, "gui", uid_of(instance))
					elseif wanted then
						census.junk = census.junk + 1
					end
				end
			end
		end

		Market.tags = found
		Market.stats.tags = Util.count_keys(found)
		Market.adopt_tags()

		return Market.stats.tags
	end
end

local Visual = {
	records = {},
	active = {},
	budget = 60,
	step = 0,
	new_left = 0,
	frame_cost = 0,
	sync_cost = 0,
	drawn = 0,
	candidates = 0,
	filled = 0,
}

Market.Visual = Visual

do
	local SYNC_STEP = 0.2
	local MAX_STUDS = 1500
	local MAX_MARKS = 120
	local NEW_NODES_PER_SYNC = 60
	local SNAP_MARKS = 8
	local SNAP_STUDS = 260

	Visual.sync_step = SYNC_STEP

	local function new_node(class)
		if not Env.drawing then
			return
		end

		local ok, node = pcall(function()
			return Drawing.new(class)
		end)

		return ok and node or nil
	end

	local function style(node, font, size)
		if node == nil then
			return
		end

		node.Font = FONT_IDS[font] or 2
		node.Size = size
		node.Center = true
		node.Outline = true
	end

	local function slot_of(record, key, class)
		local node = record[key]

		if node then
			return node
		end

		if Visual.new_left <= 0 then
			return
		end

		Visual.new_left = Visual.new_left - 1
		node = new_node(class)

		if node == nil then
			return
		end

		record[key] = node

		if class == "Text" then
			style(node, Visual.font, Visual.size)
		end

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

	local function free(record)
		kill(record.name)
		kill(record.price)
		kill(record.fair)
		kill(record.tags)
		kill(record.box)
		kill(record.snap)

		table.clear(record)
	end

	local function blank(record)
		show(record.name, false)
		show(record.price, false)
		show(record.fair, false)
		show(record.tags, false)
		show(record.box, false)
		show(record.snap, false)

		record.lines = nil
		record.used = 0
		record.box_on = false
		record.snap_on = false
		record.shown = nil
	end

	Visual.free = free
	Visual.blank = blank

	local function rank_of(entry)
		return Rarity.order[entry.rarity] or 0
	end

	local function push_candidate(out, entry, origin, limit_studs, min_rank, deals_only)
		local position = entry.position

		if position == nil or entry.bare == true then
			return
		end

		if entry.name == nil and entry.price == nil then
			return
		end

		local vector = position - origin
		local away = math.sqrt(vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z)

		if away > limit_studs then
			return
		end

		local rank = rank_of(entry)

		if rank > 0 and rank < min_rank then
			return
		end

		if deals_only and entry.fair ~= nil and entry.price ~= nil and entry.price >= entry.fair then
			return
		end

		entry.dist = away
		out[#out + 1] = entry

		if entry.memory == true then
			Visual.filled = (Visual.filled or 0) + 1
		end
	end

	function Visual.entries()
		local camera = workspace.CurrentCamera

		if camera == nil then
			return {}
		end

		local origin = camera.CFrame.Position
		local studs = math.min(Util.number("market_studs", 900), MAX_STUDS)
		local min_rank = Rarity.order[Util.pick("market_rarity", "Common")] or 1
		local deals_only = Util.on("market_deals")
		local out = {}

		Visual.filled = 0

		local items_on = Util.on("market_items")

		if Util.on("market_shop") then
			for _, entry in next, Market.slots do
				if not (items_on and entry.item_key ~= nil) then
					push_candidate(out, entry, origin, studs, min_rank, deals_only)
				end
			end
		end

		if items_on then
			for _, entry in next, Market.roots do
				push_candidate(out, entry, origin, studs, min_rank, deals_only)
			end
		end

		if Util.on("market_signs") then
			local stalls = Util.on("market_stalls")

			for _, entry in next, Market.tags do
				if entry.name ~= nil and entry.price ~= nil and entry.dup ~= true and entry.useful == true then
					if entry.reseller ~= true or stalls then
						push_candidate(out, entry, origin, studs, min_rank, deals_only)
					end
				end
			end
		end

		if Util.on("market_van") then
			for _, entry in next, Market.van do
				push_candidate(out, entry, origin, studs, min_rank, deals_only)
			end
		end

		if Util.on("market_grayled") then
			for _, entry in next, Market.listings do
				if entry.position ~= nil then
					push_candidate(out, entry, origin, studs, min_rank, deals_only)
				end
			end
		end

		if Util.on("market_loose") then
			local stacked = {}

			for key, entry in next, Market.pushed do
				if string.sub(tostring(key), 1, 5) ~= "slot:" then
					if entry.position == nil and entry.shop ~= nil then
						entry.position = Market.zone_anchor(entry.shop)
					end

					if entry.position ~= nil then
						local anchor_key = tostring(math.floor(entry.position.X)) .. "," .. tostring(math.floor(entry.position.Z))
						local count = (stacked[anchor_key] or 0) + 1

						stacked[anchor_key] = count
						entry.offset = count - 1
						push_candidate(out, entry, origin, studs, min_rank, deals_only)
					end
				end
			end
		end

		local clean = {}
		local spots = {}

		for _, entry in next, out do
			local position = entry.position
			local spot = string.format(
				"%.0f|%.0f|%s|%s|%d",
				position.X * 0.5,
				position.Z * 0.5,
				tostring(entry.name),
				tostring(entry.price),
				entry.offset or 0
			)

			if spots[spot] == nil then
				spots[spot] = true
				clean[#clean + 1] = entry
			end
		end

		table.sort(clean, function(a, b)
			local ra, rb = rank_of(a), rank_of(b)

			if ra ~= rb then
				return ra > rb
			end

			return (a.dist or 0) < (b.dist or 0)
		end)

		local capped = {}
		local limit = math.min(Util.number("market_limit", 60), MAX_MARKS)

		for index = 1, math.min(#clean, limit) do
			capped[index] = clean[index]
		end

		Visual.candidates = #clean

		return capped
	end

	local function add_line(lines, used, node, dy)
		if node == nil then
			return used
		end

		local line = lines[used + 1]

		if line == nil then
			line = {}
			lines[used + 1] = line
		end

		line.node = node
		line.dy = dy

		return used + 1
	end

	local function blank_lines(record)
		local lines = record.lines
		local used = record.used or 0

		if lines ~= nil then
			for index = 1, used do
				lines[index].node.Visible = false
			end
		end

		show(record.box, false)
		show(record.snap, false)
	end

	local function compose(record, entry, cfg)
		local lines = record.lines

		if lines == nil then
			lines = {}
			record.lines = lines
		end

		local size = cfg.size
		local top = -size * 1.2 - (entry.offset or 0) * (size * 4.6)
		local color = (entry.rarity and Rarity.colors[entry.rarity]) or cfg.fallback
		local used = 0

		if cfg.names and entry.name ~= nil then
			local node = slot_of(record, "name", "Text")

			if node ~= nil then
				style(node, cfg.font, size)
				node.Text = Util.case(Util.clip(entry.name, 30), cfg.case_mode)
				node.Color = color
				used = add_line(lines, used, node, top)
			end
		end

		if cfg.price and entry.price ~= nil then
			local node = slot_of(record, "price", "Text")

			if node ~= nil then
				local tone = cfg.price_color

				if entry.fair ~= nil and entry.fair > 0 then
					if entry.price < entry.fair then
						tone = Color3.fromRGB(80, 220, 120)
					elseif entry.price > entry.fair * 1.15 then
						tone = Color3.fromRGB(240, 90, 90)
					end
				end

				node.Text = Util.money(entry.price)
				node.Color = tone
				style(node, cfg.font, size)
				used = add_line(lines, used, node, top + size * 1.15)
			end
		end

		if cfg.fair and entry.fair ~= nil then
			local node = slot_of(record, "fair", "Text")

			if node ~= nil then
				local text = "fair " .. Util.money(entry.fair)

				if entry.price ~= nil then
					text = text .. string.format("  %+0.0f%%", (entry.price / entry.fair - 1) * 100)
				else
					text = text .. string.format(
						"  ~%s-%s",
						Util.money(entry.fair * cfg.low),
						Util.money(entry.fair * cfg.high)
					)
				end

				if entry.retired then
					text = text .. "  retired"
				end

				node.Text = text
				node.Color = Color3.fromRGB(190, 190, 200)
				style(node, cfg.font, size)
				used = add_line(lines, used, node, top + size * 2.3)
			end
		end

		if cfg.tags then
			local parts = {}

			if entry.rarity then
				parts[#parts + 1] = Rarity.labels[entry.rarity] or string.lower(entry.rarity)
			end

			if entry.brand then
				parts[#parts + 1] = string.lower(entry.brand)
			end

			if entry.kind then
				parts[#parts + 1] = string.lower(entry.kind)
			end

			if entry.id ~= nil and entry.rarity == nil and entry.brand == nil and entry.kind == nil then
				parts[#parts + 1] = "#" .. tostring(entry.id)
			end

			if entry.seller then
				parts[#parts + 1] = "@" .. entry.seller
			end

			if entry.auction_bids then
				parts[#parts + 1] = "auction " .. tostring(entry.auction_bids)
			end

			if entry.boosted then
				parts[#parts + 1] = "boosted"
			end

			if entry.mystery then
				parts[#parts + 1] = "mystery"
			end

			if entry.source == "van" then
				parts[#parts + 1] = "black market"
			end

			if cfg.dist then
				parts[#parts + 1] = string.format("%.0f m", entry.dist or 0)
			end

			if #parts > 0 then
				local node = slot_of(record, "tags", "Text")

				if node ~= nil then
					node.Text = Util.case(Util.clip(table.concat(parts, " · "), 54), cfg.case_mode)
					node.Color = Color3.fromRGB(150, 150, 165)
					style(node, cfg.font, math.max(8, size - 2))
					used = add_line(lines, used, node, top + size * 3.4)
				end
			end
		end

		local pool = { record.name, record.price, record.fair, record.tags }

		for pool_index = 1, 4 do
			local node = pool[pool_index]

			if node ~= nil then
				local wanted = false

				for used_index = 1, used do
					if lines[used_index].node == node then
						wanted = true
						break
					end
				end

				if wanted ~= true then
					node.Visible = false
				end
			end
		end
		record.box_on = false

		if cfg.box then
			local node = slot_of(record, "box", "Square")

			if node ~= nil then
				node.Color = color
				node.Thickness = 1
				node.Filled = false
				node.Transparency = 0.35
				record.box_on = true
				record.box_stud = entry.size ~= nil
				record.box_size = entry.size
			else
				show(record.box, false)
			end
		else
			show(record.box, false)
		end

		record.snap_on = false

		if cfg.snap and entry.snap_on == true then
			local node = slot_of(record, "snap", "Line")

			if node ~= nil then
				node.Color = color
				node.Thickness = 1
				node.Transparency = 0.6
				record.snap_on = true
			else
				show(record.snap, false)
			end
		else
			show(record.snap, false)
		end

		record.entry = entry
		record.used = used
	end

	function Visual.sync()
		if not Env.drawing then
			return
		end

		local camera = workspace.CurrentCamera

		if camera == nil then
			return
		end

		local font = Util.pick("market_font", "SourceSans")
		local size = math.max(8, Util.number("market_size", 14))

		Visual.font = font
		Visual.size = size

		local ceiling = math.min(Util.number("market_limit", 60), MAX_MARKS)
		local budget = Visual.budget
		local slow = Visual.frame_cost > 3 or Visual.sync_cost > 25
		local comfy = Visual.frame_cost < 1.2 and Visual.sync_cost < 10

		if Visual.step == 0 then
			budget = ceiling
		elseif slow then
			budget = math.max(12, math.floor(budget * 0.7))
		elseif comfy and budget < ceiling then
			budget = math.min(ceiling, budget + 3)
		end

		if budget > ceiling then
			budget = ceiling
		end

		Visual.budget = budget

		local all = Visual.entries()
		local cfg = {
			font = font,
			case_mode = Util.pick("market_case", "none"),
			fallback = Util.color("market_color_name", Color3.fromRGB(235, 235, 240)),
			price_color = Util.color("market_color_price", Color3.new(1, 1, 1)),
			names = Util.on("market_names"),
			price = Util.on("market_price"),
			fair = Util.on("market_fair"),
			tags = Util.on("market_tags"),
			dist = Util.on("market_dist"),
			box = Util.on("market_box"),
			snap = Util.on("market_snap"),
			low = Catalog.bands.low,
			high = Catalog.bands.high,
			size = size,
		}

		for index = 1, #all do
			all[index].snap_on = false
		end

		if cfg.snap then
			local picked = 0

			while picked < SNAP_MARKS do
				local best
				local best_dist = SNAP_STUDS + 1

				for index = 1, #all do
					local entry = all[index]
					local away = entry.dist or 0

					if entry.snap_on ~= true and away <= SNAP_STUDS and away < best_dist then
						best = entry
						best_dist = away
					end
				end

				if best == nil then
					break
				end

				best.snap_on = true
				picked = picked + 1
			end
		end

		Visual.new_left = NEW_NODES_PER_SYNC

		local keep = {}
		local active = {}
		local limit = math.min(#all, budget)

		for index = 1, limit do
			local entry = all[index]
			local key = entry.key

			if key ~= nil then
				keep[key] = true

				local record = Visual.records[key]

				if record == nil then
					record = { key = key }
					Visual.records[key] = record
				end

				compose(record, entry, cfg)
				record.shown = true
				active[#active + 1] = record
			end
		end

		for index = limit + 1, #all do
			local key = all[index].key

			if key ~= nil then
				keep[key] = true
			end
		end

		for key, record in next, Visual.records do
			if keep[key] == nil then
				free(record)
				Visual.records[key] = nil
			elseif record.shown ~= true then
				blank(record)
			else
				record.shown = nil
			end
		end

		Visual.active = active
	end

	function Visual.frame()
		if not Env.drawing then
			return
		end

		local camera = workspace.CurrentCamera

		if camera == nil then
			return
		end

		local now = os.clock()

		if Visual.pulse ~= nil then
			local delta = (now - Visual.pulse) * 1000

			if delta > 120 then
				delta = 120
			end

			Visual.step = Visual.step * 0.85 + delta * 0.15
		end

		Visual.pulse = now

		local active = Visual.active
		local viewport = camera.ViewportSize
		local right = viewport.X + 80
		local bottom = viewport.Y + 80
		local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
		local scene = camera.CFrame
		local origin = scene.Position
		local forward = scene.LookVector
		local focal = viewport.Y * 0.5 / math.max(0.01, math.tan(math.rad(camera.FieldOfView * 0.5)))
		local drawn = 0

		for index = 1, #active do
			local record = active[index]
			local entry = record.entry
			local position = nil

			if entry ~= nil then
				position = entry.position
			end

			if position == nil then
				blank_lines(record)
			else
				local vector = position - origin
				local depth = vector.X * forward.X + vector.Y * forward.Y + vector.Z * forward.Z

				if depth > 0.5 then
					local screen = camera:WorldToViewportPoint(position)
					local x = screen.X
					local y = screen.Y

					if x > -80 and x < right and y > -80 and y < bottom then
						local lines = record.lines

						if lines ~= nil then
							for line_index = 1, record.used or 0 do
								local line = lines[line_index]
								line.node.Position = Vector2.new(x, y + line.dy)
								line.node.Visible = true
							end
						end

						if record.box_on == true then
							local node = record.box
							local distance = depth

							if distance < 1 then
								distance = 1
							end

							if record.box_stud == true then
								local size = record.box_size
								local wide = focal * math.max(size.X, size.Z) / distance

								if wide < 8 then
									wide = 8
								elseif wide > 340 then
									wide = 340
								end

								local tall = focal * size.Y / distance

								if tall < 8 then
									tall = 8
								elseif tall > 340 then
									tall = 340
								end

								node.Position = Vector2.new(x - wide * 0.5, y - tall * 0.5)
								node.Size = Vector2.new(wide, tall)
							else
								local radius = 16000 / distance

								if radius < 9 then
									radius = 9
								elseif radius > 150 then
									radius = 150
								end

								node.Position = Vector2.new(x - radius * 0.5, y - radius * 0.7)
								node.Size = Vector2.new(radius, radius * 1.4)
							end

							node.Visible = true
						else
							show(record.box, false)
						end

						if record.snap_on == true then
							local node = record.snap
							node.From = center
							node.To = Vector2.new(x, y)
							node.Visible = true
						else
							show(record.snap, false)
						end

						drawn = drawn + 1
					else
						blank_lines(record)
					end
				else
					blank_lines(record)
				end
			end
		end

		Visual.drawn = drawn
	end

	function Visual.teardown()
		for _, record in next, Visual.records do
			free(record)
		end

		Visual.records = {}
		Visual.active = {}
		Visual.drawn = 0
		Visual.pulse = nil
		Visual.step = 0
	end
end

local window = leet:window({
	name = "leet.cheats · market",
	size = UDim2.fromOffset(520, 600),
})

local market_tab = window:tab({ name = "market" })
local rules_tab = window:tab({ name = "rules" })
local data_tab = window:tab({ name = "data" })

do
	local main = market_tab:section({ name = "sale esp" })

	main:toggle({
		name = "market esp",
		flag = "market_esp",
		default = true,
		tooltip = "master switch for every sale tag below",
	})

	main:keybind({
		name = "esp bind",
		flag = "market_bind",
		display = "menu",
		default = Enum.KeyCode.U,
		tooltip = "flips market esp, the checkbox follows",
		callback = function(active)
			Util.set_flag("market_esp", active == true)
		end,
	})

	main:toggle({
		name = "shop racks",
		flag = "market_shop",
		default = true,
		tooltip = "clothes racks and stalls replicated into the world",
	})

	main:toggle({
		name = "shop items",
		flag = "market_items",
		default = true,
		tooltip = "the real product models on the racks, found by __ShopVisualRoot, box hugs the part",
	})

	main:toggle({
		name = "shop price signs",
		flag = "market_signs",
		default = true,
		tooltip = "reads the 3D signs the game itself puts over racks, pairs name with price and rarity",
	})

	main:toggle({
		name = "player stalls",
		flag = "market_stalls",
		default = false,
		tooltip = "also highlight tables where players resell, tagged with their nickname",
	})

	main:toggle({
		name = "black market van",
		flag = "market_van",
		default = true,
		tooltip = "van cycle stock, pulled once and refreshed by the button",
	})

	main:toggle({
		name = "player listings",
		flag = "market_grayled",
		default = false,
		tooltip = "grayled stock pinned over each seller, needs the probe",
	})

	main:toggle({
		name = "loose pushes",
		flag = "market_loose",
		default = true,
		tooltip = "draws pushed items at their own spot or over their shop building when no slot matched",
	})

	local lines = market_tab:section({ name = "tag lines", side = "right" })

	lines:toggle({
		name = "name",
		flag = "market_names",
		default = true,
		tooltip = "item name painted in the rarity colour",
	})

	lines:toggle({
		name = "price",
		flag = "market_price",
		default = true,
		tooltip = "what they ask, green below fair, red 15% over",
	})

	lines:toggle({
		name = "fair price",
		flag = "market_fair",
		default = true,
		tooltip = "catalogue fair price plus the gap, or the expected band",
	})

	lines:toggle({
		name = "tags",
		flag = "market_tags",
		default = true,
		tooltip = "rarity · brand · kind · seller · distance",
	})

	lines:toggle({
		name = "distance",
		flag = "market_dist",
		default = false,
		tooltip = "appends studs distance into the tag line",
	})

	lines:toggle({
		name = "box",
		flag = "market_box",
		default = false,
		tooltip = "outline around the item anchor",
	})

	lines:toggle({
		name = "snapline",
		flag = "market_snap",
		default = false,
		tooltip = "line from the crosshair to the item",
	})
end

do
	local filters = rules_tab:section({ name = "filters" })
	local look = rules_tab:section({ name = "look", side = "right" })

	filters:dropdown({
		name = "min rarity",
		flag = "market_rarity",
		items = Rarity.NAMES,
		default = "Common",
		tooltip = "hides anything ranked below this",
	})

	filters:toggle({
		name = "underpriced only",
		flag = "market_deals",
		default = false,
		tooltip = "hides asks above the catalogue fair price; items with no fair price always show",
	})

	filters:slider({
		name = "max studs",
		flag = "market_studs",
		default = 600,
		min = 50,
		max = 4000,
		interval = 50,
		tooltip = "hard ceiling is 1500 studs, anything wider only eats frames",
	})

	filters:slider({
		name = "max marks",
		flag = "market_limit",
		default = 60,
		min = 5,
		max = 300,
		interval = 5,
		tooltip = "pool ceiling, autoscale trims it by itself when frames go slow",
	})

	filters:slider({
		name = "rescan hz",
		flag = "market_hz",
		default = 1,
		min = 1,
		max = 10,
		interval = 1,
		tooltip = "how often new racks get indexed",
	})

	look:dropdown({
		name = "font",
		flag = "market_font",
		items = FONT_NAMES,
		default = "SourceSans",
	})

	look:slider({
		name = "size",
		flag = "market_size",
		default = 14,
		min = 8,
		max = 34,
		interval = 1,
	})

	look:dropdown({
		name = "case",
		flag = "market_case",
		items = { "none", "UPPERCASE", "lowercase" },
		default = "none",
	})

	look:colorpicker({
		name = "unranked colour",
		flag = "market_color_name",
		color = Color3.fromRGB(235, 235, 240),
		tooltip = "used when the rarity stays unknown",
	})

	look:colorpicker({
		name = "price colour",
		flag = "market_color_price",
		color = Color3.new(1, 1, 1),
	})
end

local Labels = {}

do
	local probes = data_tab:section({ name = "probes" })
	local status = data_tab:section({ name = "status", side = "right" })

	local function note(text)
		print("leet.cheats: " .. text)

		pcall(function()
			leet:notification({ text = text, time = 4 })
		end)
	end

	probes:button({
		name = "rescan world",
		tooltip = "re-indexes the workspace looking for sale slots",
		callback = function()
			local total = Market.rebuild()
			local tags = Market.scan_tags()

			note(string.format("slots %d · signs %d", total, tags))
		end,
	})

	probes:button({
		name = "pull van",
		tooltip = "invokes GetBlackMarketData for this cycle stock",
		callback = function()
			local count, err = Market.probe_van()

			note(err and ("van: " .. err) or string.format("van stock: %d", count))
		end,
	})

	probes:button({
		name = "pull grayled",
		tooltip = "asks the staff rpc for active listings, may be gated",
		callback = function()
			local count, err = Market.probe_grayled()

			note(err and ("grayled: " .. err) or string.format("listings: %d", count))
		end,
	})

	probes:button({
		name = "dump item root",
		tooltip = "prints attributes, tags, parts and the nearest price signs of two product models",
		callback = function()
			local shown = 0

			for model, entry in next, Market.roots do
				if shown >= 2 then
					break
				end

				shown = shown + 1

				local attrs = {}

				pcall(function()
					for key, value in next, model:GetAttributes() do
						attrs[#attrs + 1] = key .. "=" .. tostring(value)
					end
				end)

				local tags = {}

				pcall(function()
					for _, tag in next, game:GetService("CollectionService"):GetTags(model) do
						tags[#tags + 1] = tag
					end
				end)

				local parts = 0
				local classes = {}

				pcall(function()
					for _, child in next, model:GetChildren() do
						if #classes < 12 then
							classes[#classes + 1] = child.ClassName .. " " .. child.Name
						end
					end

					for _, child in next, model:GetDescendants() do
						if child:IsA("BasePart") then
							parts = parts + 1
						end
					end
				end)

				local pivot, box

				pcall(function()
					pivot = model:GetPivot().Position
					box = select(2, model:GetBoundingBox())
				end)

				print(string.format(
					"leet.cheats root: %s | parts=%d anchor=%s size=%s pivot=%s box=%s",
					tostring(entry.key),
					parts,
					tostring(entry.position),
					tostring(entry.size),
					tostring(pivot),
					tostring(box)
				))

				print("leet.cheats root attrs: " .. table.concat(attrs, " "))
				print("leet.cheats root tags: " .. table.concat(tags, " "))
				print("leet.cheats root kids: " .. table.concat(classes, ", "))

				local near = {}

				for _, tag in next, Market.tags do
					if tag.position ~= nil then
						near[#near + 1] = {
							away = (tag.position - entry.position).Magnitude,
							text = tag.text,
							dup = tag.dup,
						}
					end
				end

				table.sort(near, function(a, b)
					return a.away < b.away
				end)

				for index = 1, math.min(3, #near) do
					print(string.format(
						"leet.cheats near: %.1f studs | %s dup=%s",
						near[index].away,
						tostring(near[index].text),
						tostring(near[index].dup)
					))
				end
			end

			note(shown > 0 and ("dumped " .. shown .. " item roots") or "no __ShopVisualRoot models found")
		end,
	})

	probes:button({
		name = "report",
		tooltip = "prints what every source actually returned",
		callback = function()
			local filled = 0
			local pinned = 0
			local named = 0
			local item_named = 0
			local item_known = 0

			for _, slot in next, Market.slots do
				if slot.bare ~= true then
					filled = filled + 1
				end

				if slot.name ~= nil then
					named = named + 1
				end
			end

			for _, root in next, Market.roots do
				if root.bare ~= true then
					item_known = item_known + 1
				end

				if root.name ~= nil then
					item_named = item_named + 1
				end
			end

			for key in next, Market.pushed do
				if string.sub(tostring(key), 1, 5) == "slot:" then
					pinned = pinned + 1
				end
			end

			print(string.format(
				"leet.cheats report: catalogue=%d numbers=%d names=%d slots=%d filled=%d items=%d item_named=%d exact=%d pushed=%d pinned=%d signs=%d van=%d listings=%d taps=%d bands=%.2f-%.2f",
				#Catalog.records,
				Util.count_keys(Catalog.by_number),
				Util.count_keys(Catalog.by_name),
				Market.stats.slots,
				filled,
				Market.stats.items,
				item_named,
				Market.stats.exact,
				Market.stats.pushed,
				pinned,
				Market.stats.tags,
				Market.stats.van,
				Market.stats.listings,
				#Market.taps,
				Catalog.bands.low,
				Catalog.bands.high
			))

			print(string.format(
				"leet.cheats gates: esp=%s shop=%s items=%s loose=%s signs=%s stalls=%s deals=%s lines=%s min_rarity=%s studs=%s limit=%s drawn=%d",
				tostring(Util.on("market_esp")),
				tostring(Util.on("market_shop")),
				tostring(Util.on("market_items")),
				tostring(Util.on("market_loose")),
				tostring(Util.on("market_signs")),
				tostring(Util.on("market_stalls")),
				tostring(Util.on("market_deals")),
				tostring(Util.on("market_tags")),
				tostring(Util.pick("market_rarity", "?")),
				tostring(Util.number("market_studs", 0)),
				tostring(Util.number("market_limit", 0)),
				Util.count_keys(Visual.records)
			))

			local passed = {}

			pcall(function()
				passed = Visual.entries()
			end)

			local projected = 0
			local camera = workspace.CurrentCamera

			if camera ~= nil then
				for _, entry in next, passed do
					if Util.project(camera, entry.position) ~= nil then
						projected = projected + 1
					end
				end
			end

			print(string.format(
				"leet.cheats draw: engine=%s named_slots=%d items=%d item_named=%d exact=%d signs=%d fair=%d passed=%d projected=%d records=%d",
				tostring(Env.drawing),
				named,
				Market.stats.items,
				item_named,
				Market.stats.exact,
				Market.stats.tags,
				Market.stats.fair,
				#passed,
				projected,
				Util.count_keys(Visual.records)
			))

			print(string.format(
				"leet.cheats perf: frame=%.2f ms sync=%.1f ms period=%.1f ms budget=%d active=%d drawn=%d candidates=%d records=%d",
				Visual.frame_cost or 0,
				Visual.sync_cost or 0,
				Visual.step or 0,
				Visual.budget or 0,
				#Visual.active,
				Visual.drawn or 0,
				Visual.candidates or 0,
				Util.count_keys(Visual.records)
			))

			print(string.format(
				"leet.cheats memory: keys=%d named=%d filled=%d pushes=%d",
				Market.stats.memory,
				Market.stats.recalled,
				Visual.filled or 0,
				Market.stats.pushed
			))

			for tag in next, Catalog.loaded do
				print("leet.cheats config: " .. tag)
			end

			for _, name in next, Market.taps do
				print("leet.cheats tap: " .. name)
			end

			local shown = 0

			for _, entry in next, Market.slots do
				if shown >= 8 then
					break
				end

				if entry.bare ~= true or shown < 4 then
					shown = shown + 1

					print(string.format(
						"leet.cheats slot: %s | key=%s bare=%s name=%s price=%s rarity=%s id=%s fair=%s known=%s",
						tostring(entry.key),
						tostring(entry.slot_key),
						tostring(entry.bare),
						tostring(entry.name),
						tostring(entry.price),
						tostring(entry.rarity),
						tostring(entry.id),
						tostring(entry.fair),
						tostring(entry.catalogued)
					))
				end
			end

			shown = 0

			for _, entry in next, Market.roots do
				if shown >= 8 then
					break
				end

				shown = shown + 1

				print(string.format(
					"leet.cheats item: %s | bare=%s name=%s price=%s rarity=%s id=%s shop=%s slot=%s size=%s pos=%s",
					tostring(entry.key),
					tostring(entry.bare),
					tostring(entry.name),
					tostring(entry.price),
					tostring(entry.rarity),
					tostring(entry.id),
					tostring(entry.shop),
					tostring(entry.slot_key),
					tostring(entry.size),
					tostring(entry.position)
				))
			end

			shown = 0

			for _, entry in next, Market.pushed do
				if shown >= 8 then
					break
				end

				shown = shown + 1

				print(string.format(
					"leet.cheats push: %s | key=%s shop=%s slot=%s name=%s price=%s rarity=%s id=%s",
					tostring(entry.source),
					tostring(entry.key),
					tostring(entry.shop),
					tostring(entry.slot_index),
					tostring(entry.name),
					tostring(entry.price),
					tostring(entry.rarity),
					tostring(entry.id)
				))
			end

			print(string.format(
				"leet.cheats signs: three_d=%d gui=%d skipped=%d objects=%d labels=%d",
				Market.sign_census.three_d,
				Market.sign_census.gui,
				Market.sign_census.junk,
				Market.sign_census.objects,
				Market.sign_census.labels
			))

			shown = 0

			for _, entry in next, Market.tags do
				if shown >= 8 then
					break
				end

				shown = shown + 1

				print(string.format(
					"leet.cheats sign: %s | src=%s name=%s price=%s rarity=%s zone=%s shop=%s stall=%s dup=%s known=%s pos=%s",
					tostring(entry.key),
					tostring(entry.source),
					tostring(entry.name),
					tostring(entry.price),
					tostring(entry.rarity),
					tostring(entry.zone),
					tostring(entry.shop),
					tostring(entry.reseller),
					tostring(entry.dup),
					tostring(entry.catalogued),
					tostring(entry.position)
				))
			end

			note(string.format(
				"slots %d · filled %d · named %d · items %d · pushed %d · pinned %d · signs %d",
				Market.stats.slots,
				filled,
				named,
				Market.stats.items,
				Market.stats.pushed,
				pinned,
				Market.stats.tags
			))
		end,
	})

	Labels.catalogue = status:label({ name = "catalogue: loading" })
	Labels.slots = status:label({ name = "world slots: 0" })
	Labels.pushed = status:label({ name = "pushed records: 0" })
	Labels.signs = status:label({ name = "price signs: 0" })
	Labels.van = status:label({ name = "van stock: 0" })
	Labels.listings = status:label({ name = "listings: 0" })
	Labels.filled = status:label({ name = "with data: 0" })
	Labels.shown = status:label({ name = "drawn now: 0" })

	Market.paint = function()
		if Labels.catalogue then
			Labels.catalogue.set("catalogue: " .. #Catalog.records .. " / " .. Util.count_keys(Catalog.loaded) .. " configs")
		end

		if Labels.slots then
			Labels.slots.set("world slots: " .. Market.stats.slots .. " · items " .. Market.stats.items)
		end

		if Labels.pushed then
			Labels.pushed.set(
				"pushed records: " .. Market.stats.pushed
				.. " · memory " .. Market.stats.memory
				.. " · named from memory " .. Market.stats.recalled
			)
		end

		if Labels.van then
			Labels.van.set("van stock: " .. Market.stats.van)
		end

		if Labels.listings then
			Labels.listings.set("listings: " .. Market.stats.listings)
		end

		if Labels.signs then
			Labels.signs.set("price signs: " .. Market.stats.tags)
		end

		if Labels.filled then
			local ready = 0
			local with_name = 0
			local item_ready = 0

			for _, slot in next, Market.slots do
				if slot.bare ~= true then
					ready = ready + 1
				end

				if slot.name ~= nil then
					with_name = with_name + 1
				end
			end

			for _, root in next, Market.roots do
				if root.bare ~= true then
					item_ready = item_ready + 1
				end
			end

			Labels.filled.set(
				"with data: " .. ready .. " · named " .. with_name .. " · items lit " .. item_ready
			)
		end

		if Labels.shown then
			Labels.shown.set(string.format(
				"drawn %d · pool %d · budget %d · memory %d · %.1f ms/frame",
				Visual.drawn or 0,
				#Visual.active,
				Visual.budget or 0,
				Visual.filled or 0,
				Visual.step or 0
			))
		end
	end
end

task.spawn(function()
	local total = Catalog.load()

	print(string.format("leet.cheats: catalogue built %d items from %d configs", total, Util.count_keys(Catalog.loaded)))

	local ok_rebuild, rebuild_error = pcall(Market.rebuild)

	if not ok_rebuild then
		print("leet.cheats: rebuild failed: " .. tostring(rebuild_error))
	end

	local ok_scan, signs = pcall(Market.scan_tags)

	if not ok_scan then
		print("leet.cheats: sign scan failed: " .. tostring(signs))
		signs = 0
	end

	local lit = 0
	local named = 0

	for _, slot in next, Market.slots do
		if slot.bare ~= true then
			lit = lit + 1
		end

		if slot.name ~= nil then
			named = named + 1
		end
	end

	print(string.format(
		"leet.cheats: price signs %d, slots with data %d of %d, named %d, items %d | three_d=%d gui=%d objects=%d labels=%d",
		signs,
		lit,
		Market.stats.slots,
		named,
		Market.stats.items,
		Market.sign_census.three_d,
		Market.sign_census.gui,
		Market.sign_census.objects,
		Market.sign_census.labels
	))

	pcall(Market.arm_taps)
	pcall(Market.watch)

	pcall(Market.probe_van)

	local last = os.clock()
	local last_sign = os.clock()
	local last_join = 0
	local last_draw = 0

	while not leet.dead do
		task.wait(0.1)

		if os.clock() - last >= 1 / math.max(1, Util.number("market_hz", 1)) then
			last = os.clock()
			pcall(Market.flush)
		end

		if Util.on("market_signs")
			and Market.signs_dirty
			and os.clock() - last_sign >= SIGN_COOLDOWN then
			last_sign = os.clock()
			Market.signs_dirty = false
			pcall(Market.scan_tags)
		end

		if Util.on("market_signs")
			and Util.on("market_esp")
			and os.clock() - last_sign >= SIGN_RESCAN then
			last_sign = os.clock()
			pcall(Market.scan_tags)
		end

		if Market.join_dirty and os.clock() - last_join >= JOIN_COOLDOWN then
			last_join = os.clock()
			pcall(Market.adopt_tags)
		end

		if Util.on("market_esp") then
			if os.clock() - last_draw >= Visual.sync_step then
				last_draw = os.clock()

				local began = os.clock()

				pcall(Visual.sync)
				Visual.sync_cost = Visual.sync_cost * 0.7 + (os.clock() - began) * 1000 * 0.3
			end
		elseif next(Visual.records) ~= nil then
			Visual.teardown()
		end

		if Market.paint then
			pcall(Market.paint)
		end
	end
end)

local paint_link = run_service.RenderStepped:Connect(function()
	if leet.dead == true then
		paint_link:Disconnect()
		Visual.teardown()

		return
	end

	if Util.on("market_esp") then
		local began = os.clock()

		pcall(Visual.frame)
		Visual.frame_cost = Visual.frame_cost * 0.85 + (os.clock() - began) * 1000 * 0.15
	end
end)

if not leet:load_last_config() then
	print("leet.cheats: nothing saved yet, defaults stand")
end

if not Util.on("market_esp") then
	print("leet.cheats: market esp came back OFF from your saved config - press U or tick the box")
end

leet:enable_autosave()

return nil
