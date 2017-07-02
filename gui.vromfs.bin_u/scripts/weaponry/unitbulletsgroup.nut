class BulletGroup
{
  unit = null
  groupIndex = -1
  selectedName = ""   //selected bullet name
  bullets = null  //bullets list for this group
  bulletsCount = -1
  maxBulletsCount = -1
  gunInfo = null
  guns = 1
  active = false
  canChangeActivity = false

  option = null //bullet option. initialize only on request because generate descriptions
  selectedBullet = null //selected bullet from modifications list

  constructor(_unit, _groupIndex, _gunInfo, _active = false, _canChangeActivity = false)
  {
    unit = _unit
    groupIndex = _groupIndex
    gunInfo = _gunInfo
    guns = ::getTblValue("guns", gunInfo) || 1
    active = _active
    canChangeActivity = _canChangeActivity

    bullets = ::get_options_bullets_list(unit, groupIndex)
    selectedName = ::getTblValue(bullets.value, bullets.values, "")

    if (::get_last_bullets(unit.name, groupIndex) != selectedName)
      ::set_unit_last_bullets(unit, groupIndex, selectedName)

    local count = ::get_unit_option(unit.name, ::USEROPT_BULLET_COUNT0 + groupIndex)
    if (count != null)
      bulletsCount = (count / guns).tointeger()
    updateCounts()
  }

  function canChangeBulletsCount()
  {
    return gunInfo != null
  }

  function getGunIdx()
  {
    return getTblValue("gunIdx", gunInfo, 0)
  }

  function setBullet(bulletName)
  {
    if (selectedName == bulletName)
      return false

    local bulletIdx = bullets.values.find(bulletName)
    if (bulletIdx < 0)
      return false

    selectedName = bulletName
    selectedBullet = null
    ::set_unit_last_bullets(unit, groupIndex, selectedName)
    if (option)
      option.value = bulletIdx

    updateCounts()

    return true
  }

  //return is new bullet not from list
  function setBulletNotFromList(bList)
  {
    if (!::isInArray(selectedName, bList))
      return true

    foreach(idx, value in bullets.values)
    {
      if (!bullets.items[idx].enabled)
        continue
      if (::isInArray(value, bList))
        continue
      if (setBullet(value))
        return true
    }
    return false
  }

  function getBulletNameByIdx(idx)
  {
    return ::getTblValue(idx, bullets.values)
  }

  function setBulletsCount(count)
  {
    if (bulletsCount == count)
      return

    bulletsCount = count
    ::set_unit_option(unit.name, ::USEROPT_BULLET_COUNT0 + groupIndex, (count * guns).tointeger())
  }

  //return bullets changed
  function updateCounts()
  {
    if (!gunInfo)
      return false

    maxBulletsCount = gunInfo.total
    if (!isAmmoFree(unit.name, selectedName, AMMO.PRIMARY))
    {
      local boughtCount = (::getAmmoAmount(unit.name, selectedName, AMMO.PRIMARY) / guns).tointeger()
      maxBulletsCount = ::min(boughtCount, gunInfo.total)

      local bulletsSet = ::getBulletsSetData(unit, selectedName)
      local maxToRespawn = ::getTblValue("maxToRespawn", bulletsSet, 0)
      if (maxToRespawn > 0)
        maxBulletsCount = ::min(maxBulletsCount, maxToRespawn)
    }

    if (bulletsCount < 0 || bulletsCount <= maxBulletsCount)
      return false

    setBulletsCount(maxBulletsCount)
    return true
  }

  function getGunMaxBullets()
  {
    return ::getTblValue("total", gunInfo, 0)
  }

  function getOption()
  {
    if (!option)
    {
      ::aircraft_for_weapons = unit.name
      option = ::get_option(::USEROPT_BULLETS0 + groupIndex)
    }
    return option
  }

  function tostring()
  {
    return ::format("BulletGroup( unit = %s, idx = %d, active = %s, selected = %s )",
                    unit.name, groupIndex, active.tostring(), selectedName)
  }

  function getHeader()
  {
    if (!bullets || !unit)
      return ""
    return ::get_bullets_list_header(unit, bullets)
  }

  function getModByBulletName(bulName)
  {
    local mod = ::getModificationByName(unit, bulName)
    if (!mod) //default
      mod = { name = bulName, isDefaultForGroup = groupIndex, type = weaponsItem.modification }
    return mod
  }

  _bulletsModsList = null
  function getBulletsModsList()
  {
    if (!_bulletsModsList)
    {
      _bulletsModsList = []
      foreach(bulName in bullets.values)
        _bulletsModsList.append(getModByBulletName(bulName))
    }
    return _bulletsModsList
  }

  function getSelBullet()
  {
    if (!selectedBullet)
      selectedBullet = getModByBulletName(selectedName)
    return selectedBullet
  }
}