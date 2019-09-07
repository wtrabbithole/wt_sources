<<#countries>>
shopFilter {
  id:t='header_country<<countryIdx>>'
  height:t='ph'
  class:t='slotsHeader'
  tooltip:t='<<tooltipText>>'
  <<^isEnabled>>
  enable:t='no'
  <</isEnabled>>

  img {
    id:t='hdr_image'
    size:t='@cIco, @cIco'
    top:t='0.5(ph-h)'
    position:t='relative'
    background-image:t='<<countryIcon>>'
    background-svg-size:t='@cIco, @cIco'
  }

  <<#bonusData>>
  bonusNoFrame {
    background-image:t='<<background-image>>'
    bonusType:t='<<bonusType>>'
    tooltip:t='<<tooltip>>'
  }
  <</bonusData>>

  slotsCountryText {
    class:t='full'
    text:t='#<<country>>'
  }
  slotsCountryText {
    display:t='hide'
    class:t='short'
    text:t='#<<country>>/short'
  }
}
<</countries>>
