if myHero.charName ~= "Caitlyn" then return end
local version = "1.06"

-------------------------------------
local REQUIRED_LIBS = {
  ["SourceLib"] = "https://bitbucket.org/TheRealSource/public/raw/master/common/SourceLib.lua",
  ["VPrediction"] = "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua",
  ["SOW"] = "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua",
}

local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

function AfterDownload()
  DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
  if DOWNLOAD_COUNT == 0 then
    DOWNLOADING_LIBS = false
    print("<b>[Caitlyn]: SourceLib downloaded successfully, please reload (double F9).</b>")
  end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
  if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
    require(DOWNLOAD_LIB_NAME)
  else
    DOWNLOADING_LIBS = true
    DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
    DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
  end
end

if DOWNLOADING_LIBS then return end



-------------------------------------

--[[local libDownloader = Require("MixsStar's Caitlyn")
libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
libDownloader:Check()

if libDownloader.downloadNeeded then return end]]
-------------------------------------
LU = LazyUpdater("Caitlyn", version, "raw.github.com", "/MixsStar/BoL_Studio/master/Scripts/Caitlyn.lua", tostring(SCRIPT_PATH .. GetCurrentEnv().FILE_NAME))



--A basic BoL template for the Eclipse Lua Development Kit
AutoUpGen = true

player = GetMyHero()

-- AutoWard Start Code
local wardRange = 600
local scriptActive = true
local wardTimer = 0
local wardSlot = nil
local wardMatrix = {}
local wardDetectedFlag = {}
local lastWard = 0
wardMatrix[1] = {10000,11326,10012,8924,8078,11186,5925,4911,4025,2781,4031,2842}
wardMatrix[2] = {2868,3817,4842,5461,4600,6979,9851,8878,9621,10578,11519,7575}
wardMatrix[3] = {}
for i = 1, 12 do
  --Ward present nearby ?
  wardMatrix[3][i] = false
  wardDetectedFlag[i] = false
end

function wardUpdate()
  for i = 1, 12 do
    wardDetectedFlag[i] = false
  end
  for k = 1, objManager.maxObjects do
    local object = objManager:GetObject(k)
    if object ~= nil and (string.find(object.name, "Ward") ~= nil or string.find(object.name, "Wriggle") ~= nil) then
      for i = 1, 12 do
        if math.sqrt((wardMatrix[1][i] - object.x)*(wardMatrix[1][i] - object.x) + (wardMatrix[2][i] - object.z)*(wardMatrix[2][i] - object.z)) < 1100 then
          wardDetectedFlag[i] = true
          wardMatrix[3][i] = true
        end
      end
    end
    for i = 1, 12 do
      if wardDetectedFlag[i] == false then
        wardMatrix[3][i] = false
      end
    end
  end
  wardTimer = GetTickCount()
end
-- AutoWard End Code

blue = false
PassiveUp = false

aaRange = 650
qRange = 1250
wRange = 800
eRange = 950
rRange = nil
rRangelvl = {2000,2500,3000}

local QAble, WAble, RAble = false, false, false
local qDmg, eDmg, rDmg, DmgRange

-- called once when the script is loaded
function OnLoad()
  Menu()
  VP = VPrediction()
  AutoUpGen = mc.autoupdategeneral
  if AutoUpGen then
    LU:CheckUpdate()
  end

  OrbWalk()
end

-- handles script logic, a pure high speed loop
space = false
mixed = false

