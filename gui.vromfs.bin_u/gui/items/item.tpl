<<#items>>
itemDiv {
  smallFont:t='yes';
  class:t='smallFont'
  total-input-transparent:t='yes'
  css-hier-invalidate:t='yes'
  <<#active>>
    active:t='yes'
  <</active>>

  <<#enableBackground>>
    enableBackground:t='yes'
  <</enableBackground>>
  <<#today>>
    today:t='yes'
  <</today>>

  <<#bigPicture>>
    trophyRewardSize:t='yes'
  <</bigPicture>>

  <<#ticketBuyWindow>>
    ticketBuyWindow:t='yes'
  <</ticketBuyWindow>>

  <<#isItemLocked>>
    item_locked:t='yes'
  <</isItemLocked>>
  <<#openedPicture>>
    previousDay:t='yes'
  <</openedPicture>>

  <<#active>>
    wink { pattern { type:t='bright_texture'; position:t='absolute' } }
  <</active>>

  // Used in recent items handler.
  <<#onClick>>
  behavior:t='button'
  on_click:t='<<onClick>>'
  <<#itemIndex>>
  holderId:t='<<itemIndex>>'
  <</itemIndex>>

  pushedBorder {
    size:t='pw-4, ph-4'
    pos:t='50%pw-50%w, 50%ph-50%h'
    position:t='absolute'
    border:t='yes'
    border-color:t='#40404040'
    input-transparent:t='yes'
    display:t='hide'

    pushedBorder {
      size:t='pw-2, ph-2'
      pos:t='50%pw-50%w, 50%ph-50%h'
      position:t='absolute'
      border:t='yes'
      border-color:t='#55555555'
      input-transparent:t='yes'
    }
  }

  hoverBorder {
    size:t='pw-4, ph-4'
    pos:t='50%pw-50%w, 50%ph-50%h'
    position:t='absolute'
    border:t='yes'
    border-color:t='#20202020'
    input-transparent:t='yes'
    display:t='hide'

    hoverBorder {
      size:t='pw-2, ph-2'
      pos:t='50%pw-50%w, 50%ph-50%h'
      position:t='absolute'
      border:t='yes'
      border-color:t='#33333333'
      input-transparent:t='yes'
    }
  }
  <</onClick>>

  tdiv {
    size:t='pw, ph'
    text-halign:t='center'
    <<#itemIndex>>
    id:t='shop_item_<<itemIndex>>'
    <</itemIndex>>

    <<#itemHighlight>>
    itemHighlight {
      highlight:t='<<itemHighlight>>'
    }
    <</itemHighlight>>

    tdiv {
      size:t='pw, ph'
      overflow:t='hidden'
      <<@layered_image>>
      <<@getLayeredImage>>
    }

    <<#contentIconData>>
    contentCorner {
      contentType:t='<<contentType>>'
      foreground-image:t='<<contentIcon>>'
    }
    <</contentIconData>>

    <<#headerText>>
    activeText {
      width:t='pw'
      top:t='10%ph-50%h'
      position:t='absolute'
      pare-text:t='yes'
      text:t='<<headerText>>'
    }
    <</headerText>>

    <<#newIconWidget>>
    newIconWidget {
      id:t='item_new_icon_widget'
      position:t='absolute'
      pos:t='pw-w, 0'
      <<@newIconWidget>>
    }
    <</newIconWidget>>

    <<#expireTime>>
    textareaNoTab {
      id:t='expire_time'
      pos:t='pw-w-1@itemPadding, ph - h'
      position:t='absolute'
      text:t='<<expireTime>>'
      overlayTextColor:t='disabled'
    }
    <</expireTime>>

    <<#amount>>
    textareaNoTab {
      pos:t='pw-w - 1@itemPadding, 1@itemPadding'
      position:t='absolute'
      overlayTextColor:t='active'
      text:t='<<amount>>'
    }
    <</amount>>

    <<^isAllBought>>
    <<#price>>
    textareaNoTab {
      id:t='price'
      pos:t='pw-w -1@itemPadding, ph -0.5@dIco -1@dp +1@itemPadding -h/2'
      position:t='absolute'
      text:t='<<price>>'
    }
    <</price>>
    <</isAllBought>>

    <<#needAllBoughtIcon>>
    img{
      id:t='all_bougt_icon';
      size:t='@unlockIconSize, @unlockIconSize';
      pos:t='pw-w  -1@itemPadding +1*@sf/@pf_outdated, ph -0.5@dIco -1@dp +1@itemPadding -0.6h'
      position:t='absolute'
      background-image:t='#ui/gameuiskin#favorite';
      <<^isAllBought>>display:t='hide'<</isAllBought>>
    }
    <</needAllBoughtIcon>>
  }

  <<#arrowNext>>
  arrowNext{
    <<#tomorrow>>colored:t='yes'<</tomorrow>>
    arrowType:t='<<arrowType>>'
  }
  <</arrowNext>>

  tdiv {
    flow:t='vertical'
    position:t='absolute'
    <<@getWarbondShopLevelImage>>
    <<@getWarbondMedalImage>>
  }

  selBorder {
    size:t='pw-4, ph-4'
    pos:t='50%pw-50%w, 50%ph-50%h'
    position:t='absolute'
    border:t='yes'
    border-color:t='#40606060'
    input-transparent:t='yes'

    selBorder {
      size:t='pw-2, ph-2'
      pos:t='50%pw-50%w, 50%ph-50%h'
      position:t='absolute'
      border:t='yes'
      border-color:t='#55555555'
      input-transparent:t='yes'
    }
  }

  focus_border {}

  <<#hasButton>>
  <<#modActionName>>
  Button_text {
    id:t='actionBtn'
    pos:t='50%pw-50%w, ph-h/2' //empty zone in button texture
    position:t='absolute'
    visualStyle:t='common'
    class:t='smallButton'
    text:t='<<modActionName>>'
    <<#itemIndex>>
    holderId:t='<<itemIndex>>'
    <</itemIndex>>
    on_click:t='onItemAction'
    btnName:t='A'
    ButtonImg {}
  }
  <</modActionName>>
  <</hasButton>>




  <<#tooltipId>>
  tooltipObj {
    id:t='tooltip_<<tooltipId>>'
    on_tooltip_open:t='onGenericTooltipOpen'
    on_tooltip_close:t='onTooltipObjClose'
    display:t='hide'
  }
  title:t='$tooltipObj';
  <</tooltipId>>
}
<</items>>
