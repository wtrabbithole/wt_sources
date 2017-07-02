::dagui_propid.add_name_id("_queueTableGenCode")

class ::gui_handlers.QueueTable extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.CUSTOM
  sceneBlkName = "gui/queue/queueTable.blk"

  queueMask = QUEUE_TYPE_BIT.UNKNOWN

  updateTimer = 0
  build_IA_shop_filters = false
  isPrimaryFocus = false
  focusArray = ["ia_table_clusters_list"]

  function initScreen()
  {
    setCurQueue(::queues.findQueue({}, queueMask))

    scene.findObject("queue_players_total").show(!::is_me_newbie())

    scene.findObject("queue_table_timer").setUserData(this)
    scene.findObject("countries_header").setValue(::loc("available_countries") + ":")
    updateTip()
  }

  curQueue = null
  function getCurQueue() { return curQueue }
  function setCurQueue(value)
  {
    if (::queues.isQueuesEqual(curQueue, value))
      return

    curQueue = value
    fullUpdate()
  }

  function fullUpdate()
  {
    build_IA_shop_filters = true
    fillQueueInfo()
    updateScene()
  }

  function getCurCountry()
  {
    local queue = getCurQueue()
    return queue != null ? ::queues.getQueueCountry(queue) : ""
  }

  function goBack()
  {
    setShowQueueTable(false)
  }

  function onUpdate(obj, dt)
  {
    if (!scene.isVisible())
      return

    updateTimer -= dt
    if (updateTimer <= 0)
    {
      updateTimer += 1.0
      updateWaitTime()
    }
  }

  function getShowQueueTable() { return scene.isVisible() }
  function setShowQueueTable(value)
  {
    if (scene.isVisible() == value)
      return
    if (value)
      updateTip()
    // Not switching show/enable directly...
    /*scene.show(value)
    scene.enable(value)*/
    // ... but requesting switch from somewhere else (GamercardDrawer)
    local id = this.scene.id
    local params = {
      target = this.scene
      visible = value
    }
    ::broadcastEvent("RequestToggleVisibility", params)
  }

  function updateTip()
  {
    local tipObj = getObj("queue_tip")
    if (!tipObj)
      return

    local esUnitTypes = getCurEsUnitTypesList()
    local mask = 0
    foreach(esUnitType in esUnitTypes)
      mask = mask | (1 << esUnitType)
    tipObj.setValue(mask)
  }

  function fillQueueInfo()
  {
    local txtPlayersWaiting = ""
    local curQueue = getCurQueue()
    if (curQueue && curQueue.queueStats)
    {
      local playersOfMyRank = curQueue.queueStats.getPlayersCountOfMyRank()
      txtPlayersWaiting = ::loc("multiplayer/playersInQueue") + ::loc("ui/colon") + playersOfMyRank
    }
    scene.findObject("queue_players_total").setValue(txtPlayersWaiting)
    updateAvailableCountries()
  }

  function updateWaitTime()
  {
    local txtWaitTime = ""
    local curQueue = getCurQueue()
    local waitTime = curQueue ? ::queues.getQueueActiveTime(curQueue) : 0
    if (waitTime > 0)
      txtWaitTime = ::format("%d:%02d", waitTime / TIME_MINUTE_IN_SECONDS, waitTime % TIME_MINUTE_IN_SECONDS)

    scene.findObject("msgText").setValue(txtWaitTime)
  }

  function updateAvailableCountries()
  {
    local curQueue = getCurQueue()
    local availCountriesObj = scene.findObject("available_countries")

    if (curQueue == null)
    {
      availCountriesObj.show(false)
      return
    }

    local event = ::events.getEvent(curQueue.name)
    local countriesList = ::events.getAvailableCountriesByEvent(event)

    if (countriesList.len() == 0)
      availCountriesObj.show(false)
    else
    {
      local blk = ::handyman.renderCached("gui/countriesList",
                                          {
                                            countries = (@(countriesList) function () {
                                              local res = []
                                              foreach (country in countriesList)
                                                res.append({
                                                  countryName = country
                                                  countryIcon = ::get_country_icon(country)
                                                })
                                              return res
                                            })(countriesList)
                                          })

      local iconsObj = availCountriesObj.findObject("countries_icons")
      availCountriesObj.show(true)
      guiScene.replaceContentFromText(iconsObj, blk, blk.len(), this)
    }
  }

  function updateScene()
  {
    if (!::checkObj(scene))
      return

    local queueTblObj = scene.findObject("queue_table")
    if (!::checkObj(queueTblObj))
      return

    local showQueueTbl = ::queues.isQueueActive(getCurQueue())
    setShowQueueTable(showQueueTbl)
    if (!showQueueTbl)
      return

    fillQueueTable()
  }

  function onClustersTabChange()
  {
    updateTabContent()
  }

  function updateTabs(queue)
  {
    if (!queue || !build_IA_shop_filters)
      return

    local clustersListObj = scene.findObject("ia_table_clusters_list")
    if (!::checkObj(clustersListObj))
      return

    build_IA_shop_filters = false

    local data = createClustersFiltersData(queue)
    guiScene.replaceContentFromText(clustersListObj, data, data.len(), this)
    clustersListObj.setValue(0)
  }

  function createClustersFiltersData(queue)
  {
    local view = { tabs = [] }
    view.tabs.append({ tabName = "#multiplayer/currentWaitTime" })

    if (::queues.isClanQueue(queue))
      view.tabs.append({ tabName = "#multiplayer/currentPlayers" })
    else
    {
      foreach (clusterName in ::queues.getQueueClusters(queue))
        view.tabs.append({
          id = clusterName
          tabName = ::g_clusters.getClusterLocName(clusterName)
        })
    }

    return ::handyman.renderCached("gui/frameHeaderTabs", view)
  }

  function fillQueueTable()
  {
    local queue = getCurQueue()
    updateTabs(queue)

    local event = ::queues.getQueueEvent(queue)
    if (!event)
      return

    local nestObj = scene.findObject("ia_tooltip")
    if (!::checkObj(nestObj))
      return

    local genCode = event.name + "_" + ::queues.getQueueCountry(queue) + "_" + ::queues.getMyRankInQueue(queue)
    if (nestObj._queueTableGenCode == genCode)
    {
      updateTabContent()
      return
    }
    nestObj._queueTableGenCode = genCode

    if (::events.isEventForClan(event))
      createQueueTableClan(nestObj)
    else
      ::g_qi_view_utils.createViewByCountries(nestObj.findObject("ia_tooltip_table"), queue, event)

    // Forces table to refill.
    updateTabContent()

    local obj = getObj("inQueue-topmenu-text")
    if (obj != null)
      obj.wink = (getCurQueue() != null) ? "yes" : "no"
  }

  function createQueueTableClan(nestObj)
  {
    local queueBoxObj = nestObj.findObject("queue_box_container")
    guiScene.createElementByObject(queueBoxObj, "gui/events/queueBox.blk", "div", this)

    foreach(team in ::events.getSidesList())
      queueBoxObj.findObject(team + "_block").show(team == Team.A) //clan queue always symmetric
  }

  function updateTabContent()
  {
    if (!::checkObj(scene))
      return
    local queue = getCurQueue()
    if (!queue)
      return

    local clustersListBoxObj = scene.findObject("ia_table_clusters_list")
    if (!::checkObj(clustersListBoxObj))
      return

    local value = ::max(0, clustersListBoxObj.getValue())
    local timerObj = scene.findObject("waiting_time")
    local tableObj = scene.findObject("ia_tooltip_table")
    local clanTableObj = scene.findObject("queue_box_container")
    local isClanQueue = ::queues.isClanQueue(queue)
    local isQueueTableVisible = value > 0
    timerObj.show(!isQueueTableVisible)
    tableObj.show(isQueueTableVisible && !isClanQueue)
    clanTableObj.show(isQueueTableVisible && isClanQueue)
    if (!isQueueTableVisible)
      return

    if (isClanQueue)
      updateClanQueueTable()
    else
    {
      if (clustersListBoxObj.childrenCount() <= value)
        return

      local listBoxObjItemObj = clustersListBoxObj.getChild(value)
      local curCluster = listBoxObjItemObj.id
      ::g_qi_view_utils.updateViewByCountries(tableObj, getCurQueue(), curCluster)
    }
  }

  function updateClanQueueTable()
  {
    local tblObj = scene.findObject("queue_box")
    if (!::checkObj(tblObj))
      return
    tblObj.show(true)

    local queue = getCurQueue()
    local queueStats = queue && queue.queueStats
    if (!queueStats)
      return

    local statsObj = tblObj.findObject(Team.A + "_block")
    local teamData = ::events.getTeamData(::queues.getQueueEvent(queue), Team.A)
    local playersCountText = ::loc("events/clans_count") + ::loc("ui/colon") + queueStats.getClansCount()
    local tableMarkup = getClanQueueTableMarkup(queueStats)

    fillQueueTeam(statsObj, teamData, tableMarkup, playersCountText)
  }

  //!!FIX ME copypaste from events handler
  function fillQueueTeam(teamObj, teamData, tableMarkup, playersCountText , teamColor = "any", teamName = "")
  {
    if (!checkObj(teamObj))
      return

    teamObj.bgTeamColor = teamColor
    teamObj.show(teamData && teamData.len())
    fillCountriesList(teamObj.findObject("countries"), ::events.getCountries(teamData))
    teamObj.findObject("team_name").setValue(teamName)
    teamObj.findObject("players_count").setValue(playersCountText)

    local queueTableObj = teamObj.findObject("table_queue_stat")
    if (!::checkObj(queueTableObj))
      return
    guiScene.replaceContentFromText(queueTableObj, tableMarkup, tableMarkup.len(), this)
  }

  //!!FIX ME copypaste from events handler
  function getClanQueueTableMarkup(queueStats)
  {
    local totalClans = queueStats.getClansCount()
    if (!totalClans)
      return ""

    local res = buildQueueStatsHeader()
    local rowParams = "inactive:t='yes'; commonTextColor:t='yes';"

    local myClanQueueTable = queueStats.getMyClanQueueTable()
    if (myClanQueueTable)
    {
      local headerData = [{
        text = ::loc("multiplayer/playersInYourClan")
        width = "0.1@scrn_tgt_font"
      }]
      res += ::buildTableRow("", headerData, null, rowParams, "0")

      local rowData = buildQueueStatsRowData(myClanQueueTable)
      res += ::buildTableRow("", rowData, null, rowParams, "0")
    }

    local headerData = [{
      text = ::loc("multiplayer/clansInQueue")
      width = "0.1@scrn_tgt_font"
    }]
    res += ::buildTableRow("", headerData, null, rowParams, "0")

    local rowData = buildQueueStatsRowData(queueStats.getClansQueueTable())
    res += ::buildTableRow("", rowData, null, rowParams, "0")
    return res
  }

  //!!FIX ME copypaste from events handler
  function buildQueueStatsRowData(queueStatData, clusterNameLoc = "")
  {
    local params = []
    params.append({
                    text = clusterNameLoc
                    tdAlign = "center"
                 })

    for(local i = 1; i <= ::max_country_rank; i++)
    {
      params.append({
        text = ::getTblValue(i.tostring(), queueStatData, 0).tostring()
        tdAlign = "center"
      })
    }
    return params
  }

  //!!FIX ME copypaste from events handler
  function buildQueueStatsHeader()
  {
    local headerData = []
    for(local i = 0; i <= ::max_country_rank; i++)
    {
      headerData.append({
        text = ::get_roman_numeral(i)
        tdAlign = "center"
      })
    }
    return ::buildTableRow("", headerData, 0, "inactive:t='yes'; commonTextColor:t='yes';", "0")
  }

  //
  // Event handlers
  //

  function onEventQueueChangeState(_queue)
  {
    if (!::queues.checkQueueType(_queue, queueMask))
      return

    if (::queues.isQueuesEqual(_queue, getCurQueue()))
    {
      fillQueueInfo()
      updateScene()
      return
    }

    if (::queues.isQueueActive(getCurQueue()))
      return //do not switch queue visual when current queue active.

    setCurQueue(_queue)
  }

  function onEventQueueInfoUpdated(params)
  {
    if (!::checkObj(scene) || !getCurQueue())
      return

    fillQueueInfo()
    updateScene()
  }

  function onEventQueueClustersChanged(_queue)
  {
    if (!::queues.isQueuesEqual(_queue, getCurQueue()))
      return

    build_IA_shop_filters = true
    updateScene()
  }

  function onEventMyStatsUpdated(params)
  {
    updateScene()
  }

  function onEventSquadStatusChanged(params)
  {
    updateScene()
  }

  function onEventGamercardDrawerOpened(params)
  {
    updateQueueWaitIconImage()
    local target = params.target
    if (target != null && target.id == scene.id)
    {
      local clustersListObject = getObj("ia_table_clusters_list")
      if (clustersListObject != null)
        clustersListObject.select()
    }
  }

  function getCurEsUnitTypesList()
  {
    local gameModeId = ::game_mode_manager.getCurrentGameModeId()
    local gameMode = ::game_mode_manager.getGameModeById(gameModeId)
    return ::game_mode_manager._getUnitTypesByGameMode(gameMode)
  }

  function updateQueueWaitIconImage()
  {
    if (!::checkObj(scene))
      return

    local modeEsUnitTypes = getCurEsUnitTypesList()

    local circle = "invis"
    if (modeEsUnitTypes && modeEsUnitTypes.len() > 1)
      circle = "both"
    else
    {
      local unitType = ::isInArray(::ES_UNIT_TYPE_TANK, modeEsUnitTypes) ?
                         ::g_unit_type.TANK : ::g_unit_type.AIRCRAFT
      circle = unitType.name.tolower()
    }

    local waitIconObj = scene.findObject("queue_wait_icon")
    if (!::checkObj(waitIconObj))
      return

    waitIconObj.circle = circle
  }

  function getCurFocusObj()
  {
    return getObj("ia_table_clusters_list")
  }
}