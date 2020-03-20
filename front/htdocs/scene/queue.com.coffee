module.exports =
  state :
    show_queue      : false
    starting_battle : false
    player_count    : 1
  
  listener_queue        : null
  queue_pool_interval   : null
  listener_match_found  : null
  line_up_interval      : null
  mount : ()->
    bg_change "img/white_bg.jpg"
    ton.on "queue_len_update", @listener_queue = ()=>
      @force_update()
    @queue_pool_interval = setInterval ()=>
      ton.get_queue_len_request()
    , 1000
    
    ws_ton.on "data", @listener_match_found = (data)=>
      if data.switch == "match_found"
        ton.match_serialized = data.match
        @set_state {starting_battle: true}
        @timeout_start_battle = setTimeout ()=>
          router_set "match"
        , 1000
    
    @timeout_details = setTimeout ()=>
      @set_state {show_queue:true}
    , 2000
    
    @line_up_interval = setInterval ()->
      ws_ton.write {
        player_id : localStorage.player_id
        switch    : "line_up"
        unit_list : ton.line_up_gen()
      }
    , 1000
    
    
  
  unmount : ()->
    clearInterval @line_up_interval
    clearInterval @queue_pool_interval
    clearTimeout @timeout_details
    clearTimeout @timeout_start_battle
    ton.off "queue_len_update", @listener_queue
    ws_ton.off "data", @listener_match_found
  
  render : ()->
    div {class: "center pad_top"}
      div {class: "background_pad"}
        if @state.starting_battle
          div "Starting battle"
        else
          div "Waiting"
          if @state.show_queue
            # i18n на коленке
            n = ton.queue_len
            if n == 1
              div "In queue #{n} player"
            else
              div "In queue #{n} players"
  