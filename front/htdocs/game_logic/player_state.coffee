window.exp2lvl = (exp)->
  # пока тут отфонарные константы
  return 1 if 0 >= (exp -= 1  )
  return 2 if 0 >= (exp -= 2  )
  return 3 if 0 >= (exp -= 4  )
  return 4 if 0 >= (exp -= 8  )
  return 5 if 0 >= (exp -= 16 )
  return 6 if 0 >= (exp -= 32 )
  return 7 if 0 >= (exp -= 64 )
  return 8 if 0 >= (exp -= 128)
  return 9 if 0 >= (exp -= 256)
  
  return 10
  
class window.Shop_unit
  id        : 0 # REDUNDANT
  type      : ""
  lvl       : 0
  is_bought : false
  is_hover  : false
  
  clone : ()->
    ret = new Shop_unit
    ret.id        = @id        
    ret.type      = @type      
    ret.lvl       = @lvl       
    ret.is_bought = @is_bought 
    ret.is_hover  = @is_hover  
    ret

class window.Game_unit
  id        : 0
  type      : ""
  x         : 0
  y         : 0
  lvl       : 0
  star_lvl  : 1
  
  # do not clone
  is_hover  : false
  
  clone : ()->
    ret = new Game_unit
    ret.id        = @id        
    ret.type      = @type      
    ret.x         = @x         
    ret.y         = @y         
    ret.lvl       = @lvl       
    ret.star_lvl  = @star_lvl  
    ret
  
  serialize_obj : ()->
    ret = {}
    ret.id        = @id        
    ret.type      = @type      
    ret.x         = @x         
    ret.y         = @y         
    ret.lvl       = @lvl       
    ret.star_lvl  = @star_lvl  
    ret
  
  deserialize_obj : (obj)->
    @id        = obj.id        
    @type      = obj.type      
    @x         = obj.x         
    @y         = obj.y         
    @lvl       = obj.lvl       
    @star_lvl  = obj.star_lvl  
    return
  
  cmp : (t)->
    return false if @id        != t.id        
    return false if @type      != t.type      
    return false if @x         != t.x         
    return false if @y         != t.y         
    return false if @lvl       != t.lvl       
    return false if @star_lvl  != t.star_lvl  
    true
  

