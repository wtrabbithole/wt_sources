class ::gui_handlers.RecentItemsHandler extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.CUSTOM

  scene = null

  sceneBlkName = "gui/empty.blk"
  recentItems = null
  numOtherItems = -1

  function initScreen()
  {
    updateHandler()
  }

  function createItemsView(items)
  {
    local view = {
      items = []
    }
    foreach (i, item in items)
    {
      local item = items[i]
      local mainActionName = item.getMainActionName()
      view.items.push(item.getViewData({
        itemIndex = i.tostring()
        newIconWidget = null
        ticketBuyWindow = false
        hasButton = false
        onClick = mainActionName.len() > 0 ? "onItemAction" : null
        contentIcon = false
        hasTimer = false
        addItemName = false
      }))
    }
    return view
  }

  function updateHandler()
  {
    recentItems = ::g_recent_items.getRecentItems()
    local show = recentItems.len() > 0 && ::ItemsManager.isEnabled()
    scene.show(show)
    scene.enable(show)
    if (!show)
      return

    scene.type = ::g_promo.PROMO_BUTTON_TYPE.RECENT_ITEMS
    numOtherItems = ::g_recent_items.getNumOtherItems()

    local promoView = ::getTblValue(scene.id, ::g_promo.getConfig(), {})
    local view = {
      id = ::g_promo.getActionParamsKey(scene.id)
      items = ::handyman.renderCached("gui/items/item", createItemsView(recentItems))
      otherItemsText = createOtherItemsText(numOtherItems)
      action = ::g_promo.PERFORM_ACTON_NAME
      collapsedAction = ::g_promo.PERFORM_ACTON_NAME
      collapsedText = ::g_promo.getCollapsedText(promoView, scene.id)
      collapsedIcon = ::g_promo.getCollapsedIcon(promoView, scene.id)
    }
    local blk = ::handyman.renderCached("gui/items/recentItemsHandler", view)
    guiScene.replaceContentFromText(scene, blk, blk.len(), this)
  }

  function onItemAction(obj)
  {
    local itemIndex = ::to_integer_safe(::getTblValue("holderId", obj), -1)
    if (itemIndex == -1)
      return

    local params = {
      // Prevents stage select popup
      // from going off-screen.
      stakeSelectAlign = "left"
      hasStakeSelectArrow = false
      obj = obj
    }

    useItem(recentItems[itemIndex], params)
  }

  function useItem(item, params = null)
  {
    if (!item.hasRecentItemConfirmMessageBox)
      return _doActivateItem(item, params)

    local confirmText = item.getMainActionName(true, true)
    local msgBoxText = ::loc("recentItems/useItem", {
      itemName = item.getName()
    })

    msgBox("recent_item_confirmation", msgBoxText, [
      ["ok", ::Callback((@(_doActivateItem, item, params) function() {_doActivateItem(item, params)})(_doActivateItem, item, params), this)
      ], ["cancel", function () {}]], "ok")
  }

  function _doActivateItem(item, params)
  {
    item.doMainAction(function (result) { ::broadcastEvent("InventoryUpdate") }, this, params)
  }

  function onEventInventoryUpdate(params)
  {
    doWhenActiveOnce("updateHandler")
  }

  function createOtherItemsText(numItems)
  {
    local text = ::loc("recentItems/otherItems")
    if (numItems > 0)
      text += ::loc("ui/parentheses/space", {text = numItems})
    return text
  }

  function performAction(obj) { ::g_promo.performAction(this, obj) }
  function performActionCollapsed(obj)
  {
    local buttonObj = obj.getParent()
    performAction(buttonObj.findObject(::g_promo.getActionParamsKey(buttonObj.id)))
  }
  function onToggleItem(obj) { ::g_promo.toggleItem(obj) }
}