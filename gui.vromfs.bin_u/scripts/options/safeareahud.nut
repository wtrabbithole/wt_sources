local screenInfo = ::require("scripts/options/screenInfo.nut")

local defValue  = 1.0
local values    = [1.0, 0.95, 0.9, 0.85]
local items     = ["100%", "95%", "90%", "85%"]

local getFixedValue = function() //return -1 when not fixed
{
  if (::is_platform_ps4)
    return ::ps4_get_safe_area()
  if (::is_platform_xboxone)
    return ::xbox_get_safe_area()
  return -1
}

local getValue = function()
{
  local value = getFixedValue()
  if (value != -1)
    return value

  if (!::g_login.isAuthorized())
    return defValue

  return ::get_option_hud_screen_safe_area()
}

local setValue = function(value)
{
  if (!::g_login.isAuthorized())
    return

  value = ::isInArray(value, values) ? value : defValue
  ::set_option_hud_screen_safe_area(value)
  ::set_gui_option_in_mode(::USEROPT_HUD_SCREEN_SAFE_AREA, value, ::OPTIONS_MODE_GAMEPLAY)
}

local getSafearea = @() screenInfo.getFinalSafearea(getValue(), screenInfo.getHudWidthLimit())

::cross_call_api.getHudSafearea <- getSafearea

return {
  getValue = getValue
  setValue = setValue
  canChangeValue = @() getFixedValue() == -1
  getValueOptionIndex = @() values.find(getValue())
  getSafearea = getSafearea

  values = values
  items = items
  defValue = defValue
}