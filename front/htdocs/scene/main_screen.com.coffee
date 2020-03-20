module.exports =
  state:
    line_up_check: false
  
  listener_price_update : null
  mount : ()->
    bg_change "img/knight_bg.jpg"
    @set_state {line_up_check: ton.line_up_check()}
    ton.on "price_update", @listener_price_update = ()=>
      @set_state {line_up_check: ton.line_up_check()}
  
  unmount : ()->
    ton.off "price_update", @listener_price_update
  
  render : ()->
    div {class: "center pad_top"}
      div {class:"main_menu_item"}
        if @state.line_up_check
          Start_button {
            label : "Start game"
            on_click : ()=>
              router_set "queue"
          }
        else
          Start_button {
            label : "Start game"
            disabled: true
          }
      div {class:"main_menu_item"}
        Start_button {
          label : "Shop"
          on_click : ()=>
            router_set "shop"
        }
      div {class:"main_menu_item"}
        Start_button {
          label : "Practice"
          on_click : ()=>
            router_set "play_with_bot"
        }
  