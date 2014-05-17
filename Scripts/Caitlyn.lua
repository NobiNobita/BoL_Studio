if myHero.charName ~= "Caitlyn" then return end
local version = "1.11"

-------------------------------------
local REQUIRED_LIBS = {
  ["SourceLib"] = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua",
  ["VPrediction"] = "https://raw.github.com/honda7/BoL/master/Common/VPrediction.lua",
  ["SOW"] = "https://raw.github.com/honda7/BoL/master/Common/SOW.lua",
}

local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

function AfterDownload()
  DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
  if DOWNLOAD_COUNT == 0 then
    DOWNLOADING_LIBS = false
    print("<b>[Caitlyn]: Libs downloaded successfully, please reload (double F9).</b>")
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



-------------------------------------

SU = SourceUpdater("Caitlyn", version, "raw.github.com", "/MixsStar/BoL_Studio/master/Scripts/Caitlyn.lua", tostring(SCRIPT_PATH .. GetCurrentEnv().FILE_NAME))



--A basic BoL template for the Eclipse Lua Development Kit
AutoUpGen = true

local spellExpired = true
local informationTable = {}

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

aaRange = 650 -- dunno why but when drawing it draws it smaller...
qRange = 1250
wRange = 800
eRange = 950
rRange = nil
rRangelvl = {2000,2500,3000}

local QAble, WAble, RAble = false, false, false
local qDmg, eDmg, rDmg, DmgRange

