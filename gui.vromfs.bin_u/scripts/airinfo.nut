enum bit_unit_status
{
  locked      = 1
  canResearch = 2
  inResearch  = 4
  researched  = 8
  canBuy      = 16
  owned       = 32
  mounted     = 64
  disabled    = 128
  broken      = 256
  inRent      = 512
}

enum unit_rarity
{
  reserve,
  common,
  premium,
  gift
}

enum CheckFeatureLockAction
{
  BUY,
  RESEARCH
}

::chances_text <- [
  { text = "chance_to_met/high",    color = "@chanceHighColor",    brDiff = 0.0 }
  { text = "chance_to_met/average", color = "@chanceAverageColor", brDiff = 0.34 }
  { text = "chance_to_met/low",     color = "@chanceLowColor",     brDiff = 0.71 }
  { text = "chance_to_met/never",   color = "@chanceNeverColor",   brDiff = 1.01 }
]

function getUnitItemStatusText(bitStatus, isGroup = false)
{
  local statusText = ""
  if (bit_unit_status.locked & bitStatus)
    statusText = "locked"
  else if (bit_unit_status.broken & bitStatus)
    statusText = "broken"
  else if (bit_unit_status.disabled & bitStatus)
    statusText = "disabled"

  if (!isGroup && statusText != "")
    return statusText

  if (bit_unit_status.inResearch & bitStatus)
    statusText = "research"
  else if (bit_unit_status.mounted & bitStatus)
    statusText = "mounted"
  else if (bit_unit_status.owned & bitStatus || bit_unit_status.inRent & bitStatus)
    statusText = "owned"
  else if (bit_unit_status.canBuy & bitStatus)
    statusText = "canBuy"
  else if (bit_unit_status.researched & bitStatus)
    statusText = "researched"
  else if (bit_unit_status.canResearch & bitStatus)
    statusText = "canResearch"
  return statusText
}


::basic_unit_roles <- {
  [::ES_UNIT_TYPE_AIRCRAFT] = ["fighter", "assault", "bomber", "helicopter"],
  [::ES_UNIT_TYPE_TANK] = ["tank", "light_tank", "medium_tank", "heavy_tank", "tank_destroyer", "spaa"],
  [::ES_UNIT_TYPE_SHIP] = ["ship", "torpedo_boat", "gun_boat", "torpedo_gun_boat", "submarine_chaser", "destroyer", "naval_ferry_barge"],
}

::unit_role_fonticons <- {
  fighter         = ::loc("icon/unitclass/fighter"),
  assault         = ::loc("icon/unitclass/assault"),
  bomber          = ::loc("icon/unitclass/bomber"),
  helicopter      = ::loc("icon/unitclass/assault"),
  light_tank      = ::loc("icon/unitclass/light_tank"),
  medium_tank     = ::loc("icon/unitclass/medium_tank"),
  heavy_tank      = ::loc("icon/unitclass/heavy_tank"),
  tank_destroyer  = ::loc("icon/unitclass/tank_destroyer"),
  spaa            = ::loc("icon/unitclass/spaa"),
  ship            = ::loc("icon/unitclass/ship"),
}

::unit_role_by_tag <- {
  type_light_fighter = "light_fighter",
  type_medium_fighter = "medium_fighter",
  type_heavy_fighter = "heavy_fighter",
  type_naval_fighter = "naval_fighter",
  type_jet_fighter = "jet_fighter",
  type_light_bomber = "light_bomber",
  type_medium_bomber = "medium_bomber",
  type_heavy_bomber = "heavy_bomber",
  type_naval_bomber = "naval_bomber",
  type_jet_bomber = "jet_bomber",
  type_dive_bomber = "dive_bomber",
  type_common_bomber = "common_bomber", //to use as a second type: "Light fighter / Bomber"
  type_common_assault = "common_assault",
  type_strike_fighter = "strike_fighter",

  //tanks:
  type_tank = "tank" //used in profile stats
  type_light_tank = "light_tank",
  type_medium_tank = "medium_tank",
  type_heavy_tank = "heavy_tank",
  type_tank_destroyer = "tank_destroyer",
  type_spaa = "spaa",

  //ships:
  type_ship = "ship",

  //basic types
  type_fighter = "medium_fighter",
  type_assault = "common_assault",
  type_bomber = "medium_bomber"
}

::unit_role_by_name <- {}

::unlock_condition_unitclasses <- {
    aircraft          = ::ES_UNIT_TYPE_AIRCRAFT
    tank              = ::ES_UNIT_TYPE_TANK
    typeLightTank     = ::ES_UNIT_TYPE_TANK
    typeMediumTank    = ::ES_UNIT_TYPE_TANK
    typeHeavyTank     = ::ES_UNIT_TYPE_TANK
    typeSPG           = ::ES_UNIT_TYPE_TANK
    typeSPAA          = ::ES_UNIT_TYPE_TANK
    typeTankDestroyer = ::ES_UNIT_TYPE_TANK
    typeFighter       = ::ES_UNIT_TYPE_AIRCRAFT
    typeDiveBomber    = ::ES_UNIT_TYPE_AIRCRAFT
    typeBomber        = ::ES_UNIT_TYPE_AIRCRAFT
    typeAssault       = ::ES_UNIT_TYPE_AIRCRAFT
    typeStormovik     = ::ES_UNIT_TYPE_AIRCRAFT
    typeTransport     = ::ES_UNIT_TYPE_AIRCRAFT
    typeStrikeFighter = ::ES_UNIT_TYPE_AIRCRAFT
}

function get_unit_role(unitData) //  "fighter", "bomber", "assault", "transport", "diveBomber", "none"
{
  local unit = unitData
  if (typeof(unitData) == "string")
    unit = getAircraftByName(unitData);

  if (!unit)
    return ""; //not found

  local role = ::getTblValue(unit.name, ::unit_role_by_name, "")
  if (role == "")
  {
    foreach(tag in unit.tags)
      if (tag in ::unit_role_by_tag)
      {
        role = ::unit_role_by_tag[tag]
        break
      }
    ::unit_role_by_name[unit.name] <- role
  }

  return role
}

function haveUnitRole(unit, role)
{
  return ::isInArray("type_" + role, unit.tags)
}

function get_unit_basic_role(unit)
{
  local unitType = ::get_es_unit_type(unit)
  local basicRoles = ::getTblValue(unitType, ::basic_unit_roles)
  if (!basicRoles || !basicRoles.len())
    return ""

  foreach(role in basicRoles)
    if (::haveUnitRole(unit, role))
      return role
  return basicRoles[0]
}

function get_role_text(role)
{
  return ::loc("mainmenu/type_" + role)
}

function get_full_unit_role_text(unit)
{
  if (!("tags" in unit) || !unit.tags)
    return ""

  if (::is_helicopter(unit))
    return ::get_role_text("helicopter")

  local basicRoles = ::getTblValue(::get_es_unit_type(unit), ::basic_unit_roles, [])
  local textsList = []
  foreach(tag in unit.tags)
    if (tag.len()>5 && tag.slice(0, 5)=="type_" && !isInArray(tag.slice(5), basicRoles))
      textsList.append(::loc("mainmenu/"+tag))

  if (textsList.len())
    return ::implode(textsList, ::loc("mainmenu/unit_type_separator"))

  foreach (t in basicRoles)
    if (isInArray("type_" + t, unit.tags))
      return ::get_role_text(t)
  return ""
}

/*
  typeof @source == "table"  -> @source is unit
  typeof @source == "string" -> @source is role id
*/
function get_unit_role_icon(source)
{
  if (::u.isTable(source) && ::is_helicopter(source))
    return ::unit_role_fonticons.helicopter
  if (typeof source == "table")
    return ::getTblValue(::get_unit_basic_role(source), ::unit_role_fonticons, "")
  return ::getTblValue(source, ::unit_role_fonticons, "")
}

function get_unit_actions_list(unit, handler, prefix, actions)
{
  local res = {
    handler = handler
    actions = []
  }

  if (!unit || ("airsGroup" in unit) || actions.len()==0 || ::is_in_loading_screen())
    return res

  local inMenu = ::isInMenu()
  local isUsable  = unit.isUsable()
  local profile   = ::get_profile_info()
  local crew = ::getCrewIdTblByAir(unit)

  foreach(action in actions)
  {
    local actionText = ""
    local showAction = false
    local actionFunc = null
    local haveWarning  = false
    local haveDiscount = false
    local enabled    = true
    local icon       = ""
    local isLink = false

    if (action == "showroom")
    {
      actionText = ::loc(isUsable ? "mainmenu/btnShowroom" : "mainmenu/btnPreview")
      icon       = "#ui/gameuiskin#slot_showroom"
      showAction = inMenu
      actionFunc = (@(unit, handler) function () {
        handler.checkedCrewModify((@(unit, handler) function () {
          ::broadcastEvent("ShowroomOpened")
          ::show_aircraft = unit
          handler.goForward(::gui_start_decals)
        })(unit, handler))
      })(unit, handler)
    }
    else if (action == "aircraft")
    {
      if (!crew)
        continue

      actionText = ::loc("multiplayer/changeAircraft")
      icon       = "#ui/gameuiskin#slot_change_aircraft"
      showAction = inMenu && ::SessionLobby.canChangeCrewUnits()
      actionFunc = (@(crew, handler) function () {
        handler.onSlotChangeAircraft(crew)
      })(crew, handler)
    }
    else if (action == "crew")
    {
      if (!crew)
        continue

      local discountInfo = ::g_crew.getDiscountInfo(crew.countryId, crew.idInCountry)

      actionText = ::loc("mainmenu/btnCrew")
      icon       = "#ui/gameuiskin#slot_crew"
      haveWarning = ::isInArray(::get_crew_status_by_id(crew.crewId), [ "ready", "full" ])
      haveDiscount = ::g_crew.getMaxDiscountByInfo(discountInfo) > 0
      showAction = inMenu
      actionFunc = (@(crew) function () {
        if (crew)
          ::gui_modal_crew(crew.countryId, crew.idInCountry)
      })(crew)
    }
    else if (action == "weapons")
    {
      actionText = ::loc("mainmenu/btnWeapons")
      icon       = "#ui/gameuiskin#slot_weapons"
      haveWarning = ::checkUnitWeapons(unit.name) != ::UNIT_WEAPONS_READY
      haveDiscount = ::get_max_weaponry_discount_by_unitName(unit.name) > 0
      showAction = inMenu
      actionFunc = (@(unit) function () { ::open_weapons_for_unit(unit) })(unit)
    }
    else if (action == "take")
    {
      actionText = ::loc("mainmenu/btnTakeAircraft")
      icon       = "#ui/gameuiskin#slot_crew"
      showAction = inMenu && isUsable && !::isUnitInSlotbar(unit)
      actionFunc = (@(unit, handler) function () {
        handler.onTake(unit)
      })(unit, handler)
    }
    else if (action == "repair")
    {
      actionText = ::loc("mainmenu/btnRepair")+": "+::wp_get_repair_cost(unit.name)+::loc("warpoints/short")
      if (::wp_get_repair_cost(unit.name)>profile.balance)
        actionText = ::loc("mainmenu/btnRepair")+": <color=@redMenuButtonColor>"+::wp_get_repair_cost(unit.name)+"</color>"+::loc("warpoints/short")

      icon       = "#ui/gameuiskin#slot_repair"
      haveWarning = true
      showAction = inMenu && isUsable && ::wp_get_repair_cost(unit.name)>0
      actionFunc = (@(unit, handler) function () {
        handler.showMsgBoxRepair.call(handler, unit, (@(unit) function () {::check_and_repair_unit(unit)})(unit))
      })(unit, handler)
    }
    else if (action == "buy")
    {
      local isSpecial   = ::isUnitSpecial(unit)
      local isGift   = ::isUnitGift(unit)
      local canBuyOnline = ::canBuyUnitOnline(unit)
      local canBuyIngame = !canBuyOnline && ::canBuyUnit(unit)
      local priceText = ""

      if (canBuyIngame)
      {
        priceText = getPriceText(::wp_get_cost(unit.name), ::wp_get_cost_gold(unit.name))
        if (priceText.len())
        {
          if ((isSpecial && wp_get_cost_gold(unit.name) > profile.gold) || (wp_get_cost(unit.name) > profile.balance))
            priceText = "<color=@redMenuButtonColor>" + priceText + "</color>"
          priceText = ::loc("ui/colon") + priceText
        }
      }

      actionText = ::loc("mainmenu/btnOrder") + priceText
      icon       = isGift ? "#ui/gameuiskin#store_icon" : isSpecial ? "#ui/gameuiskin#shop_warpoints_premium" : "#ui/gameuiskin#shop_warpoints"
      showAction = inMenu && (canBuyIngame || canBuyOnline)
      if (canBuyOnline)
        actionFunc = (@(unit) function () {
          OnlineShopModel.showGoods({
            unitName = unit.name
          })
        })(unit)
      else
        actionFunc = (@(unit) function () {
          ::buyUnit(unit)
        })(unit)
    }
    else if (action == "research")
    {
      local countryExp = ::shop_get_country_excess_exp(::getUnitCountry(unit), ::get_es_unit_type(unit))
      local reqExp = ::getUnitReqExp(unit) - ::getUnitExp(unit)
      local getReqExp = reqExp < countryExp ? reqExp : countryExp
      local needToFlushExp = handler.shopResearchMode && countryExp > 0

      actionText = needToFlushExp
                   ? ::format(::loc("mainmenu/btnResearch") + " (%s)", ::getRpPriceText(getReqExp, true))
                   : ( ::isUnitInResearch(unit) && handler.setResearchManually
                      ? ::loc("mainmenu/btnConvert")
                      : ::loc("mainmenu/btnResearch"))
      //icon       = "#ui/gameuiskin#slot_research"
      showAction = inMenu && (!::isUnitInResearch(unit) || ::has_feature("SpendGold")) && (::isUnitFeatureLocked(unit) || ::canResearchUnit(unit))
      enabled = showAction
      actionFunc = needToFlushExp
                  ? (@(handler) function() {handler.onSpendExcessExp()})(handler)
                  : ( !handler.setResearchManually?
                      (@(handler) function () { handler.onCloseShop() })(handler)
                      : (::isUnitInResearch(unit) ?
                          (@(unit, handler) function () { ::gui_modal_convertExp(unit, handler) })(unit, handler)
                          : (@(unit) function () { if (::checkForResearch(unit))
                                                         ::researchUnit(unit)})(unit)))
    }
    else if (action == "testflight")
    {
      actionText = unit.unitType.getTestFlightText()
      icon       = unit.unitType.testFlightIcon
      showAction = inMenu && ::isTestFlightAvailable(unit)
      actionFunc = (@(unit, handler) function () {
        handler.checkedCrewModify((@(unit) function () {
          ::show_aircraft = unit
          ::test_flight_aircraft <- unit
          ::gui_start_testflight()
        })(unit))
      })(unit, handler)
    }
    else if (action == "info")
    {
      actionText = ::loc("mainmenu/btnAircraftInfo")
      icon       = "#ui/gameuiskin#slot_info"
      showAction = ::isUnitDescriptionValid(unit)
      isLink     = ::has_feature("WikiUnitInfo")
      actionFunc = (@(unit) function () {
        if (::has_feature("WikiUnitInfo"))
          ::open_url(::format(::loc("url/wiki_objects"), unit.name), false, false, "unit_actions")
        else
          ::gui_start_aircraft_info(unit.name)
      })(unit)
    }
    else if (action == "rankinfo")
    {
      local validGameModes = ::game_mode_manager.getGameModes(get_es_unit_type(unit))
      actionText = ::loc("mainmenu/btnAircraftRankInfo")
      icon       = "#ui/gameuiskin#slot_rank_info"
      showAction = ::has_feature("RankVersusInfo") && validGameModes.len() != 0
      actionFunc = (@(unit) function () { ::gui_modal_rank_versus_info(unit) })(unit)
    }

    res.actions.append({
      actionName   = action
      text         = actionText
      show         = showAction
      enabled      = enabled
      icon         = icon
      action       = actionFunc
      haveWarning  = haveWarning
      haveDiscount = haveDiscount
      isLink       = isLink
    })
  }

  return res
}

