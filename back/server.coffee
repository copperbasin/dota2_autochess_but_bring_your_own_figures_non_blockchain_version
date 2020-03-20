#!/usr/bin/env iced
require "fy"
argv = require("minimist")(process.argv.slice(2))
argv.ton_ws_port = 11111
config = require "./config"
rand = require "./rand"

WebSocketServer = require("ws").Server
ton_wss = new WebSocketServer
  port: argv.ton_ws_port
# TODO autoreload chokidar

# ###################################################################################################
#    
# ###################################################################################################
class Player
  id        : "-1"
  nickname  : ""
  address   : ""
  balance   : 1000000 # nano
  figure_hash : {}
  last_game_reward : null
  
  constructor:()->
    # @figure_hash = {}
    # DEBUG
    @figure_hash = {
      "10004_1" : 8
      "20001_2" : 8
      "30002_3" : 8
      "40004_4" : 8
      "50001_5" : 8
    }
  
class Match_player
  player      : null
  id          : "-1"
  nickname    : ""
  figure_hash : {}
  commit_state: null
  commit_simulation_state : null
  last_consensus_state : null
  hp : null # from last_consensus_state
  
  constructor:()->
    @figure_hash = {}
  
  serialize_obj : (opt = {})->
    ret = {}
    ret.id          = @id          
    ret.nickname    = @nickname    
    ret.figure_hash = @figure_hash 
    if opt.show_commit_state
      ret.commit_state = @commit_state # SUBOPTIMAL
    
    if @last_consensus_state
      ret.last_consensus_state = @last_consensus_state
    
    ret.is_commit_done = !!@commit_state
    ret.is_commit_simulation_done = !!@commit_simulation_state
    
    if @player.last_game_reward
      ret.last_game_reward = @player.last_game_reward
    
    ret

