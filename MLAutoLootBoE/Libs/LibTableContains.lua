local MAJOR, MINOR = "LibTableContains", tonumber("1.0")
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

function table.contains(table, value, ci, trim)
  if ci then
    value = string.lower(value)
  end
  if trim then
    value = string.gsub(value, "%s+", "")
  end
  for k, v in pairs(table) do
    if ci then
      v = string.lower(v)
    end
    if trim then
      v = string.gsub(v, "%s+", "")
    end
    if value == v then
      return k
    end
  end
  return false
end