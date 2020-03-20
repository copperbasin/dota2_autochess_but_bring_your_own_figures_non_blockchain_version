ws_protocol = if location.protocol == 'http:' then "ws:" else "wss:"
# window.ws_ton = new Websocket_wrap "#{ws_protocol}//#{location.hostname}:1338"
window.ws_ton = new Websocket_wrap "#{ws_protocol}//#{location.hostname}:11111"
json_cmp = (a,b)->JSON.stringify(a) == JSON.stringify(b)

window.min_figure_match_count = 8

class Ton_stub
  balance : 0
  address : "no address"
  owned_hash      : {}
  unit_price_hash : {}
  unit_battle_hash: {}
  queue_len       : 1
  match_serialized: null
  last_match_serialized : null
  
  commit_ts_left_set_ts : null
  commit_ts_left    : null
  commit_final_player_list: []
  
  event_mixin @
  constructor:()->
    event_mixin_constructor @
    @owned_hash       = {}
    @unit_price_hash  = {}
    @unit_battle_hash = {}
    
    @commit_final_player_list = []
    
    @unit_price_request()
    @unit_count_request()
    
    @load()
  
  load : ()->
    try
      @unit_battle_hash = JSON.parse localStorage.unit_battle_hash
    catch err
      puts "no storage for unit_battle_hash"
    
  
  save : ()->
    localStorage.unit_battle_hash = JSON.stringify @unit_battle_hash
  
  line_up_gen : ()->
    left_hash = {
      1 : min_figure_match_count
      2 : min_figure_match_count
      3 : min_figure_match_count
      4 : min_figure_match_count
      5 : min_figure_match_count
    }
    level_unit_hash = {
      1 : []
      2 : []
      3 : []
      4 : []
      5 : []
    }
    
    for id,count of @unit_battle_hash
      level = @unit_price_hash[id].level
      continue if left_hash[level] <= 0
      max_count = @owned_hash[id]?.count or 0
      count = Math.min count, max_count
      count = Math.min count, left_hash[level]
      left_hash[level] -= count
      continue if !count
      level_unit_hash[level].push {
        id : +id
        level
        count
      }
    
    res = []
    for k,v of level_unit_hash
      res.append v
    res
  
  line_up_check : ()->
    level_hash = {
      1 : 0
      2 : 0
      3 : 0
      4 : 0
      5 : 0
    }
    
    for id,count of @unit_battle_hash
      level = @unit_price_hash[id]?.level or 0
      continue if level == 0
      level_hash[level] += count
    
    for level,count of level_hash
      return false if count < min_figure_match_count
    true
  
  unit_price_request : ()->
    req_unit_list = []
    for unit in unit_list
      req_unit_list.push {
        id    : unit.id
        level : unit.level
      }
    
    ws_ton.write {
      player_id : localStorage.player_id
      switch    : "get_price"
      # switch    : "get_price_multi_exec"
      unit_list : req_unit_list
    }
    return
  
  unit_count_request : (id_list)->
    req_unit_list = []
    for unit in unit_list
      continue if id_list and !id_list.has unit.id
      req_unit_list.push {
        id    : unit.id
        level : unit.level
      }
    
    ws_ton.write {
      player_id : localStorage.player_id
      switch    : "get_unit_count"
      # switch    : "get_unit_count_multi_exec"
      unit_list : req_unit_list
    }
    return
  
  get_queue_len_request : ()->
    ws_ton.write {
      player_id : localStorage.player_id
      switch    : "get_queue_len"
    }


window.ton = new Ton_stub
window.ws_ton.on "data", (data)->
  switch data.switch
    # ###################################################################################################
    #    match
    # ###################################################################################################
    # немного опасно
    when "match_check"
      ton.match_serialized = data.match
      if data.match?
        if data.match.ts_left?
          ton.commit_ts_left = data.match.ts_left
          ton.commit_ts_left_set_ts = Date.now()
        router_set "match"
    
    when "match_get"
      ton.match_serialized = data.res
    
    when "update_commit_state", "battle_start"
      ton.match_serialized = data.match
      ton.commit_ts_left = data.match.ts_left
      ton.commit_ts_left_set_ts = Date.now()
      
      ton.dispatch data.switch
    
    when "battle_finish"
      ton.match_serialized = data.match
      ton.commit_ts_left = null
      ton.commit_ts_left_set_ts = null
      
      ton.dispatch data.switch
    
    when "player_left"
      # все-равно как-то хреново
      ton.last_match_serialized = data.match
    
    # ###################################################################################################
    #    non-match
    # ###################################################################################################
    when "balance"
      if ton.balance != data.balance
        ton.balance = data.balance
        ton.dispatch "balance", data.balance
    
    when "address"
      if ton.address != data.address
        ton.address = data.address
        ton.dispatch "address", data.address
    
    when "get_price"
      need_update = false
      for unit in data.unit_list
        if !json_cmp(ton.unit_price_hash[unit.id], unit)
          ton.unit_price_hash[unit.id] = unit
          need_update = true
      
      if need_update
        ton.dispatch "price_update"
    
    when "get_unit_count"
      need_update = false
      for unit in data.unit_list
        if !json_cmp(ton.unit_price_hash[unit.id], unit)
          ton.owned_hash[unit.id] = unit
          need_update = true
      
      if need_update
        ton.dispatch "count_update"
    
    when "get_queue_len"
      if ton.queue_len != data.result
        ton.queue_len = data.result
        ton.dispatch "queue_len_update"
    
  return

match_check = ()->
  ws_ton.send {
    player_id : localStorage.player_id
    switch    : "match_check"
  }
window.ws_ton.on "connect", ()->
  match_check()
match_check()