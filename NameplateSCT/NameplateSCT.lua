
---@diagnostic disable: deprecated, undefined-global, duplicate-set-field, undefined-field
---------------
-- LIBRARIES --
---------------
local C_NamePlate = C_NamePlate
local UnitHealthMax = UnitHealthMax
local GetSpellInfo = GetSpellInfo

local NameplateSCT = LibStub("AceAddon-3.0"):NewAddon("NameplateSCT", "AceConsole-3.0", "AceEvent-3.0")
NameplateSCT.frame = CreateFrame("Frame", nil, UIParent)

local L = LibStub("AceLocale-3.0"):GetLocale("NameplateSCT")
local LibEasing = LibStub("LibEasing-1.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local LibNameplates = LibStub("LibNameplates-1.0")

-------------
-- GLOBALS --
-------------
local CreateFrame = CreateFrame
local math_floor, math_pow, _math_random = math.floor, math.pow, math.random
local tostring, tonumber, band = tostring, tonumber, bit.band
local format, find = string.format, string.find
local next, pairs, ipairs = next, pairs, ipairs
local tinsert, tremove = table.insert, table.remove

local function math_random(X, Y)
  if (Y < X) then
    print('|cffdd2211NameplateSCT: error at math_random(X,Y), value Y ' ..
      Y .. ' must be bigger or equal to value X (' .. X .. '), check your animation ex-constants settings!|r')
    return X
  end
  return _math_random(X, Y)
end

------------
-- LOCALS --
------------
local _
local animating = {}

local playerGUID, targetGuid
local _playerName = UnitName("player")

local function hideMyName(name)
  if (name and name == _playerName and MyNewName) then
    name = MyNewName
  end
  return name
end

local function rgbToHex(r, g, b)
  return format("%02x%02x%02x", math_floor(255 * r), math_floor(255 * g), math_floor(255 * b))
end

local function hexToRGB(hex)
  return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, 1
end

-- table.append: добавляет все элементы из sourceTable в targetTable
local function tableappend(targetTable, sourceTable)
  for _, value in ipairs(sourceTable) do
    table.insert(targetTable, value)
  end
end

-- table.wipe: очищает содержимое таблицы
local function tablewipe(t)
  for k in pairs(t) do
    t[k] = nil
  end
end

local function splitString(inputString, separator)
  local resultTable = {}
  for item in string.gmatch(inputString, "[^" .. separator .. "]+") do
    table.insert(resultTable, item)
  end
  return resultTable
end

local function contains(table, element)
  for _, value in pairs(table) do
    if (value == element) then
      return true
    end
  end
  return false
end

-- test 11.4.24
local function utf8sub(string, i, dots)
  if not string then return end
  local bytes = string:len()
  if (bytes <= i) then
    return string
  else
    local len, pos = 0, 1
    while (pos <= bytes) do
      len = len + 1
      local c = string:byte(pos)
      if (c > 0 and c <= 127) then
        pos = pos + 1
      elseif (c >= 192 and c <= 223) then
        pos = pos + 2
      elseif (c >= 224 and c <= 239) then
        pos = pos + 3
      elseif (c >= 240 and c <= 247) then
        pos = pos + 4
      end
      if (len == i) then break end
    end

    if (len == i and pos <= bytes) then
      return string:sub(1, pos - 1) .. (dots and '..' or '')
    else
      return string
    end
  end
end

-- test 11.4.24
local function Abbrev(str)
  local letters, lastWord = "", string.match(str, ".+%s(.+)$")
  if lastWord then
    for word in gmatch(str, ".-%s") do
      local firstLetter = string.utf8sub(gsub(word, "^[%s%p]*", ""), 1, 1)
      if firstLetter ~= string.utf8lower(firstLetter) then
        letters = format("%s%s. ", letters, firstLetter)
      end
    end
    str = format("%s%s", letters, lastWord)
  end
  return str
end

-- test 11.4.24
local function shortName(name,isPersonal)
  local newName = name
  if name then
    newName = newName:gsub("-.*$", "")
  end
  local maxLen = (isPersonal and NameplateSCT.db.global.CasterNamesMaxLengthPersonal) or NameplateSCT.db.global.CasterNamesMaxLength or 0
  if newName and #newName:gsub('[\128-\191]', '') > maxLen then
    newName = Abbrev(name)
    if #newName:gsub('[\128-\191]', '') > maxLen then
      newName = utf8sub(newName, maxLen, true)
    end
    newName = newName:gsub("%s+", "")
  end
  return newName or "UNKNOWN"
end

local classColors = {
  ["DEATHKNIGHT"] = "C41F3B",
  ["DRUID"] = "FF7D0A",
  ["HUNTER"] = "A9D271",
  ["MAGE"] = "40C7EB",
  ["PALADIN"] = "F58CBA",
  ["PRIEST"] = "FFFFFF",
  ["ROGUE"] = "FFF569",
  ["SHAMAN"] = "0070DE",
  ["WARLOCK"] = "8787ED",
  ["WARRIOR"] = "C79C6E",
}

local nameClassColor = {}

local function colorName(name,unitid,guid,unknownColor,hyperLink,chathyperLink,isPersonal)
  --local classColor = classColors[select(2,GetPlayerInfoByGUID(guid))]
  if not NameplateSCT.db.global.enableClassColorCasterNames then
    if unknownColor then
      return "|cff"..unknownColor..(shortName(name,isPersonal) or "UNKNOWN").."|r"
    end
    return shortName(name,isPersonal)
  end
  
  local _name = name
  
  if not _name then
    if unitid then
      _name = UnitName(unitid)
    elseif guid and (tonumber(guid:sub(5, 5), 16) % 8 == 0) then
      _name = select(6,GetPlayerInfoByGUID(guid))
    else
      _name = "UNKNOWN"
    end
  end
  
  --if hyperLink==nil then 
  --  hyperLink=1 
  --end
  
  if hyperLink then
    if chathyperLink then
      _name = "|Hplayer:".._name.."|h".._name.."|h"
    elseif guid then
      _name = "|Hunit:" .. guid .. ":" .. _name .. "|h" .. _name .. "|h"
    end
  end
  
  local classColor
  
  if (not _name or _name == "" or _name == STRING_SCHOOL_UNKNOWN) then 
    return ""
  end
  
  if nameClassColor[name] then
    classColor = nameClassColor[name]
  elseif unitid then
    classColor = classColors[select(2,UnitClass(unitid))] or unknownColor --or "ffffff"
    nameClassColor[name]=classColor
  elseif guid then
    classColor = classColors[select(2,GetPlayerInfoByGUID(guid))] or unknownColor --or "ffffff"
    nameClassColor[name]=classColor
  elseif name then
    classColor = classColors[select(2,UnitClass(name))] or unknownColor --or "ffffff"
    nameClassColor[name]=classColor
  else
    classColor = "ffffff"
  end
  
  if not classColor then
    classColor="ffffff"
  end
  
  --print(classColor,_name)
  return "|ccc"..classColor..shortName(_name,isPersonal).."|r"
end

local animationValues = {
  ["verticalUp"] = L["Vertical Up"],
  ["verticalDown"] = L["Vertical Down"],
  ["fountain"] = L["Fountain"],
  ["rainfall"] = L["Rainfall"],
  ["rainfallRev"] = "Rainfall reverse", -- 23.11.23 added new anim type
  ["arcDown"] = "arcDown",--26.7.24
  ["disabled"] = L["Disabled"]
}

local fontFlags = {
  [""] = L["None"],
  ["OUTLINE"] = L["Outline"],
  ["THICKOUTLINE"] = L["Thick Outline"],
  ["nil, MONOCHROME"] = L["Monochrome"],
  ["OUTLINE , MONOCHROME"] = L["Monochrome Outline"],
  ["THICKOUTLINE , MONOCHROME"] = L["Monochrome Thick Outline"]
}

local stratas = {
  ["BACKGROUND"] = L["Background"],
  ["LOW"] = L["Low"],
  ["MEDIUM"] = L["Medium"],
  ["HIGH"] = L["High"],
  ["DIALOG"] = L["Dialog"],
  ["TOOLTIP"] = L["Tooltip"]
}

local positionValues = {
  ["TOP"] = L["Top"],
  ["RIGHT"] = L["Right"],
  ["BOTTOM"] = L["Bottom"],
  ["LEFT"] = L["Left"],
  ["TOPRIGHT"] = L["Top Right"],
  ["TOPLEFT"] = L["Top Left"],
  ["BOTTOMRIGHT"] = L["Bottom Right"],
  ["BOTTOMLEFT"] = L["Bottom Left"],
  ["CENTER"] = L["Center"]
}

local inversePositions = {
  ["BOTTOM"] = "TOP",
  ["LEFT"] = "RIGHT",
  ["TOP"] = "BOTTOM",
  ["RIGHT"] = "LEFT",
  ["TOPLEFT"] = "BOTTOMRIGHT",
  ["TOPRIGHT"] = "BOTTOMLEFT",
  ["BOTTOMLEFT"] = "TOPRIGHT",
  ["BOTTOMRIGHT"] = "TOPLEFT",
  ["CENTER"] = "CENTER"
}

--------
-- DB --
--------

local defaultFont = SharedMedia:IsValid("font", "Bazooka") and "Bazooka" or "Friz Quadrata TT"



local defaults = {
  global = {
    enabled = true,
    heals = true,
    personalOnly = false,
    personalHealingOnly = false,
    personal = true,
    ShowOthersUnitsHitsOnNameplates = false,
    onlyTargetSCT = false,
    displayOverkill = false,

    fontPersonal = defaultFont,
    fontFlagPersonal = "OUTLINE",
    textShadowPersonal = false,

    showIconPersonal = true,
    iconScalePersonal = 0.9,
    iconPositionPersonal = "LEFT",
    xOffsetIconPersonal = -5,
    yOffsetIconPersonal = 0,

    critsEmbiggenPersonal = true,
    critsScalePersonal = 1.5,
    missEmbiggenPersonal = false,
    missScalePersonal = 1,

    truncatePersonal = true,
    truncateLetterPersonal = true,
    commaSeperatePersonal = false,
    sizePersonal = 20,
    alphaPersonal = 1,

    sizeIsRelativeToMaxHealth = true,
    sizeIsRelativeToMaxHealthPersonal = true,
    sizeMax = 0,
    sizeMaxPersonal = 0,
    sizeMin = 0,
    sizeMinPersonal = 0,
    CustomMaxHealthSizeIsRelativeTo = 0,
    CustomMaxHealthSizeIsRelativeToPersonal = 0,

    xOffset = 10,
    yOffset = 20,
    yOffsetForVerticalDownAnim = -30,
    yOffsetForVerticalUpAnim = 12,
    modOffTargetStrata = true,
    font = defaultFont,
    fontFlag = "OUTLINE",
    textShadow = false,
    useDamageTypeColor = false,
    OverridenDamageColor = "ffff00",
    useOverridenColorOnAutoattacks = false,
    strata = {
      target = "HIGH",
      offTarget = "MEDIUM"
    },

    showIcon = true,
    iconScale = 0.9,
    iconPosition = "LEFT",
    xOffsetIcon = -5,
    yOffsetIcon = 0,

    critsEmbiggen = true,
    critsScale = 1.5,
    missEmbiggen = true,
    missScale = 1,
    smallHitsDamageScale = 0.75,
    smallHitsHealScale = 0.75,
    smallHitsDamageHide = false,
    smallHitsHealHide = false,

    size = 20,
    alpha = 1,
    useOffTarget = true, --?
    truncate = true,
    truncateLetter = true,
    commaSeperate = false,
    offTargetFormatting = {
      size = 15,
      alpha = 0.5
    }, -- +

    damageAnim = "fountain",
    critAnim = "verticalUp",
    missAnim = "verticalDown",
    healAnim = "rainfallRev", -- 23.11.23 added separate option for healing
    animationspeed = 1.2,
    spellBlacklist = {},
    smallHitMaxValueDamage = 0,
    smallHitMaxValueHeal = 0,
    SMALL_HIT_MULTIPIER = 0.5,
    SMALL_HIT_EXPIRY_WINDOW = 30,
    ANIMATION_VERTICAL_DISTANCE_MIN = 75,
    ANIMATION_VERTICAL_DISTANCE_MAX = 75,
    ANIMATION_ARC_X_MIN = 50,
    ANIMATION_ARC_X_MAX = 150,
    ANIMATION_ARC_Y_TOP_MIN = 10,
    ANIMATION_ARC_Y_TOP_MAX = 50,
    ANIMATION_ARC_Y_BOTTOM_MIN = 10,
    ANIMATION_ARC_Y_BOTTOM_MAX = 50,
    ANIMATION_RAINFALL_X_MAX = 75,
    ANIMATION_RAINFALL_Y_MIN = 50,
    ANIMATION_RAINFALL_Y_MAX = 100,
    ANIMATION_RAINFALL_Y_START_MIN = 5,
    ANIMATION_RAINFALL_Y_START_MAX = 15,

    useDamageTypeColorPersonal = false,
    OverridenDamageColorPersonal = "ff5500",
    useOverridenColorOnAutoattacksPersonal = true,
    damageAnimPersonal = "rainfall",
    critAnimPersonal = "verticalDown",
    missAnimPersonal = "verticalDown",
    healAnimPersonal = "rainfall",
    spellBlacklistPersonal = {},
    smallHitMaxValueDamagePersonal = 0,
    smallHitMaxValueHealPersonal = 0,
    SMALL_HIT_EXPIRY_WINDOW_PERSONAL = 30,
    SMALL_HIT_MULTIPIER_PERSONAL = 0.5,
    ANIMATION_VERTICAL_DISTANCE_MIN_PERSONAL = 75, -- 27.11.23
    ANIMATION_VERTICAL_DISTANCE_MAX_PERSONAL = 75, -- 27.11.23
    ANIMATION_ARC_X_MIN_PERSONAL = 50,
    ANIMATION_ARC_X_MAX_PERSONAL = 150,
    ANIMATION_ARC_Y_TOP_MIN_PERSONAL = 10,
    ANIMATION_ARC_Y_TOP_MAX_PERSONAL = 50,
    ANIMATION_ARC_Y_BOTTOM_MIN_PERSONAL = 10,
    ANIMATION_ARC_Y_BOTTOM_MAX_PERSONAL = 50,
    ANIMATION_RAINFALL_X_MAX_PERSONAL = 75,
    ANIMATION_RAINFALL_Y_MIN_PERSONAL = 50,
    ANIMATION_RAINFALL_Y_MAX_PERSONAL = 100,
    ANIMATION_RAINFALL_Y_START_MIN_PERSONAL = 5,
    ANIMATION_RAINFALL_Y_START_MAX_PERSONAL = 15,
    smallHitsHealScalePersonal = 0.75,
    smallHitsDamageScalePersonal = 0.75,
    smallHitsDamageHidePersonal = false,
    smallHitsHealHidePersonal = false,
    xOffsetPersonal = 0,
    xOffsetHealingPersonal = 0,
    yOffsetHealingPersonal = 0,
    yOffsetPersonal = -175,
    animationspeedPersonal = 1.25, -- 23.11.23
    powSizingMax = 1.5,
    powSizingMaxPersonal = 1.5,
    strataPersonal = "MEDIUM",
    showCasterNamesDamage = false,
    showCasterNamesDamagePersonal = false,
    showCasterNamesHeals = false,
    showCasterNamesHealsPersonal = false,
    CasterNamesMaxLengthPersonal = 12,
    CasterNamesMaxLength = 12,
    namesWhitelist = {},
    enableWhitelist = false,
    namesBlacklist = {},
    enableBlacklist = false,
    showAbsorbAmount = false,
    showAbsorbAmountPersonal = false,
    
    enableShowOnSpecificNameplatesByName = false,
    showOnSpecificNameplatesNameList = {},
    --hideMissParryImmuneEtc = false,
    --hideMissParryImmuneEtcPersonal = false,
    hideMyHits = false,
    enableClassColorCasterNames = false,
    enableSimpleStylePersonalSct = false,
    --},
  }
}

local AutoAttack = GetSpellInfo(6603)
local AutoShot = GetSpellInfo(75)
local DAMAGE_TYPE_COLORS = {
  [SCHOOL_MASK_PHYSICAL] = "FFFF00",
  [SCHOOL_MASK_HOLY] = "FFE680",
  [SCHOOL_MASK_FIRE] = "FF8000",
  [SCHOOL_MASK_NATURE] = "4DFF4D",
  [SCHOOL_MASK_FROST] = "80FFFF",
  [SCHOOL_MASK_FROST + SCHOOL_MASK_FIRE] = "FF80FF",
  [SCHOOL_MASK_SHADOW] = "8080FF",
  [SCHOOL_MASK_ARCANE] = "FF80FF",
  [AutoAttack] = "FFFFFF",
  [AutoShot] = "FFFFFF",
  ["pet"] = "FF9900",
  ["heals"] = "4dff4d",
}

-- local MISS_EVENT_STRINGS = {
-- ["ABSORB"] = ACTION_SPELL_MISSED_ABSORB,
-- ["BLOCK"] = ACTION_SPELL_MISSED_BLOCK,
-- ["DEFLECT"] = ACTION_SPELL_MISSED_DEFLECT,
-- ["DODGE"] = ACTION_SPELL_MISSED_DODGE,
-- ["EVADE"] = ACTION_SPELL_MISSED_EVADE,
-- ["IMMUNE"] = ACTION_SPELL_MISSED_IMMUNE,
-- ["MISS"] = ACTION_SPELL_MISSED_MISS,
-- ["PARRY"] = ACTION_SPELL_MISSED_PARRY,
-- ["REFLECT"] = L["Reflected"],
-- ["RESIST"] = L["Resisted"]
-- }