function OnTick()
  Checks()
  CheckRLevel()
  if Target then
    if Target and (space) then
      Peacemaker()
    end
    if Target and (mixed) then
      Peacemaker2()
    end
    if mc.draws.useW then Trap() end
    if mc.draws.autoEGap then AutoEGap() end
    if mc.draws.Combo then Net() PeacemakerCombo() end
    if mc.draws.KS then KS() end
  end

  if mc.draws.Dash then Dash() end

  --

  -- Infos
  if mc.draws.HitChanceInfo then
    PrintChat ("<font color='#FFFFFF'>Hitchance 0: No waypoints found for the target, returning target current position</font>")
    PrintChat ("<font color='#FFFFFF'>Hitchance 1: Low hitchance to hit the target</font>")
    PrintChat ("<font color='#FFFFFF'>Hitchance 2: High hitchance to hit the target</font>")
    PrintChat ("<font color='#FFFFFF'>Hitchance 3: Target too slowed or/and too close(~100% hit chance)</font>")
    PrintChat ("<font color='#FFFFFF'>Hitchance 4: Target inmmobile(~100% hit chace)</font>")
    PrintChat ("<font color='#FFFFFF'>Hitchance 5: Target dashing(~100% hit chance)</font>")
    --AutoCarry.PluginMenu.ranges.HitChanceInfo = false
  end

  if mc.extras.putWard then
    if GetTickCount() - wardTimer > 10000 then
      wardUpdate()
    end 

    if (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3340) then
      wardSlot = GetInventorySlotItem(3340)
    elseif (myHero:CanUseSpell(ITEM_7) == READY and myHero:getItem(ITEM_7).id == 3350) then
      wardSlot = GetInventorySlotItem(3350)
    elseif GetInventorySlotItem(2044) ~= nil then
      wardSlot = GetInventorySlotItem(2044)
    elseif GetInventorySlotItem(2043) ~= nil then
      wardSlot = GetInventorySlotItem(2043)
    else
      wardSlot = nil
    end

    for i = 1, 12 do
      if wardSlot ~= nil and GetTickCount() - lastWard > 2000 then
        if math.sqrt((wardMatrix[1][i] - player.x)*(wardMatrix[1][i] - player.x) + (wardMatrix[2][i] - player.z)*(wardMatrix[2][i] - player.z)) < 600 and wardMatrix[3][i] == false then
          CastSpell( wardSlot, wardMatrix[1][i], wardMatrix[2][i] )
          lastWard = GetTickCount()
          wardMatrix[3][i] = true
          break
        end
      end
    end
  end 
end

function OnGainBuff(unit, buff)
  if unit.isMe then
    if buff.name == "crestoftheancientgolem" then
      blue = true
      if mc.extras.debug then
        print("You Have the Blue")
      end
    end
    if buff.name == "caitlyheadshot" then
      PassiveUp = true
      if mc.extras.debug then
        print("Your Passive is Active ;D")
      end
    end
  end
end

function OnLoseBuff(unit, buff)
  if unit.isMe then
    if buff.name == "crestoftheancientgolem" then
      blue = false
      if mc.extras.debug then
        print("You Lost the Blue")
      end
    end
    if buff.name == "caitlyheadshot" then
      PassiveUp = false
      if mc.extras.debug then
        print("Your Passive is NOT Active")
      end
    end
  end
end

--handles overlay drawing (processing is not recommended here,use onTick() for that)
function OnDraw()
  if not myHero.dead then
    if QAble and mc.draws.drawQ then
      DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x6600CC)
    end
    if RAble and mc.draws.drawR then
      DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x990000)
    end
    if mc.draws.drawAA then
      DrawCircle(myHero.x, myHero.y, myHero.z, aaRange, 0x990000)
    end

  end
end


--handles input
function OnWndMsg(msg,key)
  if msg == KEY_DOWN and key == 32 then space = true end
  if msg == KEY_UP and key == 32 then space = false end
  if msg == KEY_DOWN and key == string.byte("C") then mixed = true end
  if msg == KEY_UP and key == string.byte("C") then mixed = false end
end

-- listens to chat input
function OnSendChat(txt)

end

-- listens to spell
function OnProcessSpell(owner,spell)

end

-- function to declare the menu
local HKR = string.byte("R")
local HKE = string.byte("G")
local HKC = string.byte("T")

