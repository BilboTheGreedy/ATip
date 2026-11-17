local _, ns = ...
local Get = ns.Get

local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local function count(id, bank)
	local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
	if not fn then return nil end
	local ok, n = pcall(fn, id, bank)
	if not ok or ns.IsSecret(n) or type(n) ~= "number" then return nil end
	return n
end

local QUALITY = {
	[0] = { 0.62, 0.62, 0.62 },
	[1] = { 1, 1, 1 },
	[2] = { 0.12, 1, 0 },
	[3] = { 0, 0.44, 0.87 },
	[4] = { 0.64, 0.21, 0.93 },
	[5] = { 1, 0.5, 0 },
	[6] = { 0.9, 0.8, 0.5 },
	[7] = { 0, 0.8, 1 },
}

local function linkOf(tip)
	local link
	if TooltipUtil and TooltipUtil.GetDisplayedItem then
		local _, l = Get(TooltipUtil.GetDisplayedItem, tip)
		link = l
	elseif tip.GetItem then
		local _, l = Get(tip.GetItem, tip)
		link = l
	end
	if type(link) == "string" then return link end
	return nil
end

local function onItem(tip, data)
	if not ns.db or not ns.tips[tip] then return end
	local db = ns.db
	local link = linkOf(tip)
	local id = data and data.id
	if ns.IsSecret(id) or type(id) ~= "number" then
		id = link and tonumber(link:match("item:(%d+)"))
	end
	if not id then return end
	local quality, ilvl, equipLoc
	if GetInfo then
		local ok, _, _, q, l, _, _, _, _, loc = pcall(GetInfo, link or id)
		if ok then quality, ilvl, equipLoc = q, l, loc end
	end
	if ns.IsSecret(quality) then quality = nil end
	if ns.IsSecret(ilvl) then ilvl = nil end
	if ns.IsSecret(equipLoc) then equipLoc = nil end
	if db.quality and type(quality) == "number" and quality >= 2 then
		local c = QUALITY[quality]
		if c then ns.SetBorder(tip, c[1], c[2], c[3]) end
	end
	local added = false
	if db.itemLevel and type(ilvl) == "number" and ilvl > 1 and type(equipLoc) == "string" and equipLoc ~= "" and equipLoc ~= "INVTYPE_BAG" then
		tip:AddLine("Item level " .. ilvl, 0.58, 0.6, 0.65)
		added = true
	end
	if db.itemCount then
		local bags = count(id, false)
		local all = count(id, true)
		if bags and all and all > 0 then
			local text = "In bags " .. bags
			if all > bags then text = text .. ", bank " .. (all - bags) end
			tip:AddLine(text, 0.58, 0.6, 0.65)
			added = true
		end
	end
	if db.itemID then
		tip:AddLine("Item ID " .. id, 0.58, 0.6, 0.65)
		added = true
	end
	if added then tip:Show() end
end

local function onAura(tip, aura)
	local db = ns.db
	if not db or not ns.tips[tip] or ns.IsSecret(aura) or type(aura) ~= "table" then return end
	local added = false
	if db.auraSource then
		local src = aura.sourceUnit
		if not ns.IsSecret(src) and type(src) == "string" then
			local name = ns.UnitName(src)
			if name then
				tip:AddLine("From " .. name, 0.58, 0.6, 0.65)
				added = true
			end
		end
	end
	if db.spellID then
		local id = aura.spellId
		if not ns.IsSecret(id) and type(id) == "number" then
			tip:AddLine("Spell ID " .. id, 0.58, 0.6, 0.65)
			added = true
		end
	end
	if added then tip:Show() end
end

local function byIndex(fallback)
	return function(tip, unit, index, filter)
		if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return end
		if ns.IsSecret(filter) or type(filter) ~= "string" then filter = fallback end
		pcall(onAura, tip, Get(C_UnitAuras.GetAuraDataByIndex, unit, index, filter))
	end
end

local function byInstance(tip, unit, id)
	if not C_UnitAuras or not C_UnitAuras.GetAuraDataByAuraInstanceID then return end
	pcall(onAura, tip, Get(C_UnitAuras.GetAuraDataByAuraInstanceID, unit, id))
end

local AURA_HOOKS = {
	SetUnitAura = byIndex("HELPFUL"),
	SetUnitBuff = byIndex("HELPFUL"),
	SetUnitDebuff = byIndex("HARMFUL"),
	SetUnitBuffByAuraInstanceID = byInstance,
	SetUnitDebuffByAuraInstanceID = byInstance,
}

local function onSpell(tip, data)
	if not ns.db or not ns.tips[tip] or not ns.db.spellID then return end
	local id = data and data.id
	if ns.IsSecret(id) or type(id) ~= "number" then return end
	tip:AddLine("Spell ID " .. id, 0.58, 0.6, 0.65)
	tip:Show()
end

ns.OnItem = onItem
ns.OnSpell = onSpell
ns.OnAura = onAura

ns:Listen("LOGIN", function()
	local hooked = false
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		hooked = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, function(tip, data)
			pcall(onItem, tip, data)
		end)
		if Enum.TooltipDataType.Spell then
			pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Spell, function(tip, data)
				pcall(onSpell, tip, data)
			end)
		end
	end
	if hooksecurefunc and type(GameTooltip) == "table" then
		for name, fn in pairs(AURA_HOOKS) do
			if type(GameTooltip[name]) == "function" then pcall(hooksecurefunc, GameTooltip, name, fn) end
		end
	end
	if not hooked then
		for tip in pairs(ns.tips) do
			if tip.HookScript then
				pcall(tip.HookScript, tip, "OnTooltipSetItem", function(self)
					pcall(onItem, self)
				end)
			end
		end
	end
end)
