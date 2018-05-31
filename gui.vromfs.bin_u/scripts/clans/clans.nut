local time = require("scripts/time.nut")


const CLAN_ID_NOT_INITED = ""
const CLAN_SEASON_NUM_IN_YEAR_SHIFT = 1 // Because numInYear is zero-based.
const CLAN_SEEN_CANDIDATES_SAVE_ID = "seen_clan_candidates"
const MAX_CANDIDATES_NICKNAMES_IN_POPUP = 5
const MY_CLAN_UPDATE_DELAY_MSEC = -60000

const CLAN_RANK_ERA = 5 //really used only this rank, but in lb exist 5

::my_clan_info <- null
::last_update_my_clan_time <- MY_CLAN_UPDATE_DELAY_MSEC
::get_my_clan_data_free <- true

::g_script_reloader.registerPersistentData("ClansGlobals", ::getroottable(),
  [
    "my_clan_info"
    "last_update_my_clan_time"
    "get_my_clan_data_free"
  ])

::g_clans <- {
  lastClanId = CLAN_ID_NOT_INITED //only for compare about clan id changed
  seenCandidatesBlk = null
}

function g_clans::getMyClanType()
{
  local code = ::clan_get_my_clan_type()
  return ::g_clan_type.getTypeByCode(code)
}

function g_clans::createClan(params, handler)
{
  handler.taskId = ::char_send_blk("cln_clan_create", params)
  if (handler.taskId < 0)
    return

  ::set_char_cb(handler, handler.slotOpCb)
  handler.showTaskProgressBox()
  ::sync_handler_simulate_signal("clan_info_reload")
  handler.afterSlotOp = (@(handler) function() {
    ::getMyClanData()
    ::update_gamercards()
    handler.msgBox(
      "clan_create_sacces",
      ::loc("clan/create_clan_success"),
      [["ok", (@(handler) function() { handler.goBack() })(handler)]], "ok")
  })(handler)
}

/**
 * Edit specified clan.
 * clanId @string - id of clan to edit, -1 if your clan
 * params @DataBlock - result of g_clan::prepareEditRequest function
 */
function g_clans::editClan(clanId, params, handler)
{
  local isMyClan = ::my_clan_info != null && clanId == "-1"
  handler.taskId = ::clan_request_change_info_blk(clanId, params)
  if (handler.taskId < 0)
    return

  ::set_char_cb(handler, handler.slotOpCb)
  handler.showTaskProgressBox()
  if (isMyClan)
    ::sync_handler_simulate_signal("clan_info_reload")
  handler.afterSlotOp = (@(handler) function() {
    local owner = ::getTblValue("owner", handler, null)
    if(::clan_get_admin_editor_mode() && "reinitClanWindow" in owner)
      owner.reinitClanWindow()
    else
      ::update_gamercards()
    msgBox(
      "clan_edit_sacces",
      ::loc("clan/edit_clan_success"),
      [["ok", (@(handler) function() { handler.goBack() })(handler)]], "ok")
  })(handler)
}

function g_clans::upgradeClan(clanId, params, handler)
{
  local isMyClan = ::my_clan_info != null && clanId != "-1"
  handler.taskId = ::clan_action_blk(clanId, "cln_clan_upgrade", params, true)
  if (handler.taskId < 0)
    return

  ::set_char_cb(handler, handler.slotOpCb)
  handler.showTaskProgressBox()
  if (isMyClan)
    ::sync_handler_simulate_signal("clan_info_reload")
  handler.afterSlotOp = (@(handler) function() {
    local owner = ::getTblValue("owner", handler, null)
    if(::clan_get_admin_editor_mode() && "reinitClanWindow" in owner)
      owner.reinitClanWindow()
    else
      ::update_gamercards()
    msgBox(
      "clan_upgrade_success",
      ::loc("clan/upgrade_clan_success"),
      [["ok", (@(handler) function() { handler.goBack() })(handler)]], "ok")
  })(handler)
}

function g_clans::upgradeClanMembers(clanId)
{
  local isMyClan = ::my_clan_info != null && clanId != "-1"
  local params = ::DataBlock()
  local taskId = ::clan_action_blk(clanId, "cln_clan_members_upgrade", params, true)

  local cb = ::Callback(
      (@(clanId) function() {
        ::broadcastEvent("ClanMembersUpgraded", {clanId = clanId})
        ::update_gamercards()
        ::showInfoMsgBox(::loc("clan/members_upgrade_success"), "clan_members_upgrade_success")
      })(clanId),
      this)

  if (::g_tasker.addTask(taskId, {showProgressBox = true}, cb) && isMyClan)
    ::sync_handler_simulate_signal("clan_info_reload")
}

function g_clans::disbandClan(clanId, handler)
{
  ::gui_modal_comment(handler, ::loc("clan/writeCommentary"), ::loc("clan/btnDisbandClan"),
                      (@(handler, clanId) function(comment) {
                        handler.taskId = clan_request_disband(clanId, comment);

                        if (handler.taskId >= 0)
                        {
                          ::set_char_cb(handler, slotOpCb)
                          handler.showTaskProgressBox()
                          if (isMyClan)
                            ::sync_handler_simulate_signal("clan_info_reload")
                          handler.afterSlotOp = (@(handler, isMyClan) function() {
                              ::getMyClanData()
                              ::update_gamercards()
                              handler.msgBox("clan_disbanded", ::loc("clan/clanDisbanded"), [["ok", (@(handler) function() { handler.goBack() })(handler) ]], "ok")
                            })(handler, isMyClan)
                        }
                      })(handler, clanId), true)
}

