class ::Input.DoubleAxis extends ::Input.InputBase
{
  //bit mask array of axis ids from ::JoystickParams().getAxis()
  axisIds = null

  deviceId = null

  function getMarkup()
  {
    local data = getMarkupData()
    return ::handyman.renderCached(data.template, data.view)
  }

  function getMarkupData()
  {
    local data = {
      template = "gui/shortcutAxis"
      view = {}
    }

    local image = getImage()
    if (image)
      data.view.buttonImage <- image

    return data
  }

  function getText()
  {
    return ""
  }

  function getDeviceId()
  {
    return deviceId
  }

  function getImage()
  {
    if (deviceId == ::JOYSTICK_DEVICE_0_ID)
      return ::gamepad_axes_images?[axisIds] ?? ""
    else if (deviceId == ::STD_MOUSE_DEVICE_ID)
      return ::mouse_axes_to_image?[axisIds] ?? ""

    return null
  }

  function hasImage()
  {
     return getImage() ?? "" !=""
  }

  function getConfig()
  {
    return {
      inputName = "doubleAxis"
      buttonImage = getImage()
    }
  }
}