function isAircraft(unit)
{
  return get_es_unit_type(unit) == ::ES_UNIT_TYPE_AIRCRAFT
}

function isShip(unit)
{
  return get_es_unit_type(unit) == ::ES_UNIT_TYPE_SHIP
}

function isTank(unit)
{
  return get_es_unit_type(unit) == ::ES_UNIT_TYPE_TANK
}

function is_helicopter(unit)
{
  return get_es_unit_type(unit) == ::ES_UNIT_TYPE_AIRCRAFT && ::isInArray("helicopter", ::getTblValue("tags", unit, []))
}

function get_es_unit_type(unit)
{
  return ::getTblValue("esUnitType", unit, ::ES_UNIT_TYPE_INVALID)
}

function getUnitTypeTextByUnit(unit)
{
  return ::getUnitTypeText(::get_es_unit_type(unit))
}

function isCountryHaveUnitType(country, unitType)
{
  foreach(unit in ::all_units)
    if (unit.shopCountry == country && ::get_es_unit_type(unit) == unitType)
      return true
  return false
}

function getSumByUnitTypeText(dataTbl, keyFormat = "")
{
  local sum = 0.0
  foreach(t in ::unitTypesList)
  {
    local typeText = getUnitTypeText(t)
    local key = (keyFormat=="")? typeText : format(keyFormat, typeText)
    sum += ::getTblValue(key, dataTbl, 0)
  }
  return sum
}

function getUnitRarity(unit)
{
  if (::isUnitDefault(unit))
    return "reserve"
  if (::isUnitSpecial(unit))
    return "premium"
  if (::isUnitGift(unit))
    return "gift"
  return "common"
}

function isUnitsEraUnlocked(unit)
{
  return ::is_era_available(::getUnitCountry(unit), ::getUnitRank(unit), ::get_es_unit_type(unit))
}

function getUnitsNeedBuyToOpenNextInEra(countryId, unitType, rank, ranksBlk = null)
{
  ranksBlk = ranksBlk || ::get_ranks_blk()
  local unitTypeText = getUnitTypeText(unitType)

  local commonPath = "needBuyToOpenNextInEra." + countryId + ".needBuyToOpenNextInEra"

  local needToOpen = ::getTblValueByPath(commonPath + unitTypeText + rank, ranksBlk)
  if (needToOpen != null)
    return needToOpen

  needToOpen = ::getTblValue(commonPath + rank, ranksBlk)
  if (needToOpen != null)
    return needToOpen

  return -1
}

function getUnitRank(unit)
{
  if (!unit)
    return -1
  return unit.rank
}

function getUnitCountry(unit)
{
  return ::getTblValue("shopCountry", unit, "")
}

function isUnitDefault(unit)
{
  if (!("name" in unit))
    return false
  return ::is_default_aircraft(unit.name)
}

function isUnitGift(unit)
{
  return "gift" in unit
}

function get_unit_country_icon(unit)
{
  return (unit.shopCountry != "") ? ::get_country_icon(unit.shopCountry) : ""
}

function checkAirShopReq(air)
{
  return ::getTblValue("shopReq", air, true)
}

function isUnitGroup(unit)
{
  return unit && "airsGroup" in unit
}

function isGroupPart(unit)
{
  return unit && ::getTblValue("group", unit, "") != ""
}

function canResearchUnit(unit)
{
  local isInShop = ::getTblValue("isInShop", unit)
  if (isInShop == null)
  {
    debugTableData(unit)
    ::dagor.assertf(false, "not existing isInShop param")
    return false
  }

  if (!isInShop)
    return false

  local status = ::shop_unit_research_status(unit.name)
  return (0 != (status & (::ES_ITEM_STATUS_IN_RESEARCH | ::ES_ITEM_STATUS_CAN_RESEARCH))) && !::isUnitMaxExp(unit)
}

function canBuyUnit(unit)
{
  //temporary check while shop_is_unit_available is broken
  /*
  if (::isUnitGift(unit))
    return false

  if (::isUnitSpecial(unit) && !::isUnitBought(unit))
    return true

  if(!("name" in unit))
    return false
  */
  local status = ::shop_unit_research_status(unit.name)
  return (0 != (status & ::ES_ITEM_STATUS_CAN_BUY)) && ::is_unit_visible_in_shop(unit)
}

function is_unit_visible_in_shop(unit)
{
  if (!unit.isInShop || !unit.unitType.isVisibleInShop())
    return false

  if (::is_debug_mode_enabled)
    return true

  local showOnlyBought = ::getTblValue("showOnlyWhenBought", unit, false)
  if (!showOnlyBought)
  {
    local langs = ::getTblValue("hideForLangs", unit)
    if (langs)
      showOnlyBought = langs.find(::g_language.getLanguageName()) >= 0
  }

  local showOnlyWhenResearch = getTblValue("showOnlyWhenResearch", unit, false)
  return unit.isUsable() ||
    (!showOnlyBought &&
    (!showOnlyWhenResearch || isUnitInResearch(unit) || getUnitExp(unit) > 0))
}

function can_crew_take_unit(unit)
{
  return isUnitUsable(unit) && is_unit_visible_in_shop(unit)
}

function canBuyUnitOnline(unit)
{
  return !::isUnitBought(unit) && ::isUnitGift(unit)
}

function isUnitInResearch(unit)
{
  if (!unit)
    return false

  if(!("name" in unit))
    return false

  local status = ::shop_unit_research_status(unit.name)
  return (status == ::ES_ITEM_STATUS_IN_RESEARCH) && !::isUnitMaxExp(unit)
}

function findUnitNoCase(unitName)
{
  unitName = unitName.tolower()
  foreach(name, unit in ::all_units)
    if (name.tolower() == unitName)
      return unit
  return null
}

function getCountryResearchUnit(countryName, unitType)
{
  local unitName = ::shop_get_researchable_unit_name(countryName, unitType)
  return ::getAircraftByName(unitName)
}

function getUnitName(unit, shopName = true)
{
  local unitId = (typeof(unit) == "string") ? unit : (typeof(unit) == "table") ? unit.name : ""
  local localized = ::loc(unitId + (shopName ? "_shop" : "_0"), unitId)
  return shopName ? ::stringReplace(localized, " ", ::nbsp) : localized
}

function isUnitDescriptionValid(unit)
{
  if (::is_platform_pc)
    return true // Because there is link to wiki.
  local desc = unit ? ::loc("encyclopedia/" + unit.name + "/desc", "") : ""
  return desc != "" && desc != ::loc("encyclopedia/no_unit_description")
}

function getUnitRealCost(unit)
{
  return ::Cost(unit.cost, unit.costGold)
}

function getUnitCost(unit)
{
  return ::Cost(::wp_get_cost(unit.name),
                ::wp_get_cost_gold(unit.name))
}

function isUnitBought(unit = null)
{
  if (unit == null)
    unit = this
  local unitName = ::getTblValue("name", unit)
  return unitName ? ::shop_is_aircraft_purchased(unitName) : false
}

function isUnitElite(unit)
{
  return ::get_unit_elite_status(unit.name) > ::ES_UNIT_ELITE_STAGE1
         || (!unit.isFirstBattleAward && ::isUnitSpecial(unit))
}

function isUnitBroken(unit)
{
  return ::getUnitRepairCost(unit) > 0
}

/**
 * Returns true if unit can be installed in slotbar,
 * unit can be decorated with decals, etc...
 */
function isUnitUsable(unit = null)
{
  if (unit == null)
    unit = this
  local unitName = ::getTblValue("name", unit)
  return unitName != null ? ::shop_is_player_has_unit(unitName) : false
}

function isUnitRented(unit = null)
{
  if (unit == null)
    unit = this
  local unitName = ::getTblValue("name", unit)
  return unitName != null ? ::shop_is_unit_rented(unitName) : false
}

/**
 * Returns time in seconds.
 */
function getUnitRentTimeleft(unit = null)
{
  if (unit == null)
    unit = this
  local unitName = ::getTblValue("name", unit)
  return unitName != null ? ::rented_units_get_expired_time_sec(unitName) : -1
}

function isUnitFeatureLocked(unit)
{
  local featureName = ::getUnitReqFeature(unit)
  return (featureName != "") && !::has_feature(featureName)
}

function getUnitReqFeature(unit)
{
  return ::getTblValue("reqFeature", unit, "")
}

