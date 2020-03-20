class window.Shop_controller
  state : null # hero_list (will be automatically splitted by 5)
  on_board_change_fn : null # replaceable
  on_change : null
  
  init:()->
  # ###################################################################################################
  #    Draw
  # ###################################################################################################
  $canvas_bg : null
  $canvas_fg : null
  canvas_controller: (canvas_hash)->
    return if !@$canvas_bg = $canvas_bg = canvas_hash.bg
    return if !@$canvas_fg = $canvas_fg = canvas_hash.fg
    @redraw_bg()
    @redraw_fg()
  
  props_update: (props)->
    
  
  refresh: ()->
    @has_redraw_changes_fg = true
  
  # ###################################################################################################
  #    bg
  # ###################################################################################################
  has_redraw_changes_bg : true
  redraw_bg: ()->
    return if !@has_redraw_changes_bg
    @has_redraw_changes_bg = false
    canvas = @$canvas_bg
    ctx = canvas.getContext "2d"
    # WTF clear
    canvas.width  = canvas.width
    canvas.height = canvas.height
    
    return
  
  
  # ###################################################################################################
  #    fg
  # ###################################################################################################
  has_redraw_changes_fg : true
  redraw_fg: ()->
    return if !@has_redraw_changes_fg
    @has_redraw_changes_fg = false
    canvas = @$canvas_fg
    ctx = canvas.getContext "2d"
    # WTF clear
    canvas.width  = canvas.width
    canvas.height = canvas.height
    
    grid_x = 0
    grid_y = 0
    for cell in @state.final_state.shop_unit_list
      # TODO skip units that you can't buy because of lvl
      
      x = grid_x*shop_cell_size_px
      y = grid_y*shop_cell_size_px
      
      if cell.is_bought
        ctx.fillStyle = "#ff0"
        ctx.fillRect x, y, shop_cell_size_px, shop_cell_size_px
      
      img = unit_type2image_hash[cell.type]
      if !img.loaded
        @has_redraw_changes_fg = true
      
      # TODO include line unlock cost
      cost = cell.lvl
      can_buy = (cost <= @state.final_state.gold) and (cell.lvl <= @state.final_state.lvl)
      
      ctx.globalAlpha = 0.4 if !can_buy
      ctx.drawImage img, x+shop_cell_icon_pad_px, y+shop_cell_icon_pad_px, shop_cell_icon_size_px, shop_cell_icon_size_px
      ctx.globalAlpha = 1 if !can_buy
      
      
      # TODO draw opacity when you can't buy because of gold
      
      grid_x++
      if grid_x >= 5
        grid_x = 0
        grid_y++
    
    # ###################################################################################################
    #    hover
    # ###################################################################################################
    
    grid_x = 0
    grid_y = 0
    for cell in @state.final_state.shop_unit_list
      x = grid_x*shop_cell_size_px
      y = grid_y*shop_cell_size_px
      
      if cell.is_hover
        ctx.strokeStyle = "#000"
        ctx.strokeRect x+1.5, y+1.5, shop_cell_size_px-1, shop_cell_size_px-1
      
      grid_x++
      if grid_x >= 5
        grid_x = 0
        grid_y++
    
    return
  # ###################################################################################################
  #    mouse helpers
  # ###################################################################################################
  _last_hover_cell : null
  get_hover_cell : (event)->
    {x:mx,y:my} = rel_mouse_coords event
    # suboptimal. Bruteforce all UI elements
    
    grid_x = 0
    grid_y = 0
    for cell in @state.final_state.shop_unit_list
      x0 =  1+grid_x*shop_cell_size_px
      y0 =  1+grid_y*shop_cell_size_px
      x1 = -1+(grid_x+1)*shop_cell_size_px
      y1 = -1+(grid_y+1)*shop_cell_size_px
      if (x0 < mx < x1) and (y0 < my < y1)
        return cell
      
      grid_x++
      if grid_x >= 5
        grid_x = 0
        grid_y++
    return null
  
  hover_drop : ()->
    @_last_hover_cell?.is_hover = false
    @_last_hover_cell = null
    @has_redraw_changes_fg = true
    return
    
  
  # ###################################################################################################
  #    handlers
  # ###################################################################################################
  mouse_move  : (event)->
    cell = @get_hover_cell event
    
    if cell != @_last_hover_cell
      @_last_hover_cell?.is_hover = false
      cell?.is_hover = true
      @_last_hover_cell = cell
      @has_redraw_changes_fg = true
    return
  
  mouse_down  : (event)->
    return if !cell = @get_hover_cell event
    
    if !cell.is_bought
      return if cell.lvl > @state.final_state.lvl  # not enough lvl
      return if cell.lvl > @state.final_state.gold # not enough gold
      
      action = new Player_action
      action.type = Player_action.BUY
      action.shop_id = cell.id
      action.shop_cost = cell.lvl
      action.unit_id = @state.final_state.free_unit_id # will be not written in serialized, only for fast sell
      res = @state.final_state.get_empty_space()
      if !res
        perr "out of free space"
        return
      
      [x,y] = res
      action.x = x
      action.y = y
      try
        @state.action_add action
        @on_change?()
      catch err
        perr err
        return
      
      cell.is_bought = true
      @has_redraw_changes_fg = true
      @on_board_change_fn?()
    else
      # try to rewrite history without that buy
      
      new_story = new Player_intermediate_state
      new_story.start_state = @state.start_state
      buy_action = null
      for action in @state.action_list
        if action.type == Player_action.BUY and action.shop_id == cell.id
          buy_action = action
          break
      
      if !buy_action
        perr "!buy_action"
        return
      for action in @state.action_list
        switch action.type
          when Player_action.BUY, Player_action.SELL, Player_action.MOVE
            if action.unit_id != buy_action.unit_id
              new_story.action_list.push action
          when Player_action.SWAP
            if action.unit_id == buy_action.unit_id
              replace_action = new Player_action
              replace_action.type = Player_action.MOVE
              replace_action.unit_id = action.unit_id2
              replace_action.x = action.x
              replace_action.y = action.y
              
              new_story.action_list.push replace_action
            else if action.unit_id2 == buy_action.unit_id
              replace_action = new Player_action
              replace_action.type = Player_action.MOVE
              replace_action.unit_id = action.unit_id
              replace_action.x = action.x2
              replace_action.y = action.y2
              
              new_story.action_list.push replace_action
            else
              new_story.action_list.push action
      
      # patch all actions
      for action,idx in new_story.action_list
        if action.unit_id > buy_action.unit_id
          action = action.clone()
          action.unit_id--
          new_story.action_list[idx] = action
        
        if action.unit_id2 > buy_action.unit_id
          action = action.clone()
          action.unit_id2--
          new_story.action_list[idx] = action
      
      try
        new_story.final_state_calc()
        @on_change?()
      catch err
        perr err
        return
      
      @state.action_list = new_story.action_list
      @state.final_state = new_story.final_state
      
      cell.is_bought = false
      @has_redraw_changes_fg = true
      @on_board_change_fn?()
    
    return
  
  mouse_out   : ()->
    @hover_drop()
  
  focus_out   : ()->
    @hover_drop()
  
  # ###################################################################################################
  #    unused handlers
  # ###################################################################################################
  key_down    : ()->
  key_up      : ()->
  key_press   : ()->
  
  mouse_out   : ()->
  mouse_up    : ()->
  mouse_click : ()->
  
  mouse_wheel : ()->
  