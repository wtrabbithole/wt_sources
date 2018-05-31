local sheets = ::require("scripts/items/itemsShopSheets.nut")
local workshop = ::require("scripts/items/workshop/workshop.nut")
local seenList = ::require("scripts/seen/seenList.nut")
local bhvUnseen = ::require("scripts/seen/bhvUnseen.nut")

function gui_start_itemsShop(params = null)
{
  ::gui_start_items_list(itemsTab.SHOP, params)
}

function gui_start_inventory(params = null)
{
  ::gui_start_items_list(itemsTab.INVENTORY, params)
}

function gui_start_items_list(curTab, params = null)
{
  if (!::ItemsManager.isEnabled())
    return

  local handlerParams = { curTab = curTab }
  if (params != null)
    handlerParams = ::inherit_table(handlerParams, params)
  ::handlersManager.loadHandler(::gui_handlers.ItemsList, handlerParams)
}

class ::gui_handlers.ItemsList extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.MODAL
  sceneBlkName = "gui/items/itemsShop.blk"

  curTab = 0 //first itemsTab
  visibleTabs = null //[]
  curSheet = null
  curItem = null //last selected item to restore selection after change list

  isSheetsInited = false
  isSheetsInUpdate = false
  itemsPerPage = -1
  itemsList = null
  curPage = 0
  shouldSetPageByItem = false
  currentFocusItem = 2

  slotbarActions = [ "preview", "testflight", "weapons", "info" ]

  // Used to avoid expensive get...List and further sort.
  itemsListValid = false

  function initScreen()
  {
    sheets.updateWorkshopSheets()

    local sheetData = curTab < 0 && curItem ? sheets.getSheetDataByItem(curItem) : null
    if (sheetData)
    {
      curTab = sheetData.tab
      shouldSetPageByItem = true
    } else if (curTab < 0)
      curTab = 0

    curSheet = sheetData ? sheetData.sheet
      : curSheet ? sheets.findSheet(curSheet, sheets.ALL) //it can be simple table, need to find real sheeet by it
      : sheets.ALL

    fillTabs()

    initFocusArray()

    scene.findObject("update_timer").setUserData(this)

    // If items shop was opened not in menu - player should not
    // be able to navigate through sheets and tabs.
    local checkIsInMenu = ::isInMenu() || ::has_feature("devItemShop")
    local checkEnableShop = checkIsInMenu && ::has_feature("ItemsShop")
    scene.findObject("wnd_title").show(!checkEnableShop)
    getTabsListObj().show(checkEnableShop)
    getTabsListObj().enable(checkEnableShop)
    getSheetsListObj().show(isInMenu)
    getSheetsListObj().enable(isInMenu)

    updateWarbondsBalance()
  }

  function reinitScreen(params = {})
  {
    setParams(params)
    initScreen()
  }

  function getMainFocusObj()
  {
    return getSheetsListObj()
  }

  function getMainFocusObj2()
  {
    local obj = getItemsListObj()
    return obj.childrenCount() ? obj : null
  }

  function focusSheetsList()
  {
    local obj = getSheetsListObj()
    obj.select()
    checkCurrentFocusItem(obj)
  }

  function getTabName(tabIdx)
  {
    switch (tabIdx)
    {
      case itemsTab.SHOP:          return "items/shop"
      case itemsTab.INVENTORY:     return "items/inventory"
      case itemsTab.WORKSHOP:      return "items/workshop"
    }
    return ""
  }

  isTabVisible = @(tabIdx) tabIdx != itemsTab.WORKSHOP || workshop.isAvailable()
  getTabSeenList = @(tabIdx) seenList.get(getTabSeenId(tabIdx))

  function getTabSeenId(tabIdx)
  {
    switch (tabIdx)
    {
      case itemsTab.SHOP:          return SEEN.ITEMS_SHOP
      case itemsTab.INVENTORY:     return SEEN.INVENTORY
      case itemsTab.WORKSHOP:      return SEEN.WORKSHOP
    }
    return null
  }

  function fillTabs()
  {
    visibleTabs = []
    for (local i = 0; i < itemsTab.TOTAL; i++)
      if (isTabVisible(i))
        visibleTabs.append(i)

    local view = {
      tabs = []
    }
    local selIdx = -1
    foreach(idx, tabIdx in visibleTabs)
    {
      view.tabs.append({
        tabName = ::loc(getTabName(tabIdx))
        unseenIcon = getTabSeenId(tabIdx)
        navImagesText = ::get_navigation_images_text(idx, visibleTabs.len())
      })
      if (tabIdx == curTab)
        selIdx = idx
    }
    if (selIdx < 0)
    {
      selIdx = 0
      curTab = visibleTabs[selIdx]
    }

    local data = ::handyman.renderCached("gui/frameHeaderTabs", view)
    local tabsObj = getTabsListObj()
    guiScene.replaceContentFromText(tabsObj, data, data.len(), this)
    tabsObj.setValue(selIdx)
  }

  function onTabChange()
  {
    markCurrentPageSeen()

    local value = getTabsListObj().getValue()
    curTab = visibleTabs?[value] ?? curTab

    itemsListValid = false
    updateSheets()
  }

  function initSheetsOnce()
  {
    if (isSheetsInited)
      return

    local view = {
      items = sheets.types.map(@(sh) {
        text = ::loc(sh.locId)
        unseenIcon = SEEN.ITEMS_SHOP //intial to create unseen block.real value will be set on update.
        unseenIconId = "unseen_icon"
      })
    }

    local data = ::handyman.renderCached(("gui/items/shopFilters"), view)
    guiScene.replaceContentFromText(scene.findObject("filter_block"), data, data.len(), this)
    isSheetsInited = true
  }

  function updateSheets()
  {
    isSheetsInUpdate = true //there can be multiple sheets changed on switch tab, so no need to update items several times.
    guiScene.setUpdatesEnabled(false, false)
    initSheetsOnce()

    local typesObj = getSheetsListObj()
    local seenListId = getTabSeenId(curTab)
    local curValue = -1
    foreach(idx, sh in sheets.types)
    {
      local isEnabled = sh.isEnabled(curTab)
      local child = typesObj.getChild(idx)
      child.show(isEnabled)
      child.enable(isEnabled)

      if (!isEnabled)
        continue

      if (curValue < 0 || curSheet == sh)
        curValue = idx

      child.findObject("unseen_icon").setValue(bhvUnseen.makeConfigStr(seenListId, sh.getSeenId()))
    }
    if (curValue >= 0)
      typesObj.setValue(curValue)

    guiScene.setUpdatesEnabled(true, true)
    isSheetsInUpdate = false

    applyFilters()
  }

  function onItemTypeChange(obj)
  {
    markCurrentPageSeen()

    local newSheet = sheets.types?[obj.getValue()]
    if (!newSheet)
      return

    curSheet = newSheet
    itemsListValid = false

    if (!isSheetsInUpdate)
      applyFilters()
  }

  function initItemsListSizeOnce()
  {
    if (itemsPerPage >= 1)
      return

    local sizes = ::g_dagui_utils.adjustWindowSize(scene.findObject("wnd_items_shop"), getItemsListObj(), 
                                                   "@itemWidth", "@itemHeight", "@itemSpacing", "@itemSpacing")
    itemsPerPage = sizes.itemsCountX * sizes.itemsCountY
  }

  function applyFilters(resetPage = true)
  {
    initItemsListSizeOnce()

    if (!itemsListValid)
    {
      itemsListValid = true
      itemsList = curSheet.getItemsList(curTab)
      if (curTab == itemsTab.INVENTORY)
        itemsList.sort(::ItemsManager.getItemsSortComparator(getTabSeenList(curTab)))
    }

    if (resetPage && !shouldSetPageByItem)
      curPage = 0
    else
    {
      shouldSetPageByItem = false
      local lastIdx = getLastSelItemIdx()
      if (lastIdx >= 0)
        curPage = (lastIdx / itemsPerPage).tointeger()
      else if (curPage * itemsPerPage > itemsList.len())
        curPage = ::max(0, ((itemsList.len() - 1) / itemsPerPage).tointeger())
    }

    fillPage()
  }

  function fillPage()
  {
    local view = { items = [] }
    local pageStartIndex = curPage * itemsPerPage
    local pageEndIndex = min((curPage + 1) * itemsPerPage, itemsList.len())
    local seenListId = getTabSeenId(curTab)
    for(local i=pageStartIndex; i < pageEndIndex; i++)
    {
      local item = itemsList[i]
      if (item.hasLimits())
        ::g_item_limits.enqueueItem(item.id)
      view.items.append(item.getViewData({
        itemIndex = i.tostring(),
        showSellAmount = curTab == itemsTab.SHOP,
        unseenIcon = bhvUnseen.makeConfigStr(seenListId, item.getSeenId())
        isItemLocked = isItemLocked(item)
      }))
    }
    ::g_item_limits.requestLimits()

    local listObj = getItemsListObj()
    local data = ::handyman.renderCached(("gui/items/item"), view)
    if (::checkObj(listObj))
    {
      listObj.show(data != "")
      listObj.enable(data != "")
      guiScene.replaceContentFromText(listObj, data, data.len(), this)
    }

    local emptyListObj = scene.findObject("empty_items_list")
    if (::checkObj(emptyListObj))
    {
      local adviseMarketplace = curTab == itemsTab.INVENTORY && curSheet.isMarketplace && ::ItemsManager.isMarketplaceEnabled()
      local adviseShop = ::has_feature("ItemsShop") && curTab != itemsTab.SHOP && !adviseMarketplace

      emptyListObj.show(data.len() == 0)
      emptyListObj.enable(data.len() == 0)
      showSceneBtn("items_shop_to_marketplace_button", adviseMarketplace)
      showSceneBtn("items_shop_to_shop_button", adviseShop)
      local emptyListTextObj = scene.findObject("empty_items_list_text")
      if (::checkObj(emptyListTextObj))
      {
        local caption = ::loc(curSheet.emptyTabLocId, "")
        if (!caption.len())
          caption = ::loc("items/shop/emptyTab/default")
        if (caption.len() > 0)
        {
          local noItemsAdviceLocId =
              adviseMarketplace ? "items/shop/emptyTab/noItemsAdvice/marketplaceEnabled"
            : adviseShop        ? "items/shop/emptyTab/noItemsAdvice/shopEnabled"
            :                     "items/shop/emptyTab/noItemsAdvice/shopDisabled"
          caption += " " + ::loc(noItemsAdviceLocId)
        }
        emptyListTextObj.setValue(caption)
      }
    }

    local prevValue = listObj.getValue()
    local value = findLastValue(prevValue)
    if (value >= 0)
      listObj.setValue(value)

    updateItemInfo()

    generatePaginator(scene.findObject("paginator_place"), this,
      curPage, ceil(itemsList.len().tofloat() / itemsPerPage) - 1, null, true /*show last page*/)

    if (!itemsList.len())
      focusSheetsList()
  }

  function isItemLocked(item)
  {
    return false
  }

  function isLastItemSame(item)
  {
    if (!curItem || curItem.id != item.id)
      return false
    if (!curItem.uids || !item.uids)
      return true
    foreach(uid in curItem.uids)
      if (::isInArray(uid, item.uids))
        return true
    return false
  }

  function findLastValue(prevValue)
  {
    local offset = curPage * itemsPerPage
    local total = ::min(itemsList.len() - offset, itemsPerPage)
    if (!total)
      return -1

    local res = ::clamp(prevValue, 0, total - 1)
    if (curItem)
      for(local i = 0; i < total; i++)
      {
        local item = itemsList[offset + i]
        if (curItem.id != item.id)
          continue
        res = i
        if (isLastItemSame(item))
          break
      }
    return res
  }

  function getLastSelItemIdx()
  {
    local res = -1
    if (!curItem)
      return res

    foreach(idx, item in itemsList)
      if (curItem.id == item.id)
      {
        res = idx
        if (isLastItemSame(item))
          break
      }
    return res
  }

  function onEventInventoryUpdate(p)
  {
    if (curTab != itemsTab.SHOP)
    {
      itemsListValid = false
      applyFilters(false)
    }
  }

  function onEventUnitBought(params)
  {
    updateItemInfo()
  }

  function onEventUnitRented(params)
  {
    updateItemInfo()
  }

  function getCurItem()
  {
    local obj = getItemsListObj()
    if (!::check_obj(obj))
      return

    local value = obj.getValue() + curPage * itemsPerPage
    curItem = ::getTblValue(value, itemsList)
    return curItem
  }

  function getCurItemObj()
  {
    local itemListObj = getItemsListObj()
    local value = itemListObj.getValue()
    if (value < 0)
      return null
    return itemListObj.getChild(value)
  }

  function goToPage(obj)
  {
    markCurrentPageSeen()
    curPage = obj.to_page.tointeger()
    fillPage()
  }

  function updateItemInfo()
  {
    markItemSeen(getCurItem())
    ::ItemsManager.fillItemDescr(getCurItem(), scene.findObject("item_info"), this, true, true)
    updateButtons()
  }

  function markItemSeen(item)
  {
    if (item)
      getTabSeenList(curTab).markSeen(item.getSeenId())
  }

  function markCurrentPageSeen()
  {
    if (!itemsList)
      return

    local pageStartIndex = curPage * itemsPerPage
    local pageEndIndex = min((curPage + 1) * itemsPerPage, itemsList.len())
    local list = []
    for(local i = pageStartIndex; i < pageEndIndex; ++i)
      list.append(itemsList[i].getSeenId())
    getTabSeenList(curTab).markSeen(list)
  }

  function updateButtons()
  {
    local item = getCurItem()
    local mainActionName = item ? item.getMainActionName() : ""
    local limitsCheckData = item ? item.getLimitsCheckData() : null
    local limitsCheckResult = ::getTblValue("result", limitsCheckData, true)
    local showMainAction = mainActionName != "" && limitsCheckResult
    local buttonObj = showSceneBtn("btn_main_action", showMainAction)
    if (showMainAction)
    {
      buttonObj.visualStyle = curTab == itemsTab.INVENTORY? "secondary" : "purchase"
      ::setDoubleTextToButton(scene, "btn_main_action", item.getMainActionName(false), mainActionName)
    }
    showSceneBtn("btn_preview", item ? item.canPreview() : false)

    local altActionText = item ? item.getAltActionName() : ""
    local actionBtn = showSceneBtn("btn_alt_action", altActionText != "")
    ::set_double_text_to_button(scene, "btn_alt_action", altActionText)

    local warningText = ""
    if (!limitsCheckResult && item && !item.isInventoryItem)
      warningText = limitsCheckData.reason
    setWarningText(warningText)

    local showLinkAction = item && item.hasLink()
    local buttonObj = showSceneBtn("btn_link_action", showLinkAction)
    if (showLinkAction)
    {
      local linkActionText = ::loc(item.linkActionLocId)
      ::setDoubleTextToButton(scene, "btn_link_action", linkActionText, linkActionText)
      if (item.linkActionIcon != "")
      {
        buttonObj["class"] = "image"
        buttonObj.findObject("img")["background-image"] = item.linkActionIcon
      }
    }
  }

  function onLinkAction(obj)
  {
    local item = getCurItem()
    if (item)
      item.openLink()
  }

  function onItemPreview(obj)
  {
    if (!isValid())
      return

    local item = getCurItem()
    if (item)
      item.doPreview()
  }

  function onItemAction(buttonObj)
  {
    local id = buttonObj && buttonObj.holderId
    local item = ::getTblValue(id.tointeger(), itemsList)
    local obj = scene.findObject("shop_item_" + id)
    doMainAction(item, obj)
  }

  function onMainAction(obj)
  {
    doMainAction()
  }

  function doMainAction(item = null, obj = null)
  {
    item = item || getCurItem()
    obj = obj || getCurItemObj()
    if (item != null)
    {
      item.doMainAction(function(result) { this && onMainActionComplete(result) }.bindenv(this),
                        this,
                        { obj = obj })
      markItemSeen(item)
    }
  }

  function onMainActionComplete(result)
  {
    if (!::checkObj(scene))
      return false
    if (result.success)
      updateItemInfo()
    return result.success
  }

  function onAltAction(obj)
  {
    local item = getCurItem()
    if (item)
      item.doAltAction({ obj = obj, align = "top" })
  }

  function onDescAction(obj)
  {
    local data = ::check_obj(obj) && obj.actionData && ::parse_json(obj.actionData)
    local item = ::ItemsManager.findItemById(data?.itemId)
    local action = data?.action
    if (item && action && (action in item) && ::u.isFunction(item[action]))
      item[action]()
  }

  function onUnitHover(obj)
  {
    openUnitActionsList(obj, true, true)
  }

  function onTimer(obj, dt)
  {
    local startIdx = curPage * itemsPerPage
    local lastIdx = min((curPage + 1) * itemsPerPage, itemsList.len())
    for(local i=startIdx; i < lastIdx; i++)
    {
      if (!itemsList[i].hasTimer())
        continue
      local listObj = getItemsListObj()
      local itemObj = ::checkObj(listObj) && listObj.getChild(i - curPage * itemsPerPage)
      local timeTxtObj = ::checkObj(itemObj) && itemObj.findObject("expire_time")
      if (::checkObj(timeTxtObj))
        timeTxtObj.setValue(itemsList[i].getTimeLeftText())
    }
  }

  function onToShopButton(obj)
  {
    curTab = itemsTab.SHOP
    fillTabs()
  }

  function onToMarketplaceButton(obj)
  {
    ::ItemsManager.goToMarketplace()
  }

  function goBack()
  {
    markCurrentPageSeen()
    base.goBack()
  }

  function getItemsListObj()
  {
    return scene.findObject("items_list")
  }

  function getTabsListObj()
  {
    return scene.findObject("tabs_list")
  }

  function getSheetsListObj()
  {
    return scene.findObject("sheets_list")
  }

  /**
   * Returns all the data required to restore current window state:
   * curSheet, curTab, selected item, etc...
   */
  function getHandlerRestoreData()
  {
    local data = {
      openData = {
        curTab = curTab
        curSheet = curSheet
      }
      stateData = {
        currentItemId = ::getTblValue("id", getCurItem(), null)
      }
    }
    return data
  }

  /**
   * Returns -1 if item was not found.
   */
  function getItemIndexById(itemId)
  {
    foreach (itemIndex, item in itemsList)
    {
      if (item.id == itemId)
        return itemIndex
    }
    return -1
  }

  function restoreHandler(stateData)
  {
    local itemIndex = getItemIndexById(stateData.currentItemId)
    if (itemIndex == -1)
      return
    curPage = ::ceil(itemIndex / itemsPerPage).tointeger()
    fillPage()
    getItemsListObj().setValue(itemIndex % itemsPerPage)
  }

  function onEventBeforeStartShowroom(params)
  {
    ::handlersManager.requestHandlerRestore(this, ::gui_handlers.MainMenu)
  }

  function onEventBeforeStartTestFlight(params)
  {
    ::handlersManager.requestHandlerRestore(this, ::gui_handlers.MainMenu)
  }

  function onEventItemLimitsUpdated(params)
  {
    updateItemInfo()
  }

  function setWarningText(text)
  {
    local warningTextObj = scene.findObject("warning_text")
    if (::checkObj(warningTextObj))
      warningTextObj.setValue(::colorize("redMenuButtonColor", text))
  }

  function onEventActiveHandlersChanged(p)
  {
    showSceneBtn("black_screen", ::handlersManager.findHandlerClassInScene(::gui_handlers.trophyRewardWnd) != null)
  }

  function updateWarbondsBalance()
  {
    if (!::has_feature("Warbonds"))
      return

    local warbondsObj = scene.findObject("balance_text")
    warbondsObj.setValue(::g_warbonds.getBalanceText())
    warbondsObj.tooltip = ::loc("warbonds/maxAmount", {warbonds = ::g_warbonds.getLimit()})
  }

  function onEventProfileUpdated(p)
  {
    updateWarbondsBalance()
  }
}