function checkUnitHideFeature(unit)
{
  local feature = ::getTblValue("hideFeature", unit, null)
  if (feature == null)
    return true
  return ::has_feature(feature)
}

function getUnitRepairCost__m(unit)
{
  local cost = Cost()
  if ("name" in unit)
    cost.wp = ::wp_get_repair_cost(unit.name)
  return cost
}

function getUnitRepairCost(unit)
{
  if ("name" in unit)
    return ::wp_get_repair_cost(unit.name)
  return 0
}

function buyUnit(unit, silent = false)
{
  if (!::checkFeatureLock(unit, CheckFeatureLockAction.BUY))
    return false

  local unitCost = ::getUnitCost(unit)
  if (::isTank(unit) && unitCost.gold > 0 && !::has_feature("SpendGoldForTanks"))
  {
    ::showInfoMsgBox(::loc("msgbox/tanksRestrictFromSpendGold"), "not_available_goldspend")
    return false
  }

  if (!::canBuyUnit(unit))
  {
    if (::isUnitResearched(unit) && !silent)
      ::checkPrevUnit(unit)
    return false
  }

  if (silent)
    return ::impl_buyUnit(unit)

  local unitName  = ::colorize("userlogColoredText", ::getUnitName(unit, true))
  local unitPrice = ::colorize("activeTextColor", ::getUnitCost(unit))
  local msgText = ::loc("shop/needMoneyQuestion_purchaseAircraft", { unitName = unitName, cost = unitPrice })

  local additionalCheckBox = null
  if (::facebook_is_logged_in() && ::has_feature("FacebookWallPost"))
  {
    additionalCheckBox = "cardImg{ background-image:t='#ui/gameuiskin#facebook_logo';}" +
                     "CheckBox {" +
                      "id:t='chbox_post_facebook_purchase'" +
                      "text:t='#facebook/shareMsg'" +
                      "value:t='no'" +
                      "on_change_value:t='onFacebookPostPurchaseChange';" +
                      "btnName:t='X';" +
                      "ButtonImg{}" +
                      "CheckBoxImg{}" +
                     "}"
  }

  ::scene_msg_box("need_money", null, msgText,
                  [["yes", (@(unit) function() {::impl_buyUnit(unit) })(unit) ],
                   ["no", function() {} ]],
                  "yes", { cancel_fn = function() {}, data_below_text = additionalCheckBox})
  return true
}

function impl_buyUnit(unit)
{
  if (!unit)
    return false
  if (unit.isBought())
    return false
  if (!::old_check_balance_msgBox(::wp_get_cost(unit.name), ("costGold" in unit) ? ::wp_get_cost_gold(unit.name) : 0))
    return false

  local unitName = unit.name
  local taskId = ::shop_purchase_aircraft(unitName)
  local progressBox = ::scene_msg_box("char_connecting", null, ::loc("charServer/purchase"), null, null)
  ::add_bg_task_cb(taskId, (@(unit, progressBox) function() {
      ::destroyMsgBox(progressBox)

      local config = {
        locId = "purchase_unit"
        subType = ps4_activity_feed.PURCHASE_UNIT
        backgroundPost = true
      }

      local custConfig = {
        requireLocalization = ["unitName", "country"]
        unitNameId = unit.name
        unitName = unit.name + "_shop"
        rank = ::get_roman_numeral(::getUnitRank(unit))
        country = ::getUnitCountry(unit)
        link = ::format(::loc("url/wiki_objects"), unit.name)
      }

      local postFeeds = ::FACEBOOK_POST_WALL_MESSAGE? bit_activity.FACEBOOK : bit_activity.NONE
      if (::is_platform_ps4)
        postFeeds = postFeeds == bit_activity.NONE? bit_activity.PS4_ACTIVITY_FEED : bit_activity.ALL

      ::prepareMessageForWallPostAndSend(config, custConfig, postFeeds)

      ::broadcastEvent("UnitBought", {unitName = unit.name})
    })(unit, progressBox)
  )
  return true
}

function check_and_repair_unit(unit, onTaskSuccessInclude = null)
{
  if (!unit)
    return

  local price = ::getUnitRepairCost__m(unit)
  if (price.isZero())
    return onTaskSuccessInclude? onTaskSuccessInclude() : null

  if (!::check_balance_msgBox(price))
    return

  ::repair_unit(unit, onTaskSuccessInclude)
}

function repair_unit(unit, onTaskSuccessInclude = null)
{
  local blk = ::DataBlock()
  blk.setStr("name", unit.name)

  local taskId = ::char_send_blk("cln_prepare_aircraft", blk)

  local progBox = { showProgressBox = true }
  local onTaskSuccess = (@(unit, onTaskSuccessInclude) function() {
    ::update_gamercards()
    ::g_squad_utils.updateMyCountryData()
    ::broadcastEvent("UnitRepaired", {unit = unit})

    if (onTaskSuccessInclude)
      onTaskSuccessInclude()
  })(unit, onTaskSuccessInclude)

  ::g_tasker.addTask(taskId, progBox, onTaskSuccess)
}

function researchUnit(unit, checkCurrentUnit = true)
{
  if (!::canResearchUnit(unit) || (checkCurrentUnit && ::isUnitInResearch(unit)))
    return

  local prevUnitName = ::shop_get_researchable_unit_name(::getUnitCountry(unit), ::get_es_unit_type(unit))
  local taskId = ::shop_set_researchable_unit(unit.name, ::get_es_unit_type(unit))
  local progressBox = ::scene_msg_box("char_connecting", null, ::loc("charServer/purchase0"), null, null)
  local unitName = unit.name
  ::add_bg_task_cb(taskId, (@(unitName, prevUnitName, progressBox) function() {
      ::destroyMsgBox(progressBox)
      ::broadcastEvent("UnitResearch", {unitName = unitName, prevUnitName = prevUnitName})
    })(unitName, prevUnitName, progressBox)
  )
}

function checkPrevUnit(unit)
{
  local prevUnit = ::getPrevUnit(unit)
  if (!prevUnit)
    return true

  local reason = ::getCantBuyUnitReason(unit)
  if (::u.isEmpty(reason))
    return true

  local selectButton = "ok"
  local buttons = [["ok", function () {}]]
  if (::canBuyUnit(prevUnit))
  {
    selectButton = "purchase"
    reason += " " + ::loc("mainmenu/canBuyThisVehicle", {price = ::colorize("activeTextColor", ::getUnitCost(prevUnit))})
    buttons = [["purchase", (@(prevUnit) function () { ::buyUnit(prevUnit, true) })(prevUnit)],
             ["cancel", function () {}]]
  }

  ::scene_msg_box("need_buy_prev", null, reason, buttons, selectButton)
  return false
}

function checkFeatureLock(unit, lockAction)
{
  if (!::isUnitFeatureLocked(unit))
    return true
  local params = {
    purchaseAvailable = ::has_feature("OnlineShopPacks")
    featureLockAction = lockAction
    unit = unit
  }

  ::gui_start_modal_wnd(::gui_handlers.VehicleRequireFeatureWindow, params)
  return false
}

function checkForResearch(unit)
{
  // Feature lock has higher priority than ::canResearchUnit.
  if (!::checkFeatureLock(unit, CheckFeatureLockAction.RESEARCH))
    return false

  if (::canResearchUnit(unit))
    return true

  if (!::isUnitSpecial(unit) && !::isUnitGift(unit) && !::isUnitsEraUnlocked(unit))
  {
    ::showInfoMsgBox(getCantBuyUnitReason(unit), "need_unlock_rank")
    return false
  }
  if (!checkPrevUnit(unit))
    return false
  return true
}

/**
 * Used in shop tooltip display logic.
 */
function need_buy_prev_unit(unit)
{
  if (::isUnitBought(unit) || ::isUnitGift(unit))
    return false
  if (!::isUnitSpecial(unit) && !::isUnitsEraUnlocked(unit))
    return false
  if (!::isPrevUnitBought(unit))
    return true
  return false
}

function getCantBuyUnitReason(unit, isShopTooltip = false)
{
  if (!unit)
    return ::loc("leaderboards/notAvailable")

  if (::isUnitBought(unit) || ::isUnitGift(unit))
    return ""

  local special = ::isUnitSpecial(unit)
  if (!special && !::isUnitsEraUnlocked(unit))
  {
    local countryId = ::getUnitCountry(unit)
    local unitType = ::get_es_unit_type(unit)
    local rank = ::getUnitRank(unit)

    for (local prevRank = rank - 1; prevRank > 0; prevRank--)
    {
      local unitsCount = 0
      foreach (u in ::all_units)
        if (::isUnitBought(u) && ::getUnitRank(u) == prevRank && ::getUnitCountry(u) == countryId && ::get_es_unit_type(u) == unitType)
          unitsCount++
      local unitsNeed = ::getUnitsNeedBuyToOpenNextInEra(countryId, unitType, prevRank)
      local unitsLeft = max(0, unitsNeed - unitsCount)

      if (unitsLeft > 0)
      {
        return ::loc("shop/unlockTier/locked", { rank = ::get_roman_numeral(rank) })
          + "\n" + ::loc("shop/unlockTier/reqBoughtUnitsPrevRank", { prevRank = ::get_roman_numeral(prevRank), amount = unitsLeft })
      }
    }
    return ::loc("shop/unlockTier/locked", { rank = ::get_roman_numeral(rank) })
  }
  else if (!::isPrevUnitResearched(unit))
  {
    if (isShopTooltip)
      return ::loc("mainmenu/needResearchPreviousVehicle")
    return ::loc("msgbox/need_unlock_prev_unit/research", {name = ::colorize("userlogColoredText", ::getUnitName(::getPrevUnit(unit), true))})
  }
  else if (!::isPrevUnitBought(unit))
  {
    if (isShopTooltip)
      return ::loc("mainmenu/needBuyPreviousVehicle")
    return ::loc("msgbox/need_unlock_prev_unit/purchase", {name = ::colorize("userlogColoredText", ::getUnitName(::getPrevUnit(unit), true))})
  }
  else if (!special && !::canBuyUnit(unit) && ::canResearchUnit(unit))
    return ::loc(::isUnitInResearch(unit) ? "mainmenu/needResearch/researching" : "mainmenu/needResearch")

  if (!isShopTooltip)
  {
    local info = ::get_profile_info()
    local balance = ::getTblValue("balance", info, 0)
    local balanceG = ::getTblValue("gold", info, 0)

    if (special && (::wp_get_cost_gold(unit.name) > balanceG))
      return ::loc("mainmenu/notEnoughGold")
    else if (!special && (::wp_get_cost(unit.name) > balance))
      return ::loc("mainmenu/notEnoughWP")
   }

  return ""
}

function isUnitAvailableForGM(air, gm)
{
  if (!air.unitType.isAvailable())
    return false
  if (gm == ::GM_TEST_FLIGHT)
    return air.testFlight != ""
  if (gm == ::GM_DYNAMIC || gm == ::GM_BUILDER)
    return ::isAircraft(air)
  return true
}

function isTestFlightAvailable(unit)
{
  if (!::isUnitAvailableForGM(unit, ::GM_TEST_FLIGHT))
    return false

  if (unit.isUsable()
      || ::canResearchUnit(unit)
      || ::isUnitGift(unit)
      || ::isUnitResearched(unit)
      || ::isUnitSpecial(unit))
    return true

  return false
}

function getMaxRankUnboughtUnitByCountry(country, unitType)
{
  local unit = null
  foreach (newUnit in ::all_units)
    if (!country || country == ::getUnitCountry(newUnit))
      if (::getTblValue("rank", newUnit, 0) > ::getTblValue("rank", unit, 0))
        if (unitType == ::get_es_unit_type(newUnit)
            && !::isUnitSpecial(newUnit)
            && ::canBuyUnit(newUnit)
            && ::isPrevUnitBought(newUnit))
          unit = newUnit
  return unit
}

function getMaxRankResearchingUnitByCountry(country, unitType)
{
  local unit = null
  foreach (newUnit in ::all_units)
    if (country == ::getUnitCountry(newUnit))
      if (unitType == ::get_es_unit_type(newUnit) && ::canResearchUnit(newUnit))
        unit = (::getTblValue("rank", newUnit, 0) > ::getTblValue("rank", unit, 0))? newUnit : unit
  return unit
}

