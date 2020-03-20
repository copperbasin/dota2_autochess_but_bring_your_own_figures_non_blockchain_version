module = emulator
_uid = 0
module.status_effect_hash = {
  none        : _uid++ # for status effects without need to check
  # https://dota2.gamepedia.com/Disable
  # полная неуправляемость
  stun        : _uid++
  shackle     : _uid++ # действует пока не сделать disable источнику shackle (кроме flaming lasso)
  cyclone     : _uid++
  fear        : _uid++
  taunt       : _uid++
  # почти полная неуправляемость
  hide        : _uid++ # можно только переключать и перекладывать предметы
  hex         : _uid++ # можно только двигаться, но 
  # частичная потеря управляемости
  root        : _uid++ # нельзя двигаться и blink/teleport
  disarm      : _uid++ # нельзя атаковать
  ethereal    : _uid++ # нельзя атаковать, но неуязвимость для физ урона
  silence     : _uid++ # нельзя кастовать
  mute        : _uid++ # нельзя использовать предметы
  forced_move : _uid++ # неуправляемость по движению
  # особое
  break       : _uid++ # потеря пассивок
  # ухудшение управляемости
  leash       : _uid++ # модификатор движения, который не позволяет двигаться в определённых направлениях и использовать blink/teleport
  attack_slow : _uid++
  move_slow   : _uid++
  blind       : _uid++ # шанс miss'а
}

module.status_effect_to_idx_mask = (id)->
  big_idx   = id // 32
  small_idx = id  % 32
  mask      = 1 << small_idx
  {
    big_idx  
    small_idx
    mask     
  }

class module.Status_effect
  id      : -1
  until_ts: 0
  # _remove : false
  
  # WARNING should be used only for idempotent attr changes
  on_apply  : (unit, state)-> # replace me
  
  on_remove : (unit, state)-> # replace me
