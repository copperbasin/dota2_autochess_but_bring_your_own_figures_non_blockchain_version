module.exports =
  state:
    right_panel : "shop"
  controller : null
  
  mount : ()->
    @controller = new Board_buy_controller
    @controller.readonly = @props.readonly
    @controller.state = @props.state
    @controller.on_change = @props.on_change
    
    window.debug_shop_state = @controller.state
    
    return
  
  render : ()->
    @controller.props_update @props
    table
      tbody
        tr
          td {
            style:
              textAlign: "left"
              width  : battle_board_cell_size_px*8+3
              height : battle_board_cell_size_px*10 # +1 т.к. скамья запасных
              width  : 500
          }
            Canvas_multi {
              layer_list : ["bg", "fg", "hover"]
              canvas_cb   : (canvas_hash)=>
                @controller.canvas_controller canvas_hash
              gui         : @controller
              ref_textarea: ($textarea)=>
                @controller.$textarea = $textarea
                @controller.init()
            }
          if !@props.readonly
            td {
              style:
                verticalAlign: "top"
                width : 500
            }
              Tab_bar {
                hash : {
                  "shop"        : "Shop"
                  "leaderboard" : "Leaderboard"
                }
                center : true
                value: @state.right_panel
                on_change : (right_panel)=>
                  @set_state {right_panel}
              }
              switch @state.right_panel
                when "shop"
                  Board_shop {
                    state : @controller.state
                    on_change : @props.on_change
                    on_board_change : ()=>
                      @controller.refresh()
                  }
                when "leaderboard"
                  Leaderboard {
                    player_list : @props.leaderboard_player_list
                  } 
        