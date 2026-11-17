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

function ns.Options()
	local db = ns.db
	local entries = {
		{ text = "Units", title = true },
		UI.Check(db, "style", "Dark flat look", changed),
		UI.Check(db, "classColor", "Colour names by class or reaction", changed),
		UI.Check(db, "border", "Colour the border by class or reaction", changed),
		UI.Check(db, "guild", "Highlight guild names", changed),
		UI.Check(db, "level", "Coloured level, race and class line", changed),
		UI.Check(db, "target", "Show who the unit is targeting", changed),
		UI.Check(db, "healthBar", "Slim health bar", changed),
		UI.Check(db, "healthText", "Health numbers on the bar", changed),
		UI.Check(db, "combatHide", "Hide unit tooltips in combat", changed),
		{ text = "Items and spells", title = true },
		UI.Check(db, "quality", "Colour the border by item quality", changed),
		UI.Check(db, "itemLevel", "Show item level", changed),
		UI.Check(db, "itemCount", "Show how many I have", changed),
		UI.Check(db, "itemID", "Show item ID", changed),
		UI.Check(db, "spellID", "Show spell ID", changed),
		UI.Check(db, "auraSource", "Show who cast a buff or debuff", changed),
		{ text = "Position", title = true },
		anchorEntry("Default corner", "default"),
		anchorEntry("Follow the cursor", "cursor"),
		anchorEntry("Right of the cursor", "cursorRight"),
		anchorEntry("Fixed spot", "fixed"),
		{ text = ns.MoverShown() and "Hide the anchor" or "Move the fixed spot...", func = function() ns.ToggleMover() end },
	}
	for _, e in ipairs(UI.ScaleEntries(db, changed)) do entries[#entries + 1] = e end
	return entries
end

function ns.OpenOptions(anchor)
	if not ns.db then return end
	if not anchor then
		if not holder then
			holder = CreateFrame("Frame", nil, UIParent)
			holder:SetSize(1, 1)
			holder:SetPoint("CENTER", UIParent, "CENTER", -130, 220)
		end
		anchor = holder
	end
	UI.Menu(anchor, ns.Options())
end
