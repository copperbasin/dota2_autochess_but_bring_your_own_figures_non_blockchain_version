{Damage_instance} = emulator
module = emulator
module.tick_targeting = (u0_list, u1_list, unit_hash)->
  need_retarget_count = 0
  for u0 in u0_list
    need_retarget = false
    need_retarget = true if u0.target_unit_uid == -1
    need_retarget = true if !unit_hash[u0.target_unit_uid]
    if need_retarget
      need_retarget_count++
      if u1_list.length == 0
        u0.target_unit_uid = -1
        continue
      
      target = u0.target_policy u1_list
      if !target
        u0.target_unit_uid = -1
      else
        u0.target_unit_uid = target.uid
  need_retarget_count

module.retargeting = (state)->
  {
    cache_unit_hash
    cache_side_unit_list
  } = state
  
  [
    u0_list
    u1_list
  ] = cache_side_unit_list
  
  need_retarget_count = 0
  need_retarget_count += module.tick_targeting u0_list, u1_list, cache_unit_hash
  need_retarget_count += module.tick_targeting u1_list, u0_list, cache_unit_hash
  need_retarget_count
# ###################################################################################################

module.dead_remove = (state)->
  # простой и медленный способ
  {
    unit_list
    projectile_list
    cache_unit_hash
    cache_side_unit_list
  } = state
  
  idx = 0
  loop
    break if idx >= unit_list.length
    unit = unit_list[idx]
    if unit._remove
      unit_list.remove_idx idx
      delete cache_unit_hash[unit.uid]
      # по-тупому
      cache_side_unit_list[unit.side].remove unit
      continue
    idx++
  
  idx = 0
  loop
    break if idx >= projectile_list.length
    projectile = projectile_list[idx]
    if projectile._remove
      projectile_list.remove_idx idx
      continue
    idx++
  
  
  return

# attack damage deal
module.damage_deal = (src, dst, state)->
  state.pending_effect_list.push ()->
    # TODO attack modifiers
    
    # p "damage_deal ad=#{src.ad100} t=#{state.tick_idx}"
    di = new Damage_instance
    di.damage100 = src.ad100
    
    for mod in src.a_mod_fn_list
      mod.fn di, src, dst, state
    
    for mod in dst.damage_block_fn_list
      mod.fn di, src, dst, state
    
    dst.hp100 -= di.damage100
    
    state.event_counter++
    
    # TODO only if src is unit
    # TODO src should get more mana
    src.mp100 += 2500
    dst.mp100 += 2500
    
    # p "damage_deal #{src.ad100} #{dst.hp100} #{state.tick_idx}"
    return [src, dst]
  
  return

module.status_effect_remove = (state)->
  # p "status_effect_remove #{state.tick_idx}"
  {
    tick_idx
    unit_list
  } = state
  for unit in unit_list
    {status_effect_list} = unit
    remove_idx_list = []
    for status_effect, idx in unit.status_effect_list
      if tick_idx > status_effect.until_ts # DEV
        ### !pragma coverage-skip-block ###
        throw new Error "OVERSHOOT #{state.tick_idx - unit.fsm_next_event_tick}"
      if tick_idx == status_effect.until_ts
        # p "NEED REMOVE #{tick_idx} <= #{status_effect.until_ts}"
        remove_idx_list.push idx
    
    # reverse for preserving index order in rest array
    if remove_idx_list.length
      while remove_idx_list.length
        idx = remove_idx_list.pop()
        # TODO OPT inline
        # TODO OPT perform only 1 length change
        status_effect_list.fast_remove_idx idx
      unit.status_effect_update_bitmap()
  return
