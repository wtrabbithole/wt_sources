const LONG_ACTIONBAR_SHORCUT_LEN = 6;

class ActionBar
{
  actionItems             = null
  guiScene                = null
  scene                   = null

  canControl              = true
  useWheelmenu            = false
  killStreaksActions      = null

  artillery_target_mode = false

  curActionBarUnit = null

  __action_id_prefix = "action_bar_item_"

  constructor(_nestObj) {
    if (!::checkObj(_nestObj))
      return
    scene     = _nestObj
    guiScene  = _nestObj.getScene()

    canControl = !::isPlayerDedicatedSpectator() && !::is_replay_playing()

    updateVisibility()

    ::g_hud_event_manager.subscribe("ToggleKillStreakWheel", function (eventData) {
      if ("open" in eventData)
        toggleKillStreakWheel(eventData.open)
    }, this)
    ::g_hud_event_manager.subscribe("LiveStatsVisibilityToggled", function (eventData) {
      updateVisibility()
    }, this)
    ::g_hud_event_manager.subscribe("LocalPlayerAlive", function (data) {
      fill() //the same unit can change bullets order.
    }, this)

    updateParams()
    fill()
  }

  function reinit()
  {
    updateParams()
    if (getActionBarUnit() != curActionBarUnit)
      fill()
    else
      onUpdate()
  }

  function updateParams()
  {
    useWheelmenu = ::is_xinput_device()
  }

  function isValid()
  {
    return ::checkObj(scene)
  }

  function getActionBarUnit()
  {
    return ::getAircraftByName(::get_action_bar_unit_name())
  }

  function fill()
  {
    if (!::checkObj(scene))
      return

    curActionBarUnit = getActionBarUnit()
    actionItems = getActionBarItems()

    local view = {
      items = ::u.map(actionItems, (@(a) buildItemView(a, true)).bindenv(this))
    }

    local partails = {
      items           = ::load_scene_template("gui/hud/actionBarItem")
      textShortcut    = canControl ? ::load_scene_template("gui/hud/actionBarItemTextShortcut")    : ""
      gamepadShortcut = canControl ? ::load_scene_template("gui/hud/actionBarItemGamepadShortcut") : ""
    }
    local blk = ::handyman.renderCached(("gui/hud/actionBar"), view, partails)
    guiScene.replaceContentFromText(scene, blk, blk.len(), this)
    scene.findObject("action_bar").setUserData(this)
  }

  //creates view for handyman by one actionBar item
  function buildItemView(item, needShortcuts = false)
  {
    local unit = getActionBarUnit()
    local actionBarType = ::g_hud_action_bar_type.getByActionItem(item)
    local viewItem = {}

    local isReady = isActionReady(item)

    local shortcutText = ""
    local shortcutTexture = ""
    if (needShortcuts)
    {
      local scData = ::get_shortcut_text_and_texture(actionBarType.getVisualShortcut(item, unit))
      shortcutText = scData.text
      shortcutTexture = ::getTblValue(0, scData.textures, "")
    }

    viewItem.id                 <- __action_id_prefix + item.id
    viewItem.selected           <- item.selected ? "yes" : "no"
    viewItem.active             <- item.active ? "yes" : "no"
    viewItem.enabled            <- isReady ? "yes" : "no"
    viewItem.wheelmenuEnabled   <- isReady
    viewItem.shortcutText       <- shortcutText
    viewItem.isLongScText       <- ::utf8_strlen(shortcutText) >= LONG_ACTIONBAR_SHORCUT_LEN
    viewItem.gamepadButtonImg   <- shortcutTexture
    viewItem.cancelButton       <- shortcutTexture
    viewItem.isXinput           <- ::is_xinput_device()

    if (item.type == ::EII_BULLET && unit != null)
    {
      viewItem.bullets <- ::handyman.renderNested(::load_scene_template("gui/weaponry/bullets"),
        (@(item, unit, canControl) function (text) {
          local modifName = item.modificationName != null
            ? item.modificationName
            : getDefaultBulletName(unit)

          local data = ::getBulletsSetData(unit, modifName)
          local tooltipId = ::g_tooltip.getIdModification(unit.name, modifName)
          local tooltipDelayed = !canControl
          return ::weaponVisual.getBulletsIconView(data, tooltipId, tooltipDelayed)
        })(item, unit, canControl)
      )
    }
    else if (item.type == ::EII_ARTILLERY_TARGET)
    {
      local activatedShortcut = ::get_shortcut_text_and_texture("ID_SHOOT_ARTILLERY")
      viewItem.activatedButtonImg <- ::getTblValue(0, activatedShortcut.textures, "")
    }
    if (item.type != ::EII_BULLET)
    {
      local killStreakTag = ::getTblValue("killStreakTag", item)
      viewItem.icon <- actionBarType.getIcon(killStreakTag)
      viewItem.name <- actionBarType.getTitle(killStreakTag)
      viewItem.tooltipText <- actionBarType.getTooltipText(item)
    }
    if (item.count >= 0)
      viewItem.amount <- item.count.tostring() + (item.countEx >= 0 ? "/" + item.countEx : "")

    viewItem.cooldown <- getWaitGaugeDegree(item.cooldown)
    return viewItem
  }

