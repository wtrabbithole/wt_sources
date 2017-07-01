::g_invites_classes <- {}

class ::BaseInvite
{
  static lifeTimeMsec = 3600000
  static chatLinkPrefix = "INV_"

  inviteColor = "@chatTextInviteColor"
  inviteActiveColor = "@chatTextInviteActiveColor"

  uid = ""
  receivedTime = -1

  inviterName = ""
  inviterUid = null

  isSeen = false
  isDelayed = false //do not show it to player while delayed
  isAutoAccepted = false

  timedShowStamp = -1   //  invite must be hidden till this timestamp
  timedExpireStamp = -1 //  invite must autoexpire after this timestamp

  constructor(params)
  {
    uid = getUidByParams(params)
    updateParams(params)
  }

  static function getUidByParams(params) //must be uniq between invites classes
  {
    return "ERR_" + ::getTblValue("inviterName", params, "")
  }

  function updateParams(params, initial = false)
  {
    receivedTime = ::dagor.getCurTime()
    inviterName = ::getTblValue("inviterName", params, inviterName)
    inviterUid = ::getTblValue("inviterUid", params, inviterUid)

    updateCustomParams(params, initial)

    showInvitePopup() //we are show popup on repeat the same invite.
  }

  function updateCustomParams(params, initial = false) {}

  function isValid()
  {
    return !isAutoAccepted
  }

  function isOutdated()
  {
    if ( !isValid() )
      return true
    if ( receivedTime + lifeTimeMsec < ::dagor.getCurTime() )
      return true
    if ( timedExpireStamp > 0 && timedExpireStamp <= ::get_charserver_time_sec() )
      return true
    return false
  }

  function isVisible()
  {
    return !isOutdated()
           && !isDelayed
           && !isAutoAccepted
           && !::isPlayerNickInContacts(inviterName, ::EPL_BLOCKLIST)
           && !::isUserBlockedByPrivateSetting(inviterUid, inviterName)
  }

  function setDelayed(newIsDelayed)
  {
    if (isDelayed == newIsDelayed)
      return

    isDelayed = newIsDelayed
    if (isDelayed)
      return

    ::g_invites.broadcastInviteReceived(this)
    showInvitePopup()
  }

  function updateDelayedState( now )
  {
    if ( timedShowStamp > 0 && timedShowStamp <= now )
    {
      timedShowStamp = -1
      setDelayed(false)
    }
  }

  function getNextTriggerTimestamp()
  {
    if ( timedShowStamp > 0 )
      return timedShowStamp

    if ( timedExpireStamp > 0 )
      return timedExpireStamp

    return -1
  }

  function setTimedParams( timedShowStamp_, timedExpireStamp_ )
  {
    timedShowStamp = timedShowStamp_
    timedExpireStamp  = timedExpireStamp_
    if ( timedShowStamp > 0 && timedShowStamp > ::get_charserver_time_sec() )
      setDelayed(true)
  }


  function getChatLink()
  {
    return chatLinkPrefix + uid
  }

  function getChatInviterLink()
  {
    return ::g_chat.generatePlayerLink(inviterName)
  }

  function checkChatLink(link)
  {
    return link == getChatLink()
  }

  function autoAccept()
  {
    isAutoAccepted = true
    accept()
  }
  function accept() {}
  function getChatInviteText() { return "" }
  function getPopupText() { return "" }
  function getInviteText() { return "" }
  function getIcon() { return "" }

  function showInvitePopup()
  {
    if (!isVisible())
      return
    local msg = getPopupText()
    if (!msg.len())
      return

    msg = ::colorize(inviteColor, msg)
    local buttons = [
      { id = "accept_invite",
        text = ::loc("contacts/accept_invitation"),
        func = accept
      }
    ]

    ::g_popups.add(null, msg, ::gui_start_invites, buttons, this)
  }

  function reject()
  {
    remove()
  }

  function onRemove()
  {
    ::g_popups.removeByHandler(this)
  }

  function remove()
  {
    ::g_invites.remove(this)
  }

  function showInviterMenu(position = null)
  {
    local contact = inviterUid && ::getContact(inviterUid, inviterName)
    ::g_chat.showPlayerRClickMenu(inviterName, null, contact, position)
  }

  function markSeen(silent = false)
  {
    if (isSeen)
      return false

    isSeen = true
    if (!silent)
      ::g_invites.updateNewInvitesAmount()
    return true
  }

  function isNew()
  {
    return !isSeen && !isOutdated()
  }
}