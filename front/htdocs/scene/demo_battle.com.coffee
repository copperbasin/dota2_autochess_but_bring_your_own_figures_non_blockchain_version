module.exports =
  mount : ()->
    bg_change "img/battle_bg.jpg"
    
    @start_state = new emulator.State
    @start_state.unit_list.push battle_unit_create grid_x:0, grid_y:7, type:"tusk", side: 0
    @start_state.unit_list.push battle_unit_create grid_x:0, grid_y:0, type:"tusk", side: 1
    return
  
  render : ()->
    div {class: "center pad_top"}
      div {class: "background_pad"}
        Board_battle {start_state:@start_state}
    