  function isActionReady(action)
  {
    return action.cooldown <= 0
  }

  function getWaitGaugeDegree(val)
  {
    return (360 - (::clamp(val, 0.0, 1.0) * 360)).tointeger()
  }

  function onUpdate(obj = null, dt = 0.0)
  {
    local prevCount = typeof actionItems == "array" ? actionItems.len() : 0
    local prevKillStreaksActions = killStreaksActions

    local prewActionItems = actionItems
    actionItems = getActionBarItems()

    if (useWheelmenu)
      updateKillStreakWheel(prevKillStreaksActions)

    if (prevCount != actionItems.len())
    {
      fill()
      ::broadcastEvent("HudActionbarResized", { size = actionItems.len() })
      return
    }

    foreach(item in actionItems)
    {
      local itemObj = scene.findObject(__action_id_prefix + item.id)
      if (!::checkObj(itemObj))
        continue

      local amountObj = itemObj.findObject("amount_text")
      if (item.count >= 0)
        amountObj.setValue(item.count.tostring() + (item.countEx >= 0 ? "/" + item.countEx : ""))
      else
        amountObj.setValue("")

      if (item.type != ::EII_BULLET &&
          itemObj.enabled != "yes" &&
          isActionReady(item))
        blink(itemObj)

      handleIncrementCount(item, prewActionItems, itemObj)

      itemObj.selected = item.selected ? "yes" : "no"
      itemObj.active = item.active ? "yes" : "no"
      itemObj.enabled = isActionReady(item) ? "yes" : "no"

      local mainActionButtonObj = itemObj.findObject("mainActionButton")
      local activatedActionButtonObj = itemObj.findObject("activatedActionButton")
      local cancelButtonObj = itemObj.findObject("cancelButton")
      if (::checkObj(mainActionButtonObj) &&
          ::checkObj(activatedActionButtonObj) &&
          ::checkObj(cancelButtonObj))
      {
          mainActionButtonObj.show(!item.active)
          activatedActionButtonObj.show(item.active)
          cancelButtonObj.show(item.active)
      }

      local actionBarType = ::g_hud_action_bar_type.getByActionItem(item)
      local backgroundImage = actionBarType.backgroundImage
      local iconObj = itemObj.findObject("action_icon")
      if (::checkObj(iconObj) && backgroundImage.len() > 0)
        iconObj["background-image"] = backgroundImage

      if (item.type == ::EII_EXTINGUISHER && ::checkObj(mainActionButtonObj))
        mainActionButtonObj.show(item.cooldown == 0)
      if (item.type == ::EII_ARTILLERY_TARGET && item.active != artillery_target_mode)
      {
        artillery_target_mode = item.active
        ::broadcastEvent("ArtilleryTarget", { active = artillery_target_mode })
      }

      local cooldownObj = itemObj.findObject("cooldown")
      cooldownObj["sector-angle-1"] = getWaitGaugeDegree(item.cooldown)
    }
  }

  /**
   * Function checks increase count and shows it in view.
   * It needed for display rearming process.
   */
  function handleIncrementCount(currentItem, prewItemsArray, itemObj)
  {
    if (currentItem.type != ::EII_BULLET)
      return

    local prewItem = ::u.search(prewItemsArray, (@(currentItem) function (searchItem) {
      return currentItem.id == searchItem.id
    })(currentItem))

    if (prewItem == null)
      return

    if ((prewItem.countEx == currentItem.countEx && prewItem.count < currentItem.count) ||
        (prewItem.countEx < currentItem.countEx))
    {
      local blk = ::handyman.renderCached("gui/hud/actionBarIncrement", {})
      guiScene.appendWithBlk(itemObj, blk, this)
    }
  }