function _afterUpdateAirModificators(unit, callback)
{
  if ("secondaryWeaponMods" in unit)
    delete unit.secondaryWeaponMods //invalidate secondary weapons cache
  ::broadcastEvent("UnitModsRecount", { unit = unit })
  if(callback != null)
    callback()
}

//return true when modificators already valid.
function check_unit_mods_update(air, callBack = null, forceUpdate = false)
{
  if (::getTblValue("_modificatorsRequested", air, false))
  {
    if (forceUpdate)
      ::remove_calculate_modification_effect_jobs()
    else
      return false
  } else
    if (!forceUpdate && "modificators" in air)
      return true

  if (::isShip(air))
    return true //ships dosnt calculated yet

  if (isTank(air))
  {
    air._modificatorsRequested <- true
    calculate_tank_parameters_async(air.name, this, (@(air, callBack) function(effect, ...) {
      air._modificatorsRequested <- false
      air.modificators <- {
        arcade = effect.arcade
        historical = effect.historical
        fullreal = effect.fullreal
      }

      ::_afterUpdateAirModificators(air, callBack)
    })(air, callBack))
    return false
  }

  air._modificatorsRequested <- true
  ::calculate_min_and_max_parameters(air.name, this, (@(air, callBack) function(effect, ...) {
    air._modificatorsRequested <- false
    air.modificators <- {
      arcade = effect.arcade
      historical = effect.historical
      fullreal = effect.fullreal
    }
    air.minChars <- effect.min
    air.maxChars <- effect.max

    ::_afterUpdateAirModificators(air, callBack)
  })(air, callBack))
  return false
}

// modName == ""  mean 'all mods'.
function updateAirAfterSwitchMod(air, modName = null)
{
  if (!air)
    return

  if (air.name == ::hangar_get_current_unit_name() && modName)
  {
    local modsList = modName == "" ? air.modifications : [ ::getModificationByName(air, modName) ]
    foreach (mod in modsList)
    {
      if (!::getTblValue("requiresModelReload", mod, false))
        continue
      ::hangar_force_reload_model()
      break
    }
  }

  if (!::isUnitGroup(air))
    ::check_unit_mods_update(air, null, true)
}

//return true when already counted
function check_secondary_weapon_mods_recount(unit, callback = null)
{
  if (!::isAircraft(unit))
    return true //no need to recount secondary weapons for tanks

  local weaponName = ::get_last_weapon(unit.name)
  local secondaryMods = ::getTblValue("secondaryWeaponMods", unit)
  if (secondaryMods && secondaryMods.weaponName == weaponName)
  {
    if (secondaryMods.effect)
      return true
    if (callback)
      secondaryMods.callback <- callback
    return false
  }

  unit.secondaryWeaponMods <- {
    weaponName = weaponName
    effect = null
    callback = callback
  }

  ::calculate_mod_or_weapon_effect(unit.name, weaponName, false, this, (@(unit, weaponName) function(effect, ...) {
      local secondaryMods = ::getTblValue("secondaryWeaponMods", unit)
      if (!secondaryMods || weaponName != secondaryMods.weaponName)
        return

      secondaryMods.effect <- effect || {}

      ::broadcastEvent("SecondWeaponModsUpdated", { unit = unit })
      if(secondaryMods.callback != null)
      {
        secondaryMods.callback()
        secondaryMods.callback = null
      }
    })(unit, weaponName))
  return false
}

function getUnitExp(unit)
{
  return ::shop_get_unit_exp(unit.name)
}

function getUnitReqExp(unit)
{
  if(!("reqExp" in unit))
    return 0
  return unit.reqExp
}

function isUnitMaxExp(unit) //temporary while not exist correct status between in_research and canBuy
{
  return ::isUnitSpecial(unit) || (::getUnitReqExp(unit) <= ::getUnitExp(unit))
}

function getNextTierModsCount(unit, tier)
{
  if (tier < 1 || tier > unit.needBuyToOpenNextInTier.len() || !("modifications" in unit))
    return 0

  local req = unit.needBuyToOpenNextInTier[tier-1]
  foreach(mod in unit.modifications)
    if (("tier" in mod) && mod.tier == tier &&
        !::wp_get_modification_cost_gold(unit.name, mod.name) &&
        ::getModificationBulletsGroup(mod.name) == "" &&
        ::isModResearched(unit, mod)
       )
      req--
  return max(req, 0)
}

function generateUnitShopInfo()
{
  local blk = ::get_shop_blk()
  local totalCountries = blk.blockCount()

  for(local c = 0; c < totalCountries; c++)  //country
  {
    local cblk = blk.getBlock(c)
    local totalPages = cblk.blockCount()

    for(local p = 0; p < totalPages; p++)
    {
      local pblk = cblk.getBlock(p)
      local totalRanges = pblk.blockCount()

      for(local r = 0; r < totalRanges; r++)
      {
        local rblk = pblk.getBlock(r)
        local totalAirs = rblk.blockCount()
        local prevAir = null

        for(local a = 0; a < totalAirs; a++)
        {
          local airBlk = rblk.getBlock(a)
          local air = ::getAircraftByName(airBlk.getBlockName())

          if (airBlk.reqAir != null)
            prevAir = airBlk.reqAir

          if (air)
          {
            ::generate_unit_shop_info_common(air, airBlk, prevAir)
            prevAir = air.name
          }
          else //aircraft group
          {
            local groupTotal = airBlk.blockCount()
            local firstIGroup = null
            local groupName = airBlk.getBlockName()
            for(local ga = 0; ga < groupTotal; ga++)
            {
              local gAirBlk = airBlk.getBlock(ga)
              air = ::getAircraftByName(gAirBlk.getBlockName())
              if (!air)
                continue
              ::generate_unit_shop_info_common(air, gAirBlk, prevAir)
              air.group <- groupName
              air.groupImage <- airBlk.image
              prevAir = air.name
              if (!firstIGroup)
                firstIGroup = air
            }

            if (firstIGroup
                && !::isUnitSpecial(firstIGroup)
                && !::isUnitGift(firstIGroup))
              prevAir = firstIGroup.name
            else
              prevAir = null
          }
        }
      }
    }
  }
}

function has_platform_from_blk_str(blk, fieldName, defValue = false, separator = "; ")
{
  local listStr = blk[fieldName]
  if (!::u.isString(listStr))
    return defValue
  return ::isInArray(::target_platform, ::split(listStr, separator))
}

function generate_unit_shop_info_common(air, air_blk, prev_air)
{
  local isVisibleUnbought = !air_blk.showOnlyWhenBought
    && ::has_platform_from_blk_str(air_blk, "showByPlatform", true)
    && !::has_platform_from_blk_str(air_blk, "hideByPlatform", false)

  air.showOnlyWhenBought <- !isVisibleUnbought

  air.showOnlyWhenResearch <- air_blk.showOnlyWhenResearch

  if (isVisibleUnbought && ::u.isString(air_blk.hideForLangs))
    air.hideForLangs <- ::split(air_blk.hideForLangs, "; ")

  if (air_blk.gift != null)
    air.gift <- air_blk.gift
  if (air_blk.giftParam != null)
    air.giftParam <- air_blk.giftParam

  air.reqAir <- prev_air
  if (::u.isString(air_blk.reqFeature))
    air.reqFeature <- air_blk.reqFeature
  if (air_blk.hideFeature != null)
    air.hideFeature <- air_blk.hideFeature
  air.isInShop = true
}

function getPrevUnit(unit)
{
  return "reqAir" in unit ? ::getAircraftByName(unit.reqAir) : null
}

function isUnitLocked(unit)
{
  local status = ::shop_unit_research_status(unit.name)
  return 0 != (status & ::ES_ITEM_STATUS_LOCKED)
}

function isUnitResearched(unit)
{
  if (::isUnitBought(unit))
    return true

  local status = ::shop_unit_research_status(unit.name)
  return (0 != (status & (::ES_ITEM_STATUS_CAN_BUY | ::ES_ITEM_STATUS_RESEARCHED)))
}

function isPrevUnitResearched(unit)
{
  local prevUnit = ::getPrevUnit(unit)
  if (!prevUnit || ::isUnitResearched(prevUnit))
    return true
  return false
}

function isPrevUnitBought(unit)
{
  local prevUnit = ::getPrevUnit(unit)
  if (!prevUnit || ::isUnitBought(prevUnit))
    return true
  return false
}

function getNextUnits(unit)
{
  local res = []
  foreach (item in ::all_units)
    if ("reqAir" in item && unit.name == item.reqAir)
      res.append(item)
  return res
}

function setOrClearNextUnitToResearch(unit, country, type) //return -1 when clear prev
{
  if (unit)
    return ::shop_set_researchable_unit(unit.name, type)

  ::shop_reset_researchable_unit(country, type)
  return -1
}

function getMinBestLevelingRank(unit)
{
  if (!unit)
    return -1

  local unitRank = ::getUnitRank(unit)
  if (::isUnitSpecial(unit) || unitRank == 1)
    return 1
  local result = unitRank - ::getHighestRankDiffNoPenalty(true)
  return result > 0 ? result : 1
}

function getMaxBestLevelingRank(unit)
{
  if (!unit)
    return -1

  local unitRank = ::getUnitRank(unit)
  if (unitRank == 5)
    return 5
  local result = unitRank + ::getHighestRankDiffNoPenalty()
  return result <= 5 ? result : 5
}

function getHighestRankDiffNoPenalty(inverse = false)
{
  local ranksBlk = ::get_ranks_blk()
  local paramPrefix = inverse
                      ? "expMulWithTierDiffMinus"
                      : "expMulWithTierDiff"

  for (local rankDif = 0; rankDif < 5; rankDif++)
    if (ranksBlk[paramPrefix + rankDif] < 0.8)
      return rankDif - 1
}

function getUnitRankName(rank, full = false)
{
  return full? ::loc("shop/age/" + rank.tostring() + "/name") : ::get_roman_numeral(rank)
}

function get_battle_type_by_unit(unit)
{
  return (::get_es_unit_type(unit) == ::ES_UNIT_TYPE_TANK)? BATTLE_TYPES.TANK : BATTLE_TYPES.AIR
}

function get_unit_wp_reward_muls(unit, difficulty = ::g_difficulty.ARCADE)
{
  local ws = ::get_warpoints_blk()
  local premPart = ::isUnitSpecial(unit) ?
    ::get_blk_value_by_path(ws, "rewardMulVisual/premRewardMulVisualPart", 0.5) : 0.0

  local mode = difficulty.getEgdName()
  local mul = ::getTblValue("rewardMul" + mode, unit, 1.0) *
    ::get_blk_value_by_path(ws, "rewardMulVisual/rewardMulVisual" + mode, 1.0)

  return {
    wpMul   = ::round_by_value(mul * (1.0 - premPart), 0.1)
    premMul = ::round_by_value(1.0 / (1.0 - premPart), 0.1)
  }
}

function get_unit_tooltip_image(unit)
{
  local customTooltipImage = ::getTblValue("customTooltipImage", unit)
  if (customTooltipImage)
    return customTooltipImage

  switch (::get_es_unit_type(unit))
  {
    case ::ES_UNIT_TYPE_AIRCRAFT:       return "ui/aircrafts/" + unit.name
    case ::ES_UNIT_TYPE_TANK:           return "ui/tanks/" + unit.name
    case ::ES_UNIT_TYPE_SHIP:           return "ui/ships/" + unit.name
  }
  return ""
}

function get_chance_to_met_text(battleRating1, battleRating2)
{
  local brDiff = fabs(battleRating1.tofloat() - battleRating2.tofloat())
  local brData = null
  foreach(data in ::chances_text)
    if (!brData
        || (data.brDiff <= brDiff && data.brDiff > brData.brDiff))
      brData = data
  return brData? format("<color=%s>%s</color>", brData.color, ::loc(brData.text)) : ""
}

