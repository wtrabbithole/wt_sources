
/*
API:

add(title, msg, onClickPopupAction = null, buttons = null, handler = null, groupName = null)
  title - header text
  msg - mainText
  onClickPopupAction - callback which call on popup clicked
  buttons - array of buttons config
    first buttons function bindes on click on popup
    !!all buttons params are required!!
  [
    {id = button_id, text = buttonText, func = function (){}}
    {id = button_id, text = buttonText, func = function (){}}
    {id = button_id, text = buttonText, func = function (){}}
    {id = button_id, text = buttonText, func = function (){}}
  ]
  handler - pointer to handler, in the context of which will be called buttons functions.
    if not specified, functions will be called in global scope
  lifetime - popup showing time
  groupName - group of popups. Only one popup by group can be showed at the same time

removeByHandler(handler) - Remove all popups associated with the handler, which is set in the add method
*/

::g_popups <- {
  MAX_POPUPS_ON_SCREEN = 3

  popupsList = []
  suspendedPopupsList = []

  lastPerformDelayedCallTime = 0
}

//********** PUBLIC **********//

function g_popups::add(title, msg, onClickPopupAction = null, buttons = null, handler = null, groupName = null, lifetime = 0)
{
  savePopup(
    ::Popup({
        title = title
        msg = msg
        onClickPopupAction = onClickPopupAction
        buttons = buttons
        handler = handler
        groupName = groupName
        lifetime = lifetime
      }
    )
  )

  performDelayedFlushPopupsIfCan()
}

function g_popups::removeByHandler(handler)
{
  if (handler == null)
    return

  foreach(idx, popup in popupsList)
    if (popup.handler == handler)
    {
      popup.destroy(true)
      remove(popup)
    }

  for(local i = suspendedPopupsList.len()-1; i >= 0; i--)
    if (suspendedPopupsList[i].handler == handler)
      suspendedPopupsList.remove(i)
}

//********** PRIVATE **********//
function g_popups::performDelayedFlushPopupsIfCan()
{
  local curTime = ::dagor.getCurTime()
  if (curTime - lastPerformDelayedCallTime < LOST_DELAYED_ACTION_MSEC)
    return

  lastPerformDelayedCallTime = curTime
  local guiScene = ::get_cur_gui_scene()
  guiScene.performDelayed(
    this,
    function() {
      lastPerformDelayedCallTime = 0

      removeInvalidPopups()
      if (suspendedPopupsList.len() == 0)
        return

      for(local i = suspendedPopupsList.len()-1; i >= 0; i--)
      {
        local popup = suspendedPopupsList[i]
        local hasShowedPopupWithSameGroup = !::u.isEmpty(getByGroup(popup))
        if (canShowPopup() || hasShowedPopupWithSameGroup)
        {
          ::u.removeFrom(suspendedPopupsList, popup)
          show(popup)
        }
      }
    }
  )
}

function g_popups::show(popup)
{
  local popupByGroup = getByGroup(popup)
  if (popupByGroup)
  {
    popupByGroup.destroy(true)
    remove(popupByGroup, false)
  }

  local popupNestObj = ::get_active_gc_popup_nest_obj()
  popup.show(popupNestObj)
  popupsList.append(popup)
}

function g_popups::getPopupCount()
{
  return popupsList.len()
}

function g_popups::remove(popup, needFlushSuspended = true)
{
  for(local i = 0; i < popupsList.len(); i++)
  {
    local checkedPopup = popupsList[i]
    if (checkedPopup == popup)
    {
      popupsList.remove(i)
      break
    }
  }

  if (needFlushSuspended)
    performDelayedFlushPopupsIfCan()
}

function g_popups::getByGroup(sourcePopup)
{
  if (!sourcePopup.groupName)
    return

  return ::u.search(
    popupsList,
    @(popup) popup.groupName == sourcePopup.groupName
  )
}

function g_popups::savePopup(newPopup)
{
  local index = -1
  if (newPopup.groupName)
    index = ::u.searchIndex(
      suspendedPopupsList,
      @(popup) popup.groupName == newPopup.groupName
    )

  if (index >= 0)
    suspendedPopupsList.remove(index)

  suspendedPopupsList.insert(::max(index, 0), newPopup)
}

function g_popups::canShowPopup()
{
  local popupNestObj = ::get_active_gc_popup_nest_obj()
  if (!::check_obj(popupNestObj))
    return false

  return !::handlersManager.isAnyModalHandlerActive() && getPopupCount() < MAX_POPUPS_ON_SCREEN
}

function g_popups::removeInvalidPopups()
{
  for(local i = popupsList.len()-1; i >= 0; i--)
    if (!popupsList[i].isValidView())
      popupsList.remove(i)
}

//********** EVENT HANDLERDS ***********//

function g_popups::onEventActiveHandlersChanged(params)
{
  performDelayedFlushPopupsIfCan()
}

::subscribe_handler(::g_popups, ::g_listener_priority.DEFAULT_HANDLER)