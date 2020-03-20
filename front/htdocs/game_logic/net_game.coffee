class window.Board
  player_host : null
  player_guest: null
  gen_emulator_start_state : ()->
    prepare_battle @player_host.state.final_state, @player_guest.state.final_state
  
class window.Net_game
  seed              : 0
  battle_seed       : 0
  active_player_list: []
  player_list       : []
  board_list        : []
  unit_pool_list    : []
  current_player    : null
  match_ready       : false
  
  constructor:(match_serialized)->
    @sync match_serialized
    return
  
  sync : (match_serialized)->
    @seed = match_serialized.seed
    @battle_seed = match_serialized.battle_seed
    
    @active_player_list = []
    @board_list         = []
    @unit_pool_list     = []
    # ###################################################################################################
    #    unit_pool_list
    # ###################################################################################################
    for net_player in match_serialized.match_player_list
      for figure_name, count of net_player.figure_hash
        [figure_id] = figure_name.split "_"
        for i in [0 ... count]
          # TODO make unit.uid for remove from unit_pool_list units that are on boards (and after sell place them back to unit_pool_list, !!!NOTE merge!!)
          @unit_pool_list.push unit_id_hash[figure_id]
    
    # ###################################################################################################
    #    player_list
    # ###################################################################################################
    for net_player, order_id in match_serialized.match_player_list
      @active_player_list.push player = new Player
      player.id       = net_player.id
      player.nickname = net_player.nickname
      player.is_commit_done = net_player.is_commit_done
      player.state = player_state = new Player_intermediate_state
      # а где мне взять его state с прошлого раунда??? к которому собственно добавлять action'ы
      
      if net_player.commit_state
        player.state.action_list_deserialize_json net_player.commit_state.action_list
      
      player.last_game_reward = net_player.last_game_reward
      
      if net_player.last_consensus_state
        start_state = new Player_cross_round_state
        start_state.deserialize_json net_player.last_consensus_state
        # !!! BUG no player.state
        player.state.start_state = start_state
      else
        player_state.start_state = new Player_cross_round_state
        player_state.start_state.hp   = 1
        player_state.start_state.gold = 10
    
    @shop_init()
    
    for player,idx in @active_player_list
      net_player = match_serialized.match_player_list[idx]
      player_state = player.state
      try
        # player_state.final_state_calc() # shop_init includes final_state_calc
        if net_player.commit_state
          test_state = new Player_cross_round_state
          test_state.deserialize_json net_player.commit_state.final_state
          if !test_state.cmp player_state.final_state
            throw new Error "!test_state.cmp(player_state.final_state)"
      catch err
        perr err
        player_state.final_state = player_state.start_state.clone()
      
      player.order_id = order_id
    
    found = false
    for player in @active_player_list
      if !player.is_commit_done
        found = true
        break
    @match_ready = !found
    
    @player_list = @active_player_list.clone()
    
    for player in @player_list
      if player.id == localStorage.player_id
        @current_player = player
    
    return
  
  shop_init : ()->
    window.rand_seed = @seed+1
    player_idx    = 0
    player_idx_mod= @active_player_list.length
    while @unit_pool_list.length
      unit      = rand_list @unit_pool_list
      @unit_pool_list.remove unit
      player    = @active_player_list[player_idx]
      player_idx= (player_idx+1)%player_idx_mod
      
      cell = new Shop_unit
      cell.id   = player.state.start_state.shop_unit_list.length
      # TODO pass unit.uid
      cell.type = unit.type
      cell.lvl  = unit.level
      player.state.start_state.shop_unit_list.push cell
    
    for player in @active_player_list
      player.state.final_state_calc()
    
    return
  
  player_commit_server : ()->
    ws_ton.send {
      player_id   : localStorage.player_id
      switch      : "submit_position"
      # TODO will be base64 buffer here
      action_list : @current_player.state.action_list_serialize_json()
      final_state : @current_player.state.final_state_serialize_json()
    }
    @current_player.is_commit_done = true
    return
  
  phase_calc_client : ()->
    # TODO remove
    # # ###################################################################################################
    # #    action apply
    # # ###################################################################################################
    # battle_seed_enthropy_source_list = []
    # for player_num, action_list of action_list_hash
    #   player = @active_player_list[player_num]
    #   player.action_list = action_list
    #   try
    #     player.final_state_calc()
    #     # ??? TODO compare final state
    #     battle_seed_enthropy_source_list.push action_list
    #   catch err
    #     perr "player #{player.id} submitted bad action list", err
    #     player.action_list.clear()
    #     player.final_state = player.start_state.clone()
    # ###################################################################################################
    #    generate battle seed
    # ###################################################################################################
    # TODO calc from battle_seed_enthropy_source_list
    battle_seed = @battle_seed
    window.rand_seed = battle_seed+1
    # ###################################################################################################
    #    board_list
    # ###################################################################################################
    @board_list.clear()
    for player in @active_player_list
      @board_list.push board = new Board
      board.player_host = player
      loop
        player_guest = rand_list @active_player_list
        break if player_guest != player
      board.player_guest= player_guest
    # ###################################################################################################
    #    calculate each battle
    # ###################################################################################################
    for board in @board_list
      window.rand_seed = battle_seed+1
      emu = new emulator.Emulator
      emu.end_condition = emulator.eliminate
      emu.tick_limit = 30*100 # 30 sec
      emu.state = board.gen_emulator_start_state()
      result = emu.go()
      battle_final_state = emu.state
      
      switch result
        # when "draw"
        #   "nothing"
        # when "s0"
        #   "nothing"
        
        when "s1"
          sum = 0
          for unit in battle_final_state.unit_list
            sum += unit.star_lvl
          board.player_host.state.final_state.hp -= sum
    # ###################################################################################################
    #    submit for consensus
    # ###################################################################################################
    for player in @active_player_list
      player.state.action_list.clear()
      player.state.start_state = player.state.final_state
      player.state.final_state_calc()
    ws_ton.send {
      player_id : localStorage.player_id
      switch : "submit_sim_result"
      match  : 
        match_player_list : @active_player_list.map (player)->player.state.final_state.serialize_json()
    }
    return
  
  phase_consensus : ()->
    @match_ready = false
    for player in @active_player_list
      player.is_commit_done = false
    return
  
  phase_new_round : ()->
    @active_player_list = @active_player_list.filter (t)->t.state.start_state.hp > 0
    return
  

  