function getCharacteristicActualValue(air, characteristicName, prepareTextFunc, modeName)
{
  local showReferenceText = false
  if (!(characteristicName[0] in air.shop))
    air.shop[characteristicName[0]] <- 0;

  local value = air.shop[characteristicName[0]] + (("modificators" in air) ? air.modificators[modeName][characteristicName[1]] : 0)
  local min = "minChars" in air ? air.shop[characteristicName[0]] + air.minChars[modeName][characteristicName[1]] : value
  local max = "maxChars" in air ? air.shop[characteristicName[0]] + air.maxChars[modeName][characteristicName[1]] : value
  local text = prepareTextFunc(value)
  if("modificators" in air && air.modificators[modeName][characteristicName[1]] == 0)
  {
    text = "<color=@goodTextColor>" + text + "</color>*"
    showReferenceText = true
  }

  local weaponModValue = ::getTblValueByPath("secondaryWeaponMods.effect." + modeName + "." + characteristicName[1], air, 0)
  local weaponModText = ""
  if(weaponModValue != 0)
    weaponModText = "<color=@badTextColor>" + (weaponModValue > 0 ? " + " : " - ") + prepareTextFunc(fabs(weaponModValue)) + "</color>"
  return [text, weaponModText, min, max, value, air.shop[characteristicName[0]], showReferenceText]
}

function setReferenceMarker(obj, min, max, refer, modeName)
{
  if(!::checkObj(obj))
    return

  local refMarkerObj = obj.findObject("aircraft-reference-marker")
  if (::checkObj(refMarkerObj))
  {
    if(min == max || (modeName == "arcade"))
    {
      refMarkerObj.show(false)
      return
    }

    refMarkerObj.show(true)
    local left = (refer - min) / (max - min)
    refMarkerObj.left = ::format("%.3fpw - 0.5w)", left)
  }
}

function fillAirCharProgress(progressObj, min, max, cur)
{
  if(!::checkObj(progressObj))
    return
  if(min == max)
    return progressObj.show(false)
  else
    progressObj.show(true)
  local value = ((cur - min) / (max - min)) * 1000.0
  progressObj.setValue(value)
}

function fillAirInfoTimers(holderObj, air, needShopInfo)
{
  ::secondsUpdater(holderObj, (@(air, needShopInfo) function(obj, params) {
    local isActive = false

    // Unit repair cost
    local hp = shop_get_aircraft_hp(air.name)
    local isBroken = hp >= 0 && hp < 1
    isActive = isActive || isBroken
    local hpTrObj = obj.findObject("aircraft-condition-tr")
    if (hpTrObj)
      if (isBroken)
      {
        //local hpText = format("%d%%", floor(hp*100))
        //hpText += (hp < 1)? " (" + hoursToString(shop_time_until_repair(air.name)) + ")" : ""
        local hpText = ::loc("shop/damaged") + " (" + hoursToString(shop_time_until_repair(air.name), false, true) + ")"
        hpTrObj.show(true)
        hpTrObj.findObject("aircraft-condition").setValue(hpText)
      } else
        hpTrObj.show(false)
    if (needShopInfo && isBroken && obj.findObject("aircraft-repair_cost-tr"))
    {
      local cost = ::wp_get_repair_cost(air.name)
      obj.findObject("aircraft-repair_cost-tr").show(cost > 0)
      obj.findObject("aircraft-repair_cost").setValue(::getPriceAccordingToPlayersCurrency(cost, 0))
    }

    // Unit rent time
    local isRented = air.isRented()
    isActive = isActive || isRented
    local rentObj = obj.findObject("unit_rent_time")
    if (::checkObj(rentObj))
    {
      local sec = air.getRentTimeleft()
      local show = sec > 0
      local value = ""
      if (show)
      {
        local time = ::hoursToString(sec / TIME_HOUR_IN_SECONDS_F, false, true, true)
        value = ::colorize("goodTextColor", ::loc("mainmenu/unitRentTimeleft") + ::loc("ui/colon") + time)
      }
      if (rentObj.isVisible() != show)
        rentObj.show(show)
      if (show && rentObj.getValue() != value)
        rentObj.setValue(value)
    }

    return !isActive
  })(air, needShopInfo))
}

function get_show_aircraft_name()
{
  return ::show_aircraft? ::show_aircraft.name : ::hangar_get_current_unit_name()
}

function get_show_aircraft()
{
  return ::show_aircraft? ::show_aircraft : ::getAircraftByName(::hangar_get_current_unit_name())
}

function updateAirInfoInHandlerScene(air, handlerScene)
{
  local lockObj = handlerScene.findObject("crew-notready-topmenu")
  if(::checkObj(lockObj))
  {
    lockObj.tooltip = ::format(::loc("msgbox/no_available_aircrafts"), ::secondsToString(::lockTimeMaxLimitSec))
    ::setCrewUnlockTime(lockObj, air)
  }
  ::update_unit_rent_info(air, handlerScene)
}

function update_unit_rent_info(unit, handlerScene)
{
  local rentInfoObj = handlerScene.findObject("rented_unit_info_text")
  if (!::checkObj(rentInfoObj))
    return

  local unitIsRented = unit.isRented()
  rentInfoObj.show(unitIsRented)
  if (!unitIsRented)
    return

  local messageTemplate = ::loc("mainmenu/unitRentTimeleft") + ::loc("ui/colon") + "%s"
  ::secondsUpdater(rentInfoObj, (@(unit, messageTemplate) function(obj, params) {
    local isRented = unit.isRented()
    if (isRented)
    {
      local sec = unit.getRentTimeleft()
      local time = (sec < TIME_HOUR_IN_SECONDS) ?
        ::secondsToString(sec) :
        ::hoursToString(sec / TIME_HOUR_IN_SECONDS_F, false, true, true)
      obj.setValue(::format(messageTemplate, time))
    }
    else
      obj.show(false)
    return !isRented
  })(unit, messageTemplate))
}