function g_clans::prepareCreateRequest(clanType, name, tag, slogan, description, announcement, region)
{
  local requestData = ::DataBlock()
  requestData["name"] = name
  requestData["tag"] = tag
  requestData["slogan"] = slogan
  requestData["region"] = region
  requestData["type"] = clanType.getTypeName()

  if (clanType.isDescriptionChangeAllowed())
    requestData["desc"] = description

  if (clanType.isAnnouncementAllowed())
    requestData["announcement"] = announcement

  return requestData
}

function g_clans::getMyClanMembersCount()
{
  return ::getTblValue("members", ::my_clan_info, []).len()
}

function g_clans::getMyClanMembers()
{
  return ::my_clan_info?.members ?? []
}

function g_clans::getMyClanCandidates()
{
  return ::getTblValue("candidates", ::my_clan_info, [])
}

function g_clans::prepareEditRequest(clanType, name, tag, slogan, description, announcement, region)
{
  local requestData = ::DataBlock()

  requestData["version"] = 2

  if (name != null)
    requestData["name"] = name
  if (tag != null)
    requestData["tag"] = tag
  if (clanType.isDescriptionChangeAllowed() && description != null)
    requestData["desc"] = description
  if (slogan != null)
    requestData["slogan"] = slogan
  if (clanType.isAnnouncementAllowed() && announcement != null)
    requestData["announcement"] = announcement
  if (region != null)
    requestData["region"] = region

  return requestData
}

function g_clans::prepareUpgradeRequest(clanType, tag, description, announcement)
{
  local requestData = ::DataBlock()
  requestData["type"] = clanType.getTypeName()
  requestData["tag"] = tag
  requestData["desc"] = clanType.isDescriptionChangeAllowed() ? description : ""
  requestData["announcement"] = clanType.isAnnouncementAllowed() ? announcement : ""
  return requestData
}

/** Returns false if battalion clan type is disabled. */
function g_clans::clanTypesEnabled()
{
  return ::has_feature("Battalions")
}

/**
 * Return minimum interval between clan region update in menuts.
 * 1 day by default.
 */
function g_clans::getRegionUpdateCooldownTime()
{
  return ::getTblValue(
    "clansChangeRegionPeriodSeconds",
    ::get_game_settings_blk(),
    time.daysToSeconds(1)
  )
}

function g_clans::requestClanLog(clanId, rowsCount, requestMarker, callbackFnSuccess, callbackFnError, handler)
{
  local params = ::DataBlock()
  params["_id"] = clanId.tointeger()
  params["count"] = rowsCount
  if (requestMarker != null)
    params["last"] = requestMarker
  local taskId = ::clan_request_log(clanId, params)
  local successCb = ::Callback(callbackFnSuccess, handler)
  local errorCb = ::Callback(callbackFnError, handler)

  ::g_tasker.addTask(
    taskId,
    null,
    (@(successCb) function () {
      local logData = {}
      local logDataBlk = ::clan_get_clan_log()

      logData.requestMarker <- logDataBlk.lastMark
      logData.logEntries <- []
      foreach (logEntry in logDataBlk % "log")
      {
        if (logEntry?.uid != null && logEntry?.nick != null)
          ::getContact(logEntry.uid, logEntry.nick)

        if (logEntry?.uId != null && logEntry?.uN != null)
          ::getContact(logEntry.uId, logEntry.uN)

        local logEntryTable = ::buildTableFromBlk(logEntry)
        local logType = ::g_clan_log_type.getTypeByName(logEntryTable.ev)

        if ("time" in logEntryTable)
          logEntryTable.time = time.buildDateTimeStr(::get_time_from_t(logEntryTable.time))

        logEntryTable.header <- logType.getLogHeader(logEntryTable)
        if (logType.needDetails(logEntryTable))
        {
          local commonFields = logType.getLogDetailsCommonFields()
          local shortCommonDetails = ::u.pick(logEntryTable, commonFields)
          local individualFields = logType.getLogDetailsIndividualFields()
          local shortIndividualDetails = ::u.pick(logEntryTable, individualFields)

          local fullDetails = shortCommonDetails
          foreach (key, value in shortIndividualDetails)
          {
            local fullKey = logEntryTable.ev + "_" + key
            fullDetails[fullKey] <- value
          }

          logEntryTable.details <- fullDetails
          logEntryTable.details.signText <- logType.getSignText(logEntryTable)
        }

        logData.logEntries.append(logEntryTable)
      }

      successCb(logData)
    })(successCb),
    errorCb
  )
}

function g_clans::hasRightsToQueueWWar()
{
  if (!::is_in_clan())
    return false
  if (!::has_feature("WorldWarClansQueue"))
    return false
  local myRights = clan_get_role_rights(clan_get_my_role())
  return ::isInArray("WW_REGISTER", myRights)
}

function g_clans::isNonLatinCharsAllowedInClanName()
{
  return ::is_vendor_tencent()
}

function g_clans::stripClanTagDecorators(clanTag)
{
  local uftClanTag = ::utf8(clanTag)
  local length = uftClanTag.charCount()
  return length > 2 ? uftClanTag.slice(1, length - 1) : clanTag
}

function g_clans::checkClanChangedEvent()
{
  if (lastClanId == ::clan_get_my_clan_id())
    return

  local needEvent = lastClanId != CLAN_ID_NOT_INITED
  lastClanId = ::clan_get_my_clan_id()
  if (needEvent)
    ::broadcastEvent("MyClanIdChanged")
}

function g_clans::onEventProfileUpdated(p)
{
  ::getMyClanData()
}

function g_clans::onEventScriptsReloaded(p)
{
  ::getMyClanData()
}

function g_clans::onEventSignOut(p)
{
  lastClanId = CLAN_ID_NOT_INITED
  seenCandidatesBlk = null
  ::last_update_my_clan_time = MY_CLAN_UPDATE_DELAY_MSEC
}

