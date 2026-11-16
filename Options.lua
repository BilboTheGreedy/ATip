local _, ns = ...
local UI = ns.UI

local holder

local function changed()
	ns:Fire("CHANGED")
end

local function anchorEntry(text, mode)
	return {
		text = text, checked = ns.db.anchor == mode,
		func = function()
			ns.db.anchor = mode
			changed()
		end,
	}
end

function ns.OpenOptions(anchor)
	local db = ns.db
	if not db then return end
	if not anchor then
		if not holder then
			holder = CreateFrame("Frame", nil, UIParent)
			holder:SetSize(1, 1)
			holder:SetPoint("CENTER", UIParent, "CENTER", -130, 220)
		end
		anchor = holder
	end
	local entries = {
		{ text = "ATip", title = true },
		UI.Toggle(db, "style", "Dark flat look", changed),
		UI.Toggle(db, "classColor", "Colour names by class or reaction"),
		UI.Toggle(db, "border", "Colour the border by class or reaction"),
		UI.Toggle(db, "guild", "Highlight guild names"),
		UI.Toggle(db, "level", "Coloured level, race and class line"),
		UI.Toggle(db, "target", "Show who the unit is targeting"),
		UI.Toggle(db, "healthBar", "Slim health bar", changed),
		UI.Toggle(db, "combatHide", "Hide unit tooltips in combat"),
		{ text = "Items", title = true },
		UI.Toggle(db, "quality", "Colour the border by item quality"),
		UI.Toggle(db, "itemLevel", "Show item level"),
		UI.Toggle(db, "itemID", "Show item ID"),
		UI.Toggle(db, "spellID", "Show spell ID"),
		{ text = "Position", title = true },
		anchorEntry("Default corner", "default"),
		anchorEntry("Follow the cursor", "cursor"),
		anchorEntry("Fixed spot", "fixed"),
		{ text = ns.MoverShown() and "Hide the anchor" or "Move the fixed spot...", func = function() ns.ToggleMover() end },
	}
	for _, e in ipairs(UI.ScaleEntries(db, changed)) do entries[#entries + 1] = e end
	UI.Menu(anchor, entries)
end
