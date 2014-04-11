if myHero.charName ~= "Caitlyn" then return end
local version = "1"

-------------------------------------
local REQUIRED_LIBS = {
  ["SourceLib"] = "https://bitbucket.org/TheRealSource/public/raw/master/common/SourceLib.lua",
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

local libDownloader = Require("MixsStar's Caitlyn")
libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
libDownloader:Check()

if libDownloader.downloadNeeded then return end
-------------------------------------
LU = LazyUpdater("Caitlyn", version, "raw.github.com", "/MixsStar/BoL_Studio/master/Scripts/Caitlyn.lua", tostring(SCRIPT_PATH .. GetCurrentEnv().FILE_NAME))



--A basic BoL template for the Eclipse Lua Development Kit
AutoUpGen = true

player = GetMyHero()

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
    if mc.draws.Combo then Net() PeacemakerCombo() end
  end
  if mc.draws.KS then KS() end
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
  myConfig = scriptConfig("Caitlyn is.. Awesome - Config", "mixsstarScript")
  mc = myConfig
  mc:addParam("autoupdategeneral", "AutoUpdate", SCRIPT_PARAM_ONOFF, true)
  mc:addSubMenu("OrbWalk", "orbwalkSubMenu")
  mc:addSubMenu("Skills and Draws", "draws")  
  mc.draws:addParam("HitChance", "Q - Hitchance", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
  mc.draws:addParam("HitChanceInfo", "Info - Hitchance", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("sep", "-- Misc Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("useW", "Use - Yordle Snap Trap", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("Dash", "Dash - 90 Caliber Net", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
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
  mc.draws:addParam("debug", "Print and Draw Debugs", SCRIPT_PARAM_ONOFF, false)
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
  if mc.draws.debug then
    print("Casting KS()")
  end
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
  if mc.draws.debug then
    print("Casting PeaceMakerKS()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and HitChance >= 2 and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Peacemaker()
  if mc.draws.debug then
    print("Casting PeaceMaker()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and mc.draws.useQ and SOWi:CanMove() and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z)
    elseif QAble and mc.draws.useQ and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Peacemaker2()
  if mc.draws.debug then
    print("Casting PeaceMaker2()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and mc.draws.useQ2 and SOWi:CanMove() and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z)
    elseif QAble and mc.draws.useQ2 and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Trap()
  if mc.draws.debug then
    print("Casting Trap()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 1.5, 100, wRange, math.huge, myHero)
    if WAble and HitChance >= 4 and GetDistance(CastPosition) <= 800 then SOWi:DisableAttacks() CastSpell(_W, CastPosition.x, CastPosition.z) SOWi:EnableAttacks() end
  end
end

function Dash()
  if mc.draws.debug then
    print("Casting Dash()")
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
  if mc.draws.debug then
    print("Casting Combo()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
    if QAble and not EAble and HitChance >= 2 and GetDistance(CastPosition) < qRange then CastSpell(_Q, CastPosition.x, CastPosition.z) end
  end
end

function Net()
  if mc.draws.debug then
    print("Casting Net()")
  end
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.1, 80, eRange, 1960, myHero)
    if EAble and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < eRange then CastSpell(_E, CastPosition.x, CastPosition.z) end
  end
end