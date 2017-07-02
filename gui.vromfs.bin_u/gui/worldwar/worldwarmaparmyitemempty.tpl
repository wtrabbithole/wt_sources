<<#army>>
  armyBlock {
    id:t=''
    behavior:t='button'
    display:t='hide'
    surrounded:t='no'
    battleDescription:t='yes'
    armyName:t=''
    clanId:t=''
    on_click:t='onClickArmy'
    on_hover:t='onHoverArmyItem'
    on_unhover:t='onHoverLostArmyItem'

    armyIcon {
      id:t='armyIcon'
      team:t=''
      isBelongsToMyClan:t='no'
      entrenchIcon {
        id:t='entrenchIcon'
        size:t='1@mIco, 1@mIco'
        pos:t='50%pw-50%w, 50%ph-50%h'
        position:t='absolute'
        background-image:t='#ui/gameuiskin#army_defense'
        background-color:t='@armyEntrencheColor'
      }
      background {
        background-image:t='#ui/gameuiskin#ww_army'
        foreground-image:t='#ui/gameuiskin#ww_select_army'
        pos:t='50%pw-50%w, 50%ph-50%h'
        position:t='absolute'
      }
      armyUnitType {
        id:t='armyUnitType'
        text:t=''
        pos:t='50%pw-50%w, 50%ph-50%h'
        position:t='absolute'
      }
    }
  }
<</army>>
