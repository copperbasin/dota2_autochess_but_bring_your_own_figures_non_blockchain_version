window.shop_init = (state, todo_player_id, todo_unit_pool_list)->
  shop_unit_list = state.start_state.shop_unit_list
  for i in [0 ... 25]
    cell = new Shop_unit
    cell.id   = i
    cell.type = unit_list[i].type
    cell.lvl  = unit_list[i].level
    shop_unit_list.push cell
  
  return
