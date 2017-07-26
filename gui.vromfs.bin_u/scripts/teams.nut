enum Team //better to replace it everywhere by g_teams
{
  Any   = 0,
  A     = 1,
  B     = 2,
  none  = 3
}

::g_team <- {
  types = []
  teams = null
  cache = {
    byCode = {}
    byCountriesOption = {}
  }
}

::g_team.template <- {
  id = "" //filled automatically by type id
  code = -1
  opponentTeamCode = -1
  name = ""
  shortNameLocId = ""
  cssLabel = ""
  teamCountriesOption = -1 //USEROPT_*

  getNameInPVE = function() {
    return ::loc("multiplayer/" + name)
  }
  getShortName = function() { return ::loc(shortNameLocId) }
}

::g_enum_utils.addTypesByGlobalName("g_team", {
  ANY = {
    code = Team.Any
    opponentTeamCode = Team.none
    name = "unknown"
  }
  A = {
    code = Team.A
    opponentTeamCode = Team.B
    name = "teamA"
    cssLabel = "a"
    shortNameLocId = "teamA"
    teamCountriesOption = ::USEROPT_BIT_COUNTRIES_TEAM_A
  }
  B = {
    code = Team.B
    opponentTeamCode = Team.A
    name = "teamB"
    cssLabel = "b"
    shortNameLocId = "teamB"
    teamCountriesOption = ::USEROPT_BIT_COUNTRIES_TEAM_B
  }
  NONE = {
    code = Team.none
    opponentTeamCode = Team.Any
    name = "unknown"
  }
}, null, "id")

::g_team.teams = [::g_team.A, ::g_team.B]
function g_team::getTeams()
{
  return teams
}

function g_team::getTeamByCode(code)
{
  return ::g_enum_utils.getCachedType("code", code, cache.byCode, this, NONE)
}

function g_team::getTeamByCountriesOption(optionId)
{
  return ::g_enum_utils.getCachedType("teamCountriesOption", optionId, cache.byCountriesOption, this, NONE)
}