class @window.Player_cross_round_state
  seed  : 0 # REDUNDANT, based on external
  
  hp    : 100
  gold  : 1
  exp   : 1
  lvl   : 1 # REDUNDANT, derived from exp
  
  free_unit_id : 0
  board_unit_hash : {} # {id,x,y,type,star_lvl}[]
  # TODO board
  # TODO shop (based on seed and pool)
  
  # REDUNDANT for fast place check
  # [no holes][can have holes], so [x][y] will always work in range
  board_place_mx : [] # [x][y] -> {id,x,y,type,star_lvl}
  
  shop_unit_list : [] # Shop_unit
  
  
  is_valid : true
  
  constructor:()->
    @board_unit_hash= {}
    # @board_unit_list= []
    @board_place_mx = []
    for i in [0 ... 8]
      @board_place_mx.push col = []
      for j in [0 ... 9]
        col.push null
    
    @shop_unit_list = []
  
  clone : ()->
    ret = new Player_cross_round_state
    ret.hp    = @hp    
    ret.gold  = @gold  
    ret.exp   = @exp   
    ret.lvl   = @lvl   
    
    ret.free_unit_id   = @free_unit_id   
    
    for id, unit of @board_unit_hash
      ret.board_unit_hash[id] = unit.clone()
    
    for col,x in @board_place_mx
      ret_col = ret.board_place_mx[x]
      for unit,y in col
        continue if !unit
        ret_col[y] = ret.board_unit_hash[unit.id]
    
    for unit in @shop_unit_list
      ret.shop_unit_list.push unit.clone()
    ret
  
  serialize_json : ()->
    ret = {}
    ret.hp    = @hp    
    ret.gold  = @gold  
    ret.exp   = @exp   
    ret.lvl   = @lvl   
    ret.free_unit_id   = @free_unit_id   
    
    ret.board_unit_hash = {}
    for id, unit of @board_unit_hash
      ret.board_unit_hash[id] = unit.serialize_obj()
    
    JSON.stringify ret
  
  deserialize_json : (json)->
    obj = JSON.parse json
    
    @hp    = obj.hp    
    @gold  = obj.gold  
    @exp   = obj.exp   
    @lvl   = obj.lvl   
    @free_unit_id   = obj.free_unit_id   
    
    @board_unit_hash = {}
    for id, unit of obj.board_unit_hash
      new_unit = new Game_unit
      new_unit.deserialize_obj(unit)
      @board_unit_hash[id] = new_unit
    
    return
  
  cmp : (t)->
    return false if @hp    != t.hp    
    return false if @gold  != t.gold  
    return false if @exp   != t.exp   
    return false if @lvl   != t.lvl   
    return false if @free_unit_id   != t.free_unit_id   
    
    # немного затратно, но немного меньше кода
    return false if Object.keys(@board_unit_hash).join() != Object.keys(t.board_unit_hash).join()
    
    for id, unit of @board_unit_hash
      t_unit = t.board_unit_hash[id]
      return false if !unit.cmp t_unit
    
    true
  # ###################################################################################################
  
  valid_calc : ()->
    @is_valid = @_valid_calc()
  
  _valid_calc : ()->
    return false if @gold < 0
    on_board_count = 0
    for id, unit of @board_unit_hash
      if unit.y != 8
        on_board_count++
    return false if on_board_count > @lvl
    
    true
  
  id_compact : ()->
    # reassign
  
  get_empty_space : ()->
    # check spare line only
    y = 8
    for x in [0 ... 8]
      if !@board_place_mx[x][y]
        return [x,y]
    return null
  
  # !!! will make state invalid from invalid action
  action_apply : (action)->
    switch action.type
      when Player_action.BUY
        {x,y} = action
        shop_unit = @shop_unit_list[action.shop_id]
        if !shop_unit
          throw new Error "invalid buy. shop_unit not exists"
        if shop_unit.is_bought
          throw new Error "invalid buy. shop_unit is_bought"
        if shop_unit.lvl > @lvl
          throw new Error "invalid buy. You are buying unit with more lvl than player"
        if @board_place_mx[x][y]
          throw new Error "invalid move. dst x,y is occupied"
        
        # remove from shop (mark as bought)
        shop_unit.is_bought = true
        
        unit = new Game_unit
        unit.id   = @free_unit_id++
        unit.x    = x
        unit.y    = y
        unit.type = shop_unit.type
        unit.lvl  = shop_unit.lvl
        @board_unit_hash[unit.id] = unit
        @board_place_mx[x][y] = unit
        
        @gold -= unit.lvl
      
      when Player_action.SELL
        if !unit = @board_unit_hash[action.unit_id]
          throw new Error "invalid sell. id not exists"
        
        delete @board_unit_hash[unit.id]
        @board_place_mx[unit.x][unit.y] = null
        
        @gold += unit.lvl + (unit.star_lvl - 1)
        # TODO item return
      
      when Player_action.MOVE
        {x,y} = action
        if !unit = @board_unit_hash[action.unit_id]
          throw new Error "invalid move. id not exists"
        
        unless (0 <= x <= 7) and (4 <= y <= 8)
          throw new Error "invalid move. dst x,y out of bounds"
        
        if @board_place_mx[x][y]
          throw new Error "invalid move. dst x,y is occupied"
        
        @board_place_mx[unit.x][unit.y] = null
        
        unit.x = x
        unit.y = y
        
        @board_place_mx[unit.x][unit.y] = unit
      
      when Player_action.SWAP
        if !src_unit = @board_unit_hash[action.unit_id]
          throw new Error "invalid swap. id not exists"
        
        if !dst_unit = @board_unit_hash[action.unit_id2]
          throw new Error "invalid swap. id2 not exists"
        
        # swap pos
        dst_unit_x = src_unit.x
        dst_unit_y = src_unit.y
        
        src_unit_x = dst_unit.x
        src_unit_y = dst_unit.y
        
        # apply pos
        src_unit.x = src_unit_x
        src_unit.y = src_unit_y
        @board_place_mx[src_unit.x][src_unit.y] = src_unit
        
        dst_unit.x = dst_unit_x
        dst_unit.y = dst_unit_y
        @board_place_mx[dst_unit.x][dst_unit.y] = dst_unit
      
      when Player_action.BUY_EXP
        @gold -= 4
        @exp  += 4
        @lvl   = exp2lvl @exp
      
      else
        throw new Error "unknown action"
    @valid_calc()
    if !@is_valid
      throw new Error "intermediate state is not valid"
    return