function g_clans::loadSeenCandidates()
{
  local result = ::DataBlock()
  if(isHaveRightsToReviewCandidates())
  {
    local loaded = ::load_local_account_settings(CLAN_SEEN_CANDIDATES_SAVE_ID, null)
    if(loaded != null)
      result.setFrom(loaded)
  }
  return result
}

function g_clans::saveCandidates()
{
  if( ! isHaveRightsToReviewCandidates() || ! seenCandidatesBlk)
    return
  ::save_local_account_settings(CLAN_SEEN_CANDIDATES_SAVE_ID, seenCandidatesBlk)
}

function g_clans::getUnseenCandidatesCount()
{
  if( ! ::my_clan_info || ! getMyClanCandidates().len() ||
    ! isHaveRightsToReviewCandidates() || ! seenCandidatesBlk)
    return 0

  local count = 0
  local clanCandidates = getMyClanCandidates()
  foreach (clanCandidate in clanCandidates)
  {
    local result = seenCandidatesBlk[clanCandidate.uid]
    if( ! result)
      count++
  }
  return count
}

function g_clans::markClanCandidatesAsViewed()
{
  if( ! isHaveRightsToReviewCandidates())
    return

  local clanInfoChanged = false
  local clanCandidates = getMyClanCandidates()
  foreach (clanCandidate in clanCandidates)
  {
    if (seenCandidatesBlk[clanCandidate.uid] == true)
      continue

    seenCandidatesBlk[clanCandidate.uid] = true
    clanInfoChanged = true
  }
  if(clanInfoChanged)
    onClanCandidatesChanged()
}

function g_clans::isHaveRightsToReviewCandidates()
{
  if( ! ::is_in_clan())
    return false
  local rights = clan_get_role_rights(clan_get_my_role())
  return isInArray("MEMBER_ADDING", rights) || isInArray("MEMBER_REJECT", rights)
}

function g_clans::parseSeenCandidates()
{
  if( ! seenCandidatesBlk)
    seenCandidatesBlk = loadSeenCandidates()

  local isChanged = false
  local actualUids = {}
  local newCandidatesNicknames = []
  local clanCandidates = getMyClanCandidates()
  foreach(candidate in clanCandidates)
  {
    actualUids[candidate.uid] <- true
    if(seenCandidatesBlk[candidate.uid] != null)
      continue
    seenCandidatesBlk[candidate.uid] <- false
    newCandidatesNicknames.push(candidate.nick)
    isChanged = true
  }

  for (local i = seenCandidatesBlk.paramCount()-1; i >= 0; i--)
  {
    local paramName = seenCandidatesBlk.getParamName(i)
    if( ! (paramName in actualUids))
    {
      isChanged = true
      seenCandidatesBlk[paramName] = null
    }
  }

  if( ! isChanged)
    return

  local extraText = ""
  if(newCandidatesNicknames.len() > MAX_CANDIDATES_NICKNAMES_IN_POPUP)
  {
    extraText = ::loc("clan/moreCandidates",
      {count = newCandidatesNicknames.len() - MAX_CANDIDATES_NICKNAMES_IN_POPUP})
    newCandidatesNicknames.resize(MAX_CANDIDATES_NICKNAMES_IN_POPUP)
  }

  if(newCandidatesNicknames.len())
    ::g_popups.add(null,
      ::loc("clan/requestRecieved") +::loc("ui/colon") +::g_string.implode(newCandidatesNicknames, ", ") +
      " " + extraText,
      function()
      {
        if(getMyClanCandidates().len())
          showClanRequests(getMyClanCandidates(), ::clan_get_my_clan_id(), null)
      },
      null,
      ::g_clans)

  onClanCandidatesChanged()
}

function g_clans::onClanCandidatesChanged()
{
  if( ! getUnseenCandidatesCount())
    ::g_popups.removeByHandler(::g_clans)

  saveCandidates()
  ::update_clan_alert_icon()
}

function g_clans::getClanPlaceRewardLogData(clanData, maxCount = -1)
{
  return getRewardLogData(clanData, "rewardLog", maxCount)
}

function g_clans::getClanRaitingRewardLogData(clanData, maxCount = -1)
{
  return getRewardLogData(clanData, "raitingRewardLog", maxCount)
}

function g_clans::getRewardLogData(clanData, rewardId, maxCount)
{
  local list = []
  local count = 0
  foreach (seasonReward in clanData[rewardId])
  {
    list.append({
      iconStyle  = seasonReward.iconStyle()
      iconParams = seasonReward.iconParams()
      name = seasonReward.name()
      desc = seasonReward.desc()
    })

    if (maxCount != -1 && ++count == maxCount)
      break
  }
  return list
}

function g_clans::showClanRewardLog(clanData)
{
  ::showUnlocksGroupWnd([{
    unlocksList = getClanPlaceRewardLogData(clanData)
    titleText = ::loc("clan/clan_awards")
  }])
}

function g_clans::getClanCreationDateText(clanData)
{
  return time.buildDateStr(::get_time_from_t(clanData.cdate))
}

function g_clans::getClanInfoChangeDateText(clanData)
{
  local t = ::get_time_from_t(clanData.changedTime)
  return time.buildDateTimeStr(t, false, false)
}

function g_clans::getClanMembersCountText(clanData)
{
  if (clanData.mlimit)
    return ::format("%d/%d", clanData.members.len(), clanData.mlimit)

  return ::format("%d", clanData.members.len())
}

function g_clans::haveRankToChangeRoles(clanData)
{
  if (clanData?.id != ::clan_get_my_clan_id())
    return

  local myRank = ::clan_get_role_rank(::clan_get_my_role())

  local rolesNumber = 0
  for (local role = 0; role < ::ECMR_MAX_TOTAL; role++)
  {
     local rank = ::clan_get_role_rank(role)
     if (rank != 0 && rank < myRank)
       rolesNumber++
  }

  return (rolesNumber > 1)
}