local MISS_EVENT_STRINGS = {
  ["ABSORB"] = "absorb",
  ["BLOCK"] = "block",
  ["DEFLECT"] = "deflect",
  ["DODGE"] = "dodge",
  ["EVADE"] = "evade",
  ["IMMUNE"] = "immune",
  ["MISS"] = "miss",
  ["PARRY"] = "parry",
  ["REFLECT"] = "reflect",
  ["RESIST"] = "resist"
}

local STRATAS = {
  "BACKGROUND",
  "LOW",
  "MEDIUM",
  "HIGH",
  "DIALOG",
  "TOOLTIP"
}

-- 3.12.23
local function useNextStrata(currentStrata)
  local currentIndex

  -- Находим текущий индекс в таблице STRATAS
  for i, strata in ipairs(STRATAS) do
    if strata == currentStrata then
      currentIndex = i
      break
    end
  end

  -- Изменяем значение на следующее (если не последнее)
  if currentIndex and currentIndex < #STRATAS then
    local nextIndex = currentIndex + 1
    return STRATAS[nextIndex]
  else
    return currentStrata
  end
end

----------------
-- FONTSTRING --
----------------
local function getFontPath(fontName)
  local fontPath = SharedMedia:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
  return fontPath
end

-- test (simple style personal sct) 26.7.24
do
  local myRealName=UnitName("player")
  local f = CreateFrame("frame")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:SetScript("onevent",function(self) myRealName=UnitName("player") self:UnregisterEvent("PLAYER_ENTERING_WORLD") end)
  f:SetPoint("TOPLEFT")
  f:SetPoint("BOTTOMRIGHT")
  f:SetFrameLevel(0)
  f:SetFrameStrata("BACKGROUND")
  f.tex = f:CreateTexture("alertFrame_screenEdgeHighlight_dmg", "BACKGROUND")
  f.tex:SetAllPoints(f)
  f.tex:Hide()

  local texEdge = [[Interface\addons\CustomFrames\white.tga]]
  local texFull = [[Interface\addons\CustomFrames\fullwhite+edge2.tga]]
  -- local defaultPosY = -100
  -- local defaultPosX = 228
  local defaultPosY = -130
  local defaultPosX = 700
  local maxTextFrames = 20
  local defaultFontStartSize = 1
  --local defaultTextColor = {0.8,1,0.8}
  local defaultTextColor = {0.5,0.3,1}
  local defaultFlashColor = {0.5,0.3,1}
  local defaultSoundPath = [[Sound\Interface\RaidBossWarning.wav]]
  local defaultText = "test! 12345! kdsjksdjfksdjf, ЭТА ТЭСТ"
  local defaultTextDuration = 2
  local defaultFlashDuration = 1
  local defaultFont = [[Interface\addons\CustomFrames\PTSansNarrow.ttf]]
  local defaultFontMaxSize = 35
  
  local busyFrames = {}
   
  -- Функция для изменения размера фрейма
  local function animateFrameSize(startTextSize, maxTextSize, scalingDuration, textRegion)
      busyFrames[textRegion]={maxTextSize=maxTextSize}
      local startTime = GetTime()
      local scalingFactor = maxTextSize/startTextSize
      local frame=textRegion:GetParent()

      local function onUpdate()
          local elapsed = GetTime() - startTime
          local progress = elapsed / scalingDuration
          
          if frame:GetScript("OnUpdate") then
            if progress >= 1 then
                --textRegion:SetFont(defaultFont, startTextSize, 'OUTLINE')
                frame:SetScript("OnUpdate", nil)
                --busyFrames[textRegion]=nil
            else
                local curSize = select(2,textRegion:GetFont())
                local newSize = curSize + (maxTextSize - curSize) * progress
                --textRegion:SetFont(defaultFont, newSize, 'OUTLINE')
                textRegion:SetFont(getFontPath(NameplateSCT.db.global.fontPersonal) or defaultFont, newSize, 'OUTLINE')
                --print(select(2,textRegion:GetFont()))
            end
          end
      end
      
      if frame:GetScript("OnUpdate")==nil then
        frame:SetScript("OnUpdate", onUpdate)
      end
  end

  for i = 1, maxTextFrames do
    local f = CreateFrame("frame","alertFrame_dmg"..i)
    f.t=f:CreateFontString("alertFrame_text_dmg"..i, "overlay")
    --f.t:SetShadowOffset(1, -1)
    f.t:SetShadowOffset(0, 0)
    f.t:SetPoint("BOTTOM", f, "CENTER", 0, 0)
    f.t:SetJustifyH("BOTTOM")
    f.t:SetJustifyV("BOTTOM")
    f:SetFrameStrata("high")
  end
  
  local function countNewlines(text)
    if not text then return 0 end
    return select(2, text:gsub("\n", "")) or 0
  end
  
  --func_Alert("",{0,0,0},nil,1,{0.6,0,0},0.5,true,true)
  function func_dmg(text,textcolor,startTextSize,textDuration,flashColor,flashDuration,edgeFlashOnly,enableFlash,enableSound,soundPath,soundPathTwo,maxTextSize,matchText)
      if enableFlash==nil then enableFlash = true end
      if edgeFlashOnly==nil then edgeFlashOnly = true end
      if text==nil then text = defaultText end
      if soundPath==nil then soundPath = defaultSoundPath end
      if flashColor==nil then flashColor = defaultFlashColor end
      if textcolor==nil then textcolor = defaultTextColor end
      if startTextSize==nil then startTextSize = defaultFontStartSize end
      if textDuration==nil then textDuration = defaultTextDuration end
      if flashDuration==nil then flashDuration = defaultFlashDuration end
      if maxTextSize==nil then maxTextSize = defaultFontMaxSize end
      
      local tex--,screenflash
      if edgeFlashOnly then 
        tex=texEdge 
        --screenflash=true 
      elseif enableFlash then
        tex=texFull 
      end
      
      if tex then
        alertFrame_screenEdgeHighlight_dmg:SetTexture(tex)
      end
      
      local textRegion,anchor,prevTextRegion,nextTextRegion,offsetY,offsetX--,prevTextRegionNumLines,prevTextFontSize
      
      for i = 1, maxTextFrames do
        textRegion = _G["alertFrame_text_dmg" .. i]
        prevTextRegion = _G["alertFrame_text_dmg"..(i-1)]
        nextTextRegion = _G["alertFrame_text_dmg"..(i+1)]
        nextNextTextRegion = _G["alertFrame_text_dmg"..(i+2)]
        --print(textRegion:GetName())

        if (not UIFrameIsFlashing(textRegion) or (matchText and textRegion and textRegion:GetText()~=nil and textRegion:GetText():find(matchText))) then  
          --busyFrames[textRegion]=true
          --print(textRegion:GetName())
          
          if (prevTextRegion) then 
            prevTextRegionNumLines = countNewlines(prevTextRegion:GetText())+1
            --print(prevTextRegion:GetText(),prevTextRegionNumLines)
            prevTextFontSize = math.min(maxTextSize,(select(2,prevTextRegion:GetFont())))
            --offsetY = -((prevTextRegion:GetStringHeight())+maxTextSize) ---------------------------&&&&&&&&&&&&?????????????????
            --offsetY = -(busyFrames[prevTextRegion].maxTextSize+maxTextSize)
            offsetY = -(busyFrames[prevTextRegion].maxTextSize*(prevTextRegionNumLines+1))
            --print(prevTextRegionNumLines)
            --print(busyFrames[prevTextRegion].maxTextSize,maxTextSize)
            anchor = prevTextRegion
            offsetX = 0
          else
            prevTextRegion = textRegion 
            offsetY = defaultPosY +(NameplateSCT.db.global.yOffsetPersonal or 0)
            anchor = UIParent
            offsetX = defaultPosX +(NameplateSCT.db.global.xOffsetPersonal or 0)
          end
          
          --print(offsetY)
          
          if (nextTextRegion and nextTextRegion:IsVisible()) then
            UIFrameFlashStop(nextTextRegion)
            nextTextRegion:Hide()
            --print('nextTextRegion:Hide(func_Alert)')
            --UIFrameFadeOut(nextTextRegion, 0.15, nextTextRegion:GetAlpha(), 0)
            --print('UIFrameFadeOut(nextTextRegion')
          end
          
          if (nextNextTextRegion and nextNextTextRegion:IsVisible()) then
            UIFrameFlashStop(nextNextTextRegion)
            nextNextTextRegion:Hide()
            --print('nextNextTextRegion:Hide(func_Alert)')
          end
          
          -- if (nextNextTextRegion and nextNextTextRegion:IsVisible()) then
            -- UIFrameFlashStop(nextNextTextRegion)
            -- UIFrameFadeOut(nextNextTextRegion, 0.15, nextNextTextRegion:GetAlpha(), 0)
            -- print('UIFrameFadeOut(nextNextTextRegion')
          -- end
          
          textRegion:SetPoint("left", anchor, "left", offsetX, offsetY+11)
          break
        elseif (i == maxTextFrames) then
          textRegion = _G["alertFrame_text_dmg"..(1)]
          textRegion:SetPoint("left", UIParent, "left", defaultPosX, defaultPosY)
        end
      end
      
      if text then
        --textRegion:SetFont(defaultFont, startTextSize, 'OUTLINE')
        textRegion:SetFont(getFontPath(NameplateSCT.db.global.fontPersonal) or defaultFont, startTextSize, 'OUTLINE')
        textRegion:SetTextColor(unpack(textcolor))
        if myRealName and MyNewName then 
          text=text:gsub(myRealName, MyNewName):gsub(myRealName:lower(), MyNewName)
        end
        textRegion:SetText(text)
        --print(tonumber(textRegion:GetText()))
      end
      
      animateFrameSize(startTextSize, maxTextSize, 0.3, textRegion)
      --func_frameShake(textRegion, 3, 1, 0.5, stopIncremensionOnXSecond, intensityDecreaseAfterXSecond, 20)
   
      if tex and (--[[screenflash]] edgeFlashOnly or enableFlash) then
        UIFrameFlashStop(alertFrame_screenEdgeHighlight_dmg)
        if cnmFrame_screenEdgeHighlight and text~="" then 
          --cnmFrame_screenEdgeHighlight:Hide()
          UIFrameFadeOut(cnmFrame_screenEdgeHighlight, 0.8, 0.5, 0) 
        end
        alertFrame_screenEdgeHighlight_dmg:SetVertexColor(unpack(flashColor))
        local fadeInTime=flashDuration/5
        local fadeOutTime=flashDuration/2
        --UIFrameFlash(alertFrame_screenEdgeHighlight_dmg, 0.2, 0.5, flashDuration, false, flashDuration-0.2-0.5, 0)
        UIFrameFlash(alertFrame_screenEdgeHighlight_dmg, fadeInTime, fadeOutTime, flashDuration, false, flashDuration-fadeInTime-fadeOutTime, 0)
      end
      
      UIFrameFlashStop(textRegion)
      UIFrameFlash(textRegion, 0.2, 0.8, textDuration, false, textDuration-0.2-0.8, 0)
      
      if enableSound then PlaySoundFile(soundPath) end
      if soundPathTwo then PlaySoundFile(soundPathTwo) end
  end
end


do
  local myRealName=UnitName("player")
  local f = CreateFrame("frame")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:SetScript("onevent",function(self) myRealName=UnitName("player") self:UnregisterEvent("PLAYER_ENTERING_WORLD") end)
  f:SetPoint("TOPLEFT")
  f:SetPoint("BOTTOMRIGHT")
  f:SetFrameLevel(0)
  f:SetFrameStrata("BACKGROUND")
  f.tex = f:CreateTexture("alertFrame_screenEdgeHighlight_heal", "BACKGROUND")
  f.tex:SetAllPoints(f)
  f.tex:Hide()

  local texEdge = [[Interface\addons\CustomFrames\white.tga]]
  local texFull = [[Interface\addons\CustomFrames\fullwhite+edge2.tga]]
  -- local defaultPosY = -100
  -- local defaultPosX = 450
  local defaultPosY = -130
  local defaultPosX = 850
  local maxTextFrames = 20
  local defaultFontStartSize = 1
  --local defaultTextColor = {0.8,1,0.8}
  local defaultTextColor = {0.5,0.3,1}
  local defaultFlashColor = {0.5,0.3,1}
  local defaultSoundPath = [[Sound\Interface\RaidBossWarning.wav]]
  local defaultText = "test! 12345! kdsjksdjfksdjf, ЭТА ТЭСТ"
  local defaultTextDuration = 2
  local defaultFlashDuration = 1
  local defaultFont = [[Interface\addons\CustomFrames\PTSansNarrow.ttf]]
  local defaultFontMaxSize = 35
  
  local busyFrames = {}
   
  -- Функция для изменения размера фрейма
  local function animateFrameSize(startTextSize, maxTextSize, scalingDuration, textRegion)
      busyFrames[textRegion]={maxTextSize=maxTextSize}
      local startTime = GetTime()
      local scalingFactor = maxTextSize/startTextSize
      local frame=textRegion:GetParent()

      local function onUpdate()
          local elapsed = GetTime() - startTime
          local progress = elapsed / scalingDuration
          
          if frame:GetScript("OnUpdate") then
            if progress >= 1 then
                --textRegion:SetFont(defaultFont, startTextSize, 'OUTLINE')
                frame:SetScript("OnUpdate", nil)
                --busyFrames[textRegion]=nil
            else
                local curSize = select(2,textRegion:GetFont())
                local newSize = curSize + (maxTextSize - curSize) * progress
                --textRegion:SetFont(defaultFont, newSize, 'OUTLINE')
                textRegion:SetFont(getFontPath(NameplateSCT.db.global.fontPersonal) or defaultFont, newSize, 'OUTLINE')
                --print(select(2,textRegion:GetFont()))
            end
          end
      end
      
      if frame:GetScript("OnUpdate")==nil then
        frame:SetScript("OnUpdate", onUpdate)
      end
  end

  for i = 1, maxTextFrames do
    local f = CreateFrame("frame","alertFrame_heal"..i)
    f.t=f:CreateFontString("alertFrame_text_heal"..i, "overlay")
    --f.t:SetShadowOffset(1, -1)
    f.t:SetShadowOffset(0, 0)
    f.t:SetPoint("BOTTOM", f, "CENTER", 0, 0)
    f.t:SetJustifyH("BOTTOM")
    f.t:SetJustifyV("BOTTOM")
    f:SetFrameStrata("high")
  end
  
  local function countNewlines(text)
    if not text then return 0 end
    return select(2, text:gsub("\n", "")) or 0
  end
  
  --func_Alert("",{0,0,0},nil,1,{0.6,0,0},0.5,true,true)
  function func_heal(text,textcolor,startTextSize,textDuration,flashColor,flashDuration,edgeFlashOnly,enableFlash,enableSound,soundPath,soundPathTwo,maxTextSize,matchText)
      if enableFlash==nil then enableFlash = true end
      if edgeFlashOnly==nil then edgeFlashOnly = true end
      if text==nil then text = defaultText end
      if soundPath==nil then soundPath = defaultSoundPath end
      if flashColor==nil then flashColor = defaultFlashColor end
      if textcolor==nil then textcolor = defaultTextColor end
      if startTextSize==nil then startTextSize = defaultFontStartSize end
      if textDuration==nil then textDuration = defaultTextDuration end
      if flashDuration==nil then flashDuration = defaultFlashDuration end
      if maxTextSize==nil then maxTextSize = defaultFontMaxSize end
      
      local tex--,screenflash
      if edgeFlashOnly then 
        tex=texEdge 
        --screenflash=true 
      elseif enableFlash then
        tex=texFull 
      end
      
      if tex then
        alertFrame_screenEdgeHighlight_heal:SetTexture(tex)
      end
      
      local textRegion,anchor,prevTextRegion,nextTextRegion,offsetY,offsetX--,prevTextRegionNumLines,prevTextFontSize
      
      for i = 1, maxTextFrames do
        textRegion = _G["alertFrame_text_heal" .. i]
        prevTextRegion = _G["alertFrame_text_heal"..(i-1)]
        nextTextRegion = _G["alertFrame_text_heal"..(i+1)]
        nextNextTextRegion = _G["alertFrame_text_heal"..(i+2)]
        --print(textRegion:GetName())

        if (not UIFrameIsFlashing(textRegion) or (matchText and textRegion and textRegion:GetText()~=nil and textRegion:GetText():find(matchText))) then  
          --busyFrames[textRegion]=true
          --print(textRegion:GetName())
          
          if (prevTextRegion) then 
            prevTextRegionNumLines = countNewlines(prevTextRegion:GetText())+1
            --print(prevTextRegion:GetText(),prevTextRegionNumLines)
            prevTextFontSize = math.min(maxTextSize,(select(2,prevTextRegion:GetFont())))
            --offsetY = -((prevTextRegion:GetStringHeight())+maxTextSize) ---------------------------&&&&&&&&&&&&?????????????????
            --offsetY = -(busyFrames[prevTextRegion].maxTextSize+maxTextSize)
            offsetY = -(busyFrames[prevTextRegion].maxTextSize*(prevTextRegionNumLines+1))
            --print(prevTextRegionNumLines)
            --print(busyFrames[prevTextRegion].maxTextSize,maxTextSize)
            anchor = prevTextRegion
            offsetX = 0
          else
            prevTextRegion = textRegion 
            offsetY = defaultPosY +(NameplateSCT.db.global.yOffsetHealingPersonal or 0)
            anchor = UIParent
            offsetX = defaultPosX +(NameplateSCT.db.global.xOffsetHealingPersonal or 0)
          end
          
          --print(offsetY)
          
          if (nextTextRegion and nextTextRegion:IsVisible()) then
            UIFrameFlashStop(nextTextRegion)
            nextTextRegion:Hide()
            --print('nextTextRegion:Hide(func_Alert)')
            --UIFrameFadeOut(nextTextRegion, 0.15, nextTextRegion:GetAlpha(), 0)
            --print('UIFrameFadeOut(nextTextRegion')
          end
          
          if (nextNextTextRegion and nextNextTextRegion:IsVisible()) then
            UIFrameFlashStop(nextNextTextRegion)
            nextNextTextRegion:Hide()
            --print('nextNextTextRegion:Hide(func_Alert)')
          end
          
          -- if (nextNextTextRegion and nextNextTextRegion:IsVisible()) then
            -- UIFrameFlashStop(nextNextTextRegion)
            -- UIFrameFadeOut(nextNextTextRegion, 0.15, nextNextTextRegion:GetAlpha(), 0)
            -- print('UIFrameFadeOut(nextNextTextRegion')
          -- end
          
          textRegion:SetPoint("left", anchor, "left", offsetX, offsetY+11)
          break
        elseif (i == maxTextFrames) then
          textRegion = _G["alertFrame_text_heal"..(1)]
          textRegion:SetPoint("left", UIParent, "left", defaultPosX, defaultPosY)
        end
      end
      
      if text then
        --textRegion:SetFont(defaultFont, startTextSize, 'OUTLINE')
        textRegion:SetFont(getFontPath(NameplateSCT.db.global.fontPersonal) or defaultFont, startTextSize, 'OUTLINE')
        textRegion:SetTextColor(unpack(textcolor))
        if myRealName and MyNewName then 
          text=text:gsub(myRealName, MyNewName):gsub(myRealName:lower(), MyNewName)
        end
        textRegion:SetText(text)
        --print(tonumber(textRegion:GetText()))
      end
      
      animateFrameSize(startTextSize, maxTextSize, 0.3, textRegion)
      --func_frameShake(textRegion, 3, 1, 0.5, stopIncremensionOnXSecond, intensityDecreaseAfterXSecond, 20)
   
      if tex and (--[[screenflash]] edgeFlashOnly or enableFlash) then
        UIFrameFlashStop(alertFrame_screenEdgeHighlight_heal)
        if cnmFrame_screenEdgeHighlight and text~="" then 
          --cnmFrame_screenEdgeHighlight:Hide()
          UIFrameFadeOut(cnmFrame_screenEdgeHighlight, 0.8, 0.5, 0) 
        end
        alertFrame_screenEdgeHighlight_heal:SetVertexColor(unpack(flashColor))
        local fadeInTime=flashDuration/5
        local fadeOutTime=flashDuration/2
        --UIFrameFlash(alertFrame_screenEdgeHighlight_heal, 0.2, 0.5, flashDuration, false, flashDuration-0.2-0.5, 0)
        UIFrameFlash(alertFrame_screenEdgeHighlight_heal, fadeInTime, fadeOutTime, flashDuration, false, flashDuration-fadeInTime-fadeOutTime, 0)
      end
      
      UIFrameFlashStop(textRegion)
      UIFrameFlash(textRegion, 0.2, 0.8, textDuration, false, textDuration-0.2-0.8, 0)
      
      if enableSound then PlaySoundFile(soundPath) end
      if soundPathTwo then PlaySoundFile(soundPathTwo) end
  end
