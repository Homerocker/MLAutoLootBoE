local MAJOR, MINOR = "LibItemID", tonumber("1.0")
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

function GetItemID(itemLink)
  if not itemLink then
    return
  end
  local id = select(2, strsplit(":", string.match(itemLink, "item[%-?%d:]+")))
  return tonumber(id)
end