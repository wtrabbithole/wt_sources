class ::gui_handlers.clanChangeMembershipReqWnd extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.MODAL;
  sceneBlkName = "gui/clans/clanChangeMembershipReqWnd.blk";
  wndOptionsMode = ::OPTIONS_MODE_GAMEPLAY

  owner = null;
  clanData = null;

  optionItems = [
    [::USEROPT_CLAN_REQUIREMENTS_MIN_AIR_RANK,  "spinner"],
    [::USEROPT_CLAN_REQUIREMENTS_MIN_TANK_RANK, "spinner"],
    [::USEROPT_CLAN_REQUIREMENTS_ALL_MIN_RANKS, "switchbox"],
    [::USEROPT_CLAN_REQUIREMENTS_MIN_ARCADE_BATTLES, "spinner"],
    [::USEROPT_CLAN_REQUIREMENTS_MIN_REAL_BATTLES,"spinner"],
    [::USEROPT_CLAN_REQUIREMENTS_MIN_SYM_BATTLES, "spinner"],
    [::USEROPT_CLAN_REQUIREMENTS_AUTO_ACCEPT_MEMBERSHIP,"switchbox"]
  ]

  minRankCondTypeObject = null
  autoAcceptMembershipObject = null

  // MembershipRequirementsBlk looks like this
  // {
  //   type:t="and";  // root must be type="and"
  //   ranks{
  //     type:t="and"//"or"
  //     rank_Aircraft{ type:t="rank"; rank:i=4; count:i=1; unitType:t="Aircraft"; }
  //     rank_Tank{ type:t="rank"; rank:i=4; count:i=1; unitType:t="Tank"; }
  //   }
  //   battles_arcade{ type:t="battles"; difficulty:t="arcade"; count:i=10; }
  //   battles_historical{ type:t="battles"; difficulty:t="historical"; count:i=10; }
  //   battles_simulation{ type:t="battles"; difficulty:t="simulation"; count:i=10; }
  // }

  function initScreen()
  {
    if ( !clanData )
      return;

    local container = ::create_options_container("optionslist", optionItems, true, true, true, true, false)
    guiScene.replaceContentFromText("contentBody", container.tbl, container.tbl.len(), this)

    local option = ::get_option(::USEROPT_CLAN_REQUIREMENTS_ALL_MIN_RANKS)
    minRankCondTypeObject = scene.findObject(option.id)

    option = ::get_option(::USEROPT_CLAN_REQUIREMENTS_AUTO_ACCEPT_MEMBERSHIP)
    autoAcceptMembershipObject = scene.findObject(option.id)
    autoAcceptMembershipObject.setValue(clanData.autoAcceptMembership)

    loadRequirementsBattles( clanData.membershipRequirements )
    loadRequirementsRanks( clanData.membershipRequirements )

    recalcMinRankCondTypeSwitchState()
  }

  function loadRequirementsBattles( rawClanMemberRequirementsBlk )
  {
    foreach(diff in ::g_difficulty.types)
      if (diff.egdCode != ::EGD_NONE)
      {
        local option = ::get_option(diff.clanReqOption)
        local modeName = diff.getEgdName(false)
        local battlesRequired = 0;
        local req = rawClanMemberRequirementsBlk.getBlockByName(option.id)
        if ( req  &&  (req.type == "battles")  &&  (req.difficulty == modeName) )
          battlesRequired = req.getInt("count", 0)

        local optIdx = option.values.find(battlesRequired)
        scene.findObject(option.id).setValue(optIdx >= 0 ? optIdx : 0)
      }
  }


  function loadRequirementsRanks( rawClanMemberRequirementsBlk )
  {
    local rawRanksCond = rawClanMemberRequirementsBlk.getBlockByName("ranks")
    if ( !rawRanksCond )
      rawRanksCond = ::DataBlock();

    foreach( ut in ::unitTypesList )
    {
      local unitType = getUnitTypeText(ut)
      local ranksRequired = 0;
      local req = rawRanksCond.getBlockByName("rank_" + unitType);
      if ( req &&  (req.type == "rank")  &&  (req.unitType == unitType) )
        ranksRequired = req.getInt("rank",0)

      scene.findObject("rankReq" + unitType).setValue(ranksRequired);
    }

    minRankCondTypeObject.setValue(rawRanksCond.type != "or")
  }

  function getNonEmptyRankReqCount()
  {
    local nonEmptyRankReqCount = 0
    foreach( ut in ::unitTypesList )
    {
      local unitType = getUnitTypeText(ut)
      local ranksRequired = scene.findObject("rankReq" + unitType).getValue()
      if (ranksRequired > 0)
        nonEmptyRankReqCount++
    }

    return nonEmptyRankReqCount
  }

  function getNonEmptyBattlesReqCount()
  {
    local nonEmptyBattlesReqCount = 0
    foreach(diff in ::g_difficulty.types)
      if (diff.egdCode != ::EGD_NONE)
      {
        local option = ::get_option(diff.clanReqOption)
        local optIdx = scene.findObject(option.id).getValue()
        if (optIdx > 0)
          nonEmptyBattlesReqCount++
      }

    return nonEmptyBattlesReqCount
  }

  function onRankReqChange()
  {
    recalcMinRankCondTypeSwitchState()
  }

  function recalcMinRankCondTypeSwitchState()
  {
    if (getNonEmptyRankReqCount() > 1)
    {
      minRankCondTypeObject.enable(true)
    }
    else
    {
      minRankCondTypeObject.setValue(1) // "and"
      minRankCondTypeObject.enable(false)
    }
  }

  function onApply()
  {
    local newRequirements = ::DataBlock()
    local gotChanges = fillRequirements(newRequirements)

    if (gotChanges)
      sendRequirementsToChar(newRequirements, autoAcceptMembershipObject.getValue())
    else
      goBack()
  }

  function fillRequirements( newRequirements )
  {
    appendRequirementsRanks( newRequirements )
    appendRequirementsBattles( newRequirements )

    if ( newRequirements.blockCount() != 0 )
      newRequirements.setStr("type", "and")

    if ( ::u.isEqual(clanData.membershipRequirements, newRequirements) )
    {
      local autoAccept = autoAcceptMembershipObject.getValue()
      if ( clanData.autoAcceptMembership == autoAccept )
        return false;
    }

    local validateResult = clan_validate_membership_requirements(newRequirements);
    if ( validateResult == "" )
      return true;

    local errText = ::format("ERROR: [ClanMembershipReq] validation error '%s':\n%s", validateResult )
    callstack()
    ::script_net_assert_once("bad clan requirements", errText)
    return false
  }


  function appendRequirementsRanks( newRequirements )
  {
    local rankCondType = minRankCondTypeObject.getValue() ? "and" : "or"
    local ranksSubBlk = null;

    foreach( ut in ::unitTypesList )
    {
      local unitType = getUnitTypeText(ut)
      local rankVal = scene.findObject("rankReq" + unitType).getValue()

      if ( rankVal > 0 )
      {
        if ( !ranksSubBlk )
        {
          ranksSubBlk = newRequirements.addNewBlock("ranks")
          ranksSubBlk.setStr( "type", rankCondType )
        }

        local condBlk = ranksSubBlk.addNewBlock("rank_" + unitType)
        condBlk.setStr( "type", "rank" )
        condBlk.setInt( "rank", rankVal )
        condBlk.setInt( "count", 1 )
        condBlk.setStr( "unitType", unitType )
      }
    }
  }


  function appendRequirementsBattles( newRequirements )
  {
    foreach(diff in ::g_difficulty.types)
      if (diff.egdCode != ::EGD_NONE)
      {
        local option = ::get_option(diff.clanReqOption)
        local modeName = diff.getEgdName(false);
        local battleReqVal = option.values[scene.findObject(option.id).getValue()];

        if ( battleReqVal > 0 )
        {
          local condBlk = newRequirements.addNewBlock(option.id)
          condBlk.setStr( "type", "battles" )
          condBlk.setStr( "difficulty", modeName )
          condBlk.setInt( "count", battleReqVal )
        }
      }
  }


  function sendRequirementsToChar( newRequirements, autoAccept )
  {
    local resultCB = ::Callback((@(newRequirements, autoAccept) function() {
      clanData.membershipRequirements = newRequirements;
      clanData.autoAcceptMembership = autoAccept;

      if(clan_get_admin_editor_mode() && owner && "reinitClanWindow" in owner)
        owner.reinitClanWindow()

      ::broadcastEvent("ClanRquirementsChanged")
      goBack()
    })(newRequirements, autoAccept), this )

    local taskId = clan_request_set_membership_requirements(clanData.id, newRequirements, autoAccept)

    ::g_tasker.addTask(taskId, {showProgressBox = true}, resultCB)
  }

}