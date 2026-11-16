local _, ns = ...
local Get = ns.Get

local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo

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
	if db.itemID then
		tip:AddLine("Item ID " .. id, 0.58, 0.6, 0.65)
		added = true
	end
	if added then tip:Show() end
end

local function onSpell(tip, data)
	if not ns.db or not ns.tips[tip] or not ns.db.spellID then return end
	local id = data and data.id
	if ns.IsSecret(id) or type(id) ~= "number" then return end
	tip:AddLine("Spell ID " .. id, 0.58, 0.6, 0.65)
	tip:Show()
end

ns.OnItem = onItem
ns.OnSpell = onSpell

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
