window.prepare_battle = (player_a_state, player_b_state)->
  res = new emulator.State
  for _id,unit of player_a_state.board_unit_hash
    continue if unit.y == 8
    res.unit_list.push battle_unit_create
      grid_x: unit.x
      grid_y: unit.y
      type  : unit.type
      side  : 0
      star_lvl : unit.star_lvl # need for game result penalty calculation
  
  # add enemy
  for _id,unit of player_b_state.board_unit_hash
    continue if unit.y == 8
    res.unit_list.push battle_unit_create
      grid_x: 7-unit.x
      grid_y: 7-unit.y
      type  : unit.type
      side  : 1
      star_lvl : unit.star_lvl # need for game result penalty calculation
  
  res