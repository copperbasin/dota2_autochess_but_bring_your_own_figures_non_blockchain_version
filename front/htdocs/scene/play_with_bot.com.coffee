module.exports =
  state :
    # возможно еще будет loading
    # TODO battle -> battle_wait/battle_calc/battle_replay
    phase : "buy" # buy/battle/end
    battle_finish: false
  
  buy_state : null
  battle_start_state : null
  bot_state : null
  
  mount : ()->
    bg_change "img/battle_bg.jpg"
    
    @restart()
    return
  
  restart : ()->
    @game = new Practice_game
    @buy_state = @game.player_list[0].state
    @bot_state = @game.player_list[1].state
    window.debug_game = @game
    window.debug_bot_state = @bot_state
  
  commit_and_battle_start : ()->
    @game.phase_buy_finish()
    # ###################################################################################################
    #    battle emulator state prepare
    # ###################################################################################################
    @battle_start_state = prepare_battle @buy_state.final_state, @bot_state.final_state
    
    # ###################################################################################################
    # start
    @set_state {
      phase: "battle"
      battle_finish: false
    }
  
  battle_finish : (result, battle_final_state)->
    @game.phase_battle_finish result, battle_final_state
    if @game.active_player_list.length <= 1
      @set_state phase: "end_of_game"
    else
      @set_state battle_finish: true
  
  render : ()->
    div {class: "center pad_top"}
      div {class: "background_pad"}
        div {
          style:
            textAlign:"left"
            position: "abosolute"
        }
          Back_button {
            on_click : ()=>
              router_set "main"
          }
        switch @state.phase
          when "buy"
            div {class:"battle_caption"}, "Phase: #{@state.phase}"
            Match_player_stats @buy_state.final_state
            Board_buy {
              state : @buy_state
            }
            Start_button {
              label : "To battle"
              on_click : ()=>
                @commit_and_battle_start()
            }
          when "battle"
            div {class:"battle_caption"}, "Phase: #{@state.phase}"
            Match_player_stats @buy_state.final_state
            Board_battle {
              start_state:@battle_start_state
              on_finish : (result, battle_final_state)=>
                @battle_finish(result, battle_final_state)
            }
            Start_button {
              label : "End battle"
              disabled : !@state.battle_finish
              on_click : ()=>
                @set_state phase: "buy"
            }
          when "end_of_game"
            div {class:"battle_caption"}, "End of game"
            player_list = @game.player_list.clone()
            player_list.sort (a,b)->-(a.state.final_state.hp - b.state.final_state.hp)
            table {class:"table"}
              tbody
                tr
                  td "Player name"
                  td "HP left"
                  td "Gold left"
                  # TODO units left
                for player in player_list
                  tr
                    td player.nickname
                    td player.state.final_state.hp
                    td player.state.final_state.gold
            Start_button {
              label : "Restart"
              on_click : ()=>
                @restart()
                @set_state phase : "buy"
            }
    