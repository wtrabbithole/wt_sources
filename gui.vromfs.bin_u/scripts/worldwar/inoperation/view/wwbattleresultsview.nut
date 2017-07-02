enum UNIT_STATS {
  INITIAL
  KILLED
  INACTIVE
  REMAIN
  TOTAL // enum size
}

class ::WwBattleResultsView
{
  battleRes = null

  battleUnitTypes   = null
  inactiveUnitTypes = null

  teamBlock = null

  static armyStateTexts = {
    EASAB_UNKNOWN     = "debriefing/ww_army_state_unknown"
    EASAB_UNCHANGED   = "debriefing/ww_army_state_unchanged"
    EASAB_RETREATING  = "debriefing/ww_army_state_retreating"
    EASAB_DEAD        = "debriefing/ww_army_state_dead"
  }

  constructor(_battleRes)
  {
    battleRes = _battleRes

    getBattleUnitTypesData()
    teamBlock = getTeamBlock()
  }

  function getBattleUnitTypesData()
  {
    battleUnitTypes   = []
    inactiveUnitTypes = []

    foreach (team in battleRes.teams)
    {
      foreach (wwUnit in team.unitsInitial)
        ::append_once(wwUnit.getWwUnitType().code, battleUnitTypes)
      foreach (wwUnit in team.unitsRemain)
        if (wwUnit.inactiveCount > 0)
          ::append_once(wwUnit.getWwUnitType().code, inactiveUnitTypes)
    }

    battleUnitTypes.sort()
    inactiveUnitTypes.sort()
  }

  function getLocName()
  {
    return ::get_locId_name({ locId = battleRes.locName })
  }

  function getBattleTitle()
  {
    local localizedName = getLocName()
    return (localizedName != "") ? localizedName : ::loc("worldwar/autoModeBattle")
  }

  function getBattleDescText()
  {
    local curOperation = ::g_ww_global_status.getOperationById(::ww_get_operation_id())
    local operationName = curOperation ? curOperation.getNameText() : ""
    local zoneName = battleRes.zoneName != "" ? (::loc("options/dyn_zone") + " " + battleRes.zoneName) : ""
    local timeTbl = ::get_time_from_t(battleRes.time)
    local dateTime = ::build_date_str(timeTbl) + " " + ::build_time_str(timeTbl)
    return ::implode([ operationName, zoneName, dateTime ], ::loc("ui/semicolon"))
  }

  function getBattleResultText()
  {
    local isWinner = battleRes.winner == ::ww_get_player_side()
    local color = isWinner ? "wwTeamAllyColor" : "wwTeamEnemyColor"
    local result = ::loc("worldwar/log/battle_finished" + (isWinner ? "_win" : "_lose"))
    return ::colorize(color, result)
  }

  function getArmyStateText(wwArmy, armyState)
  {
    local res = ::loc(::getTblValue(armyState, armyStateTexts, ""))
    if (armyState == "EASAB_DEAD" && wwArmy.deathReason != "")
      res += ::loc("ui/parentheses/space", { text = ::loc("worldwar/log/army_died_" + wwArmy.deathReason) })
    return res
  }

  function getTeamBySide(side)
  {
    return ::u.search(battleRes.teams, (@(side) function (team) {
      return team.side == side
    })(side))
  }