end


local fontStringCache = {}
local frameCounter = 0
local function getFontString(guid, topMost)
  local fontString, fontStringFrame

  if next(fontStringCache) then
    fontString = tremove(fontStringCache)
  else
    frameCounter = frameCounter + 1
    fontStringFrame = CreateFrame("Frame", nil, UIParent)

    -- 3.12.23 mf test
    if topMost then
      fontStringFrame:SetFrameStrata(useNextStrata(NameplateSCT.db.global.strata.target))
    else
      fontStringFrame:SetFrameStrata(NameplateSCT.db.global.strata.target)
    end
    --print(NameplateSCT.db.global.strata.target)

    fontStringFrame:SetFrameLevel(frameCounter)
    fontString = fontStringFrame:CreateFontString()
    fontString:SetParent(fontStringFrame)
  end

  local isPersonal = playerGUID == guid
  local textShadow = (isPersonal and NameplateSCT.db.global.textShadowPersonal) or
      (not isPersonal and NameplateSCT.db.global.textShadow)
  local font = isPersonal and NameplateSCT.db.global.fontPersonal or NameplateSCT.db.global.font
  local fontFlag = isPersonal and NameplateSCT.db.global.fontFlagPersonal or NameplateSCT.db.global.fontFlag

  fontString:SetFont(getFontPath(font), 15, fontFlag)
  if textShadow then
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowOffset(0, 0)
  end

  fontString:SetAlpha(1)
  fontString:SetDrawLayer("BACKGROUND")
  fontString:SetText("")
  fontString:Show()

  local showIcon = (isPersonal and NameplateSCT.db.global.showIconPersonal) or
      (not isPersonal and NameplateSCT.db.global.showIcon)

  if showIcon then
    if not fontString.icon then
      fontString.icon = NameplateSCT.frame:CreateTexture(nil, "BACKGROUND")
      fontString.icon:SetTexCoord(0.062, 0.938, 0.062, 0.938)
    end
    fontString.icon:SetAlpha(1)
    fontString.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    fontString.icon:Hide()

    -- if fontString.icon.button then
    -- fontString.icon.button:Show()
    -- print('fontString.icon.button:Show')
    -- end
  end

  return fontString
end

local function recycleFontString(fontString)
  fontString:SetAlpha(0)
  fontString:Hide()

  local isPersonal = playerGUID == fontString.guid
  local textShadow = (isPersonal and NameplateSCT.db.global.textShadowPersonal) or
      (not isPersonal and NameplateSCT.db.global.textShadow)
  local font = isPersonal and NameplateSCT.db.global.fontPersonal or NameplateSCT.db.global.font
  local fontFlag = isPersonal and NameplateSCT.db.global.fontFlagPersonal or NameplateSCT.db.global.fontFlag

  animating[fontString] = nil

  fontString.distance = nil
  fontString.arcTop = nil
  fontString.arcBottom = nil
  fontString.arcXDist = nil
  fontString.deflection = nil
  fontString.numShakes = nil
  fontString.animation = nil
  fontString.animatingDuration = nil
  fontString.animatingStartTime = nil
  fontString.anchorFrame = nil
  fontString.guid = nil
  fontString.pow = nil
  fontString.startHeight = nil
  fontString.NSCTFontSize = nil
  fontString.topMost = nil -- 3.12.23

  if fontString.icon then
    fontString.icon:ClearAllPoints()
    fontString.icon:SetAlpha(0)
    fontString.icon:Hide()
    -- if fontString.icon.button then
    -- fontString.icon.button:Hide()
    -- fontString.icon.button:ClearAllPoints()
    -- print('fontString.icon.button:Hide ClearAllPoints')
    -- end

    fontString.icon.anchorFrame = nil
    fontString.icon.guid = nil
  end

  fontString:SetFont(getFontPath(font), 15, fontFlag)

  if textShadow then
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowOffset(0, 0)
  end

  fontString:ClearAllPoints()

  tinsert(fontStringCache, fontString)
end

----------------
-- NAMEPLATES --
----------------

local function adjustStrata()
  if NameplateSCT.db.global.modOffTargetStrata then
    return
  end

  if NameplateSCT.db.global.strata.target == "BACKGROUND" then
    NameplateSCT.db.global.strata.offTarget = "BACKGROUND"
    return
  end

  local offStrata
  for k, v in ipairs(STRATAS) do
    if (v == NameplateSCT.db.global.strata.target) then
      offStrata = STRATAS[k - 1]
    end
  end
  NameplateSCT.db.global.strata.offTarget = offStrata
end

----------
-- CORE --
----------
function NameplateSCT:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("NameplateSCTDB", defaults, true)
  --print(89787)
  self:RegisterChatCommand("nsct", "OpenMenu")
  self:RegisterMenu()
  SharedMedia:Register("font", "Arnold", [[Interface\Addons\NameplateSCT\Media\arnold.ttf]])
  SharedMedia:Register("font", "Century gothic (CYR)", [[Interface\Addons\NameplateSCT\Media\century gothic.ttf]])
  SharedMedia:Register("font", "Pepsi", [[Interface\Addons\NameplateSCT\Media\pepsi.ttf]])
  SharedMedia:Register("font", "BadaBoom BB", [[Interface\Addons\NameplateSCT\Media\BadaBoom BB.ttf]])
  SharedMedia:Register("font", "Impact (CYR)", [[Interface\Addons\NameplateSCT\Media\Impact.ttf]])
  SharedMedia:Register("font", "Ben Krush", [[Interface\Addons\NameplateSCT\Media\Ben Krush.ttf]])
  SharedMedia:Register("font", "Better Together", [[Interface\Addons\NameplateSCT\Media\Better Together.ttf]])
  SharedMedia:Register("font", "HOOGE", [[Interface\Addons\NameplateSCT\Media\HOOGE.ttf]])
  SharedMedia:Register("font", "a_ConceptoTitulNrFy (CYR)", [[Interface\Addons\NameplateSCT\Media\.ttf]])
  SharedMedia:Register("font", "A.C.M.E. Explosive", [[Interface\Addons\NameplateSCT\Media\A.C.M.E. Explosive.ttf]])
  --print('|cff22bbffNameplatesSCT '..GetAddOnMetadata("NameplateSCT", "X-Maintained")..'|r')
  if self.db.global.enabled == false then
    self:Disable()
  end
end

function NameplateSCT:OnEnable()
  playerGUID = UnitGUID("player")
  self:RegisterEvent("PLAYER_TARGET_CHANGED") --28.12.23
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self.db.global.enabled = true
  AutoAttack = AutoAttack or GetSpellInfo(6603)
  AutoShot = AutoShot or GetSpellInfo(75)
end

function NameplateSCT:OnDisable()
  self:UnregisterAllEvents()
  for fontString, _ in pairs(animating) do
    recycleFontString(fontString)
  end
  self.db.global.enabled = false
end

---------------
-- ANIMATION --
---------------
local function verticalPath(elapsed, duration, distance)
  return 0, LibEasing.InQuad(elapsed, 0, distance, duration)
end

local function arcPathFountain(elapsed, duration, xDist, yStart, yTop, yBottom)
  local x, y
  local progress = elapsed / duration

  x = progress * xDist

  local a = -2 * yStart + 4 * yTop - 2 * yBottom
  local b = -3 * yStart + 4 * yTop - yBottom

  y = -a * math_pow(progress, 2) + b * progress + yStart

  return x, y
end

-- local function arcPath(elapsed, duration, xDist, yStart, yTop, yBottom)
  -- local x, y
  -- local progress = elapsed / duration

  -- -- x координата изменяется линейно с течением времени
  -- x = progress * xDist

  -- -- y координата изменяется линейно от yStart к yBottom
  -- y = yStart + (yBottom - yStart) * progress

  -- return x, y
-- end

-- local function arcPath(elapsed, duration, xDist, yStart, yTop, yBottom)
  -- local x, y
  -- local progress = elapsed / duration

  -- -- Используем синусоидальную функцию для плавного начала движения по оси X
  -- x = xDist * (1 - math.cos(math.pi * progress)) / 2

  -- -- Линейное изменение по оси Y от yStart к yBottom
  -- y = yStart + (yBottom - yStart) * progress

  -- return x, y
-- end

--++
local function arcPath(elapsed, duration, xDist, yStart, yTop, yBottom)
  local x, y
  local progress = elapsed / duration

  -- Линейное движение по оси X
  x = progress * xDist

  -- Параболическое движение по оси Y, создающее эффект дуги
  local a = yStart - yBottom
  y = yStart - (a * progress * progress)

  return x, y
end

local function powSizing(elapsed, duration, start, middle, finish)
  local size = finish
  if elapsed < duration then
    if elapsed / duration < 0.5 then
      size = LibEasing.OutQuint(elapsed, start, middle - start, duration / 2)
    else
      size = LibEasing.InQuint(elapsed - elapsed / 2, middle, finish - middle, duration / 2)
    end
  end
  return size
end

--++
local function AnimationOnUpdate()
  if next(animating) then
    for fontString, _ in pairs(animating) do
      local elapsed = GetTime() - fontString.animatingStartTime
      if elapsed > fontString.animatingDuration then
        recycleFontString(fontString)
      else
        local isTarget = false
        local isPersonal = false
        if fontString.guid then
          isTarget = (UnitGUID("target") == fontString.guid)
        else
          fontString.guid = playerGUID
        end

        isPersonal = (fontString.guid == playerGUID)

        local frame = fontString:GetParent()
        local currentStrata = frame:GetFrameStrata()
        local topMost = fontString.topMost and useNextStrata(NameplateSCT.db.global.strata.target) -- 3.12.23
        local strataRequired = topMost or isTarget and NameplateSCT.db.global.strata.target or
            NameplateSCT.db.global.strata.offTarget

        -- if (topMost) then
        -- fontString.animation = "verticalUp"
        -- fontString.NSCTFontSize =
        -- end

        --print(strataRequired)
        --print('strataRequired',strataRequired)
        if (isPersonal) then -- 18.12.23
          frame:SetFrameStrata(NameplateSCT.db.global.strataPersonal)
          --print(NameplateSCT.db.global.strataPersonal)
        elseif currentStrata ~= strataRequired then
          --print('currentStrata ~= strataRequired',"strataRequired:",strataRequired)
          frame:SetFrameStrata(strataRequired)
          --print('strataRequired')
        end

        --print(NameplateSCT.db.global.useOffTarget)
        local startAlpha = isPersonal and NameplateSCT.db.global.alphaPersonal or NameplateSCT.db.global.alpha
        if NameplateSCT.db.global.useOffTarget and not isTarget and fontString.guid ~= playerGUID then
          startAlpha = NameplateSCT.db.global.offTargetFormatting.alpha
          --print('useOffTarget')
        end

        local alpha = LibEasing.InExpo(elapsed, startAlpha, -startAlpha, fontString.animatingDuration)
        fontString:SetAlpha(alpha)

        if fontString.pow then
          local iconScale = NameplateSCT.db.global.iconScale
          local height = fontString.startHeight
          if elapsed < fontString.animatingDuration / 6 then
            fontString:SetText(fontString.NSCTText)

            local powsizingmax = isPersonal and NameplateSCT.db.global.powSizingMaxPersonal or
                NameplateSCT.db.global
                .powSizingMax -- 7.12.23 custom powSizing
            local size = powSizing(elapsed, fontString.animatingDuration / 6, height / 2, height * powsizingmax, height)
            fontString:SetTextHeight(size)
          else
            local textShadow = (isPersonal and NameplateSCT.db.global.textShadowPersonal) or (not isPersonal and NameplateSCT.db.global.textShadow)
            local font = isPersonal and NameplateSCT.db.global.fontPersonal or NameplateSCT.db.global.font
            local fontFlag = isPersonal and NameplateSCT.db.global.fontFlagPersonal or NameplateSCT.db.global.fontFlag
            --print(font)

            fontString.pow = nil
            fontString:SetTextHeight(height)
            fontString:SetFont(getFontPath(font), fontString.NSCTFontSize, fontFlag)
            if textShadow then
              fontString:SetShadowOffset(1, -1)
            else
              fontString:SetShadowOffset(0, 0)
            end
            fontString:SetText(fontString.NSCTText)
          end
        end

        local xOffset, yOffset = 0, 0
        if fontString.animation == "verticalUp" then
          xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, fontString.distance)
        elseif fontString.animation == "verticalDown" then
          xOffset, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance)
        elseif fontString.animation == "fountain" then
          xOffset, yOffset = arcPathFountain(elapsed, fontString.animatingDuration, fontString.arcXDist, 0, fontString.arcTop,
            fontString.arcBottom)
        elseif fontString.animation == "arcDown" then
          xOffset, yOffset = arcPath(elapsed, fontString.animatingDuration, fontString.arcXDist, 0, fontString.arcTop,
            fontString.arcBottom)
        elseif fontString.animation == "rainfall" then
          _, yOffset = verticalPath(elapsed, fontString.animatingDuration, -fontString.distance)
          xOffset = fontString.rainfallX
          yOffset = yOffset + fontString.rainfallStartY
        elseif fontString.animation == "rainfallRev" then -- 23.11.23 added new anim type
          _, yOffset = verticalPath(elapsed, fontString.animatingDuration, fontString.distance)
          xOffset = fontString.rainfallX
          yOffset = yOffset + fontString.rainfallStartY
        end

        if fontString.anchorFrame and fontString.anchorFrame:IsShown() then
          if isPersonal then -- player frame
            fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER",
              NameplateSCT.db.global.xOffsetPersonal + xOffset, NameplateSCT.db.global.yOffsetPersonal + yOffset)
          else
            local testYoffset = NameplateSCT.db.global.yOffset + yOffset
            if (fontString.animation == "verticalDown" and not isPersonal) then
              testYoffset = testYoffset + NameplateSCT.db.global.yOffsetForVerticalDownAnim -- test
            elseif (fontString.animation == "verticalUp" and not isPersonal) then
              testYoffset = testYoffset + NameplateSCT.db.global.yOffsetForVerticalUpAnim   -- test 28.11.23
            end
            --fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER", NameplateSCT.db.global.xOffset + xOffset, NameplateSCT.db.global.yOffset + yOffset)
            -- if fontString.anchorFrame then
              -- fontString.lastKnownPoint = fontString.anchorFrame:GetPoint()
              -- print(fontString.anchorFrame:GetPoint())
            -- end
            fontString:SetPoint("CENTER", fontString.anchorFrame, "CENTER", NameplateSCT.db.global.xOffset + xOffset, testYoffset) -- 19.11.23
            --print(NameplateSCT.db.global.yOffset,NameplateSCT.db.global.xOffset)
          end
        else
          recycleFontString(fontString)
        end
      end
    end
  else
    NameplateSCT.frame:SetScript("OnUpdate", nil)
  end
