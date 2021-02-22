<<#itemBlock>>
  itemBlock {
  <<#hasComponent>>hasComponent:t='yes'<</hasComponent>>
  <<#isTooltipByHold>>
    <<#items>>
    tooltipId:t='<<tooltipId>>'
    <</items>>
  <</isTooltipByHold>>
  <<#isDisabled>>isDisabled:t='yes'<</isDisabled>>
    <<#itemId>>itemId:t='<<itemId>>'<</itemId>>
    <<#blockPos>>
      pos:t='<<blockPos>>'
      position:t='absolute'
    <</blockPos>>
    <<#isFullSize>>isFullSize:t='yes'<</isFullSize>>
    include "gui/items/item"
    tdiv {
      margin-left:t='1@blockInterval'
      <<#component>><<@component>><</component>>
    }
  }
<</itemBlock>>