game_result_translation =
  s0  : "You win"
  s1  : "You lose"
  draw: "Draw"

module.exports =
  state :
    play    : true
    tick_idx: 0
  
  game_result: null
  controller : null
  emulator   : null
  
  mount : ()->
    @emulator = new emulator.Emulator
    @emulator.end_condition = emulator.eliminate
    @emulator.tick_limit = 30*100 # 30 sec
    # @emulator.tick_limit = 100 # 1 sec
    window.debug_emulator = @emulator
    
    @controller = new Board_battle_controller
    @controller.state = @props.start_state
    if !@props.start_state
      perr "BAD battle !@props.start_state"
      return
    
    window.debug_state = @controller.state
    @emulator.state = @controller.state
    
    @controller.state.cache_actualize()
    @controller.request_emulator_step_fn = ()=>
      return false if !@state.play
      
      tick_count = 1
      for i in [0 ... tick_count]
        if @game_result = @emulator.end_condition @controller.state
          @set_state play: false
          @props.on_finish?(@game_result, @emulator.state)
          # TODO play round end animations
          break
        @emulator.tick()
        @emulator.state.tick_idx++
      
      @set_state tick_idx: @emulator.state.tick_idx
      return true
    
    return
  
  render : ()->
    @controller.props_update @props
    div {
      style:
        textAlign: "left"
        width  : battle_board_cell_size_px*8
        height : battle_board_cell_size_px*9 # +1 т.к. скамья запасных
    }
      time = @state.tick_idx//100
      time_sub = @state.tick_idx%100
      span "0:#{time.rjust 2, '0'}.#{time_sub} #{game_result_translation[@game_result] ? ''}"
      Canvas_multi {
        layer_list : ["bg", "fg"]
        canvas_cb   : (canvas_hash)=>
          @controller.canvas_controller canvas_hash
        gui         : @controller
        ref_textarea: ($textarea)=>
          @controller.$textarea = $textarea
          @controller.init()
      }
  