end

--++
local arcDirection = 1
function NameplateSCT:Animate(fontString, anchorFrame, duration, animation)
  animation = animation or "verticalUp"

  fontString.animation = animation
  fontString.animatingDuration = duration
  fontString.animatingStartTime = GetTime()
  fontString.anchorFrame = anchorFrame == "player" and UIParent or anchorFrame
  --print(anchorFrame)

  local ANIMATION_VERTICAL_DISTANCE_MIN, ANIMATION_VERTICAL_DISTANCE_MAX, ANIMATION_ARC_Y_TOP_MIN, ANIMATION_ARC_Y_TOP_MAX, ANIMATION_ARC_Y_BOTTOM_MIN, ANIMATION_ARC_Y_BOTTOM_MAX, ANIMATION_ARC_X_MIN, ANIMATION_ARC_X_MAX, ANIMATION_RAINFALL_Y_MIN, ANIMATION_RAINFALL_Y_MAX, ANIMATION_RAINFALL_X_MAX, ANIMATION_RAINFALL_Y_START_MIN, ANIMATION_RAINFALL_Y_START_MAX

  -- 23.11.23
  if (anchorFrame == "player") then
    ANIMATION_VERTICAL_DISTANCE_MIN = self.db.global.ANIMATION_VERTICAL_DISTANCE_MIN_PERSONAL -- 27.11.23
    ANIMATION_VERTICAL_DISTANCE_MAX = self.db.global.ANIMATION_VERTICAL_DISTANCE_MAX_PERSONAL -- 27.11.23
    ANIMATION_ARC_Y_TOP_MIN = self.db.global.ANIMATION_ARC_Y_TOP_MIN_PERSONAL
    ANIMATION_ARC_Y_TOP_MAX = self.db.global.ANIMATION_ARC_Y_TOP_MAX_PERSONAL
    ANIMATION_ARC_Y_BOTTOM_MIN = self.db.global.ANIMATION_ARC_Y_BOTTOM_MIN_PERSONAL
    ANIMATION_ARC_Y_BOTTOM_MAX = self.db.global.ANIMATION_ARC_Y_BOTTOM_MAX_PERSONAL
    ANIMATION_ARC_X_MIN = self.db.global.ANIMATION_ARC_X_MIN_PERSONAL
    ANIMATION_ARC_X_MAX = self.db.global.ANIMATION_ARC_X_MAX_PERSONAL
    ANIMATION_RAINFALL_Y_MIN = self.db.global.ANIMATION_RAINFALL_Y_MIN_PERSONAL
    ANIMATION_RAINFALL_Y_MAX = self.db.global.ANIMATION_RAINFALL_Y_MAX_PERSONAL
    ANIMATION_RAINFALL_X_MAX = self.db.global.ANIMATION_RAINFALL_X_MAX_PERSONAL
    ANIMATION_RAINFALL_Y_START_MIN = self.db.global.ANIMATION_RAINFALL_Y_START_MIN_PERSONAL
    ANIMATION_RAINFALL_Y_START_MAX = self.db.global.ANIMATION_RAINFALL_Y_START_MAX_PERSONAL
  else
    ANIMATION_VERTICAL_DISTANCE_MIN = self.db.global.ANIMATION_VERTICAL_DISTANCE_MIN -- 27.11.23
    ANIMATION_VERTICAL_DISTANCE_MAX = self.db.global.ANIMATION_VERTICAL_DISTANCE_MAX -- 27.11.23
    ANIMATION_ARC_Y_TOP_MIN = self.db.global.ANIMATION_ARC_Y_TOP_MIN
    ANIMATION_ARC_Y_TOP_MAX = self.db.global.ANIMATION_ARC_Y_TOP_MAX
    ANIMATION_ARC_Y_BOTTOM_MIN = self.db.global.ANIMATION_ARC_Y_BOTTOM_MIN
    ANIMATION_ARC_Y_BOTTOM_MAX = self.db.global.ANIMATION_ARC_Y_BOTTOM_MAX
    ANIMATION_ARC_X_MIN = self.db.global.ANIMATION_ARC_X_MIN
    ANIMATION_ARC_X_MAX = self.db.global.ANIMATION_ARC_X_MAX
    ANIMATION_RAINFALL_Y_MIN = self.db.global.ANIMATION_RAINFALL_Y_MIN
    ANIMATION_RAINFALL_Y_MAX = self.db.global.ANIMATION_RAINFALL_Y_MAX
    ANIMATION_RAINFALL_X_MAX = self.db.global.ANIMATION_RAINFALL_X_MAX
    ANIMATION_RAINFALL_Y_START_MIN = self.db.global.ANIMATION_RAINFALL_Y_START_MIN
    ANIMATION_RAINFALL_Y_START_MAX = self.db.global.ANIMATION_RAINFALL_Y_START_MAX
  end

  --print(ANIMATION_RAINFALL_X_MAX)

  if animation == "verticalUp" then
    fontString.distance = math_random(ANIMATION_VERTICAL_DISTANCE_MIN, ANIMATION_VERTICAL_DISTANCE_MAX) -- 27.11.23
  elseif animation == "verticalDown" then
    fontString.distance = math_random(ANIMATION_VERTICAL_DISTANCE_MIN, ANIMATION_VERTICAL_DISTANCE_MAX) -- 27.11.23
  elseif animation == "fountain" or animation == "arcDown" then
    fontString.arcTop = math_random(ANIMATION_ARC_Y_TOP_MIN, ANIMATION_ARC_Y_TOP_MAX)
    fontString.arcBottom = -math_random(ANIMATION_ARC_Y_BOTTOM_MIN, ANIMATION_ARC_Y_BOTTOM_MAX)
    fontString.arcXDist = arcDirection * math_random(ANIMATION_ARC_X_MIN, ANIMATION_ARC_X_MAX)
    arcDirection = arcDirection * -1
  elseif animation == "rainfall" then
    fontString.distance = math_random(ANIMATION_RAINFALL_Y_MIN, ANIMATION_RAINFALL_Y_MAX)
    fontString.rainfallX = math_random(-ANIMATION_RAINFALL_X_MAX, ANIMATION_RAINFALL_X_MAX)
    fontString.rainfallStartY = -math_random(ANIMATION_RAINFALL_Y_START_MIN, ANIMATION_RAINFALL_Y_START_MAX)
  elseif animation == "rainfallRev" then -- 23.11.23 added new anim type
    fontString.distance = math_random(ANIMATION_RAINFALL_Y_MIN, ANIMATION_RAINFALL_Y_MAX)
    fontString.rainfallX = math_random(-ANIMATION_RAINFALL_X_MAX, ANIMATION_RAINFALL_X_MAX)
    fontString.rainfallStartY = -math_random(ANIMATION_RAINFALL_Y_START_MIN, ANIMATION_RAINFALL_Y_START_MAX)
  end

  animating[fontString] = true

  --print(NameplateSCT.db.global.yOffset,NameplateSCT.db.global.xOffset)

  -- start onupdate if it's not already running
  if NameplateSCT.frame:GetScript("OnUpdate") == nil then
    NameplateSCT.frame:SetScript("OnUpdate", AnimationOnUpdate)
  end
end

------------
-- EVENTS --
------------

local damageSpellEvents = {
  DAMAGE_SHIELD = true,
  SPELL_DAMAGE = true,
  SPELL_PERIODIC_DAMAGE = true,
  SPELL_BUILDING_DAMAGE = true,
  RANGE_DAMAGE = true
}

local missedSpellEvents = {
  SPELL_MISSED = true,
  SPELL_PERIODIC_MISSED = true,
  RANGE_MISSED = true,
  SPELL_BUILDING_MISSED = true
}

local healSpellEvents = {
  SPELL_HEAL = true,
  SPELL_PERIODIC_HEAL = true
}

local COMBATLOG_OBJECT_TYPE_PET = COMBATLOG_OBJECT_TYPE_PET or 0x00001000
local COMBATLOG_OBJECT_TYPE_GUARDIAN = COMBATLOG_OBJECT_TYPE_GUARDIAN or 0x00002000
local BITMASK_PETS = COMBATLOG_OBJECT_TYPE_PET + COMBATLOG_OBJECT_TYPE_GUARDIAN
local BITMASK_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE or 0x00000001

function NameplateSCT:PLAYER_TARGET_CHANGED()
  targetGuid = UnitGUID("target")
  --print(targetGuid)
end

local summonedUnitOwners = {}
local GetPlayerInfoByGUID=GetPlayerInfoByGUID
local clientLang = GetLocale()

CreateFrame("GameTooltip", "NSCT_GET_PET_OWNER_FRAME", nil, "GameTooltipTemplate") 
NSCT_GET_PET_OWNER_FRAME:SetOwner(UIParent, "ANCHOR_NONE") 

local function getPetOwner(petName,petGuid)
  --print("getPetOwner",petName,petGuid)
  local ownerName,ownerGuid,_petGuid,_petName,isPet,firstText, secondText
  if petGuid and summonedUnitOwners[petGuid] then
    ownerGuid=summonedUnitOwners[petGuid].guid
    ownerName=summonedUnitOwners[petGuid].name
    if not ownerName and ownerGuid and tonumber(dstGuid:sub(5, 5), 16) % 8 == 0 then 
      ownerName = select(6, GetPlayerInfoByGUID(ownerGuid))
      summonedUnitOwners[petGuid].name = ownerName
      --print('summonedUnitOwners[petGuid].name = ownerName')
    end
  elseif petName and clientLang:find("en") and petGuid then
    NSCT_GET_PET_OWNER_FRAME:ClearLines()
    --NSCT_GET_PET_OWNER_FRAME:SetUnit(petName)
    NSCT_GET_PET_OWNER_FRAME:SetHyperlink(format("unit:%s", petGuid))--test
    
    local text = _G["NSCT_GET_PET_OWNER_FRAMETextLeft2"] and _G["NSCT_GET_PET_OWNER_FRAMETextLeft2"]:GetText()
      if text then
        --print(text)
        firstText, secondText = string.split("'", text)
        if firstText and secondText and (secondText:find('s Minion') or secondText:find('s Construct') or secondText:find('s Totem') or secondText:find('s Pet') or secondText:find('s Guardian') or secondText:find('s Opponent') or secondText:find('s Runeblade') or secondText:find('s Vehicle')) then
          isPet=true
          --print(firstText,secondText)
          if UnitInRaid(firstText) then
            local raidMembers = GetNumRaidMembers()
            if raidMembers~=0 then
              for i=1,raidMembers do
                _petName=UnitName("raidpet"..i)
                if not _petName then break end
                if _petName==petName then 
                  ownerName=firstText 
                  ownerGuid=UnitGUID(ownerName)
                  _petGuid=UnitGUID("raidpet"..i)
                  if ownerGuid and _petGuid then
                    summonedUnitOwners[_petGuid] = { name = ownerName, guid = ownerGuid }
                    --print('pet '..ownerName..' owner: '..ownerName..'')
                  end
                  break
                end
              end
            end
          else
            if UnitInParty(firstText) then
              local partyMembers = GetNumPartyMembers()
              if partyMembers~=0 then
                for i=1,partyMembers do
                  _petName=UnitName("partypet"..i)
                  if not _petName then break end
                  if _petName==petName then 
                    ownerName=firstText 
                    ownerGuid=UnitGUID(firstText)
                    _petGuid=UnitGUID("partypet"..i)
                    if ownerGuid and _petGuid then
                      summonedUnitOwners[_petGuid] = { name = ownerName, guid = ownerGuid }
                      --print('pet '..petName..' owner: '..ownerName..'')
                    end
                    break
                  end
                end
              end
            else
              for i=1,10 do
                _petName=UnitName("arenapet"..i)
                if not _petName then break end
                if _petName==petName then 
                  ownerName=firstText 
                  ownerGuid=UnitGUID(firstText)
                  _petGuid=UnitGUID("arenapet"..i)
                  if ownerGuid and _petGuid then
                    summonedUnitOwners[_petGuid] = { name = ownerName, guid = ownerGuid }
                    --print('pet '..petName..' owner: '..ownerName..'')
                  end
                  break
                end
              end
            end
          end
        end
      end
  end
  
  -- if ownerName then
    -- print('pet: '..petName..' owner: '..(ownerName or 'hz')..'')
    -- elseif firstText then
    -- print('pet: '..petName..' owner: '..firstText..' (ne tochno)')
  -- end
  
  if not ownerName and petName and isPet and firstText then --test
    --print('NSCT: unknown owner of '..petName..', probably '..firstText) 
    return firstText
  end
  

  return ownerName,ownerGuid
end

local COMBATLOG_OBJECT_TYPE_PLAYER=COMBATLOG_OBJECT_TYPE_PLAYER
local function IsPlayer(flags,guid)
	return (flags and band(flags, COMBATLOG_OBJECT_TYPE_PLAYER)==COMBATLOG_OBJECT_TYPE_PLAYER) or (guid and (tonumber(guid:sub(5, 5), 16) % 8) == 0) 
end