function g_clans::getMyClanRights()
{
  return ::clan_get_role_rights(::clan_get_admin_editor_mode() ? ::ECMR_CLANADMIN : ::clan_get_my_role())
}

function g_clans::getClanMemberRank(clanData, name)
{
  foreach(member in (clanData?.members ?? []))
    if (member.nick == name)
      return ::clan_get_role_rank(member.role)

  return 0
}

function g_clans::getLeadersCount(clanData)
{
  local count = 0
  foreach(member in clanData.members)
  {
    local rights = ::clan_get_role_rights(member.role)
    if (::isInArray("LEADER", rights) ||
        ::isInArray("DEPUTY", rights))
      count++
  }
  return count
}

function g_clans::dismissMember(contact, clanData)
{
  local isMyClan = clanData?.id == ::clan_get_my_clan_id()
  local myClanRights = ::g_clans.getMyClanRights()

  if ((!isMyClan || !::isInArray("MEMBER_DISMISS", myClanRights)) && !::clan_get_admin_editor_mode())
    return

  ::gui_modal_comment(
    null,
    ::loc("clan/writeCommentary"),
    ::loc("clan/btnDismissMember"),
    function(comment) {
      local onSuccess = function() {
        ::broadcastEvent("ClanMemberDismissed")
        ::g_popups.add("", ::loc("clan/memberDismissed"))
      }

      local taskId = ::clan_request_dismiss_member(contact.uid, comment)
      ::g_tasker.addTask(taskId, { showProgressBox = true }, onSuccess)
    }
  )
}

function g_clans::requestMembership(clanId)
{
  if (::clan_get_requested_clan_id() == "-1" || ::clan_get_my_clan_name() == "")
  {
    membershipRequestSend(clanId)
    return
  }

  ::scene_msg_box("new_request_cancels_old",
                  null,
                  ::loc("msg/clan/clan_request_cancel_previous",
                    { prevClanName = ::colorize("hotkeyColor", ::clan_get_my_clan_name())}),
                  [
                    ["ok", @() ::g_clans.membershipRequestSend(clanId) ],
                    ["cancel", @() null ]
                  ], "ok", { cancel_fn = @() null })
}

function g_clans::cancelMembership()
{
  membershipRequestSend("")
}

function g_clans::membershipRequestSend(clanId)
{
  local taskId = ::clan_request_membership_request(clanId, "", "", "")
  local onSuccess = function()
  {
    if (clanId == "") //Means that membership was canceled
    {
      ::broadcastEvent("ClanMembershipCanceled")
      return
    }

    ::g_popups.add("", ::loc("clan/requestSent"))
    ::broadcastEvent("ClanMembershipRequested")
  }
  ::g_tasker.addTask(taskId, {showProgressBox = true}, onSuccess)
}

function g_clans::approvePlayerRequest(playerUid, clanId)
{
  if (::u.isEmpty(playerUid) || ::u.isEmpty(clanId))
    return

  local onSuccess = function() {
    ::g_popups.add("", ::loc("clan/requestApproved"))
    ::broadcastEvent("ClanCandidatesListChanged", {userId = playerUid})
  }

  local taskId = ::clan_request_accept_membership_request(clanId, playerUid, "REGULAR", false)
  ::sync_handler_simulate_signal("clan_info_reload")
  ::g_tasker.addTask(taskId, { showProgressBox = true }, onSuccess)
}

function g_clans::rejectPlayerRequest(playerUid)
{
  if (::u.isEmpty(playerUid))
    return

  ::gui_modal_comment(
    null,
    ::loc("clan/writeCommentary"),
    ::loc("clan/requestReject"),
    function(comment) {
      local onSuccess = function() {
        ::g_popups.add("", ::loc("clan/requestRejected"))
        ::broadcastEvent("ClanCandidatesListChanged", { userId = playerUid })
      }

      local taskId = ::clan_request_reject_membership_request(playerUid, comment)
      ::sync_handler_simulate_signal("clan_info_reload")
      ::g_tasker.addTask(taskId, { showProgressBox = true }, onSuccess)
    }
  )
}

function g_clans::blacklistAction(playerUid, actionAdd)
{
  ::gui_modal_comment(
    null,
    ::loc("clan/writeCommentary"),
    ::loc("msgbox/btn_ok"),
    function(comment) {
      local onSuccess = function() {
        local text = actionAdd? ::loc("clan/blacklistAddSuccess") : ::loc("clan/blacklistRemoveSuccess")
        ::g_popups.add("", text)
        ::broadcastEvent("ClanCandidatesListChanged", { userId = playerUid })
      }

      local taskId = ::clan_request_edit_black_list(playerUid, actionAdd, comment)
      ::sync_handler_simulate_signal("clan_info_reload")
      ::g_tasker.addTask(taskId, { showProgressBox = true }, onSuccess)
    }
  )
}

function g_clans::requestOpenComplainWnd(clanId)
{
  if (!::tribunal.canComplaint())
    return

  local taskId = ::clan_request_info(clanId, "", "")
  local onSuccess = function() {
    local clanData = ::get_clan_info_table()
    ::g_clans.openComplainWnd(clanData)
  }

  ::g_tasker.addTask(taskId, { showProgressBox = true }, onSuccess)
}

function g_clans::openComplainWnd(clanData)
{
  local leader = ::u.search(clanData.members, @(member) member.role == ::ECMR_LEADER)
  if (leader == null)
    leader = clanData.members[0]
  ::gui_modal_complain({name = leader.nick, userId = leader.uid, clanData = clanData})
}

