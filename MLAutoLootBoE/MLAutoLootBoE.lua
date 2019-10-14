local BOE_IDs = {
  47556,--Crusader Orb
  49908,--Primordial Saronite
  45087,--Runed Orb
  43297,--Damaged Necklace
}
local exceptions = {
  45693,--Mimiron's Head
  50818,--Invincible's Reins
  46110,--Alchemist's Cache
  50226,--Festergut's Acidic Blood
  50231,--Rotface's Acidic Blood
}
MLAutoLootBoE = {}
MLAutoLootBoE_SAVED_VARS = {}
MLAutoLootBoE_SAVED_VARS.looters = {}
MLAutoLootBoE_SAVED_VARS.screenshots = {}
local itemLinks = {sm = select(2, GetItemInfo(50274)), valanyr = select(2, GetItemInfo(45038))}
local isEnchanter = select(1, IsUsableSpell(select(1, GetSpellInfo(51313)))) and true or false
local Recipe_Localized = select(10, GetAuctionItemClasses())
local f = CreateFrame("Frame")

f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")

local lootmethod, masterlooterPartyID = GetLootMethod()

local function MasterLootAward(LootSlot, PlayerName)
  PlayerName = PlayerName:lower()
  for ci = 1, 40 do
    -- checking if candidate name matches specified player name
    if GetMasterLootCandidate(ci) ~= nil and GetMasterLootCandidate(ci):lower() == PlayerName then
      -- if name matches specified name, sending loot to candidate
      GiveMasterLoot(LootSlot, ci)
      return true
    end
  end
  return false
end

local function itemShouldBeLooted(itemID, itemRarity, itemType, bindType)
  -- exception
  if table.contains(exceptions, itemID) then
    return false
  end
  -- personal quest items
  if bindType == "quest" then
    return true
  end
  -- epic BoE items
  if itemRarity == 4 and (bindType == "equip" or bindType == "use") then
    return true
  end
  -- epic non-BoP recipes
  if itemRarity == 4 and itemType == Recipe_Localized and bindType == nil then
    return true
  end
  -- additional items
  if table.contains(BOE_IDs, itemID) then
    return true
  end
  -- autolooting everything but legendary items if CTRL key is down
  if IsControlKeyDown() and not IsAltKeyDown() and itemRarity < 5 then
    return true
  end
  return false
end

local function itemShouldBeDisenchanted(itemID, itemRarity, itemType, bindType)
  if table.contains(BOE_IDs, itemID) or table.contains(exceptions, itemID) then
    return false
  end
  if itemType == Recipe_Localized and bindType ~= nil then
    return false
  end
  if itemLevel == 0 then
    return false
  end
  if itemRarity < 2 or itemRarity > 4 then
    return false
  end
  if itemRarity == 4 and not (IsControlKeyDown() and IsAltKeyDown()) then
    return false
  end
  return true
end

function MLAutoLootBoE:notify(lootType)
  if (lootType == nil or lootType == "sm") and MLAutoLootBoE_SAVED_VARS.looters["sm"] ~= nil then
    local msg = itemLinks["sm"].." will be awarded to "..MLAutoLootBoE_SAVED_VARS.looters["sm"].."."
    if masterlooterPartyID == 0 and lootType ~= nil then
      SendChatMessage(msg, "RAID")
    else
      print(msg)
    end
  end
  if (lootType == nil or lootType == "valanyr") and MLAutoLootBoE_SAVED_VARS.looters["valanyr"] ~= nil then
    local msg = itemLinks["valanyr"].." will be awarded to "..MLAutoLootBoE_SAVED_VARS.looters["valanyr"].."."
    if masterlooterPartyID == 0 and lootType ~= nil then
      SendChatMessage(msg, "RAID")
    else
      print(msg)
    end
  end
  if (lootType == nil or lootType == "de") and MLAutoLootBoE_SAVED_VARS.looters["de"] ~= nil then
    local msg = MLAutoLootBoE_SAVED_VARS.looters["de"].." is set to disenchanter."
    if masterlooterPartyID == 0 and lootType ~= nil then
      SendChatMessage(msg, "RAID")
    else
      print(msg)
    end
  end
end

