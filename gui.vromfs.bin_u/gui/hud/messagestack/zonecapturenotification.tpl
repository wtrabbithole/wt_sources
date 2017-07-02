message {
  height-base:t='0'
  height-end:t='100'
  event_team:t='<<team>>'
  hero_action:t='<<heroAction>>'

  textareaNoTab {
    id:t='text'
    text:t='<<text>>'
    position:t='relative'
    pos:t='0, ph/2 - h/2'
  }

  <<#zoneCaptureing>>
  tdiv {
    margin-left:t='0.01@shHud'
    textareaNoTab {
      zoneName:t='yes'
      text:t='<<zoneNameText>>'
      position:t='absolute'
      pos:t='pw/2 - w/2, ph/2 - h/2'
    }
    size:t='0.07@shHud, 0.07@shHud'

    tdiv {
      position:t='absolute'
      size:t='pw, ph'
      background-image:t='#ui/gameuiskin#circular_progress_1'
      background-color:t='#77555555'
    }
    tdiv {
      id:t='capture_progress'
      re-type:t='sector'
      sector-angle-1:t='0'
      sector-angle-2:t='<<captureProgress>>'

      position:t='absolute'
      size:t='pw, ph'
      background-image:t='#ui/gameuiskin#circular_progress_1'
      zone_owner:t='<<zoneOwner>>'
    }
  }
  <</zoneCaptureing>>
}