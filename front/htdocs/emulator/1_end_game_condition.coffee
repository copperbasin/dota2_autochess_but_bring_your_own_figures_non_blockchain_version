module = emulator
module.eliminate = (state, is_last_tick)->
  {cache_side_unit_list} = state
  s0 = cache_side_unit_list[0].length
  s1 = cache_side_unit_list[1].length
  if s0 >  0 and s1 >  0
    return "draw" if is_last_tick
    return null
  return "s1" if s0 == 0 and s1 >  0
  return "s0" if s0 >  0 and s1 == 0
  return "draw"
