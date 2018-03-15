/* Collection of all 'standard' ui widgets
  you can use it:
    this.__update(require("daRg/components/std.nut"))
    textArea("text")
  or
    local ui = require("daRg/components/std.nut")
    ui.textArea("my text")
*/

/*TODO:
  ? combine all *.style.nut to one table and/or move to ../style (it's easier probably to change all colors in one file?)
  ? rework styling for something easier to use
  ? consider add default fonts to darg itself (fontawesome and some std utf font. However - we definitely need better font render\layout system first, cause in other case size of font is something not defined)
  
  add widgets for:
    stext
    dtext
    text
    image
    ninerect
    select
    !property grid
    ? 'container'/ 'panel' (more sense if we would have render-to-texture panels, but whatever)

  documentation and samples


*/

local textArea = require("textArea.nut")
local text = require("text.nut").text
local stext = require("text.nut").stext
local dtext = require("text.nut").dtex
local contextMenu = require("contextMenu.nut")
local textInput = require("textInput.nut")
local scrollbar = require("scrollbar.nut")
local combobox = require("combobox.nut")
local msgbox = require("msgbox.nut")
local textButton = require("textButton.nut")
local tabs = require("tabs.nut")

return {
  textArea = textArea
  contextMenu = contextMenu
  textInput = textInput
  scrollbar = scrollbar
  combobox = combobox
  msgbox = msgbox
  textButton = textButton
  tabs = tabs
}