function NameplateSCT:COMBAT_LOG_EVENT_UNFILTERED(_, _, clueevent, srcGUID, srcName, srcFlags, dstGUID, dstName, _, ...)
  
  --print(band(unitFlags,COMBATLOG_OBJECT_AFFILIATION_PARTY+COMBATLOG_OBJECT_AFFILIATION_RAID+COMBATLOG_OBJECT_AFFILIATION_MINE))
  
  if (clueevent == "SPELL_SUMMON" and not summonedUnitOwners[dstGUID] --[[and clientLang:find("en")]]) then
    --print('SPELL_SUMMON',srcName,dstName,dstGUID)
    summonedUnitOwners[dstGUID] = { name = srcName, guid = srcGUID }
  elseif ((clueevent == "UNIT_DIED" or clueevent == "UNIT_DESTROYED" or clueevent == "UNIT_DISSIPATES") and summonedUnitOwners[dstGUID] ) then
    --print(clueevent,srcName,dstName,dstGUID)
    summonedUnitOwners[dstGUID]=nil
  end
  
  local isPersonal = (playerGUID == dstGUID)

  if (self.db.global.personalOnly and self.db.global.personal and not isPersonal) then
    return
  end

  if (self.db.global.onlyTargetSCT and dstGUID ~= targetGuid and not isPersonal) then --28.12.23
    return
  end
  
  local showCasterNames =  ((isPersonal and self.db.global.showCasterNamesDamagePersonal) or (not isPersonal and self.db.global.showCasterNamesDamage))

  local srcIsPet = band(srcFlags, BITMASK_PETS) ~= 0

  local PetOwner,PetOwnerGuid
  local tmpName=srcName

  if (srcIsPet and (showCasterNames or self.db.global.enableWhitelist or self.db.global.enableBlacklist)) then
    PetOwner,PetOwnerGuid = getPetOwner(srcName,srcGUID)
    if PetOwner and PetOwnerGuid then
      tmpName=PetOwner
    end
  end

  local srcNameIsWhitelisted = (not self.db.global.enableWhitelist) or
      (srcName and (contains(self.db.global.namesWhitelist, tmpName:gsub("-.*$", "")) or (PetOwner and contains(self.db.global.namesWhitelist, PetOwner:gsub("-.*$", "")))))
  if (not isPersonal and not srcNameIsWhitelisted) then --28.12.23
    return
  end
  
  

  local srcNameIsBlacklisted = (not self.db.global.enableBlacklist) or
      (srcName and (contains(self.db.global.namesBlacklist, tmpName:gsub("-.*$", "")) or (PetOwner and contains(self.db.global.namesBlacklist, PetOwner:gsub("-.*$", "")))))
  if (not isPersonal and not srcNameIsBlacklisted) then --28.12.23
    return
  end
  
  -- test 11.4.24
  local dstNameIsWhitelisted = (not self.db.global.enableShowOnSpecificNameplatesByName) or
      (dstName and (contains(self.db.global.showOnSpecificNameplatesNameList, dstName:gsub("-.*$", "")) ))
  if (not isPersonal and not dstNameIsWhitelisted) then 
    return
  end
  


  if (playerGUID == srcGUID or (band(srcFlags, BITMASK_MINE) ~= 0) or (self.db.global.personal and playerGUID == dstGUID) or self.db.global.ShowOthersUnitsHitsOnNameplates) then -- 3.12.23
    if band(srcFlags, BITMASK_PETS) ~= 0 then                                                                                         -- Pet/Guardian events
      if damageSpellEvents[clueevent] or (healSpellEvents[clueevent] and self.db.global.heals and (not self.db.global.personalHealingOnly or (self.db.global.personalHealingOnly and playerGUID == dstGUID))) then
        local spellId, spellName, _, amount, overkill, _, _, _, _, critical, _, _, _, _, arg15 = ...
        self:DamageEvent(dstGUID, spellName, amount, "pet", critical, spellId, healSpellEvents[clueevent] and self.db.global.heals, srcGUID, tmpName, overkill)
        --print(clueevent,srcName)
        --if clueevent:find('SPELL_PERIODIC_HEAL') then
          --print(clueevent,srcName,dstName)
        --end
      elseif clueevent == "SWING_DAMAGE" then
        local amount, overkill, _, _, _, _, critical, _, _ = ...
        self:DamageEvent(dstGUID, AutoAttack, amount, "pet", critical, 6603, nil, srcGUID, tmpName, overkill)
        --print(clueevent,srcName)
      elseif missedSpellEvents[clueevent] then
        local spellId, spellName, school, missType, absorbAmount = ...
        --print(clueevent, spellId, spellName, school, missType, absorbAmount)
        if (missType == "ABSORB" and absorbAmount) then
          self:MissEvent(dstGUID, spellName, missType, spellId, "pet", absorbAmount)
          --print(clueevent,srcName)
        else
          self:MissEvent(dstGUID, spellName, missType, spellId, "pet")
          --print(clueevent,srcName)
        end
      elseif clueevent == "SWING_MISSED" then
        local missType, absorbAmount = ...
        --print("SWING_MISSED", missType, absorbAmount)
        if (missType == "ABSORB" and absorbAmount) then
          self:MissEvent(dstGUID, AutoAttack, missType, 6603, "pet", absorbAmount)
          --print(clueevent,srcName)
        else
          self:MissEvent(dstGUID, AutoAttack, missType, 6603, "pet")
          --print(clueevent,srcName)
        end
      end
    elseif damageSpellEvents[clueevent] or (healSpellEvents[clueevent] and self.db.global.heals and (not self.db.global.personalHealingOnly or (self.db.global.personalHealingOnly and playerGUID == dstGUID))) then -- 20.11.23 added personal healing only option
      local spellId, spellName, school, amount, overkill, _, arg7, _, _, critical, _, _ = ...
      if clueevent == "SPELL_HEAL" then critical = arg7 end -- 20.11.23 now we check heal crits correctly
      self:DamageEvent(dstGUID, spellName, amount, school, critical, spellId, healSpellEvents[clueevent] and self.db.global.heals, srcGUID, tmpName, overkill)
      --print(clueevent,srcName)
    elseif clueevent == "SWING_DAMAGE" then
      local amount, overkill, _, _, _, _, critical, _, _ = ...
      self:DamageEvent(dstGUID, AutoAttack, amount, AutoAttack, critical, 6603, nil, srcGUID, tmpName, overkill)
      --print(clueevent,srcName)
    elseif missedSpellEvents[clueevent] then
      local spellId, spellName, school, missType, absorbAmount = ...
      --print(missType)
      if (missType == "ABSORB" and absorbAmount) then
        self:MissEvent(dstGUID, spellName, missType, spellId, school, absorbAmount)
        --print(clueevent,srcName)
      else
        self:MissEvent(dstGUID, spellName, missType, spellId, school)
        --print(clueevent,srcName)
      end
    elseif clueevent == "SWING_MISSED" then
      local missType, absorbAmount = ...
      --print(missType)
      if (missType == "ABSORB" and absorbAmount) then
        self:MissEvent(dstGUID, AutoAttack, missType, 6603, AutoAttack, absorbAmount)
        --print(clueevent,srcName)
      else
        self:MissEvent(dstGUID, AutoAttack, missType, 6603, AutoAttack)
        --print(clueevent,srcName)
      end
    end
  end
end

-------------
-- DISPLAY --
-------------
local function commaSeperate(number)
  local _, _, minus, int, fraction = tostring(number):find("([-]?)(%d+)([.]?%d*)")
  int = int:reverse():gsub("(%d%d%d)", "%1,")
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

--++
local numDamageEvents = 0
local lastDamageEventTime
local runningAverageDamageEvents = 0
function NameplateSCT:DamageEvent(dstGuid, spellName, amount, school, crit, spellId, heals, srcGUID, srcName, overkill)
  local text, animation, pow, size, alpha, topMost, customTexture
  local autoattack = spellName == AutoAttack or spellName == AutoShot
  local isPersonal = dstGuid == playerGUID
  
  --print(dstGuid)
  
  if not isPersonal and self.db.global.hideMyHits then
    if srcGUID == playerGUID then
      return
    end
    if school == "pet" --[[or not IsPlayer(srcGUID)]] then
      local ownerName,ownerGuid=getPetOwner(srcName,srcGUID)
      if (ownerGuid and ownerGuid == playerGUID) or (ownerName and ownerName == _playerName) then
        return
      end
    end
  end

  -- select an animation
  if (self.db.global.displayOverkill and overkill > 0 and not isPersonal and not heals) then
    animation = "verticalUp"
  elseif (heals and not crit) then -- 23.11.23 + individual animation for healing
    animation = isPersonal and self.db.global.healAnimPersonal or self.db.global.healAnim
  elseif (crit) then
    animation = isPersonal and self.db.global.critAnimPersonal or self.db.global.critAnim
  else
    animation = isPersonal and self.db.global.damageAnimPersonal or self.db.global.damageAnim
  end

  -- skip if this damage event is disabled
  if (animation == "disabled") then 
    return 
  end

  -- 23.11.23 skip if spell is Blacklisted
  --print(self.db.global.spellBlacklistPersonal,self.db.global.spellBlacklistPersonal,spellName)
  if ((isPersonal and contains(self.db.global.spellBlacklistPersonal, spellName)) or (not isPersonal and contains(self.db.global.spellBlacklist, spellName))) then
    --print('skip if spell is Blacklisted')
    return
  end

  local isTarget = (UnitGUID("target") == dstGuid)

  if (isPersonal) then
    size = self.db.global.sizePersonal
    alpha = self.db.global.alphaPersonal
  elseif (self.db.global.useOffTarget and not isTarget) then
    size = self.db.global.offTargetFormatting.size
    alpha = self.db.global.offTargetFormatting.alpha
  else
    size = self.db.global.size
    alpha = self.db.global.alpha
  end

  local sizeIsRelativeToMaxHealth = (isPersonal and self.db.global.sizeIsRelativeToMaxHealthPersonal) or
      (not isPersonal and self.db.global.sizeIsRelativeToMaxHealth)
  local sizeMax = isPersonal and self.db.global.sizeMaxPersonal or self.db.global.sizeMax
  local sizeMin = isPersonal and self.db.global.sizeMinPersonal or self.db.global.sizeMin
  local CustomMaxHealthSizeIsRelativeTo = isPersonal and self.db.global.CustomMaxHealthSizeIsRelativeToPersonal or
      self.db.global.CustomMaxHealthSizeIsRelativeTo

  if sizeMax == 0 then sizeMax = size * 2 end

  if (sizeIsRelativeToMaxHealth) then
    local maxHealth -- Пример значения максимального запаса здоровья

    if (CustomMaxHealthSizeIsRelativeTo ~= 0) then
      maxHealth = CustomMaxHealthSizeIsRelativeTo
    else
      maxHealth = isPersonal and UnitHealthMax('player') or select(2, self:GetNameplateByGuidTest(dstGuid))
    end

    if (maxHealth ~= nil and maxHealth ~= 0) then
      -- Рассчитываем процент урона относительно максимального здоровья
      local percentDamage = amount / maxHealth * 100

      -- Рассчитываем размер шрифта, скалированный от 0% до 100% максимального здоровья
      size = size + (sizeMax - size) * percentDamage / 100
      --print('scaled size:',size,'maxHealth:',maxHealth,'sizeMax:',sizeMax)
    end
  end

  local truncate = (isPersonal and self.db.global.truncatePersonal) or (not isPersonal and self.db.global.truncate)
  local truncateLetter = (isPersonal and self.db.global.truncateLetterPersonal) or
      (not isPersonal and self.db.global.truncateLetter)
  local commaSeperate = (isPersonal and self.db.global.commaSeperatePersonal) or
      (not isPersonal and self.db.global.commaSeperate)

  -- truncate
  if (truncate and amount >= 1000000 and truncateLetter) then
    text = format("%.1fM", amount / 1000000)
  elseif (truncate and amount >= 10000) then
    text = format("%.0f", amount / 1000)

    if (truncateLetter) then
      text = text .. "k"
    end
  elseif (truncate and amount >= 100) then
    text = format("%.1f", amount / 1000)

    if (truncateLetter) then
      text = text .. "k"
    end
  else
    if (commaSeperate) then
      text = commaSeperate(amount)
    else
      text = tostring(amount)
    end
  end

  local OverridenDamageColor = isPersonal and self.db.global.OverridenDamageColorPersonal or
      self.db.global.OverridenDamageColor
  local useDamageTypeColor = (isPersonal and self.db.global.useDamageTypeColorPersonal) or
      (not isPersonal and self.db.global.useDamageTypeColor) or heals or autoattack
  --print(useDamageTypeColor,OverridenDamageColor)
  local useOverridenColorOnAutoattacks = (isPersonal and self.db.global.useOverridenColorOnAutoattacksPersonal) or
      (not isPersonal and self.db.global.useOverridenColorOnAutoattacks)

  if heals then school = "heals" end -- 18.11.23 heal color always green

  text = crit and text.."!" or text
  
  text = heals and "+"..text or "-"..text

  local textColor
  if (useDamageTypeColor and school and DAMAGE_TYPE_COLORS[school] and not (autoattack and useOverridenColorOnAutoattacks)) then
    --print(autoattack,DAMAGE_TYPE_COLORS[school], school)
    --text = "\124cff" .. DAMAGE_TYPE_COLORS[school] .. text .. "\124r"
    textColor = DAMAGE_TYPE_COLORS[school]
  else
    --text = "\124cff" .. OverridenDamageColor .. text .. "\124r"
    textColor = OverridenDamageColor
    if crit then
      textColor = "FF2200"
    end
  end
  

  local showCasterNames = (heals and ((isPersonal and self.db.global.showCasterNamesHealsPersonal) or (not isPersonal and self.db.global.showCasterNamesHeals))) or
      (not heals and ((isPersonal and self.db.global.showCasterNamesDamagePersonal) or (not isPersonal and self.db.global.showCasterNamesDamage)))
      
    
  if (showCasterNames and srcName) then
    if srcGUID == playerGUID then
      text = "|cff" .. textColor .. text .. " (me)|r" -- test 11.4.24
    elseif IsPlayer(nil,srcGUID) then
      text = "|cff" .. textColor .. text .. " (" .. colorName(srcName,nil,srcGUID,textColor,nil,nil,isPersonal) .. "|cff".. textColor..")|r" -- test 11.4.24
    else 
      local PetOwner,PetOwnerGuid = getPetOwner(srcName,srcGUID)
    
      if PetOwner and PetOwnerGuid and IsPlayer(nil,PetOwnerGuid) then
        text = "|cff" .. textColor .. text .. " (" .. colorName(PetOwner,nil,PetOwnerGuid,textColor,nil,nil,isPersonal) .. "'s pet|cff" .. textColor.. ")|r" 
      elseif PetOwner and PetOwnerGuid then
        text = "|cff" .. textColor .. text .. " (" .. colorName(PetOwner,nil,PetOwnerGuid,textColor,nil,nil,isPersonal) .. "'s pet|cff" .. textColor.. ")|r" -- test 11.4.24
      elseif school == "pet" then
        text = "|cff" .. textColor .. text .. " (pet)|r" -- test 11.4.24
      else
        text = "|cff" .. textColor .. text .. " (" .. shortName(srcName,isPersonal) .. ")|r" -- test 11.4.24
      end
    end
  else
    text = "|cff" .. textColor .. text .. "|r" -- test 11.4.24
  end
  
	if (self.db.global.displayOverkill and overkill > 0 and not isPersonal and not heals) then
		text = text .. " |cff" .. textColor .. " (overkill)|r"
	end

  --test priest shit 3.12.23
  -- if (mfTicksCountCurCast) then
    -- local mfTicksCount = mfTicksCountCurCast[playerGUID]
    -- if (mfTicksCount and srcGUID == playerGUID) then
      -- if (spellName == "Mind Flay") then
        -- --print(mfTicksCount)
        -- local t = "7ddd7d×1" -- orange
        -- if mfTicksCount == 2 then
          -- t = "5dee5d×2"     -- yellow
        -- elseif mfTicksCount == 3 then
          -- t = "1dff1d×3"     -- green
          -- customTexture = [[Interface\addons\CustomNameplatesMarks\texture\ayaya]]
        -- end
        -- text = text .. "\124cff" .. t .. "\124r"
        -- topMost = true
        -- animation = "verticalUp"
        -- size = size + (mfTicksCount * 5)
      -- elseif (not heals) then
        -- animation = "fountain"
      -- end
    -- end
  -- end
  --•·

  local smallHitMaxValueDamage = isPersonal and self.db.global.smallHitMaxValueDamagePersonal or
      self.db.global.smallHitMaxValueDamage
  local smallHitMaxValueHeal = isPersonal and self.db.global.smallHitMaxValueHealPersonal or
      self.db.global.smallHitMaxValueHeal
  --print(smallHitMaxValueDamage,smallHitMaxValueHeal)

  -- shrink small hits
  if (not isPersonal and overkill <= 0) then
    if srcGUID == playerGUID then
      if (not lastDamageEventTime or (lastDamageEventTime + self.db.global.SMALL_HIT_EXPIRY_WINDOW < GetTime())) then
        numDamageEvents = 0
        runningAverageDamageEvents = 0
      end

      runningAverageDamageEvents = ((runningAverageDamageEvents * numDamageEvents) + amount) / (numDamageEvents + 1)
      numDamageEvents = numDamageEvents + 1
      lastDamageEventTime = GetTime()
    end

    if (( --[[not crit and]] srcGUID == playerGUID and amount < self.db.global.SMALL_HIT_MULTIPIER * runningAverageDamageEvents) or (srcGUID == playerGUID and crit and amount / 2 < self.db.global.SMALL_HIT_MULTIPIER * runningAverageDamageEvents) or ( --[[not crit and]] not heals and amount <= self.db.global.smallHitMaxValueDamage) or ( --[[not crit and]] heals and amount <= self.db.global.smallHitMaxValueHeal)) then -- 23.11.23 
      if ((self.db.global.smallHitsDamageHide and not heals) or (heals and self.db.global.smallHitsHealHide)) then
        -- skip this damage event, it's too small
        --print('smallHitsDamageHide or smallHitsHealHide on np')
        return
      elseif (not topMost) then
        if (heals) then
          size = size * self.db.global.smallHitsHealScale -- 23.11.23
        else
          size = size * self.db.global.smallHitsDamageScale
        end
      end
    end
    -- 23.11.23 hide or shrink small hits for self
  elseif (isPersonal and ((not heals and amount <= self.db.global.smallHitMaxValueDamagePersonal) or (heals and amount <= self.db.global.smallHitMaxValueHealPersonal))) then
    if ((self.db.global.smallHitsDamageHidePersonal and not heals) or (self.db.global.smallHitsHealHidePersonal and heals)) then
      -- skip this damage event, it's too small
      --print('smallHitsDamageHidePersonal or smallHitsHealHidePersonal on self')
      return
    elseif (not heals) then
      size = size * self.db.global.smallHitsDamageScalePersonal
    else
      size = size * self.db.global.smallHitsHealScalePersonal
    end
  end
  
  if (self.db.global.displayOverkill and overkill > 0 and not isPersonal and not heals) then
    pow = true
  end

  local critsEmbiggen = (isPersonal and self.db.global.critsEmbiggenPersonal) or
      (not isPersonal and self.db.global.critsEmbiggen)
  local critsScale = isPersonal and self.db.global.critsScalePersonal or self.db.global.critsScale

  -- embiggen crit's size
  if (critsEmbiggen and crit) then
    if (not heals and amount > smallHitMaxValueDamage) or (heals and amount > smallHitMaxValueHeal) then
      size = size * critsScale
      --print('size * critsScale',size)
    end
    pow = true
  end

  -- make sure that size is larger than 5
  if (sizeMin ~= 0 and size < sizeMin) then
    size = sizeMin
  end

  --print(size)

  -- Ограничиваем размер шрифта, чтобы не превышать максимальный размер
  if (sizeMax ~= 0 and size > sizeMax) then
    --print('size > sizeMax',size,sizeMax)
    size = sizeMax
  end

  if (autoattack and school == "pet") then spellName = "pet" end -- 27.11.23

  self:DisplayText(dstGuid, text, size, alpha, animation, spellId, pow, spellName, topMost, customTexture, overkill, heals, crit)
end