SLASH_MLAUTOLOOTBOE1 = "/ml"
SlashCmdList["MLAUTOLOOTBOE"] = function(msg)
  local _, _, cmd, name = string.find(msg, "%s?(%w+)%s?(.*)")
  if (cmd == "sm" or cmd == "valanyr" or cmd == "de") then
    if name ~= "" then
      name = name:gsub("%s+", "")
      name = name:lower()
      name = name:gsub("^%l", string.upper)
      MLAutoLootBoE_SAVED_VARS.looters[cmd] = name
      if UnitInRaid(name) then
        MLAutoLootBoE:notify(cmd)
      else
        print(name.." is not in raid.")
      end
    else
      MLAutoLootBoE_SAVED_VARS.looters[cmd] = nil
      MLAutoLootBoE:notify(cmd)
    end
  elseif cmd == "reset" then
    MLAutoLootBoE_SAVED_VARS.looters = {}
    print("All looters reset.")
  elseif cmd == "report" then
    MLAutoLootBoE:notify()
  elseif cmd == "help" then
    print("/ml sm <name> - set Shadowfrost Shard looter")
    print("/ml valanyr <name> - set Fragment of Val'anyr looter")
    print("/ml de <name> - set disenchanter")
  else
    print("Invalid command")
  end
end

f:SetScript("OnEvent", function(self, event, arg1)
  if event == "LOOT_OPENED" then
    if (UnitName("target") == "The Lich King" or UnitName("target") == "Halion") and (MLAutoLootBoE_SAVED_VARS.screenshots[UnitName("target")] or 0) < time() - 600 then
      Screenshot()
      MLAutoLootBoE_SAVED_VARS.screenshots[UnitName("target")] = time()
    end
    
    -- checking if master looting enabled and current player is master looter
    -- or loot is set to "free for all"
    if (lootmethod ~= "master" or masterlooterPartyID ~= 0)
      and lootmethod ~= "freeforall"
      and (lootmethod ~= "group" or GetNumPartyMembers() ~= 0 or GetNumRaidMembers() ~= 0) then
      return
    end
    
    for i = 1, GetNumLootItems() do
      local link = GetLootSlotLink(i)
      -- checking if link is nil (e.g. when item has been already looted, possible fix for emblems which are always autolooted)
      if link ~= nil then
        local _, itemLink, itemRarity, itemLevel, _, itemType = GetItemInfo(link)
        local bindType = GetBindType(itemLink)
        local itemID = GetItemID(itemLink)
        local looter = nil
        if itemShouldBeLooted(itemID, itemRarity, itemType, bindType) then
          looter = UnitName("player")
        elseif itemShouldBeDisenchanted(itemID, itemRarity, itemType, bindType) and MLAutoLootBoE_SAVED_VARS.looters["de"] ~= nil then
            looter = MLAutoLootBoE_SAVED_VARS.looters["de"]
        elseif itemID == 50274 and MLAutoLootBoE_SAVED_VARS.looters["sm"] ~= nil then
          looter = MLAutoLootBoE_SAVED_VARS.looters["sm"]
        elseif itemID == 45038 and MLAutoLootBoE_SAVED_VARS.looters["valanyr"] ~= nil then
          looter = MLAutoLootBoE_SAVED_VARS.looters["valanyr"]
        end
        if lootmethod ~= "master" and looter == UnitName("player") then
          LootSlot(i)
        elseif looter ~= nil then
          MasterLootAward(i, looter)
        end
      elseif LootSlotIsCoin(i) then
        LootSlot(i)
      end
    end
  elseif event == "ADDON_LOADED" and arg1 == "MLAutoLootBoE" then
    if isEnchanter and MLAutoLootBoE_SAVED_VARS.looters["de"] ~= UnitName("player") then
      MLAutoLootBoE_SAVED_VARS.looters["de"] = UnitName("player")
    end
    f:UnregisterEvent("ADDON_LOADED")
  elseif event == "PARTY_MEMBERS_CHANGED" then
    -- change loot method upon leaving party
    lootmethod, masterlooterPartyID = GetLootMethod()
  elseif event == "PARTY_LOOT_METHOD_CHANGED" then
    lootmethod, masterlooterPartyID = GetLootMethod()
    if masterlooterPartyID == 0 then
      MLAutoLootBoE:notify()
    end
  end
end)