function showAirInfo(air, show, holderObj = null, handler = null, params = null, canChangeAir = true)
{
  handler = handler || ::handlersManager.getActiveBaseHandler()

  if (!::checkObj(holderObj))
  {
    if(holderObj != null)
      return

    if (handler)
    {
      holderObj = handler.scene.findObject("slot_info")
      if (air)
        updateAirInfoInHandlerScene(air, handler.scene)
    }
    if (!::checkObj(holderObj))
      return
  }

  holderObj.show(show)
  if (!show || !air)
    return

  if (canChangeAir)
    holderObj.aircraft = air.name
  else if (holderObj.aircraft != air.name)
    return

  local isInFlight = ::is_in_flight()

  local getEdiffFunc = ::getTblValue("getCurrentEdiff", handler)
  local ediff = getEdiffFunc ? getEdiffFunc.call(handler) : ::get_current_ediff()
  local difficulty = ::get_difficulty_by_ediff(ediff)
  local diffCode = difficulty.diffCode

  local unitType = ::get_es_unit_type(air)
  local crew = ::getCrewByAir(air)

  local isOwn = ::isUnitBought(air)
  local special = ::isUnitSpecial(air)
  local cost = ::wp_get_cost(air.name)
  local costGold = ::wp_get_cost_gold(air.name)
  local aircraftPrice = special ? costGold : cost
  local gift = ::isUnitGift(air)
  local showPrice = !isOwn && aircraftPrice > 0 && !gift
  local isResearched = ::isUnitResearched(air)
  local canResearch = ::canResearchUnit(air)
  local rBlk = ::get_ranks_blk()
  local wBlk = ::get_warpoints_blk()
  local needShopInfo = ::getTblValue("needShopInfo", params, false)
  local needCrewInfo = ::getTblValue("needCrewInfo", params, false)

  local isRented = air.isRented()
  local rentTimeHours = ::getTblValue("rentTimeHours", params, -1)
  local showAsRent = isRented || rentTimeHours > 0

  if (holderObj.toggled != null)
  {
    local cdb = ::get_local_custom_settings_blk()
    local toggle = cdb.showTechSpecPanel != false && ::g_login.isAuthorized()
    airInfoToggle(holderObj, toggle)
  }

  local isSecondaryModsValid = ::check_unit_mods_update(air)
                            && ::check_secondary_weapon_mods_recount(air)

  local obj = holderObj.findObject("aircraft-name")
  if (::checkObj(obj))
    obj.setValue(::getUnitName(air.name, false))

  obj = holderObj.findObject("aircraft-type")
  if (::checkObj(obj))
  {
    local fonticon = ::colorize("activeTextColor", ::get_unit_role_icon(air))
    local typeText = ::get_full_unit_role_text(air)
    obj.show(typeText != "")
    obj.setValue(fonticon + " " + ::colorize(::getUnitClassColor(air), typeText))
  }

  obj = holderObj.findObject("player_country_exp")
  if (::checkObj(obj))
  {
    obj.show(canResearch)
    if (canResearch)
    {
      local expCur = ::getUnitExp(air)
      local expInvest = ::getTblValue("researchExpInvest", params, 0)
      local expTotal = air.reqExp
      local isResearching = ::isUnitInResearch(air)

      ::fill_progress_bar(obj, expCur - expInvest, expCur, expTotal, !isResearching)

      local labelObj = obj.findObject("exp")
      if (::checkObj(labelObj))
      {
        local statusText = isResearching ? ::loc("shop/in_research") + ::loc("ui/colon") : ""
        local slash = ::loc("ui/slash")
        local unitsText = ::loc("currency/researchPoints/sign/colored")
        local expText = ::format("%s%d%s%d%s", statusText, expCur, slash, expTotal, unitsText)
        expText = ::colorize(isResearching ? "cardProgressTextColor" : "commonTextColor", expText)
        if (expInvest > 0)
          expText += ::colorize("cardProgressTextBonusColor", ::loc("ui/parentheses/space", { text = "+" + expInvest }))
        labelObj.setValue(expText)
      }
    }
  }

  obj = holderObj.findObject("aircraft-countryImg")
  if (::checkObj(obj))
  {
    obj["background-image"] = ::get_unit_country_icon(air)
    holderObj.findObject("aircraft-countryRank").setValue(get_player_rank_by_country(air.shopCountry).tostring())
  }

  if (::has_feature("UnitTooltipImage"))
  {
    obj = holderObj.findObject("aircraft-image")
    if (::checkObj(obj))
      obj["background-image"] = ::get_unit_tooltip_image(air)
  }

  local ageObj = holderObj.findObject("aircraft-age")
  if (::checkObj(ageObj))
  {
    local nameObj = ageObj.findObject("age_number")
    if (::checkObj(nameObj))
      nameObj.setValue(::loc("shop/age") + ::getUnitRankName(air.rank, true) + ::loc("ui/colon"))
    local yearsObj = ageObj.findObject("age_years")
    if (::checkObj(yearsObj))
      yearsObj.setValue(::getUnitRankName(air.rank))
  }

  //count unit ratings
  local battleRating = ::get_unit_battle_rating_by_mode(air, ediff)
  holderObj.findObject("aircraft-battle_rating-header").setValue(::loc("shop/battle_rating") + ::loc("ui/colon"))
  holderObj.findObject("aircraft-battle_rating").setValue(format("%.1f", battleRating))

  local meetObj = holderObj.findObject("aircraft-chance_to_met_tr")
  if (::checkObj(meetObj))
  {
    local erCompare = ::getTblValue("economicRankCompare", params)
    if (erCompare != null)
    {
      if (typeof(erCompare) == "table")
        erCompare = ::getTblValue(air.shopCountry, erCompare, 0.0)
      local text = ::get_chance_to_met_text(battleRating, ::calc_battle_rating_from_rank(erCompare))
      meetObj.findObject("aircraft-chance_to_met").setValue(text)
    }
    meetObj.show(erCompare != null)
  }

  if (canResearch || (!isOwn && !special && !gift))
  {
    local prevUnitObj = holderObj.findObject("aircraft-prevUnit_bonus_tr")
    local prevUnit = ::getPrevUnit(air)
    if (::checkObj(prevUnitObj) && prevUnit)
    {
      prevUnitObj.show(true)
      local tdNameObj = prevUnitObj.findObject("aircraft-prevUnit")
      if (::checkObj(tdNameObj))
        tdNameObj.setValue(::format(::loc("shop/prevUnitEfficiencyResearch"), ::getUnitName(prevUnit, true)))
      local tdValueObj = prevUnitObj.findObject("aircraft-prevUnit_bonus")
      if (::checkObj(tdValueObj))
      {
        local curVal = 1
        local param_name = "prevAirExpMulMode"
        if(rBlk[param_name + diffCode.tostring()]!=null)
          curVal = rBlk[param_name + diffCode.tostring()]

        if (curVal != 1)
          tdValueObj.setValue(::format("<color=@userlogColoredText>%s%%</color>", (curVal*100).tostring()))
        else
          prevUnitObj.show(false)
      }
    }
  }

  local rpObj = holderObj.findObject("aircraft-require_rp_tr")
  if (::checkObj(rpObj))
  {
    local showRpReq = !isOwn && !special && !gift && !isResearched && !canResearch
    rpObj.show(showRpReq)
    if (showRpReq)
      rpObj.findObject("aircraft-require_rp").setValue(::getRpPriceText(air.reqExp, true))
  }

  if(showPrice)
  {
    local priceObj = holderObj.findObject("aircraft-price-tr")
    if (priceObj)
    {
      priceObj.show(true)
      holderObj.findObject("aircraft-price").setValue(::getPriceAccordingToPlayersCurrency(cost, costGold))
    }
  }

  local modCharacteristics = {
    [::ES_UNIT_TYPE_AIRCRAFT] = [
      {id = "maxSpeed", id2 = "speed", prepareTextFunc = function(value){return ::countMeasure(0, value)}},
      {id = "turnTime", id2 = "virage", prepareTextFunc = function(value){return format("%.1f %s", value, ::loc("measureUnits/seconds"))}},
      {id = "climbSpeed", id2 = "climb", prepareTextFunc = function(value){return ::countMeasure(3, value)}}
    ],
    [::ES_UNIT_TYPE_TANK] = [
      {id = "mass", id2 = "mass", prepareTextFunc = function(value){return format("%.1f %s", (value / 1000.0), ::loc("measureUnits/ton"))}},
      {id = "maxSpeed", id2 = "maxSpeed", prepareTextFunc = function(value){return ::countMeasure(0, value)}},
      {id = "maxInclination", id2 = "maxInclination", prepareTextFunc = function(value){return format("%d%s", (value*180.0/PI).tointeger(), ::loc("measureUnits/deg"))}}
      {id = "turnTurretTime", id2 = "turnTurretSpeed", prepareTextFunc = function(value){return format("%.1f%s", value.tofloat(), ::loc("measureUnits/deg_per_sec"))}}
    ],
    [::ES_UNIT_TYPE_SHIP] = [
      //TODO ship modificators
    ],
  }

  if (::is_helicopter(air))
    modCharacteristics = { [::ES_UNIT_TYPE_AIRCRAFT] = [] }

  local showReferenceText = false
  foreach(item in ::getTblValue(unitType, modCharacteristics, {}))
  {
    local characteristicArr = getCharacteristicActualValue(air, [item.id, item.id2], item.prepareTextFunc, difficulty.crewSkillName)
    holderObj.findObject("aircraft-" + item.id).setValue(characteristicArr[0])
    local wmodObj = holderObj.findObject("aircraft-weaponmod-" + item.id)
    if (wmodObj)
      wmodObj.setValue(characteristicArr[1])

    local progressObj = holderObj.findObject("aircraft-progress-" + item.id)
    setReferenceMarker(progressObj, characteristicArr[2], characteristicArr[3], characteristicArr[5], difficulty.crewSkillName)
    fillAirCharProgress(progressObj, characteristicArr[2], characteristicArr[3], characteristicArr[4])
    showReferenceText = showReferenceText || characteristicArr[6]

    local waitObj = holderObj.findObject("aircraft-" + item.id + "-wait")
    if (waitObj)
      waitObj.show(!isSecondaryModsValid)
  }
  local refTextObj = holderObj.findObject("references_text")
  if (::checkObj(refTextObj)) refTextObj.show(showReferenceText)

  holderObj.findObject("aircraft-speedAlt").setValue(air.shop.maxSpeedAlt>0? ::countMeasure(1, air.shop.maxSpeedAlt) : ::loc("shop/max_speed_alt_sea"))
//    holderObj.findObject("aircraft-climbTime").setValue(format("%02d:%02d", air.shop.climbTime.tointeger() / 60, air.shop.climbTime.tointeger() % 60))
//    holderObj.findObject("aircraft-climbAlt").setValue(::countMeasure(1, air.shop.climbAlt))
  holderObj.findObject("aircraft-altitude").setValue(::countMeasure(1, air.shop.maxAltitude))
  holderObj.findObject("aircraft-airfieldLen").setValue(::countMeasure(1, air.shop.airfieldLen))

//  holderObj.findObject("aircraft-range").setValue(::countMeasure(2, air.shop.range * 1000.0))

  local showCharacteristics = {
    ["aircraft-turnTurretTime-tr"]        = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-angleVerticalGuidance-tr"] = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-shotFreq-tr"]              = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-reloadTime-tr"]            = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-weaponPresets-tr"]         = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-massPerSec-tr"]            = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-armorThicknessHull-tr"]    = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-armorThicknessTurret-tr"]  = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-armorPiercing-tr"]         = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-armorPiercingDist-tr"]     = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-mass-tr"]                  = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-horsePowers-tr"]           = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-maxSpeed-tr"]              = [ ::ES_UNIT_TYPE_AIRCRAFT, ::ES_UNIT_TYPE_TANK ],
    ["aircraft-speedAlt-tr"]              = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-altitude-tr"]              = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-turnTime-tr"]              = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-climbSpeed-tr"]            = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-maxInclination-tr"]        = [ ::ES_UNIT_TYPE_TANK ],
    ["aircraft-airfieldLen-tr"]           = [ ::ES_UNIT_TYPE_AIRCRAFT ],
    ["aircraft-visibilityFactor-tr"]      = [ ::ES_UNIT_TYPE_TANK ]
  }

  foreach (rowId, showForTypes in showCharacteristics)
  {
    local obj = holderObj.findObject(rowId)
    if (obj)
      obj.show(::isInArray(unitType, showForTypes))
  }

  if (isTank(air) && ("modificators" in air))
  {
    local mode = ::domination_modes[diffCode]
    local currentParams = air.modificators[mode.id];
    local horsePowers = currentParams.horsePowers;
    local horsePowersRPM = currentParams.maxHorsePowersRPM;
    holderObj.findObject("aircraft-horsePowers").setValue(
      ::format("%s %s %d %s", ::g_measure_type.HORSEPOWERS.getMeasureUnitsText(horsePowers),
        ::loc("shop/unitValidCondition"), horsePowersRPM.tointeger(), ::loc("measureUnits/rpm")))
    local thickness = currentParams.armorThicknessHull;
    holderObj.findObject("aircraft-armorThicknessHull").setValue(format("%d / %d / %d %s", thickness[0].tointeger(), thickness[1].tointeger(), thickness[2].tointeger(), ::loc("measureUnits/mm")))
    thickness = currentParams.armorThicknessTurret;
    holderObj.findObject("aircraft-armorThicknessTurret").setValue(format("%d / %d / %d %s", thickness[0].tointeger(), thickness[1].tointeger(), thickness[2].tointeger(), ::loc("measureUnits/mm")))
    local angles = currentParams.angleVerticalGuidance;
    holderObj.findObject("aircraft-angleVerticalGuidance").setValue(format("%d / %d%s", angles[0].tointeger(), angles[1].tointeger(), ::loc("measureUnits/deg")))
    local armorPiercing = currentParams.armorPiercing;
    if (armorPiercing.len() > 2)
    {
      holderObj.findObject("aircraft-armorPiercing").setValue(format("%d / %d / %d %s", armorPiercing[0].tointeger(), armorPiercing[1].tointeger(), armorPiercing[2].tointeger(), ::loc("measureUnits/mm")))
      local armorPiercingDist = currentParams.armorPiercingDist;
      holderObj.findObject("aircraft-armorPiercingDist").setValue(format("%d / %d / %d %s", armorPiercingDist[0].tointeger(), armorPiercingDist[1].tointeger(), armorPiercingDist[2].tointeger(), ::loc("measureUnits/meters_alt")))
    }
    else
    {
      holderObj.findObject("aircraft-armorPiercing-tr").show(false)
      holderObj.findObject("aircraft-armorPiercingDist-tr").show(false)
    }

    local shotFreq = ("shotFreq" in currentParams && currentParams.shotFreq > 0) ? currentParams.shotFreq : null;
    local reloadTime = ("reloadTime" in currentParams && currentParams.reloadTime > 0) ? currentParams.reloadTime : null;
    if ("reloadTimeByDiff" in currentParams && mode.diff in currentParams.reloadTimeByDiff &&
      currentParams.reloadTimeByDiff[mode.diff] > 0)
      reloadTime = currentParams.reloadTimeByDiff[mode.diff];
    local visibilityFactor = ("visibilityFactor" in currentParams && currentParams.visibilityFactor > 0) ? currentParams.visibilityFactor : null;

    holderObj.findObject("aircraft-shotFreq-tr").show(shotFreq);
    holderObj.findObject("aircraft-reloadTime-tr").show(reloadTime);
    holderObj.findObject("aircraft-visibilityFactor-tr").show(visibilityFactor);
    if (shotFreq)
    {
      local val = ::roundToDigits(shotFreq * TIME_MINUTE_IN_SECONDS_F, 3).tostring()
      holderObj.findObject("aircraft-shotFreq").setValue(format("%s %s", val, ::loc("measureUnits/shotPerMinute")))
    }
    if (reloadTime)
      holderObj.findObject("aircraft-reloadTime").setValue(format("%.1f %s", reloadTime, ::loc("measureUnits/seconds")))
    if (visibilityFactor)
    {
      holderObj.findObject("aircraft-visibilityFactor-title").setValue(::loc("shop/visibilityFactor") + ::loc("ui/colon"))
      holderObj.findObject("aircraft-visibilityFactor-value").setValue(format("%d %%", visibilityFactor))
    }
  }

  if(unitType == ::ES_UNIT_TYPE_SHIP)
  {
    local unitTags = ::getTblValue(air.name, ::get_unittags_blk(), {})
    local unitBlk = ::DataBlock(::get_unit_file_name(air.name))
    if(unitBlk == null)
      unitBlk = {}

    // ship-displacement
    local displacementKilos = ::getTblValueByPath("ShipPhys.mass.TakeOff", unitBlk, null)
    holderObj.findObject("ship-displacement-tr").show(displacementKilos != null)
    if(displacementKilos!= null)
    {
      local displacementString = ::g_measure_type.SHIP_DISPLACEMENT_TON.getMeasureUnitsText(displacementKilos/1000, true)
      holderObj.findObject("ship-displacement-title").setValue(::loc("info/ship/displacement") + ::loc("ui/colon"))
      holderObj.findObject("ship-displacement-value").setValue(displacementString)
    }

    // ship-speed
    local speedValue = ::getTblValueByPath("Shop.maxSpeed", unitTags, 0)
    holderObj.findObject("aircraft-maxSpeed-tr").show(speedValue > 0)
    if(speedValue > 0)
      holderObj.findObject("aircraft-maxSpeed").setValue(::g_measure_type.SPEED.getMeasureUnitsText(speedValue))

    // ship-citadelArmor
    local armorThicknessCitadel = ::getTblValueByPath("Shop.armorThicknessCitadel", unitTags, null)
    holderObj.findObject("ship-citadelArmor-tr").show(armorThicknessCitadel != null)
    if(armorThicknessCitadel != null)
    {
      holderObj.findObject("ship-citadelArmor-title").setValue(::loc("info/ship/citadelArmor") + ::loc("ui/colon"))
      holderObj.findObject("ship-citadelArmor-value").setValue(
        format("%d / %d / %d %s", armorThicknessCitadel.x.tointeger(), armorThicknessCitadel.y.tointeger(),
          armorThicknessCitadel.z.tointeger(), ::loc("measureUnits/mm")))
    }

    // ship-mainFireTower
    local armorThicknessMainFireTower = ::getTblValueByPath("Shop.armorThicknessTurretMainCaliber", unitTags, null)
    holderObj.findObject("ship-mainFireTower-tr").show(armorThicknessMainFireTower != null)
    if(armorThicknessMainFireTower != null)
    {
      holderObj.findObject("ship-mainFireTower-title").setValue(::loc("info/ship/mainFireTower") + ::loc("ui/colon"))
      holderObj.findObject("ship-mainFireTower-value").setValue(
        format("%d / %d / %d %s", armorThicknessMainFireTower.x.tointeger(), armorThicknessMainFireTower.y.tointeger(),
          armorThicknessMainFireTower.z.tointeger(), ::loc("measureUnits/mm")))
    }
  }
  else
  {
    holderObj.findObject("ship-displacement-tr").show(false)
    holderObj.findObject("ship-citadelArmor-tr").show(false)
    holderObj.findObject("ship-mainFireTower-tr").show(false)
  }

  if (::is_helicopter(air))
  {
    local unutBlk = ::DataBlock(::get_unit_file_name(air.name))
    local blk = unutBlk.ui || ::DataBlock()

    local rows = {
      mass          = ::format("%.1f %s", ((blk.mass || 0.0) / 1000.0), ::loc("measureUnits/ton"))
      horsePowers   = (blk.engines || 0) + " x " + ::g_measure_type.HORSEPOWERS.getMeasureUnitsText(blk.engineHorsePowers || 0.0)
      maxSpeed      = ::g_measure_type.SPEED.getMeasureUnitsText(blk.maxMovingSpeed || 0.0)
      climbSpeed    = ::countMeasure(3, blk.climbSpeed || 0.0)
      altitude      = ::countMeasure(1, blk.maxAlt || 0.0)
      weaponPresets = ""
      speedAlt      = ""
      turnTime      = ""
      airfieldLen   = ""
    }

    foreach (id, val in rows)
    {
      local rowObj = holderObj.findObject("aircraft-" + id + "-tr")
      if (::check_obj(rowObj))
        rowObj.show(val != "")
      local obj = holderObj.findObject("aircraft-" + id)
      if (::check_obj(obj))
        obj.setValue(val)
    }
  }

  if (needShopInfo && holderObj.findObject("aircraft-train_cost-tr"))
    if (air.trainCost > 0)
    {
      holderObj.findObject("aircraft-train_cost-tr").show(true)
      holderObj.findObject("aircraft-train_cost").setValue(::getPriceAccordingToPlayersCurrency(air.trainCost, 0))
    }

  if (holderObj.findObject("aircraft-reward_rp-tr") || holderObj.findObject("aircraft-reward_wp-tr"))
  {
    local hasPremium  = ::havePremium()
    local hasTalisman = special || ::shop_is_modification_enabled(air.name, "premExpMul")
    local boosterEffects = ::getTblValue("boosterEffects", params,
      ::ItemsManager.getBoostersEffects(::ItemsManager.getActiveBoostersArray()))

    local wpMuls = ::get_unit_wp_reward_muls(air, difficulty)
    if (showAsRent)
      wpMuls.premMul = 1.0
    local wpMultText = ::format("%.1f", wpMuls.wpMul)
    if (wpMuls.premMul != 1.0)
      wpMultText += ::colorize("fadedTextColor", ::loc("ui/multiply")) + ::colorize("yellow", ::format("%.1f", wpMuls.premMul))

    local rewardFormula = {
      rp = {
        currency      = "currency/researchPoints/sign/colored"
        multText      = air.expMul.tostring()
        multiplier    = air.expMul
        premUnitMul   = 1.0
        noBonus       = 1.0
        premAccBonus  = hasPremium  ? ((rBlk.xpMultiplier || 1.0) - 1.0)    : 0.0
        premModBonus  = hasTalisman ? ((rBlk.goldPlaneExpMul || 1.0) - 1.0) : 0.0
        boosterBonus  = ::getTblValue(::BoosterEffectType.RP.name, boosterEffects, 0) / 100.0
      }
      wp = {
        currency      = "warpoints/short/colored"
        multText      = wpMultText
        multiplier    = wpMuls.wpMul
        premUnitMul   = wpMuls.premMul
        noBonus       = 1.0
        premAccBonus  = hasPremium ? ((wBlk.wpMultiplier || 1.0) - 1.0) : 0.0
        premModBonus  = 0.0
        boosterBonus  = ::getTblValue(::BoosterEffectType.WP.name, boosterEffects, 0) / 100.0
      }
    }

    foreach (id, f in rewardFormula)
    {
      if (!holderObj.findObject("aircraft-reward_" + id + "-tr"))
        continue

      local result = f.multiplier * f.premUnitMul * ( f.noBonus + f.premAccBonus + f.premModBonus + f.boosterBonus )
      local resultText = ::g_measure_type.PERCENT_FLOAT.getMeasureUnitsText(result)
      resultText = ::colorize("activeTextColor", resultText) + ::loc(f.currency)

      local formula = ::handyman.renderCached("gui/statistics/rewardSources", {
        multiplier = f.multText
        noBonus    = ::g_measure_type.PERCENT_FLOAT.getMeasureUnitsText(f.noBonus)
        premAcc    = f.premAccBonus  > 0 ? ::g_measure_type.PERCENT_FLOAT.getMeasureUnitsText(f.premAccBonus)  : null
        premMod    = f.premModBonus  > 0 ? ::g_measure_type.PERCENT_FLOAT.getMeasureUnitsText(f.premModBonus)  : null
        booster    = f.boosterBonus  > 0 ? ::g_measure_type.PERCENT_FLOAT.getMeasureUnitsText(f.boosterBonus)  : null
      })

      holderObj.getScene().replaceContentFromText(holderObj.findObject("aircraft-reward_" + id), formula, formula.len(), handler)
      holderObj.findObject("aircraft-reward_" + id + "-label").setValue(::loc("reward") + " " + resultText + ::loc("ui/colon"))
    }
  }

  if (holderObj.findObject("aircraft-spare-tr"))
  {
    local spareCount = ::get_spare_aircrafts_count(air.name)
    holderObj.findObject("aircraft-spare-tr").show(spareCount > 0)
    if (spareCount > 0)
      holderObj.findObject("aircraft-spare").setValue(spareCount.tostring() + ::loc("icon/spare"))
  }

  local fullRepairTd = holderObj.findObject("aircraft-full_repair_cost-td")
  if (fullRepairTd)
  {
    local repairCostData = ""
    local discountsList = {}
    local freeRepairsUnlimited = ::isUnitDefault(air)
    if (freeRepairsUnlimited)
      repairCostData = ::format("textareaNoTab { tinyFont:t='yes'; text:t='%s' }", ::loc("shop/free"))
    else
    {
      local avgRepairMul = wBlk.avgRepairMul? wBlk.avgRepairMul : 1.0
      local egdCode = difficulty.egdCode
      local avgCost = (avgRepairMul * ::wp_get_repair_cost_by_mode(air.name, egdCode, true)).tointeger()
      local modeName = ::get_name_by_gamemode(egdCode, false)
      discountsList[modeName] <- modeName + "-discount"
      repairCostData += format("tdiv { " +
                                 "textareaNoTab {tinyFont:t='yes' text:t='%s' }" +
                                 "discount { id:t='%s'; text:t=''; pos:t='-1*@scrn_tgt/100.0, 0.5ph-0.55h'; position:t='relative'; rotation:t='8' }" +
                               "}\n",
                          ((repairCostData!="")?"/ ":"") + ::getPriceAccordingToPlayersCurrency(avgCost.tointeger(), 0),
                          discountsList[modeName]
                        )
    }
    holderObj.getScene().replaceContentFromText(fullRepairTd, repairCostData, repairCostData.len(), null)
    foreach(modeName, objName in discountsList)
      ::showAirDiscount(fullRepairTd.findObject(objName), air.name, "repair", modeName)

    if (!freeRepairsUnlimited)
    {
      local repairTimeText = ::getTextByModes((@(air) function(mode) {
          return hoursToString(::shop_get_full_repair_time_by_mode(air.name, mode.modeId), false)
        })(air))
      holderObj.findObject("aircraft-full_repair_time_crew-tr").show(true)
      holderObj.findObject("aircraft-full_repair_time_crew").setValue(repairTimeText)

      local freeRepairs = showAsRent ? 0 : air.freeRepairs - shop_get_free_repairs_used(air.name)
      local showFreeRepairs = freeRepairs > 0
      holderObj.findObject("aircraft-free_repairs-tr").show(showFreeRepairs)
      if (showFreeRepairs)
        holderObj.findObject("aircraft-free_repairs").setValue(freeRepairs.tostring())
    }
    else
    {
      holderObj.findObject("aircraft-full_repair_time_crew-tr").show(false)
      holderObj.findObject("aircraft-free_repairs-tr").show(false)
//        if (holderObj.findObject("aircraft-full_repair_time-tr"))
//          holderObj.findObject("aircraft-full_repair_time-tr").show(false)
      ::hideBonus(holderObj.findObject("aircraft-full_repair_cost-discount"))
    }
  }

  local addInfoTextsList = []
  if (isInFlight && ::g_mis_custom_state.getCurMissionRules().hasCustomUnitRespawns())
  {
    local respawnsleft = ::g_mis_custom_state.getCurMissionRules().getUnitLeftRespawns(air)
    if (respawnsleft >= 0)
    {
      local respText = ::loc("unitInfo/team_left_respawns") + ::loc("ui/colon") + respawnsleft
      local color = respawnsleft ? "@userlogColoredText" : "@warningTextColor"
      addInfoTextsList.append(::colorize(color, respText))
    }
  }

  if (rentTimeHours != -1)
  {
    if (rentTimeHours > 0)
    {
      local time = ::colorize("activeTextColor", ::hoursToString(rentTimeHours))
      addInfoTextsList.append(::colorize("userlogColoredText", ::loc("shop/rentFor", { time =  time })))
    }
    else
      addInfoTextsList.append(::colorize("userlogColoredText", ::loc("trophy/unlockables_names/trophy")))
    if (isOwn)
    {
      local text = ::loc("shop/unit_bought") + ::loc("ui/dot") + " " + ::loc("mainmenu/receiveOnlyOnce")
      addInfoTextsList.append(::colorize("badTextColor", text))
    }
  }
  else
  {
    if (::isUnitGift(air))
      addInfoTextsList.append(::colorize("userlogColoredText", ::format(::loc("shop/giftAir/"+air.gift+"/info"), ("giftParam" in air)? ::loc(air.giftParam) : "")))
    if (::isUnitDefault(air))
      addInfoTextsList.append(::loc("shop/reserve/info"))
    if (!::isUnitBought(air) && ::isUnitResearched(air) && !::canBuyUnitOnline(air) && ::canBuyUnit(air))
    {
      local priceText = ::colorize("activeTextColor", ::getUnitCost(air).getTextAccordingToBalance())
      addInfoTextsList.append(::colorize("userlogColoredText", ::loc("mainmenu/canBuyThisVehicle", { price = priceText })))
    }
  }

  local infoObj = holderObj.findObject("aircraft-addInfo")
  if (::checkObj(infoObj))
  {
    local addInfoText = ::implode(addInfoTextsList, "\n")
    infoObj.show(addInfoText!="")
    if (addInfoText!="")
     infoObj.setValue(addInfoText)
  }

  if (needCrewInfo && crew)
  {
    local crewLevel = ::g_crew.getCrewLevel(crew, unitType)
    local crewStatus = ::get_crew_status(crew)
    local specType = ::g_crew_spec_type.getTypeByCrewAndUnit(crew, air)
    local crewSpecIcon = specType.trainedIcon
    local crewSpecName = specType.getName()

    local obj = holderObj.findObject("aircraft-crew_info")
    if (::checkObj(obj))
      obj.show(true)

    local obj = holderObj.findObject("aircraft-crew_name")
    if (::checkObj(obj))
      obj.setValue(::g_crew.getCrewName(crew))

    local obj = holderObj.findObject("aircraft-crew_level")
    if (::checkObj(obj))
      obj.setValue(::loc("crew/usedSkills") + " " + crewLevel)
    local obj = holderObj.findObject("aircraft-crew_spec-label")
    if (::checkObj(obj))
      obj.setValue(::loc("crew/trained") + ::loc("ui/colon"))
    local obj = holderObj.findObject("aircraft-crew_spec-icon")
    if (::checkObj(obj))
      obj["background-image"] = crewSpecIcon
    local obj = holderObj.findObject("aircraft-crew_spec")
    if (::checkObj(obj))
      obj.setValue(crewSpecName)

    local obj = holderObj.findObject("aircraft-crew_points")
    if (::checkObj(obj) && !isInFlight && crewStatus != "")
    {
      local crewPointsText = ::colorize("white", ::get_crew_sp_text(::g_crew_skills.getCrewPoints(crew)))
      obj.show(true)
      obj.setValue(::loc("crew/availablePoints/advice") + ::loc("ui/colon") + crewPointsText)
      obj["crewStatus"] = crewStatus
    }
  }

  if (needShopInfo && !isRented)
  {
    local reason = ::getCantBuyUnitReason(air, true)
    local addTextObj = holderObj.findObject("aircraft-cant_buy_info")
    if (::checkObj(addTextObj) && !::u.isEmpty(reason))
    {
      addTextObj.setValue(::colorize("redMenuButtonColor", reason))

      local unitNest = holderObj.findObject("prev_unit_nest")
      if (::checkObj(unitNest) && (!::isPrevUnitResearched(air) || !::isPrevUnitBought(air)) &&
        ::is_era_available(air.shopCountry, ::getUnitRank(air), unitType))
      {
        local prevUnit = ::getPrevUnit(air)
        local unitBlk = ::build_aircraft_item(prevUnit.name, prevUnit)
        holderObj.getScene().replaceContentFromText(unitNest, unitBlk, unitBlk.len(), handler)
        ::fill_unit_item_timers(unitNest.findObject(prevUnit.name), prevUnit)
      }
    }
  }

  if (::has_entitlement("AccessTest") && needShopInfo && holderObj.findObject("aircraft-surviveRating"))
  {
    local blk = ::get_global_stats_blk()
    if (blk["aircrafts"])
    {
      local stats = blk["aircrafts"][air.name]
      local surviveText = ::loc("multiplayer/notAvailable")
      local winsText = ::loc("multiplayer/notAvailable")
      local usageText = ::loc("multiplayer/notAvailable")
      local rating = -1
      if (stats)
      {
        local survive = (stats["flyouts_deaths"]!=null)? stats["flyouts_deaths"] : 1.0
        survive = (survive==0)? 0 : 1.0 - 1.0/survive
        surviveText = roundToDigits(100.0*survive, 2) + "%"
        local wins = (stats["wins_flyouts"]!=null)? stats["wins_flyouts"] : 0.0
        winsText = roundToDigits(100.0*wins, 2) + "%"

        local usage = (stats["flyouts_factor"]!=null)? stats["flyouts_factor"] : 0.0
        if (usage >= 0.000001)
        {
          rating = 0
          foreach(r in ::usageRating_amount)
            if (usage > r)
              rating++
          usageText = ::loc("shop/usageRating/" + rating)
          if (::has_entitlement("AccessTest"))
            usageText += " (" + roundToDigits(100.0*usage, 2) + "%)"
        }
      }
      holderObj.findObject("aircraft-surviveRating-tr").show(true)
      holderObj.findObject("aircraft-surviveRating").setValue(surviveText)
      holderObj.findObject("aircraft-winsRating-tr").show(true)
      holderObj.findObject("aircraft-winsRating").setValue(winsText)
      holderObj.findObject("aircraft-usageRating-tr").show(true)
      if (rating>=0)
        holderObj.findObject("aircraft-usageRating").overlayTextColor = "usageRating" + rating;
      holderObj.findObject("aircraft-usageRating").setValue(usageText)
    }
  }

  local weaponsInfoText = ::getWeaponInfoText(air)
  obj = holderObj.findObject("weaponsInfo")
  if (obj) obj.setValue(weaponsInfoText)

  local lastPrimaryWeaponName = ::get_last_primary_weapon(air)
  local lastPrimaryWeapon = ::getModificationByName(air, lastPrimaryWeaponName)
  local massPerSecValue = ::getTblValue("mass_per_sec_diff", lastPrimaryWeapon, 0)

  local weaponIndex = -1
  local wPresets = 0
  if (air.weapons.len() > 0)
  {
    local lastWeapon = ::get_last_weapon(air.name)
    weaponIndex = 0
    foreach(idx, weapon in air.weapons)
    {
      if (::isWeaponAux(weapon))
        continue
      wPresets++
      if (lastWeapon == weapon.name && "mass_per_sec" in weapon)
        weaponIndex = idx
    }
  }

  if (weaponIndex != -1)
  {
    local weapon = air.weapons[weaponIndex]
    massPerSecValue += ::getTblValue("mass_per_sec", weapon, 0)
  }

  if (massPerSecValue != 0)
  {
    local massPerSecText = format("%.2f %s", massPerSecValue, ::loc("measureUnits/kgPerSec"))
    obj = holderObj.findObject("aircraft-massPerSec")
    if (::checkObj(obj))
      obj.setValue(massPerSecText)
  }
  obj = holderObj.findObject("aircraft-massPerSec-tr")
  if (::checkObj(obj))
    obj.show(massPerSecValue != 0)

  obj = holderObj.findObject("aircraft-research-efficiency")
  if (::checkObj(obj))
  {
    local minAge = ::getMinBestLevelingRank(air)
    local maxAge = ::getMaxBestLevelingRank(air)
    local rangeText = (minAge == maxAge) ? (::get_roman_numeral(minAge) + ::nbsp + ::loc("shop/age")) :
        (::get_roman_numeral(minAge) + ::nbsp + ::loc("ui/mdash") + ::nbsp + ::get_roman_numeral(maxAge) + ::nbsp + ::loc("mainmenu/ranks"))
    obj.setValue(rangeText)
  }

  obj = holderObj.findObject("aircraft-weaponPresets")
  if (::checkObj(obj))
    obj.setValue(wPresets.tostring())

  obj = holderObj.findObject("current_game_mode_footnote_text")
  if (::checkObj(obj))
  {
    local battleType = ::get_battle_type_by_ediff(ediff)
    local fonticon = !::CAN_USE_EDIFF ? "" :
      ::loc(battleType == BATTLE_TYPES.AIR ? "icon/unittype/aircraft" : "icon/unittype/tank")
    local diffName = ::implode([ fonticon, difficulty.getLocName() ], ::nbsp)
    obj.setValue(::loc("shop/all_info_relevant_to_current_game_mode") + ::loc("ui/colon") + diffName)
  }

  obj = holderObj.findObject("unit_rent_time")
  if (::checkObj(obj))
    obj.show(false)

  ::setCrewUnlockTime(holderObj.findObject("aircraft-lockedCrew"), air)
  ::fillAirInfoTimers(holderObj, air, needShopInfo)
}