  function getTeamStats(teamInfo, battleUnitTypes, inactiveUnitTypes)
  {
    local res = {
      unitTypes = []
      units     = []
    }

    local unitTypeStats = array(::UT_TOTAL)
    foreach (wwUnitTypeCode in battleUnitTypes)
      if (!unitTypeStats[wwUnitTypeCode])
        unitTypeStats[wwUnitTypeCode] = array(UNIT_STATS.TOTAL, 0)

    // unitsInitial shows unit counts at the moment armies joins the battle.
    // unitsCasualties snapshot is taken exactly at battle finish time.
    // unitsRemain snapshot is taken some moments AFTER the battle finish time, and its counts can be lower
    //   than it should, because army loses extra units while retreating. Thats why unitsRemain is unreliable.

    teamInfo.unitsInitial.sort(::g_world_war.sortUnitsByTypeAndCount)
    foreach (wwUnit in teamInfo.unitsInitial)
    {
      local unitName = wwUnit.name
      local wwUnitType = wwUnit.getWwUnitType()
      local wwUnitTypeCode = wwUnitType.code

      local initialActive = wwUnit.count
      local initialInactive = wwUnit.inactiveCount

      local remainActive = 0
      local remainInactive = 0
      foreach (u in teamInfo.unitsRemain)
        if (u.name == unitName)
        {
          remainActive = u.count
          remainInactive = u.inactiveCount
          break
        }

      // Fake units (like Infantry) have  unitsInitial and unitsRemain, but no unitsCasualties (must be calculated as initial-remain).
      // Vehicle units have unitsInitial, unitsCasualties, and unitsRemain which is unreliable (must be calculated as initial-casualties).
      // But anyway, vehicle units must extract remainInactive from that unreliable unitsRemain (it can be non-zero for Aircrafts).

      local casualties = (initialActive + initialInactive) - (remainActive + remainInactive)
      foreach (u in teamInfo.unitsCasualties)
        if (u.name == unitName)
        {
          casualties = u.count + u.inactiveCount
          remainActive = (initialActive + initialInactive) - casualties - remainInactive // Fixes vehicle units remain counts
          break
        }

      local inactiveAdded = remainInactive - initialInactive

      if (wwUnitTypeCode in unitTypeStats)
      {
        if (!unitTypeStats[wwUnitTypeCode])
          unitTypeStats[wwUnitTypeCode] = array(UNIT_STATS.TOTAL, 0)

        local stats = unitTypeStats[wwUnitTypeCode]
        stats[UNIT_STATS.INITIAL]   += initialActive
        stats[UNIT_STATS.KILLED]    += casualties
        stats[UNIT_STATS.INACTIVE]  += inactiveAdded
        stats[UNIT_STATS.REMAIN]    += remainActive
      }

      if (wwUnitType.esUnitCode == ::ES_UNIT_TYPE_INVALID) // fake unit
        continue

      local isShowInactiveCount = ::isInArray(wwUnitTypeCode, inactiveUnitTypes)

      local stats = array(UNIT_STATS.TOTAL, 0)
      stats[UNIT_STATS.INITIAL]   = initialActive
      stats[UNIT_STATS.KILLED]    = casualties
      stats[UNIT_STATS.INACTIVE]  = inactiveAdded
      stats[UNIT_STATS.REMAIN]    = remainActive

      res.units.append({
        unitString = wwUnit.getShortStringView(true, true, false, false)
        row = getStatsRowView(stats, isShowInactiveCount)
      })
    }

    foreach (wwUnitTypeCode, stats in unitTypeStats)
    {
      if (!stats)
        continue

      local wwUnitType = ::g_ww_unit_type.getUnitTypeByCode(wwUnitTypeCode)
      local isShowInactiveCount = ::isInArray(wwUnitTypeCode, inactiveUnitTypes)

      res.unitTypes.append({
        name = "#debriefing/ww_total_" + wwUnitType.name
        row = getStatsRowView(stats, isShowInactiveCount)
      })
    }

    return res
  }

  function getStatsRowView(stats, isShowInactiveCount = false)
  {
    local columnsMap = [
      [UNIT_STATS.INITIAL],
      isShowInactiveCount ? [UNIT_STATS.KILLED, UNIT_STATS.INACTIVE] : [UNIT_STATS.KILLED],
      isShowInactiveCount ? [UNIT_STATS.REMAIN] : [UNIT_STATS.REMAIN, UNIT_STATS.INACTIVE],
    ]

    local row = []
    foreach (valueIds in columnsMap)
    {
      local values = ::u.map(valueIds, (@(stats) function(id) { return stats[id] })(stats))
      local valuesSum = ::u.reduce(values, function (v, sum) { return sum + v }, 0)

      local val = isShowInactiveCount ? ::implode(values, " + ") : valuesSum.tostring()

      local tooltip = null
      if (isShowInactiveCount && values.len() == 2 && valuesSum > 0)
          tooltip = ::loc("debriefing/destroyed") + ::loc("ui/colon") + values[0] +
            "\n" + ::loc("debriefing/ww_inactive/Aircraft") + ::loc("ui/colon") + values[1]

      row.append({
        col = val
        tooltip = tooltip
      })
    }
    return row
  }

  function getTeamBlock()
  {
    local teams = []
    foreach(sideIdx, side in ::g_world_war.getSidesOrder())
    {
      local team = getTeamBySide(side)
      if (!team)
        continue

      local armies = []
      foreach (army in team.armies)
        armies.append({
          armyView = army.getView()
          armyStateText = getArmyStateText(army, ::getTblValue(army.name, team.armyStates))
        })

      teams.append({
        invert = sideIdx != 0
        countryIcon = ::get_country_icon(team.country, true)
        armies = armies
        statistics = getTeamStats(team, battleUnitTypes, inactiveUnitTypes)
      })
    }

    return teams
  }
}