--++
function NameplateSCT:MissEvent(guid, spellName, missType, spellId, school, absorbAmount)
  local text, pow, size, alpha, color
  local isTarget = (UnitGUID("target") == guid)
  local isPersonal = guid == playerGUID
  local autoattack = spellName == AutoAttack or spellName == AutoShot
  local OverridenDamageColor = (isPersonal and self.db.global.OverridenDamageColorPersonal) or (not isPersonal and self.db.global.OverridenDamageColor)
  local useDamageTypeColor = (isPersonal and self.db.global.useDamageTypeColorPersonal) or (not isPersonal and self.db.global.useDamageTypeColor) or autoattack
  local animation = (isPersonal and self.db.global.missAnimPersonal) or (not isPersonal and self.db.global.missAnim)
  local useOverridenColorOnAutoattacks = (isPersonal and self.db.global.useOverridenColorOnAutoattacksPersonal) or (not isPersonal and self.db.global.useOverridenColorOnAutoattacks)

  -- No animation set, cancel out
  if (animation == "disabled") then
    --print(animation,'return')
    return
  end
  
  --print(isPersonal,self.db.global.missAnim)

  if (useDamageTypeColor and school and DAMAGE_TYPE_COLORS[school] and not (autoattack and useOverridenColorOnAutoattacks)) then
    --color = "ffffff" -- 19.11.23 AutoAttack/AutoShot color always white
    color = DAMAGE_TYPE_COLORS[school]
  else
    color = OverridenDamageColor
  end

  if (isPersonal) then
    size = self.db.global.sizePersonal
    alpha = self.db.global.alphaPersonal
  elseif (self.db.global.useOffTarget and not isTarget) then
    size = self.db.global.offTargetFormatting.size
    alpha = self.db.global.offTargetFormatting.alpha
  else
    size = self.db.global.size
    alpha = self.db.global.alpha
  end

  local missEmbiggen = (isPersonal and self.db.global.missEmbiggenPersonal) or
      (not isPersonal and self.db.global.missEmbiggen)
  local missScale = isPersonal and self.db.global.missScalePersonal or self.db.global.missScale
  --print(isPersonal,self.db.global.missEmbiggenPersonal,self.db.global.missEmbiggen)
  -- embiggen miss size
  if missEmbiggen then
    size = size * missScale
    pow = true
  end

  local showAbsorbAmount = (isPersonal and self.db.global.showAbsorbAmountPersonal) or (not isPersonal and self.db.global.showAbsorbAmount)
  text = MISS_EVENT_STRINGS[missType] or ACTION_SPELL_MISSED_MISS
  if showAbsorbAmount and absorbAmount then text = text .. " (" .. absorbAmount .. ")" end
  text = "\124cff" .. color .. text .. "\124r"

  if (autoattack and (spellName == "pet" or school == "pet")) then spellName = "pet" end -- 27.11.23

  self:DisplayText(guid, text, size, alpha, animation, spellId, pow, spellName)
end

function NameplateSCT:GetNameplateByGuid(guid)
  local plate = (guid == playerGUID) and "player" or nil
  if not plate and UnitExists("target") and not UnitIsUnit("target", "player") and UnitGUID("target") == guid then
    plate = LibNameplates:GetTargetNameplate()
  end
  return plate or LibNameplates:GetNameplateByGUID(guid)
end

--++
function NameplateSCT:GetNameplateByGuidTest(guid) -- 18.11.23
  local nameplate = (guid == playerGUID) and "player" or nil
  local healthMax

  if not nameplate then
    local nameplateToken

    for i = 1, 500 do
      local unit = "nameplate" .. i .. ""
      local g = UnitGUID(unit)
      if g == nil then break end
      if (g and guid == g) then
        nameplateToken = unit
        healthMax = UnitHealthMax(unit)
        break -- 18.11.23
      end
    end

    -- 18.11.23 awesome wotlk api
    if (C_NamePlate) then
      if (nameplateToken ~= nil) then
        nameplate = C_NamePlate.GetNamePlateForUnit(nameplateToken)
      end
    else
      nameplate = self:GetNameplateByGuid(guid)
    end
  end

  return nameplate, healthMax
end

--++
function NameplateSCT:DisplayText(guid, text, size, alpha, animation, spellId, pow, spellName, topMost, customTexture, overkill, heals, crit)
  local fontString, icon, texture

  local nameplate --= self:GetNameplateByGuidTest(guid) -- 18.11.23 adaptation for awesome wotlk
  
  local isPersonal = playerGUID == guid
  
  if (self.db.global.displayOverkill and overkill > 0 and not isPersonal) then
    nameplate = "player"
  else
    nameplate = self:GetNameplateByGuidTest(guid)
  end

  if not nameplate then return end
  --print(nameplate)

  fontString = getFontString(guid, topMost)

  fontString.NSCTText = text
  fontString:SetText(fontString.NSCTText)

  local textShadow = (isPersonal and self.db.global.textShadowPersonal) or (not isPersonal and self.db.global.textShadow)
  local font = isPersonal and self.db.global.fontPersonal or self.db.global.font
  local fontFlag = isPersonal and self.db.global.fontFlagPersonal or self.db.global.fontFlag
  local showIcon = (isPersonal and self.db.global.showIconPersonal) or (not isPersonal and self.db.global.showIcon)
  local iconScale = isPersonal and self.db.global.iconScalePersonal or self.db.global.iconScale
  local iconPosition = isPersonal and self.db.global.iconPositionPersonal or self.db.global.iconPosition
  local xOffsetIcon = isPersonal and self.db.global.xOffsetIconPersonal or self.db.global.xOffsetIcon
  local yOffsetIcon = isPersonal and self.db.global.yOffsetIconPersonal or self.db.global.yOffsetIcon
  local animationspeed = isPersonal and self.db.global.animationspeedPersonal or self.db.global.animationspeed

  fontString.NSCTFontSize = size
  fontString:SetFont(getFontPath(font), fontString.NSCTFontSize, fontFlag)
  if textShadow then
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowOffset(0, 0)
  end
  fontString.startHeight = fontString:GetStringHeight()
  fontString.pow = pow

  if (fontString.startHeight <= 0) then
    fontString.startHeight = 5
  end

  fontString.guid = guid

  --print(spellName)

  if (customTexture) then -- 3.12.23
    texture = customTexture
    --print(customTexture)
    -- 27.11.23 autoattack/autoshot/petattack icons
  elseif (spellName == "pet") then
    texture = [=[Interface\Icons\Ability_GhoulFrenzy]=]
  elseif (spellName == AutoAttack) then
    texture = [=[Interface\icons\INV_Sword_04]=]
  elseif (spellName == AutoShot) then
    texture = [=[Interface\Icons\INV_Weapon_Bow_05]=]
  else
    texture = select(3, GetSpellInfo(spellId or spellName))
    if not texture and spellName then
      texture = select(3, GetSpellInfo(spellName))
    end
  end

  --fontString=nil
  --print(size)
  
  local t = crit and 3.0 or 2.5

  if isPersonal and NameplateSCT.db.global.enableSimpleStylePersonalSct then
    --print(size)
    if heals then
      func_heal("|T" .. texture .. ":12|t " ..text,{1,0,0},nil,t,nil,nil,false,false,nil,nil,nil,size or 12)
    else
      func_dmg("|T" .. texture .. ":12|t " ..text,{1,0,0},nil,t,nil,nil,false,false,nil,nil,nil,size or 12)
    end
    --fontString=nil
  else
    if showIcon and texture then
      icon = fontString.icon
      icon:Show()
      icon:SetTexture(texture)
      icon:SetSize(size * iconScale, size * iconScale)
      icon:SetPoint(inversePositions[iconPosition], fontString, iconPosition,
        xOffsetIcon, yOffsetIcon)
      icon:SetAlpha(alpha)
      fontString.icon = icon
    elseif fontString.icon then
      fontString.icon:Hide()
    end

    -- 3.12.23
    if topMost then
      fontString.topMost = topMost
      --print(fontString.topMost)
    end

    self:Animate(fontString, nameplate, animationspeed, animation)
    --fontString=nil
  end
end

function NameplateSCTDisplayText(guid, text, size, alpha, animation, spellId, pow, spellName, topMost, customTexture)
  NameplateSCT:DisplayText(guid, text, size, alpha, animation, spellId, pow, spellName, topMost, customTexture)
end

-------------
-- OPTIONS --
-------------

local addonDisabled = function()
  return not NameplateSCT.db.global.enabled
end

