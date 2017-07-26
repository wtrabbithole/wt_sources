::g_event_display_type <- {
  types = []
  cache = {
    byName = {}
  }
  template = {
    name = ""
    showInEventsWindow = false
    showInGamercardDrawer = false
  }
}

::g_enum_utils.addTypesByGlobalName("g_event_display_type", {
  //hidden event
  NONE = {
    name = "none"
  }

  /** (default) Event is visible only in events window. */
  REGULAR = {
    name = "regular"
    showInEventsWindow = true
  }

  /**
   * Event is hidden from events window but visible in gamercard drawer.
   * Can be selected with check box.
   */
  RANDOM_BATTLE = {
    name = "random_battle"
    showInGamercardDrawer = true
  }

  /**
   * Event is visible both in events window and in gamercard drawer.
   * Clicking on event's icon in drawer opens it event window.
   */
  FEATURED = {
    name = "featured"
    showInEventsWindow = true
    showInGamercardDrawer = true
  }

  /**
   * PVE battle
   */
  PVE_BATTLE = {
    name = "pve_battle"
    showInGamercardDrawer = true
  }
})

function g_event_display_type::getTypeByName(name)
{
  return ::g_enum_utils.getCachedType("name", name, ::g_event_display_type.cache.byName,
    ::g_event_display_type, ::g_event_display_type.REGULAR)
}
