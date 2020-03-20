module = emulator
{status_effect_hash} = module
{State} = module
{FSM_event} = module
{
  dead_remove
  retargeting
  status_effect_remove
} = module
{
  status_effect_to_idx_mask
  status_effect_hash
} = module

{big_idx:fast_stun_idx, mask:fast_stun_mask} = status_effect_to_idx_mask status_effect_hash.stun

class module.Emulator
  tick_per_sec  : 100
  tick_limit    : 0
  state         : null
  end_condition : (state, is_last_tick)->if is_last_tick then "draw" else null # replaceable
  
  constructor:()->
    @state = new State
  
  tick : ()->
    {
      state
      tick_per_sec
    } = @
    {
      tick_idx
      unit_list
      projectile_list
      pending_effect_list
    } = state
    
    status_effect_remove state
    
    # projectile move
    for projectile in projectile_list
      {
        target
        ms
      } = projectile
      ms_per_tick = ms//tick_per_sec
      dx = target.x - projectile.x
      dy = target.y - projectile.y
      d2 = dx*dx + dy*dy
      if d2 < ms_per_tick
        # hit
        projectile._remove = true
        projectile.effect({state})
      else
        d = Math.sqrt(d2)
        dx /= d
        dy /= d
        vx = dx*ms_per_tick
        vy = dy*ms_per_tick
        projectile.x += vx
        projectile.y += vy
    
    # fsm move
    for unit in unit_list
      if unit.status_effect_bitmap[fast_stun_idx] & fast_stun_mask
        # p "stun skip #{tick_idx}"
        continue
      fn = unit.fsm_ref.transition_hash[unit.fsm_idx][FSM_event.tick]
      fn?(unit, state)
    
    for effect in pending_effect_list
      effect()
    pending_effect_list.clear()
    
    # regen
    for unit in unit_list
      # hp
      regen_per_tick = unit.hp_reg100//tick_per_sec
      unit.hp100 = Math.min unit.hp_max100, unit.hp100 + regen_per_tick
      
      if unit.hp100 <= 0
        state.event_counter++
        unit._remove = true
      
      # mp
      regen_per_tick = unit.mp_reg100//tick_per_sec
      unit.mp100 = Math.max 0, Math.min unit.mp_max100, unit.mp100 + regen_per_tick
    
    dead_remove state
    retargeting state
    
    # TBD
    return
  
  
  
  go : ()->
    @state.cache_actualize()
    loop
      @tick()
      
      break if @end_condition @state
      break if @state.tick_idx >= @tick_limit
      @state.tick_idx++
    @end_condition @state, true
  