class Match
  id    : -1
  seed  : 0 # TODO extract from blockchain
  battle_seed : 0
  match_player_list : [] # Match_player[]
  full_match_player_list : []
  commit_allowed    : true
  
  death_timer_start_ts  : null
  death_timer           : null
  death_timer2_start_ts : null
  death_timer2          : null
  
  figure_list_by_level_list : []
  
  place_counter : 0
  
  constructor:()->
    @match_player_list = []
    @full_match_player_list = []
    @figure_list_by_level_list = [[],[],[],[],[]]
  
  notify_all : (msg)->
    for match_player in @match_player_list
      for connection in player2connection_list_hash[match_player.id] or []
        connection.write msg
    return
  
  check_commit : ()->
    if !@death_timer
      timeout = config.death_timer_timeout
      @death_timer_start_ts = Date.now() + timeout
      @death_timer = setTimeout ()=>
        @force_commit()
      , 30000
    found = null
    for match_player in @match_player_list
      if !match_player.commit_state
        found = match_player
        break
    
    @notify_all
      switch  : "update_commit_state"
      match   : @serialize_obj()
    
    return if found
    
    @battle_start()
  
  force_commit : ()->
    puts "force_commit"
    # for match_player in @match_player_list
    #   if !match_player.commit_state
    #     puts "TODO set state ???"
    
    @battle_start()
  
  battle_start : ()->
    puts "battle_start"
    @commit_allowed = false
    clearTimeout @death_timer
    @death_timer = null
    @death_timer_start_ts = null
    # TODO regenerate seed
    @battle_seed = @seed+1
    
    @notify_all
      switch  : "battle_start"
      match   : @serialize_obj()
  
  check_commit_simulation : ()->
    if !@death_timer2
      timeout = config.death_timer2_timeout
      @death_timer_2start_ts = Date.now() + timeout
      @death_timer2 = setTimeout ()=>
        @force_commit_simulation()
      , 30000
    
    found = null
    for match_player in @match_player_list
      if !match_player.commit_simulation_state
        found = match_player
        break
    
    @notify_all
      switch  : "update_commit_state"
      match   : @serialize_obj()
    
    return if found
    
    @battle_finish()
  
  force_commit_simulation : ()->
    puts "force_commit_simulation"
    @battle_finish()
  
  battle_finish : ()->
    puts "battle_finish"
    @commit_allowed = true
    clearTimeout @death_timer2
    @death_timer2 = null
    @death_timer_2start_ts = null
    # TODO regenerate seed
    @seed++
    
    # select majority
    count_hash = {}
    for match_player in @match_player_list
      continue if !match_player.commit_simulation_state
      key = match_player.commit_simulation_state.match_player_list.join()
      
      count_hash[key] ?= {
        state : match_player.commit_simulation_state
        count : 0
      }
      count_hash[key].count++
    
    best_list = []
    best_count = 0
    for k,v of count_hash
      if best_count < v.count
        best_count = v.count
        best_list = [v.state]
      else if best_count == v.count
        best_list.push v.state
    
    if best_list.length != 1
      return @match_end_error new Error "best_list.length != 1 #{best_list.length}"
    
    try
      [best] = best_list
      for match_player,idx in @match_player_list
        match_player.commit_state = null
        match_player.commit_simulation_state = null
        match_player.last_consensus_state = best.match_player_list[idx]
        match_player.hp = JSON.parse(match_player.last_consensus_state).hp
    catch err
      return @match_end_error err
    
    @notify_all
      switch  : "battle_finish"
      match   : @serialize_obj()
    
    new_match_player_list = []
    for match_player in @match_player_list
      if match_player.hp > 0
        new_match_player_list.push match_player
      else
        @match_end_player(match_player)
    @match_player_list = new_match_player_list
    
    if @match_player_list.length <= 1
      for match_player in @match_player_list
        @match_end_player(match_player)
      @match_end()
    return
    # remove lost players
  
  match_end_error : (err)->
    perr err
    return @notify_all switch : "match_stuck"
  
  match_end_player : (player)->
    place = @place_counter--
    reward_figure_count_list = config.reward_per_place2[place]
    delete player2match_hash[player.id]
    rand.seed = @seed+1
    
    player_reward_list = []
    for count,level in reward_figure_count_list
      list = @figure_list_by_level_list[level]
      for i in [0 ... count]
        figure_name = rand.rand_list list
        list.remove figure_name
        player_reward_list.push figure_name
        player.player.figure_hash[figure_name] ?= 0
        player.player.figure_hash[figure_name]++
    
    p "player_reward_list", player_reward_list
    player.player.last_game_reward = player_reward_list
    
    @notify_all {
      switch : "player_left"
      player : player.id
      match  : @serialize_obj(true)
    }
  
  match_end : ()->
    p "match_end"
    delete active_match_hash[@id]
  
  serialize_obj : (full = false)->
    ret = {}
    ret.id   = @id
    ret.seed = @seed
    ret.battle_seed = @battle_seed
    ret.match_player_list = []
    list = if full then @full_match_player_list else @match_player_list
    for match_player in list
      ret.match_player_list.push match_player.serialize_obj(show_commit_state : !@commit_allowed)
    
    # ВНЕЗАПНО
    if @death_timer_start_ts?
      ret.ts_left = @death_timer_start_ts - Date.now()
    if @death_timer2_start_ts?
      ret.ts_left2 = @death_timer2_start_ts - Date.now()
    ret

# ###################################################################################################
#    dummy mm
# ###################################################################################################
mm_player_hash = {}
mm_queue = []

mm_queue_clean_tick = ()->
  now = Date.now()
  while mm_queue.length and mm_queue[0].end_ts < now
    p "clean -1"
    mm_queue.shift()
  return

active_match_uid = 0
active_match_hash = {}
player2match_hash = {}
class MM_entity
  player      : null
  figure_hash : {}
  end_ts      : 0
  
  constructor:()->
    @figure_hash = {}
  
  
  to_match_player : ()->
    res = new Match_player
    res.player      = @player
    res.id          = @player.id
    res.nickname    = @player.nickname
    res.figure_hash = @figure_hash
    res

