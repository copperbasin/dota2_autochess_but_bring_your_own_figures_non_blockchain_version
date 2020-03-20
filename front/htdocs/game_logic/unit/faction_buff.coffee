filter_by_type = (unit_list, type)->
  return unit_list.filter (unit)->
    # HACK way
    return true if unit.class == name
    return true if unit.spec  == name
    false

wrap_me = (name, cb)->
  (state)->
    {cache_side_unit_list} = state
    for unit_list, side in cache_side_unit_list
      filter_unit_list = filter_by_type unit_list, name
      cb state, filter_unit_list, side
    return

window.faction_buff =
  warrior       : wrap_me (state, unit_list, side)->
    
  druid         : wrap_me (state, unit_list, side)->
    # случайный самый низкозвездный юнит из друидов получает +1 звезду
    # звезд у нас сейчас нету
    # TODO
  mage          : wrap_me (state, unit_list, side)->
  hunter        : wrap_me (state, unit_list, side)->
  assasin       : wrap_me (state, unit_list, side)->
  mech          : wrap_me (state, unit_list, side)->
  shaman        : wrap_me (state, unit_list, side)->
  knight        : wrap_me (state, unit_list, side)->
  demon_hunter  : wrap_me (state, unit_list, side)->
  warlock       : wrap_me (state, unit_list, side)->
  
  orc           : wrap_me (state, unit_list, side)->
  beast         : wrap_me (state, unit_list, side)->
    # mult ad100
    mult = 1
    mult = 1.1  if unit_list.length >= 2
    mult = 1.15 if unit_list.length >= 4
    mult = 1.2  if unit_list.length >= 6
    for unit in state.cache_side_unit_list[side]
      unit.ad100 = Math.floor unit.ad100*mult
    return
  
  ogre          : wrap_me (state, unit_list, side)->
  undead        : wrap_me (state, unit_list, side)->
  goblin        : wrap_me (state, unit_list, side)->
  troll         : wrap_me (state, unit_list, side)->
  elf           : wrap_me (state, unit_list, side)->
  human         : wrap_me (state, unit_list, side)->
  demon         : wrap_me (state, unit_list, side)->
    # enemy demon_hunter should account as yours
    enemy_demon_hunter = filter_by_type state.cache_side_unit_list[+!side], "demon_hunter"
    return if enemy_demon_hunter.length
    
    # ad100 *1.5 only if 1
    if unit_list.length == 1
      [unit] = unit_list
      unit.ad100 = Math.floor unit.ad100*1.5
    return
  elemental     : wrap_me (state, unit_list, side)->
  naga          : wrap_me (state, unit_list, side)->
  dwarf         : wrap_me (state, unit_list, side)->
  dragon        : wrap_me (state, unit_list, side)->
