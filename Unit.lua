local _, ns = ...
local Get = ns.Get

local REACTION = {
	hostile = { 0.9, 0.25, 0.2 },
	neutral = { 1, 0.82, 0 },
	friendly = { 0.25, 0.85, 0.3 },
	tapped = { 0.55, 0.55, 0.55 },
}

local TAGS = {
	elite = "Elite",
	rare = "Rare",
	rareelite = "Rare Elite",
	worldboss = "Boss",
}

local hpText

local function healthText(unit)
	local bar = GameTooltipStatusBar
	if type(bar) ~= "table" then return end
	local db = ns.db
	if not db.healthText or not db.healthBar or not unit then
		if hpText then hpText:SetText("") end
		return
	end
	if not hpText then
		hpText = ns.UI.Text(bar, "GameFontHighlightSmall", "CENTER")
		hpText:SetPoint("CENTER", bar, "CENTER", 0, 0)
		ns.hpText = hpText
	end
	local ok, hp = pcall(UnitHealth, unit)
	local ok2, max = pcall(UnitHealthMax, unit)
	if not ok or not ok2 then
		hpText:SetText("")
		return
	end
	if ns.IsSecret(hp) or ns.IsSecret(max) then
		if not pcall(hpText.SetFormattedText, hpText, "%s / %s", hp, max) then hpText:SetText("") end
		return
	end
	if type(hp) ~= "number" or type(max) ~= "number" or max <= 0 then
		hpText:SetText("")
		return
	end
	hpText:SetText(ACore.Short(hp) .. " / " .. ACore.Short(max) .. "  " .. math.floor(hp / max * 100 + 0.5) .. "%")
end

ns.HealthText = healthText

local function levelOf(unit)
	if not UnitLevel then return nil, true end
	local ok, level = pcall(UnitLevel, unit)
	if not ok or ns.IsSecret(level) then return nil, true end
	return level, false
end

local function unitOf(tip)
	local unit
	if TooltipUtil and TooltipUtil.GetDisplayedUnit then
		local _, u = Get(TooltipUtil.GetDisplayedUnit, tip)
		unit = u
	elseif tip.GetUnit then
		local _, u = Get(tip.GetUnit, tip)
		unit = u
	end
	if type(unit) ~= "string" then
		unit = Get(UnitExists, "mouseover") and "mouseover" or nil
	end
	return unit
end

local function classColor(classFile)
	local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	if c then return c.r, c.g, c.b end
	return nil
end

local function reactionColor(unit)
	if Get(UnitIsTapDenied, unit) then return unpack(REACTION.tapped) end
	local reaction = Get(UnitReaction, unit, "player")
	if type(reaction) ~= "number" then return nil end
	if reaction <= 3 then return unpack(REACTION.hostile) end
	if reaction == 4 then return unpack(REACTION.neutral) end
	return unpack(REACTION.friendly)
end

local function levelColor(level)
	if type(level) ~= "number" or level <= 0 then return 0.9, 0.25, 0.2 end
	local c
	if GetCreatureDifficultyColor then
		c = Get(GetCreatureDifficultyColor, level)
	elseif GetQuestDifficultyColor then
		c = Get(GetQuestDifficultyColor, level)
	end
	if type(c) == "table" and c.r then return c.r, c.g, c.b end
	return 1, 1, 1
end

local function levelLine(tip, from)
	local word = type(LEVEL) == "string" and LEVEL or "Level"
	for i = from, math.min(ns.Lines(tip), 6) do
		local line = ns.Line(tip, i)
		local text = ns.LineText(line)
		if text and text:find(word, 1, true) then return line, text end
	end
	return nil
end

local function unitName(unit)
	local name = Get(UnitName, unit)
	if type(name) ~= "string" then return nil end
	if Get(UnitIsPlayer, unit) then
		local _, classFile = Get(UnitClass, unit)
		local r, g, b = classColor(classFile)
		if r then return ns.Hex(r, g, b) .. name .. "|r" end
	else
		local r, g, b = reactionColor(unit)
		if r then return ns.Hex(r, g, b) .. name .. "|r" end
	end
	return name