::ranked_column_prefix <- "dr_era"
::clan_leaderboards_list <- [
  {id = "dr_era1", icon="#ui/gameuiskin#lb_elo_rating.svg", tooltip="#clan/dr_era/desc"}
  {id = "dr_era2", icon="#ui/gameuiskin#lb_elo_rating.svg", tooltip="#clan/dr_era/desc"}
  {id = "dr_era3", icon="#ui/gameuiskin#lb_elo_rating.svg", tooltip="#clan/dr_era/desc"}
  {id = "dr_era4", icon="#ui/gameuiskin#lb_elo_rating.svg", tooltip="#clan/dr_era/desc"}
  {id = "dr_era5", icon="#ui/gameuiskin#lb_elo_rating.svg", tooltip="#clan/dr_era/desc"}
  {id = "members_cnt", sort = false, byDifficulty = false}
  {id = "air_kills", field = "akills", sort = false}
  {id = "ground_kills", field = "gkills", sort = false}
  {id = "deaths", sort = false}
  {id = "time_pvp_played", type = ::g_lb_data_type.TIME_MIN, field = "ftime", sort = false}
  {id = "activity", byDifficulty = false, showByFeature = "ClanActivity" }
]

::clan_member_list <- [
  {id = "onlineStatus", type = ::g_lb_data_type.TEXT, myClanOnly = true, iconStyle = true, needHeader = false}
  {id = "nick",         type = ::g_lb_data_type.TEXT, align = "left"}
  {id = "dr_era",       type = ::g_lb_data_type.NUM, field = ::ranked_column_prefix, loc = "rating"}
  {
    id = "activity"
    type = ::g_lb_data_type.NUM
    field = "totalActivity"
    showByFeature = "ClanActivity"
    byDifficulty = false
    getCellTooltipText = function(data) { return loc("clan/personal/" + id + "/cell/desc") }
  }
  {
    id = "role",
    type = ::g_lb_data_type.ROLE,
    sortId = "roleRank"
    sortPrepare = function(member) { member[sortId] <- ::clan_get_role_rank(member.role) }
    getCellTooltipText = function(data) { return type.getPrimaryTooltipText(::getTblValue(id, data)) }
  }
  {id = "date",         type = ::g_lb_data_type.DATE }
]

::clan_data_list <- [
  {id = "air_kills", type = ::g_lb_data_type.NUM, field = "akills"}
  {id = "ground_kills", type = ::g_lb_data_type.NUM, field = "gkills"}
  {id = "deaths", type = ::g_lb_data_type.NUM, field = "deaths"}
  {id = "time_pvp_played", type = ::g_lb_data_type.TIME_MIN, field = "ftime"}
]

::default_clan_member_list <- {
  onlyMyClan = false
  iconStyle = false
  byDifficulty = true
}
foreach(idx, item in ::clan_member_list)
{
  foreach(param, value in ::default_clan_member_list)
    if (!(param in item))
      ::clan_member_list[idx][param] <- value

  item.tooltip <-"#clan/personal/" + item.id + "/desc"
}

