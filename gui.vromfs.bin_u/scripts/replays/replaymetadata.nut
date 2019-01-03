local datablockConverter = require("scripts/utils/datablockConverter.nut")

local buildReplayMpTable = function(replayPath)
{
  local res = []

  local replayInfo = ::get_replay_info(replayPath)
  local commentsBlk = replayInfo?.comments
  if (!commentsBlk)
    return res
  local playersBlkList = commentsBlk % "player"
  if (!playersBlkList.len())
    return res

  local gameType = replayInfo?.gameType ?? 0
  local authorUserId = ::to_integer_safe(commentsBlk.authorUserId, -1000)
  local authorBlk = ::u.search(playersBlkList, @(v) ::to_integer_safe(v.userId) == authorUserId)
  local authorSquadId = authorBlk?.squadId ?? INVALID_SQUAD_ID

  foreach (b in playersBlkList)
  {
    local userId = ::to_integer_safe(b.userId, 0)
    if (userId == 0)
      continue
    if ((b.name ?? "") == "" && (b.nick ?? "") == "")
      continue

    local mplayer = {
      userId = userId
      name = b.name ?? ""
      clanTag = b.clanTag ?? ""
      team = b.team ?? Team.none
      state = ::PLAYER_HAS_LEAVED_GAME
      isLocal = userId == authorUserId
      isInHeroSquad = ::SessionLobby.isEqualSquadId(b.squadId, authorSquadId)
      isBot = userId < 0
      squadId = b.squadId ?? INVALID_SQUAD_ID
      autoSquad = b.autoSquad ?? true
      kills = b.kills ?? b.airKills ?? 0
    }

    if (mplayer.name == "")
    {
      local parts = ::split(b.nick ?? "", " ")
      local hasClanTag = parts.len() == 2
      mplayer.clanTag = hasClanTag ? parts[0] : ""
      mplayer.name    = hasClanTag ? parts[1] : parts[0]
    }

    foreach(p in ::g_mplayer_param_type.types)
      if (!(p.id in mplayer))
        mplayer[p.id] <- b[p.id] ?? p.defVal

    res.append(mplayer)
  }

  res.sort(::mpstat_get_sort_func(gameType))
  return res
}

local saveReplayScriptCommentsBlk = function(blk)
{
  blk.uiScriptsData = ::DataBlock()
  blk.uiScriptsData.playersInfo = datablockConverter.dataToBlk(::SessionLobby.playersInfo)
}

local restoreReplayScriptCommentsBlk = function(replayPath)
{
  // Works for Local replays
  local commentsBlk = ::get_replay_info(replayPath)?.comments
  local playersInfo = datablockConverter.blkToData(commentsBlk?.uiScriptsData?.playersInfo) || {}

  // Works for Server replays
  if (!playersInfo.len())
  {
    local mplayersList = buildReplayMpTable(replayPath)
    foreach (mplayer in mplayersList)
    {
      if (mplayer.isBot)
        continue
      playersInfo[mplayer.userId] <- {
        id = mplayer.userId
        team = mplayer.team
        name = mplayer.name
        clanTag = mplayer.clanTag
        squad = mplayer.squadId
        auto_squad = !!mplayer.autoSquad
      }
    }
  }

  ::SessionLobby.playersInfo = playersInfo
}

// Creates global func, which is called from client.
::getroottable()["save_replay_script_comments_blk"] <- @(blk) saveReplayScriptCommentsBlk(blk)

return {
  buildReplayMpTable = buildReplayMpTable
  saveReplayScriptCommentsBlk = saveReplayScriptCommentsBlk
  restoreReplayScriptCommentsBlk = restoreReplayScriptCommentsBlk
}