local COMMIT = "7e2e709c06e1ab27dd06c08139f4e2f46134756e"
local REPO_RAW = "https://raw.githubusercontent.com/babay2352/leet.cheats/" .. COMMIT
local BUILD = "3"
local LIB_BYTES = 147735
local SIGN_COOLDOWN = 3
local SIGN_RESCAN = 20

print("leet.cheats: rp build " .. BUILD .. " (price signs)")

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
	local ok, screen = pcall(function()
		return camera:WorldToViewportPoint(point)
	end)

	if not ok or screen.Z <= 0 then
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
	pushed = {},
	tags = {},
	van = {},
	listings = {},
	taps = {},
	connections = {},
	dirty = true,
	queued = {},
	sketched = {},
	zones = {},
	signs_dirty = false,
	join_dirty = false,
	sign_census = { three_d = 0, gui = 0, junk = 0 },
	stats = { slots = 0, pushed = 0, pinned = 0, tags = 0, van = 0, listings = 0 },
}

do
	local function position_of(host)
		local ok, position = pcall(function()
			if host:IsA("BasePart") then
				return host.Position
			end

			if host:IsA("Model") then
				return host:GetPivot().Position
			end

			local part = host:FindFirstChildWhichIsA("BasePart", true)

			if part then
				return part.Position
			end
		end)

		if ok then
			return position
		end
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

		local record = Catalog.find(entry.id, entry.name, nil)

		if record then
			Catalog.merge(entry, record)
			entry.catalogued = true
		end

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

	function Market.rebuild()
		local found = {}
		local total = 0

		local ok, all = pcall(function()
			return workspace:GetDescendants()
		end)

		if not ok then
			return 0
		end

		for _, instance in next, all do
			if looks_like_slot(instance) then
				local host = instance.Parent

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

		Market.slots = found
		Market.stats.slots = total
		Market.replay_pushes()

		if Market.stats.tags > 0 then
			Market.adopt_tags()
		end

		Market.dirty = false
		table.clear(Market.queued)

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

		if Market.stats.tags > 0 then
			Market.adopt_tags()
		end

		Market.dirty = false
	end

	function Market.watch()
		local ok, added = pcall(function()
			return workspace.DescendantAdded:Connect(function(instance)
				if looks_like_slot(instance) and instance.Parent then
					Market.queued[instance.Parent] = true
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

		local record = Catalog.find(entry.id, entry.name, entry.model)

		if record then
			Catalog.merge(entry, record)
			entry.catalogued = true
		end

		Market.apply_pushes(entry)
	end
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

		if typeof(value) ~= "userdata" then
			return
		end

		local ok, position = pcall(function()
			if value:IsA("BasePart") then
				return value.Position
			end

			if value:IsA("Model") then
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
				name = type(raw_name) == "string" and raw_name or nil,
				price = tonumber(raw_price) or (type(raw_price) == "string" and Util.stripped(raw_price) or nil),
				rarity = type(raw_rarity) == "string" and raw_rarity or nil,
				brand = type(raw_brand) == "string" and raw_brand or nil,
				fair = tonumber(raw_fair) or (type(raw_fair) == "string" and Util.stripped(raw_fair) or nil),
				stock = tonumber(raw_stock),
				seller = type(raw_seller) == "string" and raw_seller or nil,
				id = id,
			}

			local record = Catalog.find(entry.id, entry.name, raw.customModelName)

			if record then
				Catalog.merge(entry, record)
				entry.catalogued = true
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
			end
		end

		Market.stats.listings = count

		return count, nil
	end

	local PRICE_MARKS = { "₽", "руб", "P ", "₽", "$" }
	local SIGN_GAP = 10
	local SIGN_STUDS = 9

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

	local function model_anchor(host)
		local ok, position = pcall(function()
			if host:IsA("Model") then
				return host:GetPivot().Position
			end

			if host:IsA("BasePart") then
				return host.Position
			end

			local part = host:FindFirstChildWhichIsA("BasePart", true)

			if part ~= nil then
				return part.Position
			end
		end)

		if ok then
			return position
		end
	end

	local function gui_anchor(label)
		local node = label.Parent

		for _ = 1, 4 do
			if node == nil then
				return
			end

			local position = model_anchor(node)

			if position == nil then
				local ok, adornee = pcall(function()
					return node.Adornee
				end)

				if ok and adornee ~= nil then
					position = model_anchor(adornee)
				end
			end

			if position ~= nil then
				return position
			end

			node = node.Parent
		end
	end

	function Market.adopt_tags()
		local found = Market.tags

		for _, entry in next, found do
			local gap = SIGN_GAP

			for _, other in next, found do
				if other ~= entry then
					local away = (other.position - entry.position).Magnitude

					if away < gap then
						if entry.name == nil and other.name ~= nil then
							gap = away
							entry.name = other.name
							entry.dup = true
						elseif entry.price == nil and other.price ~= nil then
							gap = away
							entry.price = other.price
						end
					end
				end
			end

			if entry.name ~= nil then
				local record = Catalog.find(nil, entry.name, nil)

				if record ~= nil then
					Catalog.merge(entry, record)
					entry.catalogued = true
				end

				for _, pushed in next, Market.pushed do
					if pushed.name ~= nil and string.lower(pushed.name) == string.lower(entry.name) then
						entry.price = pushed.price or entry.price
						entry.rarity = pushed.rarity or entry.rarity
						entry.brand = entry.brand or pushed.brand
						entry.fair = entry.fair or pushed.fair
						entry.source = entry.source == "gui" and "gui+push" or "label+push"

						break
					end
				end
			end

			entry.bare = (entry.price == nil and entry.rarity == nil and entry.name == nil)
			entry.useful = (entry.price ~= nil or entry.catalogued == true or entry.rarity ~= nil)
		end

		for _, entry in next, found do
			if entry.name ~= nil and entry.dup ~= true then
				for _, other in next, found do
					if other ~= entry and other.dup ~= true and other.name == entry.name and other.price == entry.price then
						if (other.position - entry.position).Magnitude < SIGN_GAP then
							other.dup = true
						end
					end
				end
			end
		end

		for _, slot in next, Market.slots do
			if slot.position ~= nil then
				local named, priced
				local name_gap, price_gap = SIGN_STUDS, SIGN_STUDS

				for _, entry in next, found do
					local away = (entry.position - slot.position).Magnitude

					if away < name_gap and entry.name ~= nil and entry.useful == true then
						name_gap = away
						named = entry
					end

					if away < price_gap and entry.price ~= nil then
						price_gap = away
						priced = entry
					end
				end

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

				if named ~= nil then
					named.dup = true
				end

				if priced ~= nil then
					priced.dup = true
				end

				if named ~= nil or priced ~= nil then
					slot.bare = (slot.price == nil and slot.rarity == nil and slot.name == nil)
				end
			end
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

		local function spot(position)
			return tostring(math.floor(position.X))
				.. ":"
				.. tostring(math.floor(position.Y))
				.. ":"
				.. tostring(math.floor(position.Z))
		end

		local function record(host, position, text, kind)
			census[kind] = census[kind] + 1

			local head, tail_number = split_text(text)
			local entry = {
				source = kind == "gui" and "gui" or "label",
				key = (kind == "gui" and "gui:" or "label:") .. spot(position),
				text = text,
				position = position,
				price = price_in(text) or tail_number,
				zone = zone_of(host),
			}

			if head ~= nil then
				entry.name = head
			elseif entry.price == nil then
				entry.name = text
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
					record(host, position, text, "three_d")
				else
					census.junk = census.junk + 1
				end
			elseif instance:IsA("TextLabel") then
				census.labels = census.labels + 1
				local text = Util.clip(string.gsub(tostring(instance.Text), "^%s*(.-)%s*$", "%1"), 96)

				if #text >= 2 then
					local interesting = price_in(text) ~= nil
						or split_text(text) ~= nil
						or Catalog.by_name[string.lower(text)] ~= nil
						or push_named(text)

					local position = interesting and gui_anchor(instance) or nil

					if position ~= nil then
						record(instance.Parent, position, text, "gui")
					elseif interesting then
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

local Visual = { records = {} }

Market.Visual = Visual

do
	local function new_node(class)
		if not Env.drawing then
			return
		end

		local ok, node = pcall(function()
			return Drawing.new(class)
		end)

		return ok and node or nil
	end

	local function slot_of(record, key, class)
		local node = record[key]

		if node then
			return node
		end

		node = new_node(class)
		record[key] = node

		return node
	end

	local stamps = setmetatable({}, { __mode = "k" })

	local function style(node, font, size)
		pcall(function()
			node.Font = FONT_IDS[font] or 2
			node.Size = size
			node.Center = true
			node.Outline = true
		end)
	end

	local function restyle(node, font, size)
		if node == nil then
			return
		end

		local stamp = font .. ":" .. tostring(size)

		if stamps[node] == stamp then
			return
		end

		stamps[node] = stamp
		style(node, font, size)
	end

	local function put(node, text, position, color)
		if node == nil then
			return
		end

		node.Text = text
		node.Position = position
		node.Color = color
		node.Visible = #text > 0
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
		for _, node in next, record do
			kill(node)
		end

		table.clear(record)
	end

	Visual.free = free

	local function rank_of(entry)
		return Rarity.order[entry.rarity] or 0
	end

	local function push_candidate(out, entry, origin, limit_studs, min_rank, deals_only)
		if entry.position == nil or entry.bare == true then
			return
		end

		if (entry.position - origin).Magnitude > limit_studs then
			return
		end

		local rank = rank_of(entry)

		if rank > 0 and rank < min_rank then
			return
		end

		if deals_only then
			if not entry.fair or not entry.price then
				return
			end

			if entry.price >= entry.fair then
				return
			end
		end

		out[#out + 1] = entry
	end

	function Visual.entries()
		local camera = workspace.CurrentCamera

		if camera == nil then
			return {}
		end

		local origin = camera.CFrame.Position
		local studs = Util.number("market_studs", 900)
		local min_rank = Rarity.order[Util.pick("market_rarity", "Common")] or 1
		local deals_only = Util.on("market_deals")
		local out = {}

		if Util.on("market_shop") then
			for _, entry in next, Market.slots do
				push_candidate(out, entry, origin, studs, min_rank, deals_only)
			end
		end

		if Util.on("market_signs") then
			for _, entry in next, Market.tags do
				if entry.name ~= nil and entry.dup ~= true and entry.useful == true then
					push_candidate(out, entry, origin, studs, min_rank, deals_only)
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

		table.sort(out, function(a, b)
			local ra, rb = rank_of(a), rank_of(b)

			if ra ~= rb then
				return ra > rb
			end

			return (a.price or 0) > (b.price or 0)
		end)

		local capped = {}
		local limit = Util.number("market_limit", 80)

		for index = 1, math.min(#out, limit) do
			capped[index] = out[index]
		end

		return capped
	end

	function Visual.frame()
		if not Env.drawing then
			return
		end

		local camera = workspace.CurrentCamera

		if camera == nil then
			return
		end

		local viewport = camera.ViewportSize
		local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
		local font = Util.pick("market_font", "SourceSans")
		local size = Util.number("market_size", 14)
		local case_mode = Util.pick("market_case", "none")
		local fallback = Util.color("market_color_name", Color3.fromRGB(235, 235, 240))
		local bands = Catalog.bands
		local keep = {}

		for _, entry in next, Visual.entries() do
			local key = entry.key

			if key then
				local screen = Util.project(camera, entry.position)

				if screen then
					local record = Visual.records[key]

					if record == nil then
						record = {}
						Visual.records[key] = record
					end

					keep[key] = true

					local base = Vector2.new(screen.X, screen.Y - size * 1.2 - (entry.offset or 0) * (size * 4.6))
					local rarity_color = (entry.rarity and Rarity.colors[entry.rarity]) or fallback

					if Util.on("market_names") then
						local node = slot_of(record, "name", "Text")

						restyle(node, font, size)
						put(node, Util.case(Util.clip(entry.name or "item", 30), case_mode), base, rarity_color)
					else
						show(record.name, false)
					end

					if Util.on("market_price") then
						local node = slot_of(record, "price", "Text")
						local color = Util.color("market_color_price", Color3.new(1, 1, 1))
						local text = "price hidden"

						restyle(node, font, size)

						if entry.price then
							text = Util.money(entry.price)

							if entry.fair and entry.fair > 0 then
								if entry.price < entry.fair then
									color = Color3.fromRGB(80, 220, 120)
								elseif entry.price > entry.fair * 1.15 then
									color = Color3.fromRGB(240, 90, 90)
								end
							end
						else
							color = Color3.fromRGB(165, 165, 178)
						end

						put(node, text, base + Vector2.new(0, size * 1.15), color)
					else
						show(record.price, false)
					end

					if Util.on("market_fair") and entry.fair then
						local node = slot_of(record, "fair", "Text")
						local text = "fair " .. Util.money(entry.fair)

						restyle(node, font, size)

						if entry.price then
							text = text .. string.format("  %+0.0f%%", (entry.price / entry.fair - 1) * 100)
						else
							text = text .. string.format(
								"  ~%s-%s",
								Util.money(entry.fair * bands.low),
								Util.money(entry.fair * bands.high)
							)
						end

						if entry.retired then
							text = text .. "  retired"
						end

						put(node, text, base + Vector2.new(0, size * 2.3), Color3.fromRGB(190, 190, 200))
					else
						show(record.fair, false)
					end

					if Util.on("market_tags") then
						local node = slot_of(record, "tags", "Text")
						local parts = {}

						restyle(node, font, math.max(8, size - 2))

						if entry.rarity then
							parts[#parts + 1] = Rarity.labels[entry.rarity] or string.lower(entry.rarity)
						end

						if entry.brand then
							parts[#parts + 1] = string.lower(entry.brand)
						end

						if entry.kind then
							parts[#parts + 1] = string.lower(entry.kind)
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

						if Util.on("market_dist") then
							parts[#parts + 1] = string.format("%.0f m", (camera.CFrame.Position - entry.position).Magnitude)
						end

						if #parts == 0 then
							parts[#parts + 1] = tostring(entry.source)
						end

						put(
							node,
							Util.case(Util.clip(table.concat(parts, " · "), 54), case_mode),
							base + Vector2.new(0, size * 3.4),
							Color3.fromRGB(150, 150, 165)
						)
					else
						show(record.tags, false)
					end

					if Util.on("market_box") then
						local node = slot_of(record, "box", "Square")

						if node then
							local distance = math.max(1, (camera.CFrame.Position - entry.position).Magnitude)
							local radius = math.max(9, math.min(150, 16000 / distance))

							node.Position = Vector2.new(screen.X - radius * 0.5, screen.Y - radius * 0.7)
							node.Size = Vector2.new(radius, radius * 1.4)
							node.Color = rarity_color
							node.Thickness = 1
							node.Filled = false
							node.Transparency = 0.35
							node.Visible = true
						end
					else
						show(record.box, false)
					end

					if Util.on("market_snap") then
						local node = slot_of(record, "snap", "Line")

						if node then
							node.From = center
							node.To = Vector2.new(screen.X, screen.Y)
							node.Color = rarity_color
							node.Thickness = 1
							node.Transparency = 0.6
							node.Visible = true
						end
					else
						show(record.snap, false)
					end
				end
			end
		end

		for key, record in next, Visual.records do
			if keep[key] == nil then
				free(record)
				Visual.records[key] = nil
			end
		end
	end

	function Visual.teardown()
		for _, record in next, Visual.records do
			free(record)
		end

		Visual.records = {}
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
		name = "shop price signs",
		flag = "market_signs",
		default = true,
		tooltip = "reads the 3D signs the game itself puts over racks, pairs name with price and rarity",
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
		tooltip = "keeps asks below the catalogue fair price",
	})

	filters:slider({
		name = "max studs",
		flag = "market_studs",
		default = 900,
		min = 50,
		max = 4000,
		interval = 50,
	})

	filters:slider({
		name = "max marks",
		flag = "market_limit",
		default = 80,
		min = 5,
		max = 300,
		interval = 5,
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
		name = "report",
		tooltip = "prints what every source actually returned",
		callback = function()
			local filled = 0
			local pinned = 0

			for _, slot in next, Market.slots do
				if slot.bare ~= true then
					filled = filled + 1
				end
			end

			for key in next, Market.pushed do
				if string.sub(tostring(key), 1, 5) == "slot:" then
					pinned = pinned + 1
				end
			end

			print(string.format(
				"leet.cheats report: catalogue=%d numbers=%d names=%d slots=%d filled=%d pushed=%d pinned=%d signs=%d van=%d listings=%d taps=%d bands=%.2f-%.2f",
				#Catalog.records,
				Util.count_keys(Catalog.by_number),
				Util.count_keys(Catalog.by_name),
				Market.stats.slots,
				filled,
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
				"leet.cheats gates: esp=%s shop=%s loose=%s signs=%s deals=%s lines=%s min_rarity=%s studs=%s limit=%s drawn=%d",
				tostring(Util.on("market_esp")),
				tostring(Util.on("market_shop")),
				tostring(Util.on("market_loose")),
				tostring(Util.on("market_signs")),
				tostring(Util.on("market_deals")),
				tostring(Util.on("market_tags")),
				tostring(Util.pick("market_rarity", "?")),
				tostring(Util.number("market_studs", 0)),
				tostring(Util.number("market_limit", 0)),
				Util.count_keys(Visual.records)
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
					"leet.cheats sign: %s | src=%s name=%s price=%s rarity=%s zone=%s dup=%s known=%s pos=%s",
					tostring(entry.key),
					tostring(entry.source),
					tostring(entry.name),
					tostring(entry.price),
					tostring(entry.rarity),
					tostring(entry.zone),
					tostring(entry.dup),
					tostring(entry.catalogued),
					tostring(entry.position)
				))
			end

			note(string.format(
				"slots %d · filled %d · pushed %d · pinned %d · signs %d",
				Market.stats.slots,
				filled,
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
			Labels.slots.set("world slots: " .. Market.stats.slots)
		end

		if Labels.pushed then
			Labels.pushed.set("pushed records: " .. Market.stats.pushed)
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

			for _, slot in next, Market.slots do
				if slot.bare ~= true then
					ready = ready + 1
				end
			end

			Labels.filled.set("with data: " .. ready)
		end

		if Labels.shown then
			Labels.shown.set("drawn now: " .. Util.count_keys(Visual.records))
		end
	end
end

task.spawn(function()
	local total = Catalog.load()

	print(string.format("leet.cheats: catalogue built %d items from %d configs", total, Util.count_keys(Catalog.loaded)))

	Market.rebuild()

	local signs = Market.scan_tags()
	local lit = 0

	for _, slot in next, Market.slots do
		if slot.bare ~= true then
			lit = lit + 1
		end
	end

	print(string.format(
		"leet.cheats: price signs %d, slots with data %d of %d | three_d=%d gui=%d objects=%d labels=%d",
		signs,
		lit,
		Market.stats.slots,
		Market.sign_census.three_d,
		Market.sign_census.gui,
		Market.sign_census.objects,
		Market.sign_census.labels
	))

	Market.arm_taps()
	Market.watch()

	pcall(Market.probe_van)

	local last = os.clock()
	local last_sign = os.clock()

	while not leet.dead do
		task.wait(0.25)

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

		if Market.stats.tags > 0 and Market.join_dirty then
			pcall(Market.adopt_tags)
		end

		if Util.on("market_esp") then
			pcall(Visual.frame)
		elseif next(Visual.records) ~= nil then
			Visual.teardown()
		end

		if Market.paint then
			pcall(Market.paint)
		end
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