function get_max_era_available_by_country(country, unitType = ::ES_UNIT_TYPE_INVALID)
{
  for(local era = 1; era <= ::max_country_rank; era++)
    if (!::is_era_available(country, era, unitType))
      return (era - 1)
  return ::max_country_rank
}

function airInfoToggle(holderObj, toggle = null, showTabs = true)
{
  if (toggle == null)
    toggle = ::loadLocalByAccount("show_slot_info_panel", true)
  else
    ::saveLocalByAccount("show_slot_info_panel", toggle)

  local toggled = holderObj.toggled != "no"
  if (toggled == toggle)
    return

  holderObj.toggled = toggle? "yes" : "no"

  local contentObj = holderObj.findObject("slot_info_content")
  if (::checkObj(contentObj))
    contentObj.show(toggle)

  local contentSwitchObj = holderObj.findObject("slot_info_listbox")
  if (::checkObj(contentSwitchObj))
    contentSwitchObj.show(toggle && showTabs)

  local bObj = holderObj.findObject("btnAirInfoToggle")
  if (bObj)
    bObj.tooltip = ::loc(toggle? "mainmenu/btnCollapse" : "mainmenu/btnExpand")
  local iObj = holderObj.findObject("btnAirInfoToggle_icon")
  if (iObj)
    iObj.rotation = toggle? "270" : "90"
}


