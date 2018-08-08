local u = ::require("std/u.nut")
local time = require("scripts/time.nut")
local unitActions = require("scripts/unit/unitActions.nut")
local ugcPreview = require("scripts/ugc/ugcPreview.nut")

local MOD_TIERS_COUNT = 4

//!!FIX ME: better to convert weapons and modifications to class
local weaponProperties = [
  "reqRank", "reqExp", "mass_per_sec", "mass_per_sec_diff",
  "repairCostCoef", "repairCostCoefArcade", "repairCostCoefHistorical", "repairCostCoefSimulation",
  "caliber", "deactivationIsAllowed", "isTurretBelt", "bulletsIconParam"
]
local reqNames = ["reqWeapon", "reqModification"]
local upgradeNames = ["weaponUpgrade1", "weaponUpgrade2", "weaponUpgrade3", "weaponUpgrade4"]
local needCollectEffects = ["torpedoes_movement_mode"]

local Unit = class
{
   name = ""
   rank = 0
   shopCountry = ""
   isInited = false //is inited by wpCost, warpoints, and unitTags

   expClass = ::g_unit_class_type.UNKNOWN
   unitType = ::g_unit_type.INVALID
   esUnitType = ::ES_UNIT_TYPE_INVALID
   isPkgDev = false

   cost = 0
   costGold = 0
   reqExp = 0
   expMul = 1.0
   gift = null //""
   giftParam = null //""
   premPackAir = false
   repairCost = 0
   repairTimeHrsArcade = 0
   repairTimeHrsHistorical = 0
   repairTimeHrsSimulation = 0
   freeRepairs = 0
   trainCost = 0
   train2Cost = 0
   train3Cost_gold = 0
   train3Cost_exp = 0
   gunnersCount = 0
   hasDepthCharge = false
   hasMines = false

   isInShop = false
   reqAir = null //name of unit required by shop tree
   group = null //name of units group in shop
   showOnlyWhenBought = false
   showOnlyWhenResearch = false
   showOnlyIfPlayerHasUnlock = null //"" or null
   hideForLangs = null //[] or null when no lang restrictions
   reqFeature = null //"" or null
   hideFeature = null //"" or null
   reqUnlock = null //"" or null

   customImage = null //""
   customClassIco = null //""
   customTooltipImage = null //""

   tags = null //[]
   weapons = null //[]
   modifications = null //[]
   skins = null //[]
   previewSkinId = null //""
   weaponUpgrades = null //[]
   spare = null //{} or null
   needBuyToOpenNextInTier = null //[]

   commonWeaponImage = "#ui/gameuiskin#weapon"
   primaryBullets = null //{}
   secondaryBullets = null //{}
   bulletsIconParam = 0

   shop = null //{} - unit params table for shop unit info
   info = null //{} - tank params info

   testFlight = ""

   isToStringForDebug = true

   //!!FIX ME: params below are still set from outside of unit
   modificatorsRequestTime = -1
   modificators = null //{} or null
   modificatorsBase = null //{} or null
   minChars = null //{} or null
   maxChars = null //{} or null
   primaryWeaponMods = null //[] or null
   secondaryWeaponMods = null //{} or null
   type = -1 //used in weapons.nut, but no any reason to be here
   guiPosIdx = -1
   bulGroups = -1
   bulModsGroups = -1
   bulletsSets = null //{}
   primaryBulletsInfo = null //[] or null
   shopReq = true //used in shop, but look like shop can get it from other sources than from unit.


  //unit table generated by native function gather_and_build_aircrafts_list
  constructor(unitTbl)
  {
    //!!FIX ME: Is it really required? we can init units by unittags self without native code
    foreach(key, value in unitTbl)
      if (key in this)
        this[key] = value

    foreach(key in ["tags", "weapons", "modifications", "skins", "weaponUpgrades", "needBuyToOpenNextInTier"])
      if (!u.isArray(this[key]))
        this[key] = []
    foreach(key in ["shop", "info", "primaryBullets", "secondaryBullets", "bulletsSets"])
      if (!u.isTable(this[key]))
        this[key] = {}
  }

  function setFromUnit(unit)
  {
    foreach(key, value in unit)
      if (!u.isFunction(value)
        && (key in this)
        && !u.isFunction(this[key])
      )
        this[key] = value
    return this
  }

  function initOnce()
  {
    if (isInited)
      return
    isInited = true
    local errorsTextArray = []

    local warpoints = ::get_warpoints_blk()
    local uWpCost = getUnitWpCostBlk()
    if (!u.isDataBlock(uWpCost))
      uWpCost = ::DataBlock() //units list generated by airtags blk, so they can be missing in warpoints.blk

    local expClassStr = uWpCost.unitClass
    if (::isInArray("ship", tags) || ::isInArray("type_ship", tags))
      expClassStr = "exp_ship" // Temporary hack for Ships research tree.
    expClass = ::g_unit_class_type.getTypeByExpClass(expClassStr)
    esUnitType = expClass.unitTypeCode
    unitType = ::g_unit_type.getByEsUnitType(esUnitType)

    foreach(p in [
      "costGold", "rank", "reqExp",
      "repairCost", "repairTimeHrsArcade", "repairTimeHrsHistorical", "repairTimeHrsSimulation",
      "train2Cost", "train3Cost_gold", "train3Cost_exp",
      "gunnersCount", "bulletsIconParam"
    ])
      this[p] = uWpCost[p] ?? 0

    cost                      = uWpCost.value || 0
    freeRepairs               = uWpCost?.freeRepairs ?? warpoints?.freeRepairs ?? 0
    expMul                    = uWpCost.expMul ?? 1.0
    shopCountry               = uWpCost.country ?? ""
    trainCost                 = uWpCost.trainCost ?? warpoints.trainCostByRank?["rank"+rank] ?? 0
    gift                      = uWpCost.gift
    giftParam                 = uWpCost.giftParam
    premPackAir               = uWpCost.premPackAir ?? false
    hasDepthCharge            = uWpCost.hasDepthCharge ?? shop_is_modification_enabled(name, "ship_depth_charge")
    hasMines                  = uWpCost.hasMines ?? shop_is_modification_enabled(name, "ship_mines")
    commonWeaponImage         = uWpCost.commonWeaponImage ?? commonWeaponImage
    customClassIco            = uWpCost.customClassIco
    customTooltipImage        = uWpCost.customTooltipImage
    isPkgDev                  = ::is_dev_version && uWpCost.pkgDev ?? false

    foreach (weapon in weapons)
      weapon.type <- ::g_weaponry_types.WEAPON.type

    if (u.isDataBlock(uWpCost.weapons))
    {
      foreach (weapon in weapons)
        initWeaponry(weapon, uWpCost.weapons[weapon.name])
      initWeaponryUpgrades(this, uWpCost)
    }

    if (u.isDataBlock(uWpCost.modifications))
      foreach(modName, modBlk in uWpCost.modifications)
      {
        local mod = { name = modName, type = ::g_weaponry_types.MODIFICATION.type }
        modifications.append(mod)
        initWeaponry(mod, modBlk)
        initWeaponryUpgrades(mod, modBlk)
        if (::is_modclass_expendable(mod))
          mod.type = ::g_weaponry_types.EXPENDABLES.type

        if (modBlk.maxToRespawn)
          mod.maxToRespawn <- modBlk.maxToRespawn

        //validate prevModification. it used in gui only.
        if (("prevModification" in mod) && !(uWpCost.modifications[mod.prevModification]))
          errorsTextArray.append(format("Not exist prevModification '%s' for '%s' (%s)",
                                 delete mod.prevModification, modName, name))
      }

    if (u.isDataBlock(uWpCost.spare))
    {
      spare = {
        name = "spare"
        type = ::g_weaponry_types.SPARE.type
        cost = uWpCost.spare.value || 0
        image = ::get_weapon_image(esUnitType, ::get_modifications_blk().modifications?.spare, uWpCost.spare)
      }
      if (uWpCost.spare.costGold != null)
        spare.costGold <- uWpCost.spare.costGold
    }

    for(local i = 1; i <= MOD_TIERS_COUNT; i++)
      needBuyToOpenNextInTier.append(uWpCost["needBuyToOpenNextInTier" + i] || 0)

    customImage = uWpCost.customImage ?? ::get_unit_preset_img(name)
    if (!customImage && ::is_tencent_unit_image_reqired(this))
      customImage = ::get_tomoe_unit_icon(name)
    if (customImage && !::isInArray(customImage.slice(0, 1), ["#", "!"]))
      customImage = ::get_unit_icon_by_unit(this, customImage)

    return errorsTextArray
  }

  function applyShopBlk(shopUnitBlk, prevShopUnitName, unitGroupName = null)
  {
    isInShop = true
    reqAir = prevShopUnitName
    group = unitGroupName

    local isVisibleUnbought = !shopUnitBlk.showOnlyWhenBought
      && ::has_platform_from_blk_str(shopUnitBlk, "showByPlatform", true)
      && !::has_platform_from_blk_str(shopUnitBlk, "hideByPlatform", false)

    showOnlyWhenBought = !isVisibleUnbought
    showOnlyWhenResearch = shopUnitBlk.showOnlyWhenResearch

    if (isVisibleUnbought && u.isString(shopUnitBlk.hideForLangs))
      hideForLangs = ::split(shopUnitBlk.hideForLangs, "; ")

    foreach(key in ["reqFeature", "hideFeature", "showOnlyIfPlayerHasUnlock", "reqUnlock"])
      if (!u.isEmpty(shopUnitBlk[key]))
        this[key] = shopUnitBlk[key]

    gift = shopUnitBlk.gift //we already got it from wpCost. is we still need it here?
    giftParam = shopUnitBlk.giftParam
  }

  isAir                 = @() esUnitType == ::ES_UNIT_TYPE_AIRCRAFT
  isTank                = @() esUnitType == ::ES_UNIT_TYPE_TANK
  isShip                = @() esUnitType == ::ES_UNIT_TYPE_SHIP

  getUnitWpCostBlk      = @() ::get_wpcost_blk()[name]
  isBought              = @() ::shop_is_aircraft_purchased(name)
  isUsable              = @() ::shop_is_player_has_unit(name)
  isRented              = @() ::shop_is_unit_rented(name)
  getRentTimeleft       = @() ::rented_units_get_expired_time_sec(name)
  getRepairCost         = @() ::Cost(::wp_get_repair_cost(name))
  getCrewTotalCount     = @() getUnitWpCostBlk()?.crewTotalCount || 1

  repair                = @(onSuccessCb = null) unitActions.repairWithMsgBox(this, onSuccessCb)

  _isRecentlyReleased = null
  function isRecentlyReleased()
  {
    if (_isRecentlyReleased != null)
      return _isRecentlyReleased

    local res = false
    local releaseDate = ::get_unittags_blk()?[name]?.releaseDate
    if (releaseDate)
    {
      local recentlyReleasedUnitsDays = ::configs.GUI.get().markRecentlyReleasedUnitsDays || 0
      if (recentlyReleasedUnitsDays)
      {
        local releaseTime = ::get_t_from_utc_time(time.getTimeFromStringUtc(releaseDate))
        res = releaseTime + time.daysToSeconds(recentlyReleasedUnitsDays) > ::get_charserver_time_sec()
      }
    }

    _isRecentlyReleased = res
    return _isRecentlyReleased
  }

  function getEconomicRank(ediff)
  {
    return ::get_unit_blk_economic_rank_by_mode(getUnitWpCostBlk(), ediff)
  }

  function getBattleRating(ediff)
  {
    if (!::CAN_USE_EDIFF)
      ediff = ediff % EDIFF_SHIFT
    local mrank = getEconomicRank(ediff)
    return ::calc_battle_rating_from_rank(mrank)
  }

  function getWpRewardMulList(difficulty = ::g_difficulty.ARCADE)
  {
    local warpoints = ::get_warpoints_blk()
    local uWpCost = getUnitWpCostBlk()
    local mode = difficulty.getEgdName()

    local premPart = ::isUnitSpecial(this) ? warpoints?.rewardMulVisual?.premRewardMulVisualPart ?? 0.5 : 0.0
    local mul = (uWpCost?["rewardMul" + mode] ?? 1.0) *
      (warpoints?.rewardMulVisual?["rewardMulVisual" + mode] ?? 1.0)

    return {
      wpMul   = ::round_by_value(mul * (1.0 - premPart), 0.1)
      premMul = ::round_by_value(1.0 / (1.0 - premPart), 0.1)
    }
  }

  function _tostring()
  {
    return "Unit( " + name + " )"
  }

  function canAssignToCrew(country)
  {
    return ::getUnitCountry(this) == country && canUseByPlayer()
  }

  function canUseByPlayer()
  {
    return isUsable() && isVisibleInShop() && unitType.isAvailable()
  }

  function isVisibleInShop()
  {
    if (!isInShop || !unitType.isVisibleInShop())
      return false
    if (::is_debug_mode_enabled || isUsable())
      return true
    if (showOnlyWhenBought)
      return false
    if (hideForLangs && hideForLangs.find(::g_language.getLanguageName()) >= 0)
      return false
    if (showOnlyIfPlayerHasUnlock && !::is_unlocked_scripted(-1, showOnlyIfPlayerHasUnlock))
      return false
    if (showOnlyWhenResearch && !isUnitInResearch(this) && getUnitExp(this) <= 0)
      return false
    return true
  }

  /*************************************************************************************************/
  /************************************PRIVATE FUNCTIONS *******************************************/
  /*************************************************************************************************/

  //!!FIX ME: better to convert weapons and modifications to class
  function initWeaponry(weaponry, blk)
  {
    local weaponBlk = ::get_modifications_blk().modifications?[weaponry.name]
    if (blk?.value != null)
      weaponry.cost <- blk.value
    if (blk?.costGold)
    {
      weaponry.costGold <- blk.costGold
      weaponry.cost <- 0
    }
    weaponry.tier <- blk?.tier? blk.tier.tointeger() : 1
    weaponry.modClass <- blk?.modClass || weaponBlk?.modClass || ""
    weaponry.image <- ::get_weapon_image(esUnitType, weaponBlk, blk)
    weaponry.requiresModelReload <- weaponBlk?.requiresModelReload ?? false

    if (weaponry.name == "tank_additional_armor")
      weaponry.requiresModelReload <- true

    if (::isInArray(weaponry.name, needCollectEffects))
    {
      local cbFunc = function(effect, ...) { weaponry.effects <- effect }
      ::calculate_mod_or_weapon_effect(name, weaponry.name, true, this, cbFunc, null)
    }

    foreach(p in weaponProperties)
    {
      local val = blk?[p] ?? weaponBlk?[p]
      if (val != null)
        weaponry[p] <- val
    }

    local prevModification = blk?["prevModification"] || weaponBlk?["prevModification"]
    if (u.isString(prevModification) && prevModification.len())
      weaponry["prevModification"] <- prevModification

    if (u.isDataBlock(blk))
      foreach(rp in reqNames)
      {
        local reqData = []
        foreach (req in (blk % rp))
          if (u.isString(req) && req.len())
            reqData.append(req)
        if (reqData.len() > 0)
          weaponry[rp] <- reqData
      }
  }

  function initWeaponryUpgrades(upgradesTarget, blk)
  {
    foreach(upgradeName in upgradeNames)
    {
      if (!blk[upgradeName])
        break

      if (!("weaponUpgrades" in upgradesTarget))
        upgradesTarget.weaponUpgrades <- []
      upgradesTarget.weaponUpgrades.append(::split(blk[upgradeName], "/"))
    }
  }

  function resetSkins()
  {
    skins = []
  }

  function getSkins()
  {
    if (skins.len() == 0)
      skins = ::get_skins_for_unit(name) //always returns at least one entry
    return skins
  }

  function getPreviewSkinId()
  {
    if (!previewSkinId)
    {
      previewSkinId = ""
      foreach (skin in getSkins())
        if (::g_decorator.getDecorator(name + "/" + skin.name, ::g_decorator_type.SKINS)?.blk?.useByDefault)
          previewSkinId = skin.name
    }
    return previewSkinId
  }

  getSpawnScore = @(weaponName = null) ::shop_get_spawn_score(name, weaponName || ::get_last_weapon(name))

  function getMinimumSpawnScore()
  {
    local res = -1
    foreach (weapon in weapons)
      if (::is_weapon_visible(this, weapon) && ::is_weapon_enabled(this, weapon))
      {
        local spawnScore = getSpawnScore(weapon.name)
        if (res < 0 || res > spawnScore)
          res = spawnScore
      }
    return ::max(res, 0)
  }

  function invalidateModificators()
  {
    if (modificatorsRequestTime > 0)
    {
      ::remove_calculate_modification_effect_jobs()
      modificatorsRequestTime = -1
    }
    modificators = null
  }

  function canPreview()
  {
    return isInShop
  }

  function doPreview()
  {
    if (canPreview())
      ugcPreview.showUnitSkin(name)
  }
}

u.registerClass("Unit", Unit, @(u1, u2) u1.name == u2.name, @(unit) !unit.name.len())

return Unit