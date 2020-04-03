local MAJOR, MINOR = "LibBindType", tonumber("1.0")
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

function GetBindType(itemLink)
	local tt = CreateFrame("GAMETOOLTIP", "myTooltipFromTemplate", nil, "GameTooltipTemplate")
	tt:SetOwner(WorldFrame, "ANCHOR_NONE")
	tt:SetHyperlink(itemLink)
	if tt:NumLines() > 1 then
		for i = 2, math.min(tt:NumLines(), 3) do
			local line = _G["myTooltipFromTemplateTextLeft"..i]:GetText()
			if line == ITEM_BIND_ON_PICKUP then
				return "pickup"
			elseif line == ITEM_BIND_ON_EQUIP then
				return "equip"
			elseif line == ITEM_BIND_ON_USE then
				return "use"
			elseif line == ITEM_BIND_QUEST then
				return "quest"
			end
		end
	end
	return nil
end