foreach(idx, category in ::clan_leaderboards_list)
{
  if (typeof(category) != "table")
    ::clan_leaderboards_list[idx] = { id=category }
  if (!("type" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].type <- ::g_lb_data_type.NUM
  if (!("sort" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].sort <- true
  if (!("byDifficulty" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].byDifficulty <- true
  if (!("field" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].field <- ::clan_leaderboards_list[idx].id
  if (!("icon" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].icon <- "#ui/gameuiskin#lb_" + ::clan_leaderboards_list[idx].id + ".svg"
  if (!("tooltip" in ::clan_leaderboards_list[idx]))
    ::clan_leaderboards_list[idx].tooltip <- "#clan/" + ::clan_leaderboards_list[idx].id + "/desc"
}

function getMyClanData(forceUpdate = false)
{
  if(!::get_my_clan_data_free)
    return

  ::g_clans.checkClanChangedEvent()

  local myClanId = ::clan_get_my_clan_id()
  if(myClanId == "-1")
  {
    if (::my_clan_info)
    {
      ::my_clan_info = null
      ::g_clans.parseSeenCandidates()
      ::broadcastEvent("ClanInfoUpdate")
      ::broadcastEvent("ClanChanged")
      ::update_gamercards()
    }
    return
  }

  if(!forceUpdate && ::getTblValue("id", ::my_clan_info, "-1") == myClanId)
    if(::dagor.getCurTime() - ::last_update_my_clan_time < - MY_CLAN_UPDATE_DELAY_MSEC)
      return

  ::last_update_my_clan_time = ::dagor.getCurTime()
  local taskId = ::clan_request_my_info()
  ::get_my_clan_data_free = false
  ::add_bg_task_cb(taskId, function(){
    ::my_clan_info = ::get_clan_info_table()
    ::handle_new_my_clan_data()
    ::get_my_clan_data_free = true
    ::broadcastEvent("ClanInfoUpdate")
    ::update_gamercards()
  })
}

function is_in_clan()
{
  return ::clan_get_my_clan_id() != "-1"
}

function handle_new_my_clan_data()
{
  ::g_clans.parseSeenCandidates()
  ::contacts[::EPLX_CLAN] <- []
  if("members" in ::my_clan_info)
  {
    foreach(mem, block in ::my_clan_info.members)
    {
      if(!(block.uid in ::contacts_players))
        ::getContact(block.uid, block.nick)
      ::contacts_players[block.uid].presence = ::getMyClanMemberPresence(block.nick)
      if(::my_user_id_str != block.uid)
        ::contacts[::EPLX_CLAN].append(::contacts_players[block.uid])
      ::clanUserTable[block.nick] <- ::my_clan_info.tag
    }
  }
}

function is_in_my_clan(name = null, uid = null)
{
  if(my_clan_info == null)
    return false
  if("members" in my_clan_info)
    foreach(i, block in my_clan_info.members)
    {
      if(name)
        if(name == block.nick)
          return true
      if(uid)
        if(uid == block.uid)
          return true
    }
  return false
}

::clan_candidate_list <- [
  { id = "nick", type = ::g_lb_data_type.TEXT }
  { id = "date", type = ::g_lb_data_type.DATE }
];

::empty_rating <- {
  dr_era1_arc = 0
  dr_era1_hist = 0
  dr_era1_sim = 0

  dr_era2_arc = 0
  dr_era2_hist = 0
  dr_era2_sim = 0

  dr_era3_arc = 0
  dr_era3_hist = 0
  dr_era3_sim = 0

  dr_era4_arc = 0
  dr_era4_hist = 0
  dr_era4_sim = 0

  dr_era5_arc = 0
  dr_era5_hist = 0
  dr_era5_sim = 0
}

::empty_activity <- {
  cur = 0
  total = 0
}


::clanInfoTemplate <- {
  function isRegionChangeAvailable()
  {
    if (regionLastUpdate == 0)
      return true

    return regionLastUpdate + ::g_clans.getRegionUpdateCooldownTime() <= ::get_charserver_time_sec()
  }

  function getRegionChangeAvailableTime()
  {
    return ::get_time_from_t(regionLastUpdate + ::g_clans.getRegionUpdateCooldownTime())
  }

  function getClanUpgradeCost()
  {
    local cost = type.getNextTypeUpgradeCost()
    local resultingCostGold = cost.gold - spentForMemberUpgrades
    if (resultingCostGold < 0)
      resultingCostGold = 0
    cost.gold = resultingCostGold
    return cost
  }

  function getAllRegaliaTags()
  {
    local result = []
    foreach (rewards in ["seasonRewards", "seasonRatingRewards"])
    {
      local regalias = ::getTblValue("regaliaTags", this[rewards], [])
      if (!::u.isArray(regalias))
        regalias = [regalias]

      //check for duplicate before add
      //total amount of regalias is less than 10, so this square
      //complexity actually is not a big deal
      foreach (regalia in regalias)
        if (!::isInArray(regalia, result))
          result.append(regalia)
    }

    return result
  }

  function memberCount()
  {
    return members.len()
  }

  function getTypeName()
  {
    return type.getTypeName()
  }

  function getCreationDateText()
  {
    return ::g_clans.getClanCreationDateText(this)
  }

  function getInfoChangeDateText()
  {
    return ::g_clans.getClanInfoChangeDateText(this)
  }

  function getMembersCountText()
  {
    return ::g_clans.getClanMembersCountText(this)
  }

  function canShowActivity()
  {
    return ::has_feature("ClanActivity")
  }

  function getActivity()
  {
    return ::getTblValue("activity", astat, 0)
  }
}

/**
 * Pass internal clanInfo for debug purposes
 */
function get_clan_info_table(clanInfo = null)
{
  if (!clanInfo)
  {
    clanInfo = ::DataBlock();
    clanInfo = clan_get_clan_info();
  }

  if (!clanInfo._id)
    return null

  local clan = clone ::clanInfoTemplate
  clan.id     <- clanInfo._id
  clan.name   <- ::getTblValue("name",   clanInfo, "")
  clan.tag    <- ::getTblValue("tag",    clanInfo, "")
  clan.lastPaidTag <- ::getTblValue("lastPaidTag", clanInfo, "")
  clan.slogan <- ::getTblValue("slogan", clanInfo, "")
  clan.desc   <- ::getTblValue("desc",   clanInfo, "")
  clan.region <- ::getTblValue("region", clanInfo, "")
  clan.announcement <- getTblValue("announcement", clanInfo, "")
  clan.cdate  <- ::getTblValue("cdate",  clanInfo, 0)
  clan.status <- ::getTblValue("status", clanInfo, "open")
  clan.mlimit <- ::getTblValue("mlimit", clanInfo, 0)

  clan.changedByNick <- ::getTblValue("changed_by_nick", clanInfo, "")
  clan.changedByUid <- ::getTblValue("changed_by_uid", clanInfo, "")
  clan.changedTime <- ::getTblValue("changed_time", clanInfo, 0)

  clan.spentForMemberUpgrades <- ::getTblValue("mspent", clanInfo, 0)
  clan.regionLastUpdate <- ::getTblValue("region_last_updated", clanInfo, 0)
  clan.type   <- ::g_clan_type.getTypeByName(::getTblValue("type", clanInfo, ""))
  clan.autoAcceptMembership <- ::getTblValue("autoaccept",   clanInfo, false)
  clan.membershipRequirements <- ::DataBlock()
  local membReqs = ::clan_get_membership_requirements( clanInfo )
  if ( membReqs )
    clan.membershipRequirements.setFrom( membReqs );

  clan.astat <- {}

  if (clanInfo.astat)
    foreach(stat, value in clanInfo.astat)
      clan.astat[stat] <- value

  local clanMembersInfo = clanInfo % "members"
  local clanActivityInfo = clanInfo.activity
  if (!clanActivityInfo)
    clanActivityInfo = ::DataBlock()

  clan.members <- []

  local member_ratings = ::getTblValue("member_ratings", clanInfo, {})
  foreach(member in clanMembersInfo)
  {
    local memberItem = {}

    //get common members data
    foreach(key, value in member)
      memberItem[key] <- value

    //get members ELO
    local ratingTable = ::getTblValue(memberItem.uid, member_ratings, {})
    foreach(key, value in ::empty_rating)
      memberItem[key] <- ::round(::getTblValue(key, ratingTable, value))
    memberItem.onlineStatus <- ::g_contact_presence.UNKNOWN

    //get members activity
    local memberActivityInfo = clanActivityInfo.getBlockByName(memberItem.uid) || ::DataBlock()
    foreach(key, value in ::empty_activity)
      memberItem[key + "Activity"] <- memberActivityInfo.getInt(key, value)
    memberItem["activityHistory"] <-
        ::buildTableFromBlk(memberActivityInfo.getBlockByName("history"))

    clan.members.append(memberItem)
  }

  local clanCandidatesInfo = clanInfo % "candidates";
  clan.candidates <- []

  foreach(candidate in clanCandidatesInfo)
  {
    local candidateTemp = {}
    foreach(info, value in candidate)
      candidateTemp[info] <- value
    clan.candidates.append(candidateTemp)
  }

  local clanBlacklist = clanInfo % "blacklist"
  clan.blacklist <- []

  foreach(person in clanBlacklist)
  {
    local blackTemp = {}
    foreach(info, value in person)
      blackTemp[info] <- value
    clan.blacklist.append(blackTemp)
  }

  local getRewardLog = (@(clan) function(clanInfo, rewardBlockId, titleClass) {
    if (!(rewardBlockId in clanInfo))
      return []

    local log = []
    foreach (season in clanInfo[rewardBlockId])
    {
      local seasonName = titleClass.getSeasonName(season)
      foreach (title in season % "titles")
        log.append(titleClass.createFromClanReward(title, season.t, seasonName, clan))
    }
    return log
  })(clan)

  local sortRewardsInlog = @(a, b) b.seasonTime <=> a.seasonTime

  clan.rewardLog <- getRewardLog(clanInfo, "clanRewardLog", ::ClanSeasonPlaceTitle)
  clan.rewardLog.sort(sortRewardsInlog)

  clan.raitingRewardLog <- getRewardLog(clanInfo, "clanRewardRatingLog", ClanSeasonRaitingTitle)
  clan.raitingRewardLog.sort(sortRewardsInlog)

  clan.seasonRewards <- ::buildTableFromBlk(::getTblValue("clanSeasonRewards", clanInfo))
  clan.seasonRatingRewards <- ::buildTableFromBlk(::getTblValue("clanSeasonRatingRewards", clanInfo))

  //dlog("GP: Show clan table");
  //debugTableData(clan);
  return getFilteredClanData(clan)
}

class ClanSeasonTitle
{
  clanTag = ""
  clanName = ""
  seasonName = ""
  seasonTime = 0
  difficultyName = ""


  constructor (...)
  {
    ::dagor.assertf(false, "Error: attempt to instantiate ClanSeasonTitle intreface class.")
  }

  static function getSeasonName(blk)
  {
    local year = ::get_utc_time_from_t(blk.seasonStartTimestamp || 0).year.tostring()
    local num  = ::get_roman_numeral(::to_integer_safe(blk.numInYear || 0) + CLAN_SEASON_NUM_IN_YEAR_SHIFT)
    return ::loc("clan/battle_season/name", { year = year, num = num })
  }

  function getBattleTypeTitle()
  {
    local difficulty = ::g_difficulty.getDifficultyByEgdLowercaseName(difficultyName)
    return ::loc(difficulty.abbreviation)
  }

  function getUpdatedClanInfo(unlockBlk)
  {
    local isMyClan = ::is_in_clan() && (unlockBlk.clanId || "").tostring() == ::clan_get_my_clan_id()
    return {
      clanTag  = isMyClan ? ::clan_get_my_clan_tag()  : unlockBlk.clanTag
      clanName = isMyClan ? ::clan_get_my_clan_name() : unlockBlk.clanName
    }
  }

  function name() {}
  function desc() {}
  function iconStyle() {}
  function iconParams() {}
}


class ClanSeasonPlaceTitle extends ClanSeasonTitle
{
  place = ""


  static function createFromClanReward (titleString, sTime, seasonName, clanData)
  {
    local titleParts = ::split(titleString, "@")
    local place = ::getTblValue(0, titleParts, "")
    local difficultyName = ::getTblValue(1, titleParts, "")
    return ClanSeasonPlaceTitle(
      sTime,
      difficultyName,
      place,
      seasonName,
      clanData.tag,
      clanData.name
    )
  }


  static function createFromUnlockBlk (unlockBlk)
  {
    local idParts = ::split(unlockBlk.id, "_")
    local info = ::ClanSeasonPlaceTitle.getUpdatedClanInfo(unlockBlk)
    return ClanSeasonPlaceTitle(
      unlockBlk.t
      unlockBlk.rewardForDiff,
      idParts[0],
      ::ClanSeasonPlaceTitle.getSeasonName(unlockBlk),
      info.clanTag,
      info.clanName
    )
  }


  constructor (
    _seasonTime,
    _difficlutyName,
    _place,
    _seasonName,
    _clanTag,
    _clanName,
  )
  {
    seasonTime = _seasonTime
    difficultyName = _difficlutyName
    place = _place
    seasonName = _seasonName
    clanTag = _clanTag
    clanName = _clanName
  }

  function isWinner()
  {
    return ::g_string.startsWith(place, "place")
  }

  function getPlaceTitle()
  {
    if (isWinner())
      return ::loc("clan/season_award/place/" + place)
    else
      return ::loc("clan/season_award/place/top", { top = ::g_string.slice(place, 3) })
  }

  function name()
  {
    return ::loc(
      "clan/season_award/title",
      {
        achievement = getPlaceTitle()
        battleType = getBattleTypeTitle()
        season = seasonName
      }
    )
  }

  function desc()
  {
    local placeTitleColored = ::colorize("activeTextColor", getPlaceTitle())
    return ::loc(
      "clan/season_award/desc/" + (isWinner() ? "place" : "top"),
      {
        place = placeTitleColored
        top = placeTitleColored
        battleType = ::colorize("activeTextColor", getBattleTypeTitle())
        squadron = ::colorize("activeTextColor", clanTag + ::nbsp + clanName)
        season = ::colorize("activeTextColor", seasonName)
      }
    )
  }

  function iconStyle()
  {
    return "clan_medal_" + place + "_" + difficultyName
  }

  function iconParams()
  {
    return { season_title = { text = seasonName } }
  }
}


class ClanSeasonRaitingTitle extends ClanSeasonTitle
{
  difficultyName = ""
  rating = ""


  static function createFromClanReward (titleString, sTime, seasonName, clanData)
  {
    local titleParts = ::split(titleString, "@")
    local rating = ::getTblValue(0, titleParts, "")
    rating = ::g_string.slice(rating, 0, ::g_string.indexOf(rating, "rating"))
    local difficultyName = ::getTblValue(1, titleParts, "")
    return ClanSeasonRaitingTitle(
      sTime
      difficultyName,
      rating,
      seasonName,
      clanData.tag,
      clanData.name
    )
  }


  static function createFromUnlockBlk (unlockBlk)
  {
    local info = ::ClanSeasonRaitingTitle.getUpdatedClanInfo(unlockBlk)
    return ClanSeasonRaitingTitle(
      seasonTime,
      difficultyName,
      rating,
      seasonName,
      info.clanTag,
      info.clanName
    )
  }


  constructor (
    _seasonTime,
    _dufficultyName,
    _rating,
    _seasonName,
    _clanTag,
    _clanName
  )
  {
    seasonTime = _seasonTime
    difficultyName = _dufficultyName
    rating = _rating
    seasonName = _seasonName
    clanTag = _clanTag
    clanName = _clanName
  }


  function name()
  {
    return ::loc(
      "clan/season_award/title",
      {
        achievement = ::loc("clan/season_award/rating", { ratingValue = rating })
        battleType = getBattleTypeTitle()
        season = seasonName
      }
    )
  }

  function desc()
  {
    local coloredRating = ::colorize("activeTextColor", rating)
    return ::loc(
      "clan/season_award/desc/rating",
      {
        ratingValue = coloredRating
        battleType = ::colorize("activeTextColor", getBattleTypeTitle())
        squadron = ::colorize("activeTextColor", clanTag + ::nbsp + clanName)
        season = ::colorize("activeTextColor", seasonName)
      }
    )
  }

  function iconStyle()
  {
    return "clan_medal_" + rating + "rating_" + difficultyName
  }

  function iconParams()
  {
    return { season_title = { text = seasonName } }
  }
}

function getFilteredClanData(clanData)
{
  if ("tag" in clanData)
    clanData.tag = ::checkClanTagForDirtyWords(clanData.tag)

  local textFields = [
    "name"
    "desc"
    "slogan"
    "announcement"
    "region"
  ]

  foreach (key in textFields)
    if (key in clanData)
      clanData[key] = ::ps4CheckAndReplaceContentDisabledText(clanData[key])

  return clanData
}

function checkClanTagForDirtyWords(clanTag, returnString = true)
{
  if (::is_platform_ps4)
  {
    if (returnString)
      return ::dirty_words_filter.checkPhrase(clanTag)
    else
      return ::dirty_words_filter.isPhrasePassing(clanTag)
  }

  return returnString? clanTag : true
}

function ps4CheckAndReplaceContentDisabledText(processingString)
{
  local pattern = "[^ ]"
  local replacement = "*"

  if (!::ps4_is_ugc_enabled())
    processingString = ::regexp2(pattern).replace(replacement, processingString)
  return processingString
}

function getMyClanMemberPresence(nick)
{
  local clanActiveUsers = []

  foreach (idx, roomData in ::g_chat.rooms)
    if (::g_chat.isRoomClan(roomData.id) && roomData.users.len() > 0)
    {
      foreach (idx, user in roomData.users)
        clanActiveUsers.append(user.name)
      break
    }

  if (::isInArray(nick, clanActiveUsers))
  {
    local contact = ::Contact.getByName(nick)
    if (!(contact?.forceOffline ?? false))
      return ::g_contact_presence.ONLINE
  }
  return ::g_contact_presence.OFFLINE
}

function get_show_in_squadron_statistics(modeId)
{
  local gameSettingsBlk = ::get_game_settings_blk()
  if (gameSettingsBlk == null) return true
  local filter = gameSettingsBlk["squadronStatisticsFilter"]
  return ::getTblValue(modeId, filter, true)
}

function clan_request_set_membership_requirements(clanIdStr, requirements, autoAccept)
{
  local blk = ::DataBlock()
  blk["membership_req"] <- requirements
  blk["_id"] = clanIdStr
  if (autoAccept)
    blk["autoaccept"] = true
  return ::char_send_clan_oneway_blk("cln_clan_set_membership_requirements", blk)
}

function gui_modal_new_clan()
{
  gui_start_modal_wnd(::gui_handlers.CreateClanModalHandler)
}

function gui_modal_edit_clan(clanData, owner)
{
  gui_start_modal_wnd(::gui_handlers.EditClanModalhandler, {clanData = clanData, owner = owner})
}

function gui_modal_upgrade_clan(clanData, owner)
{
  gui_start_modal_wnd(::gui_handlers.UpgradeClanModalHandler, {clanData = clanData, owner = owner})
}

function gui_modal_clans(startPage = "")
{
  gui_start_modal_wnd(::gui_handlers.ClansModalHandler, {startPage = startPage})
}

::subscribe_handler(::g_clans, ::g_listener_priority.DEFAULT_HANDLER)