function fill_progress_bar(obj, curExp, newExp, maxExp, isPaused = false)
{
  if (!::checkObj(obj) || !maxExp)
    return

  local guiScene = obj.getScene()
  if (!guiScene)
    return

  guiScene.replaceContent(obj, "gui/countryExpItem.blk", this)

  local barObj = obj.findObject("expProgressOld")
  if (::checkObj(barObj))
  {
    barObj.show(true)
    barObj.setValue(1000.0 * curExp / maxExp)
    barObj.paused = isPaused ? "yes" : "no"
  }

  local barObj = obj.findObject("expProgress")
  if (::checkObj(barObj))
  {
    barObj.show(true)
    barObj.setValue(1000.0 * newExp / maxExp)
  }
}

::__types_for_coutries <- null //for avoid recalculations
function get_unit_types_in_countries()
{
  if (::__types_for_coutries)
    return ::__types_for_coutries

  local defaultCountryData = {}
  foreach(unitType in ::g_unit_type.types)
    defaultCountryData[unitType.esUnitType] <- false

  ::__types_for_coutries = {}
  foreach(country in ::shopCountriesList)
    ::__types_for_coutries[country] <- clone defaultCountryData

  foreach(unit in ::all_units)
  {
    if (!unit.unitType.isAvailable())
      continue
    local esUnitType = unit.unitType.esUnitType
    local countryData = ::getTblValue(::getUnitCountry(unit), ::__types_for_coutries)
    if (::getTblValue(esUnitType, countryData, true))
      continue
    countryData[esUnitType] <- ::isUnitBought(unit)
  }

  return ::__types_for_coutries
}

function get_countries_by_unit_type(unitType)
{
  local res = []
  foreach (countryName, countryData in ::get_unit_types_in_countries())
    if (::getTblValue(unitType, countryData))
      res.append(countryName)

  return res
}

function is_country_has_any_es_unit_type(country, esUnitTypeMask)
{
  local typesList = ::getTblValue(country, ::get_unit_types_in_countries(), {})
  foreach(esUnitType, isInCountry in typesList)
    if (isInCountry && (esUnitTypeMask & (1 << esUnitType)))
      return true
  return false
}

function get_player_cur_unit()
{
  local unit = null
  if (::is_in_flight())
  {
    local unitId = ("get_player_unit_name" in getroottable())? ::get_player_unit_name() : ::cur_aircraft_name
    unit = unitId && ::getAircraftByName(unitId)
  }
  else
    unit = ::show_aircraft
  return unit
}

function is_loaded_model_high_quality(def = true)
{
  if (::hangar_get_loaded_unit_name() == "")
    return def
  return ::hangar_is_high_quality()
}

function getNotResearchedUnitByFeature(country = null, unitType = null)
{
  foreach(unit in ::all_units)
    if (    (!country || ::getUnitCountry(unit) == country)
         && (!unitType || ::get_es_unit_type(unit) == unitType)
         && ::isUnitFeatureLocked(unit)
       )
      return unit
  return null
}

function get_units_list(filterFunc)
{
  local res = []
  foreach(unit in ::all_units)
    if (filterFunc(unit))
      res.append(unit)
  return res
}

function get_units_count_at_rank(rank, type, country, exact_rank)
{
  local count = 0
  foreach (unit in ::all_units)
  {
    if (!::isUnitBought(unit))
      continue

    // Keep this in sync with getUnitsCountAtRank() in chard
    if (
        (::ES_UNIT_TYPE_TOTAL == type || ::get_es_unit_type(unit) == type) &&
        (unit.rank == rank || (!exact_rank && unit.rank > rank) ) &&
        ("" == country || unit.shopCountry == country)
       )
    {
      count++
    }
  }
  return count
}

function find_units_by_loc_name(unitLocName, searchIds = false, needIncludeNotInShop = false)
{
  needIncludeNotInShop = needIncludeNotInShop && ::is_dev_version

  local comparePrep = function(text) {
    text = ::g_string.utf8ToLower(text.tostring())
    foreach (symbol in [ ::nbsp, " ", "-", "_" ])
      text = ::stringReplace(text, symbol, "")
    return text
  }

  local searchStr = comparePrep(unitLocName)
  if (searchStr == "")
    return []

  return ::u.filter(::all_units, @(unit)
    (needIncludeNotInShop || unit.isInShop) && (
      comparePrep(::getUnitName(unit, false)).find(searchStr) != null ||
      comparePrep(::getUnitName(unit)).find(searchStr) != null ||
      searchIds && comparePrep(unit.name).find(searchStr) != null )
  )
}

function get_fm_file(unitId, unitBlkData = null)
{
  local unitPath = ::get_unit_file_name(unitId)
  if (unitBlkData == null)
    unitBlkData = ::DataBlock(unitPath)
  local nodes = ::split(unitPath, "/")
  if (nodes.len())
    nodes.pop()
  local unitDir = ::implode(nodes, "/")
  local fmPath = unitDir + "/" + (unitBlkData.fmFile || ("fm/" + unitId))
  return ::DataBlock(fmPath)
}
