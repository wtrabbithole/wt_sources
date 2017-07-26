/*
my_stats API
   getStats()  - return stats or null if stats not recived yet, and request stats update when needed.
                 broadcast event "MyStatsUpdated" after result receive.
   markStatsReset() - mark stats to reset to update it with the next request.
   isStatsLoaded()

   isMeNewbie()   - bool, count is player newbie depends n stats
   isNewbieEventId(eventId) - bool  - is event in newbie events list in config
*/
::my_stats <-{
  updateDelay = 3600000 //once per 1 hour, we have force update after each battle or debriefing.

  _my_stats = null
  _last_update = -10000000
  _is_in_update = false
  _resetStats = false

  _newPlayersBattles = {}

  newbie = false
  newbieNextEvent = {}
  _needRecountNewbie = true
  _unitTypeByNewbieEventId = {}
  _maxUnitsUsedRank = null

  function getStats()
  {
    updateMyPublicStatsData()
    return _my_stats
  }

  function getTitles(showHidden = false)
  {
    local titles = ::getTblValue("titles", _my_stats, [])
    if (showHidden)
      return titles

    for (local i = titles.len() - 1; i >= 0 ; i--)
    {
      local titleUnlock = ::g_unlocks.getUnlockById(titles[i])
      if (!titleUnlock || titleUnlock.hidden)
        titles.remove(i)
    }

    return titles
  }

  function updateMyPublicStatsData()
  {
    if (!::g_login.isLoggedIn())
      return
    local time = ::dagor.getCurTime()
    if (_is_in_update && time - _last_update < 45000)
      return
    if (!_resetStats && _my_stats && time - _last_update < updateDelay) //once per 15min
      return

    _is_in_update = true
    _last_update = time
    ::add_bg_task_cb(::req_player_public_statinfo(::my_user_id_str),
                     function () {
                       _is_in_update = false
                       _resetStats = false
                       _needRecountNewbie = true
                       _update_my_stats()
                     }.bindenv(this))
  }

  function _update_my_stats()
  {
    local blk = ::DataBlock()
    ::get_player_public_stats(blk)

    if (!blk)
      return

    _my_stats = ::get_player_stats_from_blk(blk)

    ::broadcastEvent("MyStatsUpdated")
  }

  function isStatsLoaded()
  {
    return _my_stats != null
  }

  function clearStats()
  {
    _my_stats = null
  }

  function markStatsReset()
  {
    _resetStats = true
  }

  function onEventUnitBought(p)
  {
    //need update bought units list
    markStatsReset()
  }

  function onEventAllModificationsPurchased(p)
  {
    markStatsReset()
  }

  //newbie stats
  function onEventInitConfigs(p)
  {
    local blk = ::get_game_settings_blk()
    local blk = blk && blk.newPlayersBattles
    if (!blk)
      return

    foreach(unitType in ::unitTypesList)
    {
      local data = {
        minKills = 0
        battles = []
      }
      local list = blk % ::getUnitTypeText(unitType).tolower()
      foreach(ev in list)
      {
        _unitTypeByNewbieEventId[ev.event] <- unitType
        if (!ev.event)
          continue

        data.battles.append({
          event    = ev.event
          kills    = ev.kills || 1
          games    = ev.games || 0
          unitRank = ev.unitRank || 0
        })
        data.minKills = ::max(data.minKills, ev.kills)
      }
      if (data.minKills)
        _newPlayersBattles[unitType] <- data
    }
  }

  function onEventScriptsReloaded(p)
  {
    onEventInitConfigs(p)
  }

  function checkRecountNewbie()
  {
    local statsLoaded = isStatsLoaded()  //when change newbie recount, dont forget about check stats loaded for newbie tutor
    if (!_needRecountNewbie || !statsLoaded)
    {
      if (!statsLoaded || newbie)
        updateMyPublicStatsData()
      return
    }
    _needRecountNewbie = false

    newbie = __isNewbie()
    newbieNextEvent.clear()
    foreach(unitType, config in _newPlayersBattles)
    {
      local event = null
      local kills = getKillsOnUnitType(unitType)
      foreach(evData in config.battles)
      {
        if (kills >= evData.kills)
          continue
        if (evData.games && evData.games <= ::loadLocalByAccount("tutor/newbieBattles/" + evData.event, 0))
          continue
        if (evData.unitRank && checkUnitInSlot(evData.unitRank, unitType))
          continue
        event = ::events.getEvent(evData.event)
        if (event)
          break
      }
      if (event)
        newbieNextEvent[unitType] <- event
    }
  }

  function checkUnitInSlot(requiredUnitRank, unitType)
  {
    if (_maxUnitsUsedRank == null)
      _maxUnitsUsedRank = calculateMaxUnitsUsedRanks()

    if (requiredUnitRank <= ::getTblValue(unitType.tostring(), _maxUnitsUsedRank, 0))
      return true

    return false
  }

  /**
   * Checks am i newbie, looking to my stats.
   *
   * Internal usage only. If there is no stats
   * result will be unconsistent.
   */
  function __isNewbie()
  {
    foreach (unitType in ::unitTypesList)
    {
      local newbieProgress = ::getTblValue(unitType, _newPlayersBattles)
      local killsReq = (newbieProgress && newbieProgress.minKills) || 0
      local kills = getKillsOnUnitType(unitType)
      if (kills >= killsReq)
        return false
    }
    return true
  }

  function onEventAfterJoinEventRoom(event)
  {
    if (!::events.isEventMatchesType(event, EVENT_TYPE.NEWBIE_BATTLES))
      return

    local id = "tutor/newbieBattles/" + event.name
    ::saveLocalByAccount(id, 1 + ::loadLocalByAccount(id, 0))
  }

  function onEventEventsDataUpdated(params)
  {
    _needRecountNewbie = true
  }

  function onEventCrewTakeUnit(params)
  {
    local unitType = ::get_es_unit_type(params.unit)
    local unitRank = ::getUnitRank(params.unit)
    local lastMaxRank = ::getTblValue(unitType.tostring(), _maxUnitsUsedRank, 0)
    if (lastMaxRank >= unitRank)
      return

    if (_maxUnitsUsedRank == null)
      _maxUnitsUsedRank = calculateMaxUnitsUsedRanks()

    _maxUnitsUsedRank[unitType.tostring()] = unitRank
    ::saveLocalByAccount("tutor/newbieBattles/unitsRank", _maxUnitsUsedRank)
    _needRecountNewbie = true
  }

  /**
   * Returns summ of specified fields in players statistic.
   * @summaryName - game mode. Available values:
   *  pvp_played
   *  skirmish_played
   *  dynamic_played
   *  campaign_played
   *  builder_played
   *  other_played
   *  single_played
   * @filter - table config.
   *   {
   *     addArray - array of fields to summ
   *     subtractArray - array of fields to subtract
   *     unitType - unit type filter; if not specified - get both
   *   }
   */
  function getSummary(summaryName, filter = {})
  {
    local res = 0
    local pvpSummary = ::getTblValue(summaryName, ::getTblValue("summary", _my_stats))
    if (!pvpSummary)
      return res

    local roles = []
    if ("unitType" in filter)
      roles = ::basic_unit_roles[filter.unitType]
    else
      foreach (rolesList in ::basic_unit_roles)
        roles.extend(rolesList)

    foreach(idx, diffData in pvpSummary)
      foreach(unitRole, data in diffData)
      {
        if (!::isInArray(unitRole, roles))
          continue

        foreach(param in ::getTblValue("addArray", filter, []))
          res += ::getTblValue(param, data, 0)
        foreach(param in ::getTblValue("subtractArray", filter, []))
          res -= ::getTblValue(param, data, 0)
      }
    return res
  }

  function getPvpRespawns()
  {
    return getSummary("pvp_played", {addArray = ["respawns"]})
  }

  function getMPlayersKillsCount()
  {
    return getSummary("pvp_played", {
                                      addArray = ["air_kills", "ground_kills"]
                                      subtractArray = ["air_kills_ai", "ground_kills_ai"]
                                    })
  }

  function getKillsOnUnitType(unitType)
  {
    return getSummary("pvp_played", {
                                      addArray = ["air_kills", "ground_kills"],
                                      subtractArray = ["air_kills_ai", "ground_kills_ai"]
                                      unitType = unitType
                                    })
  }

  function getClassFlags(unitType)
  {
    if (unitType == ::ES_UNIT_TYPE_AIRCRAFT)
      return ::CLASS_FLAGS_AIRCRAFT
    if (unitType == ::ES_UNIT_TYPE_TANK)
      return ::CLASS_FLAGS_TANK
    return (1 << ::EUCT_TOTAL) - 1
  }

  function getSummaryFromProfile(func, unitType = null, diff = null, mode = 1 /*domination*/)
  {
    local res = 0.0
    local classFlags = getClassFlags(unitType)
    for(local i = 0; i < ::EUCT_TOTAL; i++)
      if (classFlags & (1 << i))
      {
        if (diff != null)
          res += func(diff, i, mode)
        else
          for(local d = 0; d < 3; d++)
            res += func(d, i, mode)
      }
    return res
  }

  function getTimePlayed(unitType = null, diff = null)
  {
    return getSummaryFromProfile(stat_get_value_time_played, unitType, diff)
  }

  function isMeNewbie() //used in code
  {
    checkRecountNewbie()
    return newbie
  }

  function getNextNewbieEvent(country = null, unitType = null, checkSlotbar = true) //return null when no newbie event
  {
    checkRecountNewbie()
    if (!country)
      country = ::get_profile_info().country

    if (unitType == null)
    {
      unitType = ::get_first_chosen_unit_type(::ES_UNIT_TYPE_AIRCRAFT)
      if (checkSlotbar)
      {
        local unitTypes = getSlotbarUnitTypes(country)
        if (unitTypes.len() && !::isInArray(unitType, unitTypes))
          unitType = unitTypes[0]
      }
    }
    return ::getTblValue(unitType, newbieNextEvent)
  }

  function isNewbieEventId(eventName)
  {
    foreach(config in _newPlayersBattles)
      foreach(evData in config.battles)
        if (eventName == evData.event)
          return true
    return false
  }

  function getUnitTypeByNewbieEventId(eventId)
  {
    return ::getTblValue(eventId, _unitTypeByNewbieEventId, ::ES_UNIT_TYPE_INVALID)
  }

  function afterAccountReset()
  {
    ::saveLocalByAccount("tutor", null)
    ::save_local_account_settings("tutor", null)
    ::saveLocalByAccount(::skip_tutorial_bitmask_id, null)
    ::gui_handlers.InfoWnd.clearAllSaves()
  }

  function calculateMaxUnitsUsedRanks()
  {
    local needRecalculate = false
    local loadedBlk = ::loadLocalByAccount("tutor/newbieBattles/unitsRank", ::DataBlock())
    foreach(idx, unitType in ::unitTypesList)
      if (::getTblValue(unitType.tostring(), loadedBlk, 0) < ::max_country_rank)
      {
        needRecalculate = true
        break
      }

    if (!needRecalculate)
      return loadedBlk

    local saveBlk = ::DataBlock()
    saveBlk.setFrom(loadedBlk)
    local countryCrewsList = ::get_crew_info()
    foreach(idx, countryCrews in countryCrewsList)
      foreach (idx, crew in ::getTblValue("crews", countryCrews, []))
      {
        local unit = ::g_crew.getCrewUnit(crew)
        if (unit == null)
          continue

        local curUnitType = ::get_es_unit_type(unit)
        saveBlk[curUnitType.tostring()] = ::max(::getTblValue(curUnitType.tostring(), saveBlk, 0), ::getUnitRank(unit))
      }

    if (!::u.isEqual(saveBlk, loadedBlk))
      ::saveLocalByAccount("tutor/newbieBattles/unitsRank", saveBlk)

    return saveBlk
  }
}

::subscribe_handler(::my_stats, ::g_listener_priority.DEFAULT_HANDLER)

function is_me_newbie() //used in code
{
  return ::my_stats.isMeNewbie()
}
