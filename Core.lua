local ADDON, ns = ...

local defaults = {
	style = true,
	scale = 1,
	classColor = true,
	border = true,
	guild = true,
	level = true,
	target = true,
	healthBar = true,
	healthText = false,
	itemCount = true,
	auraSource = true,
	quality = true,
	itemLevel = true,
	itemID = false,
	spellID = false,
	combatHide = false,
	anchor = "default",
	mover = { default = { "BOTTOMRIGHT", "BOTTOMRIGHT", -220, 180 } },
}

ACore.New(ADDON, ns, { db = "ATipDB", defaults = defaults, profile = true })

ns.tips = {}

function ns.Get(fn, ...)
	if not fn then return nil end
	local ok, a, b, c = pcall(fn, ...)
	if not ok then return nil end
	if ns.IsSecret(a) then a = nil end
	if ns.IsSecret(b) then b = nil end
	if ns.IsSecret(c) then c = nil end
	return a, b, c
end

function ns.Hex(r, g, b)
	return string.format("|cff%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

function ns.Line(tip, index)
	local name = tip.GetName and tip:GetName()
	if type(name) ~= "string" then return nil end
	local line = _G[name .. "TextLeft" .. index]
	if type(line) ~= "table" then return nil end
	return line
end

function ns.LineText(line)
	if not line then return nil end
	local text = ns.Get(line.GetText, line)
	if type(text) ~= "string" or text == "" then return nil end
	return text
end

function ns.Lines(tip)
	local n = ns.Get(tip.NumLines, tip)
	if type(n) ~= "number" then return 0 end
	return n
end

ACore.Register({
	name = "ATip",
	title = "ATip",
	slash = "/atip",
	desc = "tooltips",
	options = function() return ns.Options() end,
	toggle = function() ns.OpenOptions() end,
})

SLASH_ATIP1 = "/atip"
SlashCmdList["ATIP"] = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "anchor" or msg == "move" then
		ns.ToggleMover()
	elseif msg == "reset" then
		ns.db.mover.pos = nil
		ns.db.scale = 1
		ns.db.anchor = "default"
		ns:Fire("CHANGED")
	else
		ns.OpenOptions()
	end
end