  function blink(obj)
  {
    local blinkObj = obj.findObject("availability")
    if (::checkObj(blinkObj))
      blinkObj["_blink"] = "yes"
  }

  function updateVisibility()
  {
    if (::checkObj(scene))
      scene.show(!::g_hud_live_stats.isVisible())
  }

  /* *
   * Wrapper for ::get_action_bar_items().
   * Need to separate killstreak reward form other
   * action bar items.
   * Works only with gamepad controls.
   * */
  function getActionBarItems()
  {
    local isUnitValid = ::get_es_unit_type(getActionBarUnit()) != ::ES_UNIT_TYPE_INVALID
    local rawActionBarItem = isUnitValid ? ::get_action_bar_items() : []
    killStreaksActions = []

    if (!useWheelmenu)
      return rawActionBarItem

    for (local i = rawActionBarItem.len() - 1; i >= 0; i--)
    {
      local actionBarType = ::g_hud_action_bar_type.getByActionItem(rawActionBarItem[i])
      if (actionBarType.isForWheelMenu)
        killStreaksActions.insert(0, rawActionBarItem[i])
    }

    return rawActionBarItem
  }

  function activateAction(obj)
  {
    local action = getActionByObj(obj)
    if (action)
    {
      local shortcut = ::g_hud_action_bar_type.getByActionItem(action).getShortcut(action, getActionBarUnit())
      toggle_shortcut(shortcut)
    }
  }

  //Only for streak wheel menu
  function activateStreak(streakId)
  {
    local action = ::getTblValue(streakId, killStreaksActions)
    if (action)
    {
      local shortcutIdx = ::getTblValue("shortcutIdx", action, action.id) //compatibility with 1.67.2.X
      ::activate_action_bar_action(shortcutIdx)
    }
    else if (streakId >= 0) //something goes wrong; -1 is valid situation = player does not choose smthng
    {
      debugTableData(killStreaksActions)
      callstack()
      ::dagor.assertf(false, "Error: killStreak id out of range.")
    }
  }

  function getActionByObj(obj)
  {
    local actionItemNum = obj.id.slice(-(obj.id.len() - __action_id_prefix.len())).tointeger()
    foreach (item in actionItems)
      if (item.id == actionItemNum)
        return item
  }

  function toggleKillStreakWheel(open)
  {
    if (!::checkObj(scene))
      return

    if (open)
    {
      if (killStreaksActions.len() == 1)
      {
        activateStreak(0)
        ::close_cur_wheelmenu()
      }
      else
        openKillStreakWheel()
    }
    else
      ::close_cur_wheelmenu()
  }

  function openKillStreakWheel()
  {
    if (!killStreaksActions || killStreaksActions.len() == 0)
      return

    ::close_cur_voicemenu()

    fillKillStreakWheel()
  }

  function fillKillStreakWheel()
  {
    local menu = []
    foreach(action in killStreaksActions)
      menu.append(buildItemView(action))

    local params = {
      menu            = menu
      callbackFunc    = activateStreak
      contentTemplate = "gui/hud/actionBarItemStreakWheel"
      contentType     = WM_CONTENT_TYPE.TEMPLATE
      owner           = this
    }

    ::gui_start_wheelmenu(params)
  }

  function updateKillStreakWheel(prevActions)
  {
    local handler = ::handlersManager.findHandlerClassInScene(::gui_handlers.wheelMenuHandler)
    if (!handler || !handler.isActive)
      return

    local update = false
    if (killStreaksActions.len() != prevActions.len())
      update = true
    else
    {
      for (local i = killStreaksActions.len() - 1; i >= 0; i--)
        if (killStreaksActions[i].active != prevActions[i].active ||
          isActionReady(killStreaksActions[i]) != isActionReady(prevActions[i]) ||
          killStreaksActions[i].count != prevActions[i].count ||
          killStreaksActions[i].countEx != prevActions[i].countEx)
        {
          update = true
          break
        }
    }

    if (update)
      fillKillStreakWheel()
  }

  function onTooltipObjClose(obj)
  {
    ::g_tooltip.close.call(this, obj)
  }

  function onGenericTooltipOpen(obj)
  {
    ::g_tooltip.open(obj, this)
  }
}