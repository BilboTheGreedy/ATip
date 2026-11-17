local _, ns = ...
local UI = ns.UI
local C = UI.colors

local mover

local function build()
	mover = CreateFrame("Frame", "ATipAnchor", UIParent)
	mover:SetSize(170, 56)
	mover:SetFrameStrata("DIALOG")
	mover:EnableMouse(true)
	mover:RegisterForDrag("LeftButton")
	UI.Fill(mover, { C.select[1], C.select[2], C.select[3], 0.35 })
	UI.Border(mover, C.accent)
	local text = UI.Text(mover, "GameFontHighlightSmall", "CENTER")
	text:SetPoint("CENTER", 0, 7)
	text:SetText("Tooltip anchor")
	local sub = UI.Text(mover, "GameFontDisableSmall", "CENTER", C.dim)
	sub:SetPoint("CENTER", 0, -8)
	sub:SetText("drag me, /atip anchor to hide")
	UI.Movable(mover, ns.db.mover)
	mover:SetScript("OnDragStart", function(self) self:StartDrag() end)
	mover:SetScript("OnDragStop", function(self) self:StopDrag() end)
	mover:Hide()
end

local function ensure()
	if not mover then build() end
	return mover
end

function ns.ToggleMover()
	local m = ensure()
	if m:IsShown() then
		m:Hide()
	else
		ns.db.anchor = "fixed"
		m:Show()
	end
end

function ns.MoverShown()
	return mover and mover:IsShown() or false
end

local function anchor(tip, parent)
	if not ns.db or not tip or not tip.SetOwner then return end
	local mode = ns.db.anchor
	if mode == "cursor" then
		tip:SetOwner(parent or UIParent, "ANCHOR_CURSOR")
	elseif mode == "cursorRight" then
		tip:SetOwner(parent or UIParent, "ANCHOR_CURSOR_RIGHT", 24, 0)
	elseif mode == "fixed" then
		local m = ensure()
		tip:SetOwner(parent or UIParent, "ANCHOR_NONE")
		tip:ClearAllPoints()
		tip:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", 0, 0)
	end
end

ns.Anchor = anchor

ns:Listen("LOGIN", function()
	if hooksecurefunc and GameTooltip_SetDefaultAnchor then
		pcall(hooksecurefunc, "GameTooltip_SetDefaultAnchor", function(tip, parent)
			pcall(anchor, tip, parent)
		end)
	end
end)

ns:Listen("CHANGED", function()
	if mover then
		mover:Restore()
		if ns.db.anchor ~= "fixed" then mover:Hide() end
	end
end)
