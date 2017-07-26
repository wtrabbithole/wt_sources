function view_fullscreen_image(obj)
{
  ::handlersManager.loadHandler(::gui_handlers.ShowImage, { showObj = obj })
}

class ::gui_handlers.ShowImage extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.MODAL
  sceneBlkName = "gui/showImage.blk"

  showObj = null
  baseSize = null
  maxSize = null
  basePos = null
  lastPos = null
  imgObj = null
  frameObj = null
  shadeObj = null

  resizeTime = 0.2
  timer = 0.0
  moveBack = false

  function initScreen()
  {
    if (!::checkObj(showObj))
      return goBack()

    local image = showObj["background-image"]
    maxSize = [showObj["max-width"].tointeger(), showObj["max-height"].tointeger()]

    if (!image || image=="" || !maxSize[0] || !maxSize[1])
      return goBack()

    scene.findObject("image_update").setUserData(this)

    baseSize = showObj.getSize()
    basePos = showObj.getPosRC()
    local rootSize = guiScene.getRoot().getSize()
    basePos = [basePos[0] + baseSize[0]/2, basePos[1] + baseSize[1]/2]
    lastPos = [rootSize[0]/2, rootSize[1]/2]

    local sizeKoef = 1.0
    if (maxSize[0] > 0.9*rootSize[0])
      sizeKoef = 0.9*rootSize[0] / maxSize[0]
    if (maxSize[1] > 0.9*rootSize[1])
    {
      local koef2 = 0.9*rootSize[1] / maxSize[1]
      if (koef2 < sizeKoef)
        sizeKoef = koef2
    }
    if (sizeKoef < 1.0)
    {
      maxSize[0] = (maxSize[0] * sizeKoef).tointeger()
      maxSize[1] = (maxSize[1] * sizeKoef).tointeger()
    }

    imgObj = scene.findObject("image")
    imgObj["max-width"] = maxSize[0].tostring()
    imgObj["max-height"] = maxSize[1].tostring()
    imgObj["background-image"] = image

    frameObj = scene.findObject("imgFrame")
    shadeObj = scene.findObject("root-box")
    onUpdate(null, 0.0)
  }

  function countProp(baseVal, max, t)
  {
    local div = max - baseVal
    div *= 1.0 - (t - 1)*(t - 1)
    return (baseVal+ div).tointeger().tostring()
  }

  function onUpdate(obj, dt)
  {
    if (frameObj && frameObj.isValid()
        && ((!moveBack && timer < resizeTime) || (moveBack && timer > 0)))
    {
      timer += moveBack? -dt : dt
      local t = timer / resizeTime
      if (t >= 1.0)
      {
        t = 1.0
        timer = resizeTime
        scene.findObject("btn_back").show(true)
      }
      if (moveBack && t <= 0.0)
      {
        t = 0.0
        timer = 0.0
        goBack() //performDelayed inside
      }

      imgObj.width = countProp(baseSize[0], maxSize[0], t)
      imgObj.height = countProp(baseSize[1], maxSize[1], t)
      frameObj.left = countProp(basePos[0], lastPos[0], t) + "-50%w"
      frameObj.top = countProp(basePos[1], lastPos[1], t) + "-50%h"
      shadeObj["transparent"] = (100 * t).tointeger().tostring()
    }
  }

  function onBack()
  {
    if (!moveBack)
    {
      moveBack = true
      scene.findObject("btn_back").show(false)
    }
  }
}

function gui_start_image_wnd(image = null, ratio = 1)
{
  if (::u.isEmpty(image))
    return

  ::handlersManager.loadHandler(::gui_handlers.ShowImageSimple, { image = image, ratio = ratio })
}

class ::gui_handlers.ShowImageSimple extends ::gui_handlers.BaseGuiHandlerWT
{
  wndType = handlerType.MODAL
  sceneBlkName = "gui/showImage.blk"

  image = null
  ratio = 1

  function initScreen()
  {
    local rootObj = scene.findObject("root-box")
    if (!::checkObj(rootObj))
      return goBack()

    rootObj["transparent"] = "100"

    local frameObj = rootObj.findObject("imgFrame")
    frameObj.pos = "50%pw-50%w, 45%ph-50%h"

    local imgObj = frameObj.findObject("image")
    if (!::checkObj(imgObj))
      return goBack()

    imgObj["background-image"] = image

    local height = ::screen_height()/1.5
    imgObj.height = height.tointeger()
    imgObj.width = (ratio*height).tointeger()

    scene.findObject("btn_back").show(true)
  }

  function onBack()
  {
    goBack()
  }
}