local menu = {
  name = "NameplateSCT \124c00ffffffBackported\124r by \124cfff58cbaKader\124r",
  handler = NameplateSCT,
  type = "group",
  get = function(i)
    return NameplateSCT.db.global[i[#i]]
  end,
  set = function(i, val)
    NameplateSCT.db.global[i[#i]] = val
  end,
  args = {
    nameplatesEnabled = {
      type = "description",
      name = "\124cFFFF0000" .. L["YOUR ENEMY NAMEPLATES ARE DISABLED, NAMEPLATESCT WILL NOT WORK!!"] .. "\124r",
      hidden = function()
        return GetCVar("nameplateShowEnemies") == "1"
      end,
      order = 1,
      width = "double"
    },
    enable = {
      type = "toggle",
      name = L["Enable"],
      desc = L["If the addon is enabled."],
      get = "IsEnabled",
      set = function(_, val)
        if val then
          NameplateSCT:Enable()
        else
          NameplateSCT:Disable()
        end
      end,
      order = 2
    },
    heals = {
      type = "toggle",
      name = L["Include Heals"],
      desc = L["Also show numbers when you heal"],
      order = 3
    },
    personal = {
      type = "toggle",
      name = L["Personal SCT"],
      desc = L["Also show numbers when you take damage on your personal nameplate or center screen"],
      disabled = addonDisabled,
      order = 4
    },
    personalOnly = {
      type = "toggle",
      name = L["Personal SCT Only"],
      desc = L["Don't display any numbers on enemies and only use the personal SCT."],
      disabled = function()
        return (not NameplateSCT.db.global.personal or not NameplateSCT.db.global.enabled)
      end,
      order = 5
    },
    personalHealingOnly = { -- 20.11.23 added personal healing only option
      type = "toggle",
      name = "|cff55ff55Do not show heals for nameplates|r",
      desc = "Only personal heals SCT",
      order = 6,
      width = "double"
    },
    ShowOthersUnitsHitsOnNameplates = { -- 3.12.23
      type = "toggle",
      name = "|cffff8811Show all units hits (TEST)|r",
      desc = "TEST",
      order = 7,
      width = "double"
    },
    onlyTargetSCT = {
      type = "toggle",
      name = "|cffff8811Only target SCT|r",
      --desc = "TEST",
      order = 8,
      --width = "double"
    },
		displayOverkill = {
			type = 'toggle',
			name = "Display Overkill",
			desc = "Display your overkill for a target over your own nameplate",
			order = 9,
		},
    hideMyHits = {
			type = 'toggle',
			name = "Hide my hits",
			desc = "Hide my hits",
			order = 10,
		},
    enableClassColorCasterNames = {
			type = 'toggle',
			name = "Class color caster names",
			desc = "Class color caster names",
			order = 11,
		},
    enableSimpleStylePersonalSct = {
			type = 'toggle',
			name = "enableSimpleStylePersonalSct",
			desc = "enableSimpleStylePersonalSct",
			order = 12,
		},

    animations = {
      type = "group",
      name = "NAMEPLATES ANIMATIONS",
      order = 20,
      inline = true,
      disabled = addonDisabled,
      get = function(i)
        return NameplateSCT.db.global[i[#i]]
      end,
      set = function(i, val)
        NameplateSCT.db.global[i[#i]] = val
      end,
      args = {
        spellBlacklist = { -- added 22.11.23
          order = 400,
          type = "input",
          width = "full",
          multiline = true,
          desc = "Spell names, separated by \";\" without space",
          name = "|cffffaa00Blacklisted spells for nameplates, separated by \";\" without space|r",
          get = function()
            return table.concat(NameplateSCT.db.global.spellBlacklist or {}, ";")
          end,
          set = function(info, value)
            NameplateSCT.db.global.spellBlacklist = {}
            for spell in string.gmatch(value, "([^;]+)") do
              table.insert(NameplateSCT.db.global.spellBlacklist, spell)
              --print(spell)
            end
          end,
        },

        animationExConstants = {
          type = "group",
          name = "Animation ex constants (nameplates)",
          order = 500,
          inline = true,
          args = {
            SMALL_HIT_EXPIRY_WINDOW = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55SMALL_HIT_EXPIRY_WINDOW|r",
              desc = "default:30",
              min = 0,
              max = 500,
              step = 1,
              order = 2,
              width = "double"
            },
            SMALL_HIT_MULTIPIER = { -- added 23.11.23
              type = "range",
              name = "|cffff5555SMALL_HIT_MULTIPIER|r",
              desc = "default:0.5",
              min = 0,
              max = 10,
              step = 0.1,
              order = 3,
              width = "double"
            },
            ANIMATION_VERTICAL_DISTANCE_MIN = { -- added 23.11.23
              type = "range",
              name = "|cff5555ffANIMATION_VERTICAL_DISTANCE_MIN|r",
              desc = "default:75, must be < than ANIMATION_VERTICAL_DISTANCE_MAX",
              min = 0,
              max = 500,
              step = 1,
              order = 4,
              width = "double"
            },
            ANIMATION_VERTICAL_DISTANCE_MAX = { -- added 27.11.23
              type = "range",
              name = "|cff5555ffANIMATION_VERTICAL_DISTANCE_MAX|r",
              desc = "default:75, must be > than ANIMATION_VERTICAL_DISTANCE_MIN",
              min = 0,
              max = 500,
              step = 1,
              order = 5,
              width = "double"
            },
            ANIMATION_ARC_X_MIN = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_ARC_X_MIN",
              desc = "default:50, must be < than ANIMATION_ARC_X_MAX",
              min = 0,
              max = 500,
              step = 1,
              order = 6,
              width = "double"
            },
            ANIMATION_ARC_X_MAX = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_ARC_X_MAX",
              desc = "default:150, must be > than ANIMATION_ARC_X_MIN",
              min = 0,
              max = 500,
              step = 1,
              order = 7,
              width = "double"
            },
            ANIMATION_ARC_Y_TOP_MIN = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55ANIMATION_ARC_Y_TOP_MIN|r",
              desc = "default:10, must be < than ANIMATION_ARC_Y_TOP_MAX",
              min = 0,
              max = 500,
              step = 1,
              order = 8,
              width = "double"
            },
            ANIMATION_ARC_Y_TOP_MAX = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55ANIMATION_ARC_Y_TOP_MAX|r",
              desc = "default:50, must be > than ANIMATION_ARC_Y_TOP_MIN",
              min = 0,
              max = 500,
              step = 1,
              order = 9,
              width = "double"
            },
            ANIMATION_ARC_Y_BOTTOM_MIN = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_ARC_Y_BOTTOM_MIN|r",
              desc = "default:10, must be < than ANIMATION_ARC_Y_BOTTOM_MAX",
              min = -500,
              max = 500,
              step = 1,
              order = 10,
              width = "double"
            },
            ANIMATION_ARC_Y_BOTTOM_MAX = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_ARC_Y_BOTTOM_MAX|r",
              desc = "default:50, must be > than ANIMATION_ARC_Y_BOTTOM_MIN",
              min = -500,
              max = 500,
              step = 1,
              order = 11,
              width = "double"
            },
            ANIMATION_RAINFALL_X_MAX = { -- added 23.11.23
              type = "range",
              name = "|cff5555ffANIMATION_RAINFALL_X_MAX|r",
              desc = "default:75, no MIN available for this value",
              min = 0,
              max = 500,
              step = 1,
              order = 12,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_MIN = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_RAINFALL_Y_MIN",
              desc = "default:50, must be < than ANIMATION_RAINFALL_Y_MAX",
              min = -500,
              max = 500,
              step = 1,
              order = 13,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_MAX = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_RAINFALL_Y_MAX",
              desc = "default:100, must be > than ANIMATION_RAINFALL_Y_MIN",
              min = -500,
              max = 500,
              step = 1,
              order = 14,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_START_MIN = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_RAINFALL_Y_START_MIN|r",
              desc = "default:5, must be < than ANIMATION_RAINFALL_Y_START_MAX",
              min = -500,
              max = 500,
              step = 1,
              order = 15,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_START_MAX = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_RAINFALL_Y_START_MAX|r",
              desc = "default:15, must be > than ANIMATION_RAINFALL_Y_START_MIN",
              min = -500,
              max = 500,
              step = 1,
              order = 16,
              width = "double"
            },
          }
        },

        enableWhitelist = { -- added 28.12.23
          type = "toggle",
          name = "|cffff8811Enable names(src names) whitelist (for show-all-units-hits option)|r",
          desc = "Show SCT only from names(src names) from whitelist (when all units hits enabled)",
          order = 595,
          width = "double"
        },

        namesWhitelist = { -- added 28.12.23
          order = 600,
          type = "input",
          width = "full",
          multiline = true,
          desc = "Names(src names) to show only their SCT (when all units hits enabled), separated by \";\" without space|r",
          name = "|cffffaa00Names whitelist(src names), separated by \";\" without space|r",
          get = function()
            return table.concat(NameplateSCT.db.global.namesWhitelist or {}, ";")
          end,
          set = function(info, value)
            NameplateSCT.db.global.namesWhitelist = {}
            for name in string.gmatch(value, "([^;]+)") do
              table.insert(NameplateSCT.db.global.namesWhitelist, name)
            end
          end,
        },

        enableBlacklist = { -- added 28.12.23
          type = "toggle",
          name = "|cffff8811Enable names(src names) blacklist (for show-all-units-hits option)|r",
          desc = "Show SCT only from names(src names) from whitelist (when all units hits enabled)",
          order = 605,
          width = "double"
        },

        namesBlacklist = { -- added 28.12.23
          order = 610,
          type = "input",
          width = "full",
          multiline = true,
          desc = "Names blacklist(src names) to do not show their SCT (when all units hits enabled), separated by \";\" without space",
          name = "|cffffaa00Names blacklist(src names), separated by \";\" without space|r",
          get = function()
            return table.concat(NameplateSCT.db.global.namesBlacklist or {}, ";")
          end,
          set = function(info, value)
            NameplateSCT.db.global.namesBlacklist = {}
            for name in string.gmatch(value, "([^;]+)") do
              table.insert(NameplateSCT.db.global.namesBlacklist, name)
            end
          end,
        },
        
        
        
        enableShowOnSpecificNameplatesByName = { -- added 11.4.24
          type = "toggle",
          name = "|cffff8811Enable show SCT on specific nameplates by their names(dst names)|r",
          desc = "|cffff8811Enable show SCT on specific nameplates by their names(dst names)|r",
          order = 601,
          width = "double"
        },

        showOnSpecificNameplatesNameList = { -- added 11.4.24
          order = 602,
          type = "input",
          width = "full",
          multiline = true,
          desc = "Names to show only their received dmg and heal(dst names list), separated by \";\" without space|r",
          name = "Names to show only their received dmg and heal(dst names list), separated by \";\" without space|r",
          get = function()
            return table.concat(NameplateSCT.db.global.showOnSpecificNameplatesNameList or {}, ";")
          end,
          set = function(info, value)
            NameplateSCT.db.global.showOnSpecificNameplatesNameList = {}
            for name in string.gmatch(value, "([^;]+)") do
              table.insert(NameplateSCT.db.global.showOnSpecificNameplatesNameList, name)
            end
          end,
        },
        
        

        animationspeed = {
          type = "range",
          name = "Animation speed (nameplates)",
          desc = L["Default speed: 1"],
          min = 0.5,
          max = 5,
          step = .01,
          order = 1,
          width = "double"
        },
        damageAnim = {
          type = "select",
          name = "|cffff5555Damage|r",
          values = animationValues,
          order = 2,
        },
        healAnim = { -- 23.11.23 + individual animation for healing
          type = "select",
          name = "|cff55ff55Healing|r",
          values = animationValues,
          order = 3
        },
        critAnim = {
          type = "select",
          name = L["Criticals"],
          values = animationValues,
          order = 4
        },
        missAnim = {
          type = "select",
          name = L["Miss/Parry/Dodge/etc"],
          values = animationValues,
          order = 5
        },


        formatting = {
          type = "group",
          name = "Text Formatting (nameplates)",
          order = 28,
          inline = true,
          disabled = addonDisabled,
          args = {
            font = {
              type = "select",
              dialogControl = "LSM30_Font",
              name = L["Font"],
              values = AceGUIWidgetLSMlists.font,
              order = 1
            },
            fontFlag = {
              type = "select",
              name = L["Font Flags"],
              values = fontFlags,
              order = 2
            },
            textShadow = {
              type = "toggle",
              name = L["Text Shadow"],
              order = 3
            },
            useDamageTypeColor = {
              type = "toggle",
              name = L["Use Damage Type Color"],
              order = 4
            },
            OverridenDamageColor = {
              type = "color",
              name = "Overriden damage color",
              disabled = function()
                return NameplateSCT.db.global.useDamageTypeColor
              end,
              hasAlpha = false,
              set = function(_, r, g, b)
                NameplateSCT.db.global.OverridenDamageColor = rgbToHex(r, g, b)
              end,
              get = function()
                return hexToRGB(NameplateSCT.db.global.OverridenDamageColor)
              end,
              order = 5
            },
            useOverridenColorOnAutoattacks = {
              type = "toggle",
              name = "Overriden Color On Autoattacks",
              order = 6,
              width = "double"
            },
            truncate = {
              type = "toggle",
              name = L["Truncate Number"],
              order = 7
            },
            truncateLetter = {
              type = "toggle",
              name = L["Show Truncated Letter"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.truncate
              end,
              order = 8
            },
            commaSeperate = {
              type = "toggle",
              name = L["Comma Seperate"],
              desc = "100000 -> 100,000",
              disabled = function()
                return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.truncate
              end,
              order = 9
            },
            size = {
              type = "range",
              name = L["Size"],
              min = 5,
              max = 72,
              step = 1,
              get = function()
                return NameplateSCT.db.global.size
              end,
              set = function(_, val)
                NameplateSCT.db.global.size = val
              end,
              order = 10
            },
            alpha = {
              type = "range",
              name = L["Alpha"],
              min = 0.1,
              max = 1,
              step = .01,
              get = function()
                return NameplateSCT.db.global.alpha
              end,
              set = function(_, val)
                NameplateSCT.db.global.alpha = val
              end,
              order = 11
            },
            useOffTarget = {
              type = "toggle",
              name = "Use Seperate Off-Target Text Appearance:",
              order = 12,
              width = "double"
            },
            offTarget = {
              type = "group",
              name = L["Off-Target Text Appearance"],
              hidden = function()
                return not NameplateSCT.db.global.useOffTarget
              end,
              order = 13,
              inline = true,
              get = function(i)
                return NameplateSCT.db.global.offTargetFormatting[i[#i]]
              end,
              set = function(i, val)
                NameplateSCT.db.global.offTargetFormatting[i[#i]] = val
              end,
              args = {
                size = {
                  type = "range",
                  name = L["Size"],
                  min = 5,
                  max = 72,
                  step = 1,
                  order = 1
                },
                alpha = {
                  type = "range",
                  name = L["Alpha"],
                  min = 0.1,
                  max = 1,
                  step = .01,
                  order = 2
                }
              }
            }
          }
        },


        appearance = {
          type = "group",
          name = "Appearance/Offsets (nameplates)",
          order = 29,
          inline = true,
          disabled = addonDisabled,
          args = {
            xOffset = {
              type = "range",
              name = L["X Offset"],
              desc = L["Has soft max/min, you can type whatever you'd like into the editbox"],
              softMin = -75,
              softMax = 75,
              step = 1,
              order = 1,
              width = "double"
            },
            yOffset = {
              type = "range",
              name = L["Y Offset"],
              desc = L["Has soft max/min, you can type whatever you'd like into the editbox"],
              softMin = -75,
              softMax = 75,
              step = 1,
              order = 2,
              width = "double"
            },
            yOffsetForVerticalDownAnim = { -- 19.11.23 test
              type = "range",
              name = "|cffffff55Y offset for vertical down animation|r",
              desc = "test",
              softMin = -75,
              softMax = 75,
              step = 1,
              order = 3,
              width = "double"
            },
            yOffsetForVerticalUpAnim = { -- 28.11.23  test
              type = "range",
              name = "|cffffff55Y offset for vertical up animation|r",
              desc = "test",
              softMin = -75,
              softMax = 75,
              step = 1,
              order = 3,
              width = "double"
            },
            smallHitMaxValueDamage = { -- added 23.11.23
              type = "range",
              name = "|cffff5555Max small damage hit value|r",
              desc = "",
              min = 0,
              max = 10000,
              step = 10,
              order = 4,
              width = "double"
            },
            smallHitMaxValueHeal = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55Max small heal hit value|r",
              desc = "",
              min = 0,
              max = 10000,
              step = 10,
              order = 5,
              width = "double"
            },
            smallHitsDamageHide = {
              type = "toggle",
              name = "|cffff5555Hide small damage hits|r",
              desc = "Hide hits that are below a running average of your recent damage output",
              order = 6
            },
            smallHitsHealHide = { -- added 23.11.23
              type = "toggle",
              name = "|cff00ff55Hide small heal hits|r",
              desc = "Hide hits that are below a running average of your recent heal output",
              order = 7
            },
            modOffTargetStrata = {
              type = "toggle",
              name = L["Use Separate Off-Target Strata"],
              order = 8,
              width = "double"
            },
            targetStrata = {
              type = "select",
              name = L["Target Strata"],
              get = function()
                return NameplateSCT.db.global.strata.target
              end,
              set = function(_, val)
                NameplateSCT.db.global.strata.target = val
                adjustStrata()
              end,
              values = stratas,
              order = 9
            },
            offTarget = {
              type = "select",
              name = L["Off-Target Strata"],
              disabled = function()
                return not NameplateSCT.db.global.modOffTargetStrata
              end,
              get = function()
                return NameplateSCT.db.global.strata.offTarget
              end,
              set = function(_, val)
                NameplateSCT.db.global.strata.offTarget = val
              end,
              values = stratas,
              order = 10
            },
            showCasterNamesDamage = {
              type = "toggle",
              name = "|cffff5555Show caster names (damage)|r",
              desc = "",
              order = 11,
              width = "double"
            },
            showCasterNamesHeals = {
              type = "toggle",
              name = "|cff00ff55Show caster names (heals)|r",
              desc = "",
              order = 12,
              width = "double"
            },
            showAbsorbAmount = {
              type = "toggle",
              name = "Show absorb amount",  
              desc = "",
              order = 13,
              width = "double"
            },
            CasterNamesMaxLength = { 
              type = "range",
              name = "CasterNamesMaxLength",
              desc = "",
              min = 2,
              max = 12,
              step = 1,
              order = 14,
              width = "double"
            },
          }
        },

        iconAppearance = {
          type = "group",
          name = "Icons (nameplates)",
          order = 30,
          inline = true,
          args = {
            showIcon = {
              type = "toggle",
              name = L["Display Icon"],
              order = 1,
              width = "double"
            },
            iconScale = {
              type = "range",
              name = L["Icon Scale"],
              desc = L["Scale of the spell icon"],
              softMin = 0.5,
              softMax = 2,
              isPercent = true,
              step = 0.01,
              hidden = function()
                return not NameplateSCT.db.global.showIcon
              end,
              order = 2,
              width = "Half"
            },
            iconPosition = {
              type = "select",
              name = L["Position"],
              hidden = function()
                return not NameplateSCT.db.global.showIcon
              end,
              values = positionValues,
              order = 3
            },
            xOffsetIcon = {
              type = "range",
              name = L["Icon X Offset"],
              hidden = function()
                return not NameplateSCT.db.global.showIcon
              end,
              softMin = -30,
              softMax = 30,
              step = 1,
              order = 4,
              width = "Half"
            },
            yOffsetIcon = {
              type = "range",
              name = L["Icon Y Offset"],
              hidden = function()
                return not NameplateSCT.db.global.showIcon
              end,
              softMin = -30,
              softMax = 30,
              step = 1,
              order = 5,
              width = "Half"
            }
          }
        },

        sizing = {
          type = "group",
          name = "Sizing modifiers (nameplates)",
          order = 31,
          inline = true,
          disabled = function()
            return not NameplateSCT.db.global.enabled
          end,
          get = function(i)
            return NameplateSCT.db.global[i[#i]]
          end,
          set = function(i, val)
            NameplateSCT.db.global[i[#i]] = val
          end,
          args = {
            critsEmbiggen = {
              type = "toggle",
              name = L["Embiggen Crits"],
              order = 1
            },
            critsScale = {
              type = "range",
              name = L["Embiggen Crits Scale"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.critsEmbiggen
              end,
              min = 1,
              max = 3,
              step = .01,
              order = 2,
              width = "double"
            },
            powSizingMax = { -- 7.12.23
              type = "range",
              name = "Embiggen crits max pow sizing",
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.critsEmbiggen
              end,
              min = 1,
              max = 5,
              step = .01,
              order = 3,
              width = "double"
            },
            missEmbiggen = {
              type = "toggle",
              name = L["Embiggen Miss/Parry/Dodge/etc"],
              order = 4,
              width = "double"
            },
            missScale = {
              type = "range",
              name = L["Embiggen Miss/Parry/Dodge/etc Scale"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.missEmbiggen
              end,
              min = 0.5, -- 19.11.23 now we can make it smaller
              max = 3,
              step = .01,
              order = 5,
              width = "double"
            },
            smallHitsDamageScale = {
              type = "range",
              name = "|cffff5555Small damage hits scale|r",
              min = 0.33,
              max = 1,
              step = .01,
              order = 6,
              width = "double"
            },
            smallHitsHealScale = { -- 23.11.23
              type = "range",
              name = "|cff00ff55Small heal hits scale|r",
              min = 0.33,
              max = 1,
              step = .01,
              order = 7,
              width = "double"
            },
            sizeIsRelativeToMaxHealth = { -- 28.11.23
              type = "toggle",
              name = "Text size is relative to max health",
              desc = "The higher the damage or healing value, the larger the text size will be",
              order = 8,
              width = "double"
            },
            -- sizeMax = { -- 28.11.23
            -- type = "range",
            -- name = "Text max size",
            -- desc = "If 0 then max size will be: size*2",
            -- min = 0,
            -- max = 72,
            -- step = 1,
            -- get = function()
            -- return NameplateSCT.db.global.sizeMax
            -- end,
            -- set = function(_, val)
            -- NameplateSCT.db.global.sizeMax = val
            -- end,
            -- order = 9,
            -- width = "double"
            -- },
            sizeMax = { -- 28.11.23
              type = "range",
              name = "Text max size",
              --desc = "If 0 then max size will be: size*2",
              --min = 0,
              min = 5,
              max = 72,
              step = 1,
              get = function()
                if NameplateSCT.db.global.sizeMax >= NameplateSCT.db.global.size then
                  return NameplateSCT.db.global.sizeMax
                else
                  return NameplateSCT.db.global.size
                end
              end,
              set = function(_, val)
                local v = val
                if v < NameplateSCT.db.global.size then 
                  print('|cffff0000NameplateSCT: \'sizeMax\' you set ('..v..') has smaller value than \'size\' ('..NameplateSCT.db.global.size..'), set \'sizeMax\' to \'size\'|r')
                  v = NameplateSCT.db.global.size 
                end
                NameplateSCT.db.global.sizeMax = v
              end,
              order = 9,
              width = "double"
            },
            sizeMin = { -- 28.12.23
              type = "range",
              name = "Text min size",
              --desc = "",
              min = 5,
              max = 100,
              step = 1,
              get = function()
                if NameplateSCT.db.global.sizeMin <= NameplateSCT.db.global.size then
                  return NameplateSCT.db.global.sizeMin
                else
                  return NameplateSCT.db.global.size
                end
              end,
              set = function(_, val)
                local v = val
                if v > NameplateSCT.db.global.size then 
                  print('|cffff0000NameplateSCT: \'sizeMin\' you set ('..v..') has bigger value than \'size\' ('..NameplateSCT.db.global.size..'), set \'sizeMin\' to \'size\'|r')
                  v = NameplateSCT.db.global.size 
                end
                NameplateSCT.db.global.sizeMin = v
              end,
              order = 10,
              width = "double"
            },
            CustomMaxHealthSizeIsRelativeTo = { -- 28.11.23
              type = "range",
              name = "Custom max health (text size is relative to)",
              desc = "If 0 then max health will be your max health or your target's max health",
              min = 0,
              max = 200000,
              step = 100,
              order = 11,
              width = "double"
            },
          }
        },
      }
    },


    animationsPersonal = {
      type = "group",
      name = "PERSONAL SCT ANIMATIONS",
      order = 21,
      inline = true,
      hidden = function()
        return not NameplateSCT.db.global.personal
      end,
      disabled = addonDisabled,
      args = {
        animationspeedPersonal = { -- 23.11.23 + individual animation speed for self
          type = "range",
          name = "|cff00ff55Animation speed (personal)|r",
          desc = L["Default speed: 1"],
          min = 0.5,
          max = 3,
          step = .1,
          order = 1,
          width = "double"
        },
        normalPersonal = {
          type = "select",
          name = "Damage",
          get = function()
            return NameplateSCT.db.global.damageAnimPersonal
          end,
          set = function(_, val)
            NameplateSCT.db.global.damageAnimPersonal = val
          end,
          values = animationValues,
          order = 2
        },
        critPersonal = {
          type = "select",
          name = L["Criticals"],
          get = function()
            return NameplateSCT.db.global.critAnimPersonal
          end,
          set = function(_, val)
            NameplateSCT.db.global.critAnimPersonal = val
          end,
          values = animationValues,
          order = 3
        },
        healPersonal = {
          type = "select",
          name = "Heal",
          get = function()
            return NameplateSCT.db.global.healAnimPersonal
          end,
          set = function(_, val)
            NameplateSCT.db.global.healAnimPersonal = val
          end,
          values = animationValues,
          order = 4
        },
        missPersonal = {
          type = "select",
          name = L["Miss/Parry/Dodge/etc"],
          get = function()
            return NameplateSCT.db.global.missAnimPersonal
          end,
          set = function(_, val)
            NameplateSCT.db.global.missAnimPersonal = val
          end,
          values = animationValues,
          order = 5
        },



        formattingPersonal = {
          type = "group",
          name = "Text Formatting (personal)",
          order = 6,
          inline = true,
          disabled = addonDisabled,
          args = {
            fontPersonal = {
              type = "select",
              dialogControl = "LSM30_Font",
              name = L["Font"],
              values = AceGUIWidgetLSMlists.font,
              order = 1
            },
            fontFlagPersonal = {
              type = "select",
              name = L["Font Flags"],
              values = fontFlags,
              order = 2
            },
            textShadowPersonal = {
              type = "toggle",
              name = L["Text Shadow"],
              order = 3
            },
            useDamageTypeColorPersonal = {
              type = "toggle",
              name = L["Use Damage Type Color"],
              order = 4
            },
            OverridenDamageColorPersonal = {
              type = "color",
              name = "Overriden damage color",
              disabled = function()
                return NameplateSCT.db.global.useDamageTypeColorPersonal
              end,
              hasAlpha = false,
              set = function(_, r, g, b)
                NameplateSCT.db.global.useDamageTypeColorPersonal = rgbToHex(r, g, b)
              end,
              get = function()
                return hexToRGB(NameplateSCT.db.global.OverridenDamageColorPersonal)
              end,
              order = 5
            },
            useOverridenColorOnAutoattacksPersonal = {
              type = "toggle",
              name = "Overriden Color On Autoattacks",
              order = 6,
              width = "double"
            },
            truncatePersonal = {
              type = "toggle",
              name = L["Truncate Number"],
              order = 7
            },
            truncateLetterPersonal = {
              type = "toggle",
              name = L["Show Truncated Letter"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.truncatePersonal
              end,
              order = 8
            },
            commaSeperatePersonal = {
              type = "toggle",
              name = L["Comma Seperate"],
              desc = "100000 -> 100,000",
              disabled = function()
                return not NameplateSCT.db.global.enabled or NameplateSCT.db.global.truncatePersonal
              end,
              order = 9
            },
            sizePersonal = {
              type = "range",
              name = L["Size"],
              --min = 5,
              min = 5,
              max = 100,
              step = 1,
              get = function()
                return NameplateSCT.db.global.sizePersonal
              end,
              set = function(_, val)
                NameplateSCT.db.global.sizePersonal = val
              end,
              order = 10
            },
            alphaPersonal = {
              type = "range",
              name = L["Alpha"],
              min = 0.1,
              max = 1,
              step = .01,
              get = function()
                return NameplateSCT.db.global.alphaPersonal
              end,
              set = function(_, val)
                NameplateSCT.db.global.alphaPersonal = val
              end,
              order = 11
            },

          }
        },


        appearancePersonal = {
          type = "group",
          name = "Appearance/Offsets (personal)",
          order = 7,
          inline = true,
          disabled = addonDisabled,
          args = {
            xOffsetHealingPersonal = {
              type = "range",
              name = "X Offset Personal SCT (healing)",
              desc = L["Only used if Personal Nameplate is Disabled"],
              hidden = function()
                return not NameplateSCT.db.global.personal
              end,
              softMin = -400,
              softMax = 400,
              step = 1,
              order = -1,
              width = "double"
            },
            yOffsetHealingPersonal = {
              type = "range",
              name = "Y Offset Personal SCT (healing)",
              desc = L["Only used if Personal Nameplate is Disabled"],
              hidden = function()
                return not NameplateSCT.db.global.personal
              end,
              softMin = -400,
              softMax = 400,
              step = 1,
              order = -2,
              width = "double"
            },
            xOffsetPersonal = {
              type = "range",
              name = L["X Offset Personal SCT"],
              desc = L["Only used if Personal Nameplate is Disabled"],
              hidden = function()
                return not NameplateSCT.db.global.personal
              end,
              softMin = -400,
              softMax = 400,
              step = 1,
              order = 1,
              width = "double"
            },
            yOffsetPersonal = {
              type = "range",
              name = L["Y Offset Personal SCT"],
              desc = L["Only used if Personal Nameplate is Disabled"],
              hidden = function()
                return not NameplateSCT.db.global.personal
              end,
              softMin = -400,
              softMax = 400,
              step = 1,
              order = 2,
              width = "double"
            },
            smallHitsDamageHidePersonal = { -- 23.11.23
              type = "toggle",
              name = "|cffff5555Hide small damage hits (personal)|r",
              desc = "",
              order = 3,
              width = "double"
            },
            smallHitsHealHidePersonal = { -- 23.11.23
              type = "toggle",
              name = "|cff55ff55Hide small heals hits (personal)|r",
              desc = "",
              order = 4,
              width = "double"
            },
            smallHitMaxValueDamagePersonal = { -- added 23.11.23
              type = "range",
              name = "Max small damage hit value (personal)",
              desc = "",
              min = 0,
              max = 10000,
              step = 10,
              order = 5,
              width = "double"
            },
            smallHitMaxValueHealPersonal = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55Max small heal hit value (personal)|r",
              desc = "",
              min = 0,
              max = 10000,
              step = 10,
              order = 6,
              width = "double"
            },
            strataPersonal = {
              type = "select",
              name = "Strata (personal)",
              get = function()
                return NameplateSCT.db.global.strataPersonal
              end,
              set = function(_, val)
                NameplateSCT.db.global.strataPersonal = val
                --adjustStrata()
              end,
              values = stratas,
              order = 7
            },
            showCasterNamesDamagePersonal = {
              type = "toggle",
              name = "|cffff5555Show caster names (damage, personal)|r",
              desc = "",
              order = 8,
              width = "double"
            },
            showCasterNamesHealsPersonal = {
              type = "toggle",
              name = "|cff00ff55Show caster names (heals, personal)|r",
              desc = "",
              order = 9,
              width = "double"
            },
            showAbsorbAmountPersonal = {
              type = "toggle",
              name = "Show absorb amount (personal)",
              desc = "",
              order = 10,
              width = "double"
            },
            CasterNamesMaxLengthPersonal = { 
              type = "range",
              name = "CasterNamesMaxLengthPersonal (personal)",
              desc = "",
              min = 2,
              max = 12,
              step = 1,
              order = -5,
              width = "double"
            },
          }
        },



        iconAppearancePersonal = {
          type = "group",
          name = "Icons (personal)",
          order = 8,
          inline = true,
          args = {
            showIconPersonal = {
              type = "toggle",
              name = L["Display Icon"],
              order = 1,
              width = "double"
            },
            iconScalePersonal = {
              type = "range",
              name = L["Icon Scale"],
              desc = L["Scale of the spell icon"],
              softMin = 0.5,
              softMax = 2,
              isPercent = true,
              step = 0.01,
              hidden = function()
                return not NameplateSCT.db.global.showIconPersonal
              end,
              order = 2,
              width = "Half"
            },
            iconPositionPersonal = {
              type = "select",
              name = L["Position"],
              hidden = function()
                return not NameplateSCT.db.global.showIconPersonal
              end,
              values = positionValues,
              order = 3
            },
            xOffsetIconPersonal = {
              type = "range",
              name = L["Icon X Offset"],
              hidden = function()
                return not NameplateSCT.db.global.showIconPersonal
              end,
              softMin = -30,
              softMax = 30,
              step = 1,
              order = 4,
              width = "Half"
            },
            yOffsetIconPersonal = {
              type = "range",
              name = L["Icon Y Offset"],
              hidden = function()
                return not NameplateSCT.db.global.showIconPersonal
              end,
              softMin = -30,
              softMax = 30,
              step = 1,
              order = 5,
              width = "Half"
            }
          }
        },


        sizingPersonal = {
          type = "group",
          name = "Sizing modifiers (personal)",
          order = 9,
          inline = true,
          disabled = function()
            return not NameplateSCT.db.global.enabled
          end,
          get = function(i)
            return NameplateSCT.db.global[i[#i]]
          end,
          set = function(i, val)
            NameplateSCT.db.global[i[#i]] = val
          end,
          args = {
            critsEmbiggenPersonal = {
              type = "toggle",
              name = L["Embiggen Crits"],
              order = 1
            },
            critsScalePersonal = {
              type = "range",
              name = L["Embiggen Crits Scale"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.critsEmbiggenPersonal
              end,
              min = 1,
              max = 3,
              step = .01,
              order = 2,
              width = "double"
            },
            powSizingMaxPersonal = { -- 7.12.23
              type = "range",
              name = "Embiggen crits max pow sizing",
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.critsEmbiggenPersonal
              end,
              min = 1,
              max = 5,
              step = .01,
              order = 3,
              width = "double"
            },
            missEmbiggenPersonal = {
              type = "toggle",
              name = L["Embiggen Miss/Parry/Dodge/etc"],
              order = 4,
              width = "double"
            },
            missScalePersonal = {
              type = "range",
              name = L["Embiggen Miss/Parry/Dodge/etc Scale"],
              disabled = function()
                return not NameplateSCT.db.global.enabled or not NameplateSCT.db.global.missEmbiggenPersonal
              end,
              min = 0.5, -- 19.11.23 now we can make it smaller
              max = 3,
              step = .01,
              order = 5,
              width = "double"
            },
            smallHitsDamageScalePersonal = {
              type = "range",
              name = "|cffff5555Small damage hits scale|r",
              min = 0.33,
              max = 1,
              step = .01,
              order = 6,
              width = "double"
            },
            smallHitsHealScalePersonal = { -- 23.11.23
              type = "range",
              name = "|cff00ff55Small heals hits scale|r",
              min = 0.33,
              max = 1,
              step = .01,
              order = 7,
              width = "double"
            },
            sizeIsRelativeToMaxHealthPersonal = { -- 28.11.23
              type = "toggle",
              name = "Text size is relative to max health",
              desc = "The higher the damage or healing value, the larger the text size will be",
              order = 8,
              width = "double"
            },
            sizeMaxPersonal = { -- 28.11.23
              type = "range",
              name = "Text max size",
              --desc = "If 0 then max size will be: size*2",
              --min = 0,
              min = 5,
              max = 100,
              step = 1,
              get = function()
                if NameplateSCT.db.global.sizeMaxPersonal >= NameplateSCT.db.global.sizePersonal then
                  return NameplateSCT.db.global.sizeMaxPersonal
                else
                  return NameplateSCT.db.global.sizePersonal
                end
              end,
              set = function(_, val)
                local v = val
                if v < NameplateSCT.db.global.sizePersonal then v = NameplateSCT.db.global.sizePersonal end
                NameplateSCT.db.global.sizeMaxPersonal = v
              end,
              order = 9,
              width = "double"
            },
            sizeMinPersonal = { -- 28.12.23
              type = "range",
              name = "Text mix size",
              --desc = "",
              min = 5,
              max = 100,
              step = 1,
              get = function()
                if NameplateSCT.db.global.sizeMinPersonal <= NameplateSCT.db.global.sizePersonal then
                  return NameplateSCT.db.global.sizeMinPersonal
                else
                  return NameplateSCT.db.global.sizePersonal
                end
              end,
              set = function(_, val)
                local v = val
                if v > NameplateSCT.db.global.sizePersonal then 
                  print('|cffff0000NameplateSCT: \'sizeMinPersonal\' you set has bigger value than \'sizePersonal\', set \'sizeMinPersonal\' to \'sizePersonal\'|r')
                  v = NameplateSCT.db.global.sizePersonal 
                end
                NameplateSCT.db.global.sizeMinPersonal = v
              end,
              order = 10,
              width = "double"
            },
            CustomMaxHealthSizeIsRelativeToPersonal = { -- 28.11.23
              type = "range",
              name = "Custom max health (text size is relative to)",
              desc = "If 0 then max health will be your max health or your target's max health",
              min = 0,
              max = 200000,
              step = 100,
              order = 11,
              width = "double"
            },
          }
        },



        spellBlacklistPersonal = { -- added 23.11.23
          order = 10,
          type = "input",
          width = "full",
          multiline = true,
          desc = "Spell names, separated by \";\" without space",
          name = "|cffffaa00Blacklisted spells (personal), separated by \";\" without space|r",
          get = function()
            return table.concat(NameplateSCT.db.global.spellBlacklistPersonal or {}, ";")
          end,
          set = function(info, value)
            NameplateSCT.db.global.spellBlacklistPersonal = {}
            for spell in string.gmatch(value, "([^;]+)") do
              table.insert(NameplateSCT.db.global.spellBlacklistPersonal, spell)
              --print(spell)
            end
          end,
        },



        animationExConstantsPersonal = {
          type = "group",
          name = "Animation ex constants (personal)",
          order = 500,
          inline = true,
          args = {
            SMALL_HIT_EXPIRY_WINDOW_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55SMALL_HIT_EXPIRY_WINDOW_PERSONAL|r",
              desc = "default:30",
              min = 0,
              max = 300,
              step = 1,
              order = 11,
              width = "double"
            },
            SMALL_HIT_MULTIPIER_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cffff5555SMALL_HIT_MULTIPIER_PERSONAL|r",
              desc = "default:0.5",
              min = 0,
              max = 10,
              step = 0.1,
              order = 12,
              width = "double"
            },
            ANIMATION_VERTICAL_DISTANCE_MIN_PERSONAL = {
              -- added 23.11.23
              type = "range",
              name = "|cff5555ffANIMATION_VERTICAL_DISTANCE_MIN_PERSONAL|r",
              desc = "default:75, must be < than ANIMATION_VERTICAL_DISTANCE_MAX_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 13,
              width = "double"
            },
            ANIMATION_VERTICAL_DISTANCE_MAX_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cff5555ffANIMATION_VERTICAL_DISTANCE_MAX_PERSONAL|r",
              desc = "default:75, must be > than ANIMATION_VERTICAL_DISTANCE_MIN_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 14,
              width = "double"
            },
            ANIMATION_ARC_X_MIN_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_ARC_X_MIN_PERSONAL",
              desc = "default:50, must be < than ANIMATION_ARC_X_MAX_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 15,
              width = "double"
            },
            ANIMATION_ARC_X_MAX_PERSONAL = {
              -- added 23.11.23
              type = "range",
              name = "ANIMATION_ARC_X_MAX_PERSONAL",
              desc = "default:150, must be > than ANIMATION_ARC_X_MIN_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 16,
              width = "double"
            },
            ANIMATION_ARC_Y_TOP_MIN_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55ANIMATION_ARC_Y_TOP_MIN_PERSONAL|r",
              desc = "default:10, must be < than ANIMATION_ARC_Y_TOP_MAX_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 17,
              width = "double"
            },
            ANIMATION_ARC_Y_TOP_MAX_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cff55ff55ANIMATION_ARC_Y_TOP_MAX_PERSONAL|r",
              desc = "default:50, must be > than ANIMATION_ARC_Y_TOP_MIN_PERSONAL",
              min = 0,
              max = 500,
              step = 1,
              order = 18,
              width = "double"
            },
            ANIMATION_ARC_Y_BOTTOM_MIN_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_ARC_Y_BOTTOM_MIN_PERSONAL|r",
              desc = "default:10, must be < than ANIMATION_ARC_Y_BOTTOM_MAX_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 19,
              width = "double"
            },
            ANIMATION_ARC_Y_BOTTOM_MAX_PERSONAL = {
              -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_ARC_Y_BOTTOM_MAX_PERSONAL|r",
              desc = "default:50, must be > than ANIMATION_ARC_Y_BOTTOM_MIN_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 20,
              width = "double"
            },
            ANIMATION_RAINFALL_X_MAX_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cff5555ffANIMATION_RAINFALL_X_MAX_PERSONAL|r",
              desc = "default:75, no MIN available for this value",
              min = 0,
              max = 500,
              step = 1,
              order = 21,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_MIN_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_RAINFALL_Y_MIN_PERSONAL",
              desc = "default:50, must be < than ANIMATION_RAINFALL_Y_MAX_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 22,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_MAX_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "ANIMATION_RAINFALL_Y_MAX_PERSONAL",
              desc = "default:100, must be > than ANIMATION_RAINFALL_Y_MIN_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 23,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_START_MIN_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_RAINFALL_Y_START_MIN_PERSONAL|r",
              desc = "default:5, must be < than ANIMATION_RAINFALL_Y_START_MIN_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 24,
              width = "double"
            },
            ANIMATION_RAINFALL_Y_START_MAX_PERSONAL = { -- added 23.11.23
              type = "range",
              name = "|cffff5555ANIMATION_RAINFALL_Y_START_MAX_PERSONAL|r",
              desc = "default:15, must be > than ANIMATION_RAINFALL_Y_START_MIN_PERSONAL",
              min = -500,
              max = 500,
              step = 1,
              order = 25,
              width = "double"
            },
          },
        },

      }
    },


    about = {
      type = "group",
      name = "About",
      order = 22,
      inline = true,
      args = {
        date = {
          type = "description",
          name = format("|cffffff33Date|r: %s", GetAddOnMetadata("NameplateSCT", "X-Date")),
          width = "double",
          order = 1
        },
        website = {
          type = "description",
          name = format("|cffffff33Website|r: %s", GetAddOnMetadata("NameplateSCT", "X-Website")),
          width = "double",
          order = 2
        },
        discord = {
          type = "description",
          name = format("|cffffff33Discord|r: %s", GetAddOnMetadata("NameplateSCT", "X-Discord")),
          width = "double",
          order = 3
        },
        email = {
          type = "description",
          name = format("|cffffff33Email|r: %s", GetAddOnMetadata("NameplateSCT", "X-Email")),
          width = "double",
          order = 4
        },
        credits = {
          type = "description",
          name = format("|cffffff33Credits|r: %s", GetAddOnMetadata("NameplateSCT", "X-Credits")),
          width = "double",
          order = 5
        },
        note = {
          type = "description",
          name = "|cffffff33Note:|r |cff22bbff" .. GetAddOnMetadata("NameplateSCT", "X-Maintained") .. "|r",
          width = "double",
          order = 6
        }
      }
    }
  }
}

function NameplateSCT:OpenMenu()
  -- just open to the frame, double call because blizz bug
  InterfaceOptionsFrame_OpenToCategory(self.menu)
  InterfaceOptionsFrame_OpenToCategory(self.menu)
end

function NameplateSCT:RegisterMenu()
  LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("NameplateSCT", menu)
  self.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("NameplateSCT", "NameplateSCT")
end
