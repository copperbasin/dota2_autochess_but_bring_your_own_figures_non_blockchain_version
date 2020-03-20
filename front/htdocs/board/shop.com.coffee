module.exports =
  controller : null
  
  mount : ()->
    @controller = new Shop_controller
    @controller.state = @props.state
    @controller.on_change = @props.on_change
    
    @controller.on_board_change_fn = @props.on_board_change
    return
  
  render : ()->
    @controller.props_update @props
    div {
      style:
        textAlign: "left"
        width  : shop_cell_size_px*5+2
        height : battle_board_cell_size_px*10 # +1 т.к. скамья запасных
    }
      Canvas_multi {
        layer_list : ["bg", "fg"]
        canvas_cb   : (canvas_hash)=>
          @controller.canvas_controller canvas_hash
        gui         : @controller
        ref_textarea: ($textarea)=>
          @controller.$textarea = $textarea
          @controller.init()
      }
      # TODO shop
  