# ###################################################################################################
#    dummy figure cost
# ###################################################################################################

# TODO fixme
figure_cost =
  "tusk" : 1

txfee = 1

buy_unit = (unit_id, unit_level, count, player)->
  price = get_price unit_id, unit_level
  
  cost = price*count + txfee
  
  return false if player.balance < cost
  
  figure_name = "#{unit_id}_#{unit_level}"
  player.balance -= cost
  player.figure_hash[figure_name] ?= 0
  player.figure_hash[figure_name] += count
  
  return true

get_price = (unit_id, unit_level)->1
get_unit_count = (unit_id, unit_level, player)->
  figure_name = "#{unit_id}_#{unit_level}"
  player.figure_hash[figure_name] or 0
  
# ###################################################################################################
#    dummy storage
# ###################################################################################################


player_hash = {}

player = new Player
player.id = "1"
player.nickname = "Player1"
player.address = "address1"
player_hash[player.id] = player

player = new Player
player.id = "2"
player.nickname = "Player2"
player.address = "address2"
player_hash[player.id] = player

# ###################################################################################################

player2connection_list_hash = {}

validate_int = (t)->
  return false if typeof t != "number"
  return false if !isFinite t
  return false if t != Math.ceil t
  true

ton_wss.write = (msg)->
  ton_wss.clients.forEach (con)-> # FUCK ws@2.2.0
    con.write msg
  return

do ()->
  setInterval ()->
    now = Date.now()
    ton_wss.clients.forEach (con)->
      con.__last_ts = now
    
    for id, connection_list of player2connection_list_hash
      player2connection_list_hash[id] = connection_list.filter (con)->con.__last_ts == now
    return
  , 1000

