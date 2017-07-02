root {
  background-color:t='@shadeBackgroundColor'

  frame {
    id:t='window_root'
    pos:t='50%pw-50%w, 50%ph-50%h'
    position:t='absolute'
    width:t='80%sh'

    <<#hasActiveTicket>>
    height:t='70%sh'
    <</hasActiveTicket>>
    <<^hasActiveTicket>>
    height:t='60%sh'
    <</hasActiveTicket>>
    max-width:t='800*@sf/@pf + 2@framePadding'
    max-height:t='sh'
    class:t='wndNav'

    frame_header {
      activeText {
        caption:t='yes'
        text:t='<<headerText>>'
      }
      Button_close {
        img {}
      }
    }

    textareaNoTab {
      text:t='<<activeTicketText>>'
      width:t='pw - 30@sf/@pf'
      margin-top:t='50@sf/@pf'
      margin-left:t='30@sf/@pf'
      position:t='absolute'
    }

    textAreaCentered {
      text:t='<<windowMainText>>'
      width:t='pw'
      <<#hasActiveTicket>>
      margin-top:t='120@sf/@pf'
      <</hasActiveTicket>>
      <<^hasActiveTicket>>
      margin-top:t='70@sf/@pf'
      <</hasActiveTicket>>
      position:t='absolute'
    }

    frameBlock {
      id:t='items_list'
      flow:t='h-flow'
      behavior:t='posNavigator'
      navigatorShortcuts:t='yes'
      moveX:t='closest'
      moveY:t='linear'
      clearOnFocusLost:t='no'
      on_select:t = 'onTicketSelected'
      _on_dbl_click:t = 'onTicketDoubleClicked'
      on_wrap_up:t='onWrapUp'
      on_wrap_down:t='onWrapDown'
      position:t='relative'
      pos:t='0.5pw-0.5w, 0.5ph-0.5h'
      itemShopList:t='yes'
      ticketsWindow:t='yes'

      <<@tickets>>
    }

    tdiv {
      <<#ticketCaptions>>
      textareaNoTab {
        id:t='<<captionId>>'
        margin-top:t='10@sf/@pf'
        text:t='<<captionText>>'
        position:t='absolute'
        max-width:t='2@itemSpacing + 1.4@itemWidth'
        text-align:t='center'
      }
      <</ticketCaptions>>
    }

    navBar {
      navMiddle {
        Button_text {
          id:t = 'btn_apply'
          class:t='battle'
          navButtonFont:t='yes'
          text:t = '#mainmenu/btnApply'
          _on_click:t = 'onBuyClicked'
          css-hier-invalidate:t='yes'
          btnName:t='A'
          buy_ticket_button:t='yes'

          buttonWink { _transp-timer:t='0' }
          ButtonImg{}
          textarea {
            id:t='btn_apply_text'
            input-transparent:t='yes'
            removeParagraphIndent:t='yes'
          }
          buttonGlance {}
        }
      }
    }
  }
}