-- called once when the script is loaded
function OnLoad()
  EnemyMinions = minionManager(MINION_ENEMY, 720, myHero, MINION_SORT_MAXHEALTH_DEC)
  Menu()
  VP = VPrediction()
  AutoUpGen = mc.autoupdategeneral
  if AutoUpGen then
   SU:CheckUpdate()
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
    if mc.draws.Combo then PeacemakerCombo() end
    if mc.draws.KS then KS() end
  end
  if mc.draws.autoEGapDist then AutoEGap() end
  if mc.draws.Dash then Dash() end

  --
  if mc.draws.farmEnabled and (myHero.mana / myHero.maxMana * 100) >= mc.draws.ManaCheck then
    Farm()
  end

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
    if buff.name == "caitlynheadshot" then
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
    if buff.name == "caitlynheadshot" then
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
      DrawCircle(myHero.x, myHero.y, myHero.z, 720, 0x990000)
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
function OnProcessSpell(unit, spell)
  if not mc.draws.autoEGapDist then return end
  local jarvanAddition = unit.charName == "JarvanIV" and unit:CanUseSpell(_Q) ~= READY and _R or _Q -- Did not want to break the table below.
  local isAGapcloserUnit = {
    --        ['Ahri']        = {true, spell = _R, range = 450,   projSpeed = 2200},
    ['Aatrox']      = {true, spell = _Q,                  range = 1000,  projSpeed = 1200, },
    ['Akali']       = {true, spell = _R,                  range = 800,   projSpeed = 2200, }, -- Targeted ability
    ['Alistar']     = {true, spell = _W,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
    ['Diana']       = {true, spell = _R,                  range = 825,   projSpeed = 2000, }, -- Targeted ability
    ['Gragas']      = {true, spell = _E,                  range = 600,   projSpeed = 2000, },
    ['Graves']      = {true, spell = _E,                  range = 425,   projSpeed = 2000, exeption = true },
    ['Hecarim']     = {true, spell = _R,                  range = 1000,  projSpeed = 1200, },
    ['Irelia']      = {true, spell = _Q,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
    ['JarvanIV']    = {true, spell = jarvanAddition,      range = 770,   projSpeed = 2000, }, -- Skillshot/Targeted ability
    ['Jax']         = {true, spell = _Q,                  range = 700,   projSpeed = 2000, }, -- Targeted ability
    ['Jayce']       = {true, spell = 'JayceToTheSkies',   range = 600,   projSpeed = 2000, }, -- Targeted ability
    ['Khazix']      = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
    ['Leblanc']     = {true, spell = _W,                  range = 600,   projSpeed = 2000, },
    ['LeeSin']      = {true, spell = 'blindmonkqtwo',     range = 1300,  projSpeed = 1800, },
    ['Leona']       = {true, spell = _E,                  range = 900,   projSpeed = 2000, },
    ['Malphite']    = {true, spell = _R,                  range = 1000,  projSpeed = 1500 + unit.ms},
    ['Maokai']      = {true, spell = _Q,                  range = 600,   projSpeed = 1200, }, -- Targeted ability
    ['MonkeyKing']  = {true, spell = _E,                  range = 650,   projSpeed = 2200, }, -- Targeted ability
    ['Pantheon']    = {true, spell = _W,                  range = 600,   projSpeed = 2000, }, -- Targeted ability
    ['Poppy']       = {true, spell = _E,                  range = 525,   projSpeed = 2000, }, -- Targeted ability
    --['Quinn']       = {true, spell = _E,                  range = 725,   projSpeed = 2000, }, -- Targeted ability
    ['Renekton']    = {true, spell = _E,                  range = 450,   projSpeed = 2000, },
    ['Sejuani']     = {true, spell = _Q,                  range = 650,   projSpeed = 2000, },
    ['Shen']        = {true, spell = _E,                  range = 575,   projSpeed = 2000, },
    ['Tristana']    = {true, spell = _W,                  range = 900,   projSpeed = 2000, },
    ['Tryndamere']  = {true, spell = 'Slash',             range = 650,   projSpeed = 1450, },
    ['XinZhao']     = {true, spell = _E,                  range = 650,   projSpeed = 2000, }, -- Targeted ability
  }
  if unit.type == 'obj_AI_Hero' and unit.team == TEAM_ENEMY and isAGapcloserUnit[unit.charName] and GetDistance(unit) < 2000 and spell ~= nil then
  --print('1Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
    if spell.name == (type(isAGapcloserUnit[unit.charName].spell) == 'number' and unit:GetSpellData(isAGapcloserUnit[unit.charName].spell).name or isAGapcloserUnit[unit.charName].spell) then
      --print('2Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
    if spell.target ~= nil and spell.target.name == myHero.name or isAGapcloserUnit[unit.charName].spell == 'blindmonkqtwo' then
        --print('3Gapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
        CastSpell(_E, unit)
      else
    --print('NOGapcloser: ',unit.charName, ' Target: ', (spell.target ~= nil and spell.target.name or 'NONE'), " ", spell.name, " ", spell.projectileID)
        spellExpired = false
        informationTable = {
          spellSource = unit,
          spellCastedTick = GetTickCount(),
          spellStartPos = Point(spell.startPos.x, spell.startPos.z),
          spellEndPos = Point(spell.endPos.x, spell.endPos.z),
          spellRange = isAGapcloserUnit[unit.charName].range,
          spellSpeed = isAGapcloserUnit[unit.charName].projSpeed,
          spellIsAnExpetion = isAGapcloserUnit[unit.charName].exeption or false,
        }
      end
    end
  end
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

  --[[Draws General]]
  mc:addSubMenu("Skills and Draws", "draws")
  mc.draws:addParam("HitChance", "Q - Hitchance", SCRIPT_PARAM_SLICE, 2, 0, 5, 0)
  mc.draws:addParam("HitChanceInfo", "Info - Hitchance", SCRIPT_PARAM_ONOFF, false)

  --[[Misc Options]]
  mc.draws:addParam("sep", "-- Misc Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("blueQ", "Q - Cast more often when Blue",SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("useW", "Use - Yordle Snap Trap", SCRIPT_PARAM_ONOFF, false)
  mc.draws:addParam("Dash", "Dash - 90 Caliber Net", SCRIPT_PARAM_ONKEYDOWN, false, HKE)

  --[[Auto Anti-Gap Closer]]
  mc.draws:addParam("sep", "-- Auto Anti-Gap Closer Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("autoEGapDist", "Net Auto Anti-Gap Closers", SCRIPT_PARAM_ONOFF, true)

  --[[KS Options]]
  mc.draws:addParam("sep1", "-- KS Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("KS", "Enable - Killsteal", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("Killshot", "Killshot - Ace in the Hole", SCRIPT_PARAM_ONKEYDOWN, false, HKR)
  mc.draws:addParam("KSQ", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)

  --[[Orbwalk Options]]
  mc.draws:addParam("sep2", "-- Orbwalk Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("useQ", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)

  --[[Mixed Mode Options]]
  mc.draws:addParam("sep3", "-- Mixed Mode Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("useQ2", "Use - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, false)

  --[[Farming]]
  mc.draws:addParam("farm", "-- Farming Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("farmUseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
  mc.draws:addParam("farmEnabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

  --[[Drawing Options]]
  mc.draws:addParam("sep4", "-- Drawing Options --", SCRIPT_PARAM_INFO, "")
  mc.draws:addParam("drawQ", "Draw - Piltover Peacemaker", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("drawR", "Draw - Ace in the Hole", SCRIPT_PARAM_ONOFF, true)
  mc.draws:addParam("drawAA", "Draw - AA Arena", SCRIPT_PARAM_ONOFF, true)
  mc:addParam("version", "Version", SCRIPT_PARAM_INFO, version)

  --[[Extras]]
  mc:addSubMenu("Extras", "extras")
  mc.extras:addParam("putWard", "Automatically put Wards", SCRIPT_PARAM_ONOFF, true)
  mc.extras:addParam("debug", "Print and Draw Debugs", SCRIPT_PARAM_ONOFF, false)

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
  --[[if mc.extras.debug then
    print("Calling PeaceMaker()")
  end]]
  for i, target in pairs(GetEnemyHeroes()) do
    CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, 0.632, 90, qRange, 2225, myHero)
  if  not string.find(Target.name, "Turret") then
    if QAble and mc.draws.useQ and SOWi:CanMove() and HitChance >= mc.draws.HitChance and GetDistance(CastPosition) < qRange then
      if blue and mc.draws.blueQ and HitChance >= 1 then
        if mc.extras.debug then print("Casting Q More Often") end
        CastSpell(_Q, CastPosition.x, CastPosition.z)
      else
        if HitChance >= mc.draws.HitChance then CastSpell(_Q, CastPosition.x, CastPosition.z)
        if mc.extras.debug then
      print("Calling PeaceMaker() and target is")
      print(Target.name)
      print(target.name)
    end
    end
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
    if QAble and EAble and HitChance >= 1 and GetDistance(CastPosition) < qRange then CastSpell(_E, CastPosition.x, CastPosition.z) CastSpell(_Q, CastPosition.x, CastPosition.z) end
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
  if myHero:CanUseSpell(_E) == READY then
    if mc.draws.autoEGapDist then
      if not spellExpired and (GetTickCount() - informationTable.spellCastedTick) <= (informationTable.spellRange/informationTable.spellSpeed)*1000 then
        local spellDirection     = (informationTable.spellEndPos - informationTable.spellStartPos):normalized()
        local spellStartPosition = informationTable.spellStartPos + spellDirection
        local spellEndPosition   = informationTable.spellStartPos + spellDirection * informationTable.spellRange
        local heroPosition = Point(myHero.x, myHero.z)

        local lineSegment = LineSegment(Point(spellStartPosition.x, spellStartPosition.y), Point(spellEndPosition.x, spellEndPosition.y))
        --lineSegment:draw(ARGB(255, 0, 255, 0), 70)

        if lineSegment:distance(heroPosition) <= (not informationTable.spellIsAnExpetion and 65 or 200) then
          CastSpell(_E, informationTable.spellSource)
        end
      else
        spellExpired = true
        informationTable = {}
      end
    end
  end
end

function Farm()
  EnemyMinions:update()
  if mc.draws.farmUseQ then
    FarmQ()
  end
end

function FarmQ()
  if (myHero:CanUseSpell(_Q) == READY) and #EnemyMinions.objects > 0 then
    if GetMaxDistMinion() < qRange then
      local QPos = GetBestQPositionFarm()
      if QPos then
        CastQFarm(QPos)
      end
    end
  end
end

function GetBestQPositionFarm()
  local MaxQPos
  local MaxQ = 0
  for i, minion in pairs(EnemyMinions.objects) do
    local hitQ = CountMinionsHit(minion)
    if hitQ > MaxQ or MaxQPos == nil then
      MaxQPos = minion
      MaxQ = hitQ
    end
  end

  if MaxQPos then
    return MaxQPos
  else
    return nil
  end
end

function CastQFarm(to)
  CastSpell(_Q, to.x, to.z)
end

function GetMaxDistMinion()
  local max = -1
  for i, minion in ipairs(EnemyMinions.objects) do
    if GetDistance(minion) > max then
      max = GetDistance(minion)
    end
  end
  return max
end

function CountMinionsHit(QPos)
  local LineEnd = Vector(myHero) + qRange * (Vector(QPos) - Vector(myHero)):normalized()
  local n = 0
  for i, minion in pairs(EnemyMinions.objects) do
    local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), LineEnd, minion)
    if isOnSegment and GetDistance(minion, pointSegment) <= 90*1.25 then
      n = n + 1
    end
  end
  return n
end