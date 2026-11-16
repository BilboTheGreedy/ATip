local _, ns = ...
local UI = ns.UI
local C = UI.colors

local NAMES = {
	"GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
	"ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2", "WorldMapTooltip",
}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local skins = {}
local barStyled = false

local function nine(tip, alpha)
	local slice = tip.NineSlice
	if type(slice) == "table" and slice.SetAlpha then
		pcall(slice.SetAlpha, slice, alpha)
	end
end

local function skin(tip)
	local s = skins[tip]
	if s then return s end
	s = {}
	s.bg = UI.Fill(tip, { 0.05, 0.055, 0.07, 0.95 })
	s.edges = UI.Border(tip)
	skins[tip] = s
	if tip.HookScript then
		pcall(tip.HookScript, tip, "OnTooltipCleared", function(self) ns.ResetBorder(self) end)
		pcall(tip.HookScript, tip, "OnShow", function(self)
			if ns.db.style then nine(self, 0) end
		end)
	end
	return s
end

function ns.SetBorder(tip, r, g, b)
	local s = skins[tip]
	if not s or not ns.db.style then return end
	for i = 1, 4 do s.edges[i]:SetColorTexture(r, g, b, 1) end
end

function ns.ResetBorder(tip)
	ns.SetBorder(tip, C.line[1], C.line[2], C.line[3])
end

local function styleBar()
	local bar = GameTooltipStatusBar
	if type(bar) ~= "table" then return end
	if ns.db.healthBar and ns.db.style then
		bar:SetStatusBarTexture(WHITE)
		bar:SetHeight(4)
		bar:ClearAllPoints()
		bar:SetPoint("BOTTOMLEFT", GameTooltip, "BOTTOMLEFT", 2, 2)
		bar:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMRIGHT", -2, 2)
		barStyled = true
	elseif barStyled then
		bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
		bar:SetHeight(8)
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 2, -1)
		bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -2, -1)
		barStyled = false
	end
end

function ns.BarColor(r, g, b)
	local bar = GameTooltipStatusBar
	if type(bar) ~= "table" or not ns.db.healthBar then return end
	bar:SetStatusBarColor(r, g, b)
end

function ns.ApplyStyle()
	local db = ns.db
	for _, name in ipairs(NAMES) do
		local tip = _G[name]
		if type(tip) == "table" and tip.CreateTexture then
			ns.tips[tip] = true
			if db.style then
				local s = skin(tip)
				s.bg:Show()
				for i = 1, 4 do s.edges[i]:Show() end
				nine(tip, 0)
				ns.ResetBorder(tip)
			elseif skins[tip] then
				local s = skins[tip]
				s.bg:Hide()
				for i = 1, 4 do s.edges[i]:Hide() end
				nine(tip, 1)
			end
			if tip.SetScale then tip:SetScale(db.scale or 1) end
		end
	end
	styleBar()
end

ns:Listen("LOGIN", function()
	ns.ApplyStyle()
	if hooksecurefunc and SharedTooltip_SetBackdropStyle then
		pcall(hooksecurefunc, "SharedTooltip_SetBackdropStyle", function(tip)
			if skins[tip] and ns.db.style then nine(tip, 0) end
		end)
	end
end)

ns:Listen("CHANGED", function() ns.ApplyStyle() end)
