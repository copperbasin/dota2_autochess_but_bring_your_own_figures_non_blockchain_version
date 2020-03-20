module = emulator
_uid = 0
module.FSM_unit_state =
  "idling"            : _uid++
  "attacking_pre"     : _uid++
  "attacking"         : _uid++
  "cell_moving_start" : _uid++
  "cell_moving_end "  : _uid++
  "casting_pre"       : _uid++
  "casting"           : _uid++
  "stunned"           : _uid++

_uid = 0
module.FSM_event =
  "tick"              : _uid++
  # "stun"              : _uid++

# class module.FSM_transition
#   delay : 0
#   next_state_fn : (unit)-> # REPLACE
#     # TODO apply effect on unit
#     # get next state
#   

class module.FSM
  state_list      : []
  transition_hash : {} # [state][event_name] -> (unit, state)->
  constructor:()->
    @state_list      = []
    @transition_hash = [] # from -> ()->
  
###
Что должно работать
idling -> attacking_pre -> attacking -> idling
idling -> casting_pre -> casting -> idling
idling -> cell_moving_start -> cell_moving_end -> idling

idling -> *_pre -> [event stun_receive] -> idling

###