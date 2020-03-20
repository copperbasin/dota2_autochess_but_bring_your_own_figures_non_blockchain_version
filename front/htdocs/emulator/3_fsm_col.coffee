module = emulator
{Projectile} = emulator
{
  FSM
  FSM_unit_state
  FSM_event
} = emulator
{
  damage_deal
} = emulator

# NOTE this is default FSM (semi-optimized)
# WE should use optimized FSM for each unit type to achieve max perf
module.fsm_craft = (opt = {})->
  {
    cast_target_enemy
    cast_effect
  } = opt
  cast_target_enemy ?= true
  ret = new FSM
  ret.state_list.push FSM_unit_state.idling
  
  if can_attack = opt.attack_type?
    switch opt.attack_type
      when "melee", "ranged"
        ret.state_list.push FSM_unit_state.attacking_pre
        ret.state_list.push FSM_unit_state.attacking
      else
        ### !pragma coverage-skip-block ###
        throw new Error "unknown attack_type '#{opt.attack_type}'"
  
  if can_cast = opt.cast_type?
    switch opt.cast_type
      when "cast"
        ret.state_list.push FSM_unit_state.casting_pre
        ret.state_list.push FSM_unit_state.casting
      when "channel"
        ### !pragma coverage-skip-block ###
        throw new Error "unimplemented channel cast_type"
      else
        ### !pragma coverage-skip-block ###
        throw new Error "unknown cast_type '#{opt.cast_type}'"
  
  for state in ret.state_list
    ret.transition_hash[state] = {}
  
  # NON OPT
  # CLOSURE!!!!
  ret.transition_hash[FSM_unit_state.idling][FSM_event.tick] = (unit, state)->
    {tick_idx} = state
    
    if can_cast
      loop
        # TODO check silence
        break if unit.mp100 < 10000
        break if cast_target_enemy and unit.target_unit_uid == -1
        unit.fsm_next_event_tick = state.tick_idx + unit.cast_pre
        unit.fsm_idx = FSM_unit_state.casting_pre
        return true
    
    if can_attack
      if unit.next_tick_attack_available <= tick_idx
        unit.fsm_next_event_tick = state.tick_idx + unit.a_pre
        unit.fsm_idx = FSM_unit_state.attacking_pre
        return true
      else
        unit.fsm_next_event_tick = unit.next_tick_attack_available
        return true
    
    return false
  
  if can_attack
    ret.transition_hash[FSM_unit_state.attacking_pre][FSM_event.tick] = (unit, state)->
      if !target = state.cache_unit_hash[unit.target_unit_uid]
        unit.fsm_idx = FSM_unit_state.idling
        unit.fsm_next_event_tick = state.tick_idx+1
        return true
      return false if unit.fsm_next_event_tick > state.tick_idx
      if unit.fsm_next_event_tick < state.tick_idx # DEV
        ### !pragma coverage-skip-block ###
        throw new Error "OVERSHOOT #{state.tick_idx - unit.fsm_next_event_tick}"
      unit.fsm_idx = FSM_unit_state.attacking
      unit.fsm_next_event_tick = state.tick_idx+1
      return true
    
    switch opt.attack_type
      when "melee"
        ret.transition_hash[FSM_unit_state.attacking][FSM_event.tick] = (unit, state)->
          if !target = state.cache_unit_hash[unit.target_unit_uid]
            unit.fsm_idx = FSM_unit_state.idling
            unit.fsm_next_event_tick = state.tick_idx+1
            return true
          # TODO is target still in range
          damage_deal unit, target, state
          unit.fsm_idx = FSM_unit_state.idling
          unit.next_tick_attack_available = state.tick_idx + unit.a_post
          return true
      when "ranged"
        ret.transition_hash[FSM_unit_state.attacking][FSM_event.tick] = (unit, state)->
          if !target = state.cache_unit_hash[unit.target_unit_uid]
            unit.fsm_idx = FSM_unit_state.idling
            unit.fsm_next_event_tick = state.tick_idx+1
            return true
          # TODO create projectile
          projectile = new Projectile
          projectile.hd_next_tick = state.tick_idx + 1
          projectile.x = unit.x
          projectile.y = unit.y
          projectile.target = target
          projectile.effect = ()->
            damage_deal unit, target, state
          state.projectile_list.push projectile
          state.event_counter++
          
          unit.fsm_idx = FSM_unit_state.idling
          unit.next_tick_attack_available = state.tick_idx + unit.a_post
          return true
  
  if can_cast
    if !cast_effect
      ### !pragma coverage-skip-block ###
      throw new Error "missing cast_effect"
    if cast_target_enemy
      ret.transition_hash[FSM_unit_state.casting_pre][FSM_event.tick] = (unit, state)->
        return false if unit.fsm_next_event_tick > state.tick_idx
        if unit.fsm_next_event_tick < state.tick_idx # DEV
          ### !pragma coverage-skip-block ###
          throw new Error "OVERSHOOT #{state.tick_idx - unit.fsm_next_event_tick}"
        if !target = state.cache_unit_hash[unit.target_unit_uid]
          unit.fsm_idx = FSM_unit_state.idling
          unit.fsm_next_event_tick = state.tick_idx+1
          return true
        
        unit.fsm_idx = FSM_unit_state.casting
        unit.fsm_next_event_tick = state.tick_idx+1
        return true
      ret.transition_hash[FSM_unit_state.casting][FSM_event.tick] = (unit, state)->
        if !target = state.cache_unit_hash[unit.target_unit_uid]
          unit.fsm_idx = FSM_unit_state.idling
          unit.fsm_next_event_tick = state.tick_idx+1
          return true
        
        cast_effect {
          unit
          target
          state
        }
        state.event_counter++
        
        unit.fsm_idx = FSM_unit_state.idling
        unit.fsm_next_event_tick = state.tick_idx+1
        return true
    else
      ### !pragma coverage-skip-block ###
      throw new Error "!cast_target_enemy not implemented"
  
  ret