end

local function onUnit(tip)
	if not ns.db or not ns.tips[tip] then return end
	local db = ns.db
	if db.combatHide and InCombatLockdown and InCombatLockdown() then
		tip:Hide()
		return
	end
	local unit = unitOf(tip)
	if not unit then return end
	local isPlayer = Get(UnitIsPlayer, unit)
	local r, g, b
	local from = 2

	if isPlayer then
		local className, classFile = Get(UnitClass, unit)
		r, g, b = classColor(classFile)
		local guild = Get(GetGuildInfo, unit)
		if type(guild) == "string" and guild ~= "" then
			local line = ns.Line(tip, 2)
			local text = ns.LineText(line)
			if text and text:find(guild, 1, true) then
				from = 3
				if db.guild then
					local mine = Get(GetGuildInfo, "player")
					line:SetText("<" .. guild .. ">")
					if mine == guild then
						line:SetTextColor(0.4, 0.8, 1)
					else
						line:SetTextColor(0.3, 0.95, 0.35)
					end
				end
			end
		end
		local level, hidden = levelOf(unit)
		if db.level and not hidden then
			local line = levelLine(tip, from)
			if line then
				local lr, lg, lb = levelColor(level)
				local parts = { ns.Hex(lr, lg, lb) .. ((type(level) == "number" and level > 0) and level or "??") .. "|r" }
				local race = Get(UnitRace, unit)
				if type(race) == "string" then parts[#parts + 1] = race end
				if type(className) == "string" then
					if r then
						parts[#parts + 1] = ns.Hex(r, g, b) .. className .. "|r"
					else
						parts[#parts + 1] = className
					end
				end
				line:SetText(table.concat(parts, " "))
				line:SetTextColor(0.9, 0.9, 0.92)
			end
		end
	else
		r, g, b = reactionColor(unit)
		local level, hidden = levelOf(unit)
		if db.level and not hidden then
			local line, text = levelLine(tip, from)
			if line then
				local lr, lg, lb = levelColor(level)
				line:SetTextColor(lr, lg, lb)
				local tag = TAGS[Get(UnitClassification, unit) or ""]
				if tag and not text:find(tag, 1, true) then
					line:SetText(text .. " |cffffd100" .. tag .. "|r")
				end
			end
		end
	end

	if r then
		if db.classColor then
			local line = ns.Line(tip, 1)
			if line then line:SetTextColor(r, g, b) end
		end
		if db.border then ns.SetBorder(tip, r, g, b) end
		ns.BarColor(r, g, b)
	else
		ns.BarColor(0.25, 0.85, 0.3)
	end
	if tip == GameTooltip then healthText(unit) end

	if db.target then
		local tgt = unit .. "target"
		if Get(UnitExists, tgt) then
			local text
			if Get(UnitIsUnit, tgt, "player") then
				text = "|cffff4040>> You <<|r"
			else
				text = unitName(tgt)
			end
			if text then
				tip:AddLine((type(TARGET) == "string" and TARGET or "Target") .. ": " .. text, 0.58, 0.6, 0.65)
				tip:Show()
			end
		end
	end
end

ns.OnUnit = onUnit
ns.UnitName = unitName

ns:Listen("LOGIN", function()
	local hooked = false
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		hooked = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Unit, function(tip)
			pcall(onUnit, tip)
		end)
	end
	if not hooked and GameTooltip and GameTooltip.HookScript then
		pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", function(tip)
			pcall(onUnit, tip)
		end)
	end
	local bar = GameTooltipStatusBar
	if type(bar) == "table" and bar.HookScript then
		pcall(bar.HookScript, bar, "OnValueChanged", function()
			if not ns.db.healthBar or not GameTooltip:IsShown() then return end
			local unit = unitOf(GameTooltip)
			healthText(unit)
			if not unit then return end
			local r, g, b
			if Get(UnitIsPlayer, unit) then
				local _, classFile = Get(UnitClass, unit)
				r, g, b = classColor(classFile)
			else
				r, g, b = reactionColor(unit)
			end
			if r then ns.BarColor(r, g, b) end
		end)
	end
end)
