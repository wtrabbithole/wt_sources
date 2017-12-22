class SquadMember
{
  uid = ""
  name = ""
  rank = -1
  country = ""
  clanTag = ""
  pilotIcon = "cardicon_default"
  online = false
  selAirs = null
  selSlots = null
  crewAirs = null
  brokenAirs = null
  missedPkg = null
  wwOperations = null
  isReady = false
  isCrewsReady = false
  cyberCafeId = ""
  unallowedEventsENames = null
  sessionRoomId = ""

  isWaiting = true
  isInvite = false
  isApplication = false
  isNewApplication = false
  isInvitedToSquadChat = false

  updatedProperties = ["name", "rank", "country", "clanTag", "pilotIcon", "selAirs",
                       "selSlots", "crewAirs", "brokenAirs", "missedPkg", "wwOperations",
                       "isReady", "isCrewsReady", "cyberCafeId", "unallowedEventsENames",
                       "sessionRoomId"]

  constructor(uid, isInvite = false, isApplication = false)
  {
    this.uid = uid.tostring()
    this.isInvite = isInvite
    this.isApplication = isApplication
    this.isNewApplication = isApplication

    initUniqueInstanceValues()

    local contact = ::getContact(uid)
    if (contact)
      update(contact)
  }

  function initUniqueInstanceValues()
  {
    selAirs = {}
    selSlots = {}
    crewAirs = {}
    brokenAirs = []
    missedPkg = []
    wwOperations = {}
    unallowedEventsENames = []
  }

  function update(data)
  {
    local newValue = null
    local isChanged = false
    foreach(idx, property in updatedProperties)
    {
      newValue = ::getTblValue(property, data, null)
      if (newValue == null)
        continue

      if (newValue != this[property])
      {
        this[property] = newValue
        isChanged = true
      }
    }
    isWaiting = false
    return isChanged
  }

  function isActualData()
  {
    return !isWaiting && !isInvite
  }

  function canJoinSessionRoom()
  {
    return isReady && sessionRoomId == ""
  }

  function getData()
  {
    local result = {uid = uid}
    foreach(idx, property in updatedProperties)
      if (!::u.isEmpty(this[property]))
        result[property] <- this[property]

    return result
  }

  function getWwOperationCountryById(wwOperationId)
  {
    foreach (operationData in wwOperations)
      if (operationData?.id == wwOperationId)
        return operationData?.country

    return null
  }

  function isEventAllowed(eventEconomicName)
  {
    return !::isInArray(eventEconomicName, unallowedEventsENames)
  }

  function isMe()
  {
    return uid == ::my_user_id_str
  }
}