function Menu()
  myConfig = scriptConfig("Caitlyn - Config", "mixsstarScript")
  mc = myConfig
  mc:addParam("autoupdategeneral", "AutoUpdate", SCRIPT_PARAM_ONOFF, true)
  mc:addSubMenu("OrbWalk", "orbwalkSubMenu")
  mc:addSubMenu("Skills and Draws", "draws")
  mc:addSubMenu("Extras", "extras")
  mc.extras:addParam("putWard", "Automatically put Wards", SCRIPT_PARAM_ONOFF, true)
  mc.extras:addParam("debug", "Print and Draw Debugs", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("HitChance", "Q - Hitchance", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
  mc.draws:addParam("HitChanceInfo", "Info - Hitchance", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("sep", "-- Misc Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("blueQ", "Q - Cast more often when Blue",SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("useW", "Use - Yordle Snap Trap", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("Dash", "Dash - 90 Caliber Net", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
  mc.draws:addParam("autoEGap", "Net Auto Gap", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("autoEDistance", "Auto Gap - Distance to Auto Gap", SCRIPT_PARAM_SLICE, 350, 250, 800, 0)
  mc.draws:addParam("Combo", "Combo - Net Peacemaker", SCRIPT_PARAM_ONKEYDOWN, false, HKC)
  mc.draws:addParam("sep1", "-- KS Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("KS", "Enable - Killsteal", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("Killshot", "Killshot - Ace in the Hole", SCRIPT_PARAM_ONKEYDOWN, false, HKR)
  mc.draws:addParam("KSQ", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("sep2", "-- Autocarry Options --", SCRIPT_PARAM_INFO, "") 
  mc.draws:addParam("useQ", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("sep3", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("useQ2", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("sep4", "-- Drawing Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("drawQ", "Draw - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("drawR", "Draw - Ace in the Hole", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("drawAA", "Draw - AA Arena", SCRIPT_PARAM_ONOFF, true)
  mc:addParam("version", "Version", SCRIPT_PARAM_INFO, version)
end

function OrbWalk()
  SOW(VP)
  SOWi = SOW(VP)
  SOWi:LoadToMenu(myConfig.orbwalkSubMenu)
end

function Checks()
  QAble = (myHero:CanUseSpell(_Q) == READY)
  WAble = (myHero:CanUseSpell(_W) == READY)
  EAble = (myHero:CanUseSpell(_E) == READY)
  RAble = (myHero:CanUseSpell(_R) == READY)
  Target = SOWi:GetTarget()
end

function KS()
  --[[if mc.extras.debug then
  print("Calling KS()")
  end]]
  for i = 1, heroManager.iCount do
    local Enemy = heroManager:getHero(i)
    if QAble and mc.draws.KSQ then qDmg = getDmg("Q",Enemy,myHero) else qDmg = 0 end
    if EAble and mc.draws.KSE then eDmg = getDmg("E",Enemy,myHero) else eDmg = 0 end
    if RAble then rDmg = getDmg("R",Enemy,myHero) else rDmg = 0 end
    if ValidTarget(Enemy, 1300, true) and Enemy.health < qDmg then
      --Net()
      PeacemakerKS()
    end
    if ValidTarget(Enemy, rRange, true) and Enemy.health < rDmg then
      PrintFloatText(myHero, 0, "Press R For Killshot") end
    if ValidTarget(Enemy, rRange, true) and mc.draws.Killshot and Enemy.health < rDmg then
      CastSpell(_R, Enemy) end
  end
end

function CheckRLevel()
  if myHero:GetSpellData(_R).level == 1 then rRange = rRangelvl[1]
  elseif myHero:GetSpellData(_R).level == 2 then rRange = rRangelvl[2]
  elseif myHero:GetSpellData(_R).level == 3 then rRange = rRangelvl[3]
  end
end

function PeacemakerKS()
  if mc.extras.debug then
    print("Calling PeaceMakerKS()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and HitChance >= 2 and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Peacemaker()
  if mc.extras.debug then
    print("Calling PeaceMaker()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and mc.draws.useQ and SOWi:CanMove() and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then
      if blue and mc.draws.blueQ and HitChance >= 1 then
        if mc.extras.debug then print("Casting Q More Often") end 
        CastSpell(_Q, CastPosition.x, CastPosition.z) 
      else
        if HitChance >= mc.draws.HitChance then CastSpell(_Q, CastPosition.x, CastPosition.z) 
        end
      end
    end
  end
end

function Peacemaker2()
  if mc.extras.debug then
    print("Calling PeaceMaker2()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and mc.draws.useQ2 and SOWi:CanMove() and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z)
    elseif QAble and mc.draws.useQ2 and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Trap()
  if mc.extras.debug then
    print("Calling Trap()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 1.5, 100, wRange, math.huge, myHero)
    if WAble and HitChance >= 4 and GetDistance(CastPosition) <= 800 then SOWi:DisableAttacks() CastSpell(_W, CastPosition.x, CastPosition.z) SOWi:EnableAttacks() end
  end
end

function Dash()
  if mc.extras.debug then
    print("Calling Dash()")
  end
  if EAble and mc.draws.Dash then
    MPos = Vector(mousePos.x, mousePos.y, mousePos.z)
    HeroPos = Vector(myHero.x, myHero.y, myHero.z)
    DashPos = HeroPos + ( HeroPos - MPos )*(500/GetDistance(mousePos))
    myHero:MoveTo(mousePos.x,mousePos.z)
    CastSpell(_E,DashPos.x,DashPos.z)
  end
end

function PeacemakerCombo()
  if mc.extras.debug then
    print("Calling Combo()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and not EAble and HitChance >= 2 and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Net()
  if mc.extras.debug then
    print("Calling Net()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.1, 80, eRange, 1960, myHero)
    if EAble and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < eRange then CastSpell(_E, CastPosition.x, CastPosition.z) end
  end
end

function AutoEGap()
  if mc.extras.debug then
    print("Calling AutoEGap()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.1, 80, mc.draws.autoEDistante, 1960, myHero)
    if EAble and GetDistance(target) <= mc.draws.autoEDistance then CastSpell(_E, CastPosition.x, CastPosition.z) end
  end

end