class window.Player_action
  # ###################################################################################################
  #    enum
  # ###################################################################################################
  enum_counter = 0
  @BUY    : enum_counter++
  @SELL   : enum_counter++
  @MOVE   : enum_counter++
  @SWAP   : enum_counter++
  @BUY_EXP: enum_counter++
  # @MERGE : enum_counter++
  # @ITEM_CHOOSE : enum_counter++
  # @ITEM_ATTACH : enum_counter++
  
  # ###################################################################################################
  type      : -1
  
  shop_id   : -1 # for buy
  shop_cost : -1 # REDUNDANT, derived from shop_id + shop
  
  unit_id   : -1 # for sell, move
  unit_id2  : -1 # for swap
  
  # move, buy
  x         : 0
  y         : 0
  # swap # DO NOT WRITE
  x2        : 0
  y2        : 0
  
  clone : ()->
    ret = new Player_action
    ret.type      = @type      
    ret.shop_id   = @shop_id   
    ret.shop_cost = @shop_cost 
    ret.unit_id   = @unit_id   
    ret.unit_id2  = @unit_id2  
    ret.x         = @x         
    ret.y         = @y         
    ret.x2        = @x2        
    ret.y2        = @y2        
    ret
  
  serialize_obj : ()->
    ret = {}
    # NOT a compact view.
    # switch required
    # TODO make more compact
    ret.type      = @type      
    ret.shop_id   = @shop_id   
    ret.shop_cost = @shop_cost 
    ret.unit_id   = @unit_id   
    ret.unit_id2  = @unit_id2  
    ret.x         = @x         
    ret.y         = @y         
    ret.x2        = @x2        
    ret.y2        = @y2        
    ret
  
  deserialize_obj : (obj)->
    @type      = obj.type      
    @shop_id   = obj.shop_id   
    @shop_cost = obj.shop_cost 
    @unit_id   = obj.unit_id   
    @unit_id2  = obj.unit_id2  
    @x         = obj.x         
    @y         = obj.y         
    @x2        = obj.x2        
    @y2        = obj.y2        
    return

class @window.Player_intermediate_state
  start_state : null # Player_cross_round_state
  final_state : null # Player_cross_round_state
  action_list : []
  
  constructor:()->
    @action_list = []
  
  final_state_calc : ()->
    state = @start_state.clone()
    
    for action in @action_list
      # try action_apply
      state.action_apply action
    
    @final_state = state
  
  action_add : (action)->
    # try action_apply
    state = @final_state.clone()
    state.action_apply action
    
    @action_list.push action
    @final_state = state
  
  action_list_serialize_json : ()->
    action_list = []
    for action in @action_list
      action_list.push action.serialize_obj()
    JSON.stringify action_list
  
  action_list_deserialize_json : (json)->
    action_list = JSON.parse json
    @action_list.clear()
    for action in action_list
      new_action = new Player_action
      new_action.deserialize_obj(action)
      @action_list.push new_action
    return
  
  final_state_serialize_json : ()->
    @final_state.serialize_json()
  
  # final_state_deserialize_json : (json)->
    # @final_state.deserialize_json(json)
  