ton_wss.on "connection", (con)->
  con.write = (msg)->
    if typeof msg == "string" or msg instanceof Buffer
      return con.send msg, (err)->
        perr "ws", err if err
    return con.send JSON.stringify(msg), (err)->
      perr "ws", err if err
  # con.write address_msg()
  # con.write balance_msg()
  con.on "message", (msg)->
    try
      data = JSON.parse msg
    catch err
      perr err
      return con.send
        error : "invalid JSON"
    
    send_err = (err)->
      perr err
      return con.write
        switch: data.switch
        error : err
        uid   : data.uid
    send_res = (res)->
      return con.write obj_merge {
        switch: data.switch
        uid   : data.uid
      }, res
    
    if !data?.switch?
      perr "missing switch"
      return send_err "missing switch"
    
    switch data.switch
      when "get_price"
        if !data.unit_list
          return send_err "!data.unit_list"
        
        for unit in data.unit_list
          # TOO slow for bulk
          price = get_price unit.id, unit.level
          con.write {
            switch: "get_price"
            unit_list : [{
              id    : unit.id
              level : unit.level
              price
            }]
          }
        return
      
      when "get_queue_len"
        return send_res result: mm_queue.length
    
    # DUMB AUTH
    # TODO fix me
    if !player = player_hash[data.player_id]
      return send_err "unknown player"
    
    player2connection_list_hash[player.id] ?= []
    player2connection_list_hash[player.id].upush con
    
    # DEBUG
    for id, clist of player2connection_list_hash
      p "#{id} -> #{clist.length}"
    p "####################################################################################################"
    
    switch data.switch
      # ###################################################################################################
      #    shop/figures/player figures etc
      # ###################################################################################################
      when "match_check"
        for id, match of player2match_hash
          p "#{id} -> #{match?.id}"
        if match = player2match_hash[player.id]
          return send_res match: match.serialize_obj()
        else
          return send_res match: null
      
      when "get_unit_count"
        if !data.unit_list
          return send_err "!data.unit_list"
        
        for unit in data.unit_list
          # TOO slow for bulk
          count = get_unit_count unit.id, unit.level, player # extra player
          con.write {
            switch: "get_unit_count"
            unit_list : [{
              id    : unit.id
              level : unit.level
              count
            }]
          }
        return
      
      when "buy_unit"
        return send_err "!data.id"    if !data.id
        return send_err "!data.level" if !data.level
        return send_err "!data.count" if !data.count
        result = buy_unit data.id, data.level, data.count, player
        con.write {
          uid : data.uid
          result
        }
        return
      # ###################################################################################################
      when "address_get"
        return send_res res:player.address
      
      when "balance_get"
        return send_res res:player.balance
      
      # when "figure_buy"
      #   if !price = figure_cost[data.type]
      #     return send_err "unknown figure"
      #   
      #   if !validate_int(data.count) or data.count <= 0
      #     return send_err "bad count"
      #   
      #   fee = 0.01
      #   
      #   total_cost = price*data.count + fee
      #   
      #   if player.balance < total_cost
      #     return send_err "not enough balance"
      #   
      #   player.balance -= total_cost
      #   player.figure_hash[data.type] ?= 0
      #   player.figure_hash[data.type] += data.count
      #   
      #   return send_res res:"ok"
      
      # when "mm_enqueue"
      when "line_up"
        end_ts = Date.now() + 10000 # 10 sec DEBUG
        if player2match_hash[player.id]?
          return send_err "you are already in match"
        
        if mm_player_hash[player.id]?
          mm_player_hash[player.id].end_ts = end_ts
          return send_res res:"ok"
        
        # TODO verify figure_hash
        # each lvl count == 5
        
        queue_entity = new MM_entity
        queue_entity.player     = player
        for unit in data.unit_list
          figure_name = "#{unit.id}_#{unit.level}"
          queue_entity.figure_hash[figure_name]= unit.count
        queue_entity.end_ts     = end_ts
        
        mm_queue_clean_tick()
        
        mm_player_hash[player.id] = queue_entity
        mm_queue.push queue_entity
        
        while mm_queue.length >= 2
          match = new Match
          for i in [0 ... 2]
            mm_player = mm_queue.shift()
            match.match_player_list.push mm_player.to_match_player()
            delete mm_player_hash[mm_player.player.id]
            for figure_name,count of mm_player.figure_hash
              mm_player.player.figure_hash[figure_name] -= count
              [unit_id, level] = figure_name.split("_")
              for i in [0 ... count]
                match.figure_list_by_level_list[level-1].push figure_name
          
          match.full_match_player_list = match.match_player_list.clone()
          match.place_counter = match.match_player_list.length
          
          match.id = active_match_uid++
          active_match_hash[match.id] = match
          
          for player in match.match_player_list
            player2match_hash[player.id] = match
          
          match.notify_all
            switch  : "match_found"
            match   : match.serialize_obj()
        
        return send_res res:"ok"
      
      when "player_start_list_get", "submit_position_hash", "submit_position", "submit_sim_result"
        "skip to match_id check"
      
      else
        return send_err "unknown switch #{data.switch}"
    
    if !match = player2match_hash[player.id]
      return send_err "you are not in active match"
    
    switch data.switch
      # ###################################################################################################
      #    in match
      # ###################################################################################################
      when "match_get" # REDUNDANT durability
        return send_res res : match.serialize_obj()
      
      # when "submit_position_hash" # TODO
      when "submit_position"
        if !match.commit_allowed
          return send_err "!match.commit_allowed"
        for match_player in match.match_player_list
          if match_player.id == player.id
            match_player.commit_state =
              action_list : data.action_list
              final_state : data.final_state
            
        match.check_commit()
        return send_res res : "ok"
      
      when "submit_sim_result"
        for match_player in match.match_player_list
          if match_player.id == player.id
            match_player.commit_simulation_state = data.match
        match.check_commit_simulation()
        return send_res res : "ok"
        # will send "sim_result_consensus"
        # also will remove dead players from match, and get figure reward
      
    # TODO remove player from match
    return
