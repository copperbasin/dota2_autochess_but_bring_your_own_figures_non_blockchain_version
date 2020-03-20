###
limitations
  single board
  1 hp
  visitor lose -> lose hp
###
class @Practice_game
  active_player_list : []
  player_list : []
  
  constructor:()->
    @active_player_list = []
    @active_player_list.push player = new Player
    player.nickname = "Player"
    player.state = player_state = new Player_intermediate_state
    player_state.start_state = new Player_cross_round_state
    player_state.start_state.hp   = 1
    player_state.start_state.gold = 10
    
    shop_init player_state, 0, []
    player_state.final_state_calc()
    
    # ###################################################################################################
    @active_player_list.push player = new Player
    player.nickname = "Bot"
    player.state = player_state = new Player_intermediate_state
    player_state.start_state = new Player_cross_round_state
    player_state.start_state.hp   = 1
    player_state.start_state.gold = 10
    
    shop_init player_state, 1, []
    player_state.final_state_calc()
    
    action = new Player_action
    action.type = Player_action.BUY
    action.shop_id = 0
    action.x = 0
    action.y = 8
    
    player_state.action_add action
    
    action = new Player_action
    action.type = Player_action.MOVE
    action.unit_id = 0
    action.x = 0
    action.y = 7
    
    player_state.action_add action
    
    @player_list = @active_player_list.clone()
  
  _player_commit : (player)->
    player_state = player.state
    player_state.start_state = player_state.final_state
    # TODO compact id
    player_state.final_state = player_state.final_state.clone()
    player_state.action_list.clear()
    # TODO proper clear and shuffle
    player_state.start_state.shop_unit_list = player_state.start_state.shop_unit_list.filter (t)->!t.is_bought
    return
  
  phase_buy_finish : ()->
    for player in @active_player_list
      @_player_commit player
    
    # TODO update pool
    
    # LATER TODO board prepare
    
    return
  
  phase_battle_finish : (result, battle_final_state)->
    switch result
      # when "draw"
      #   "nothing"
      when "s0"
        sum = 0
        for unit in battle_final_state.unit_list
          sum += unit.star_lvl
        @active_player_list[1].state.start_state.hp -= sum
      
      when "s1"
        sum = 0
        for unit in battle_final_state.unit_list
          sum += unit.star_lvl
        @active_player_list[0].state.start_state.hp -= sum
    
    for player in @active_player_list
      player.state.final_state = player.state.start_state.clone()
    
    @active_player_list = @active_player_list.filter (t)->t.state.start_state.hp > 0
    
    return
  

  