div {
  size:t='sw, sh'
  position:t='root'
  pos:t='0, 0'
  behavior:t='button'
  on_click:t='goBack'
  on_r_click:t='goBack'
  input-transparent:t='yes'
  accessKey:t='Esc | J:B'
}

popup_menu {
  id:t='frame_obj'
  width:t='1@sliderWidth + 2@buttonHeight + 4@blockInterval'
  min-width:t='<<columns>>*(@itemWidth + @itemSpacing) + 1@itemSpacing + 2@framePadding'
  position:t='root'
  pos:t='<<position>>'
  menu_align:t='<<align>>'
  total-input-transparent:t='yes'
  flow:t='vertical'

  Button_close { _on_click:t='goBack'; smallIcon:t='yes'}

  textAreaCentered {
    id:t='header_text'
    width:t='pw'
    overlayTextColor:t='active'
    text:t='<<header>>'
  }

  div {
    id:t='items_list'
    width:t='<<columns>>*(@itemWidth + @itemSpacing) + 1@itemSpacing'
    pos:t='50%pw-50%w, 0'
    position:t='relative'
    itemShopList:t='yes'
    mouse-focusable:t='yes'
    clearOnFocusLost:t='no'

    flow:t='h-flow'
    behavior:t='posNavigator'
    navigatorShortcuts:t='yes'
    moveX:t='linear'
    moveY:t='closest'
    value:t='0'

    on_select:t = 'onItemSelect'
    on_wrap_down:t='onWrapDown'

    <<@items>>
  }

  tdiv {
    id:t='slider_block'
    pos:t='50%pw-50%w, 0'
    position:t='relative'
    padding-top:t='0.02@sf' //text aboce slider button

    Button_text {
      id:t='buttonDec'
      square:t='yes'
      text:t='-'
      tooltip:t='#items/wager/stake/decStake'
      on_click:t='onAmountDec'
    }

    slider {
      id:t='amount_slider'
      pos:t='0, 50%ph-50%h'
      position:t='relative'
      margin:t='0.5@sliderThumbWidth + 1@blockInterval, 0'
      mouse-focusable:t='yes'
      value:t='1'
      min:t='1'
      max:t='1'
      canWrap:t='yes'
      on_change_value:t='onAmountChange'
      on_wrap_up:t='onWrapUp'

      sliderButton {
        css-hier-invalidate:t='yes'

        textAreaCentered {
          id:t='amount_text'
          pos:t='50%pw-50%w, -h'
          position:t='absolute'
          overlayTextColor:t='active'
          text:t=''
        }
      }
    }

    Button_text {
      id:t='buttonInc'
      square:t='yes'
      text:t='+'
      tooltip:t='#items/wager/stake/incStake'
      on_click:t='onAmountInc'
    }
  }

  Button_text {
    pos:t='50%pw-50%w, @blockInterval'
    position:t='relative'
    text:t='#msgbox/btn_activate'
    on_click:t='onActivate'
    btnName:t='A'
    ButtonImg{}
  }

  <<#hasPopupMenuArrow>>
  popup_menu_arrow{}
  <</hasPopupMenuArrow>>
}
