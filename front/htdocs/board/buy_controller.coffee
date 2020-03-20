class window.Board_buy_controller
  state : null # emulator.State
  request_emulator_step_fn : null # remplaceable
  on_change : null
  
  init:()->
  
  # ###################################################################################################
  #    Draw
  # ###################################################################################################
  $canvas_bg : null
  $canvas_fg : null
  $canvas_hover : null
  canvas_controller: (canvas_hash)->
    @has_redraw_changes_bg    = true if $canvas_bg    != canvas_hash.bg
    @has_redraw_changes_fg    = true if $canvas_fg    != canvas_hash.fg
    @has_redraw_changes_hover = true if $canvas_hover != canvas_hash.hover
    return if !@$canvas_bg = $canvas_bg = canvas_hash.bg
    return if !@$canvas_fg = $canvas_fg = canvas_hash.fg
    return if !@$canvas_hover = $canvas_hover = canvas_hash.hover
    @redraw_bg()
    @redraw_fg()
    @redraw_hover()
  
  props_update: (props)->
    
  
  refresh: ()->
    @has_redraw_changes_fg = true
  
  # ###################################################################################################
  #    layer  bg
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
    
    # ###################################################################################################
    #    main board
    # ###################################################################################################
    # top left should be white
    # draw white
    ctx.fillStyle = "#eee"
    for grid_x in [0 ... 8]
      for grid_y in [0 ... 8]
        continue if (grid_x + grid_y) % 2 == 1
        x = grid_x*battle_board_cell_size_px
        y = grid_y*battle_board_cell_size_px
        ctx.fillRect x, y, battle_board_cell_size_px, battle_board_cell_size_px
    
    # draw black
    ctx.fillStyle = "#555"
    for grid_x in [0 ... 8]
      for grid_y in [0 ... 8]
        continue if (grid_x + grid_y) % 2 == 0
        x = grid_x*battle_board_cell_size_px
        y = grid_y*battle_board_cell_size_px
        ctx.fillRect x, y, battle_board_cell_size_px, battle_board_cell_size_px
    
    
    # border
    ctx.strokeStyle = "#555"
    ctx.lineWidth = 1
    ctx.beginPath()
    x = 8*battle_board_cell_size_px-2
    y = 8*battle_board_cell_size_px-1
    # 0.5 anti-anti-aliasing
    ctx.moveTo 0+0.5, 0+0.5
    ctx.lineTo x+0.5, 0+0.5
    ctx.lineTo x+0.5, y+0.5
    ctx.lineTo 0+0.5, y+0.5
    ctx.lineTo 0+0.5, 0+0.5
    ctx.closePath()
    ctx.stroke()
    
    # ###################################################################################################
    #    spare bench
    # ###################################################################################################
    grid_y = 8
    
    # top left should be white
    # draw white
    ctx.fillStyle = "#eee"
    for grid_x in [0 ... 8]
      continue if (grid_x + grid_y) % 2 == 1
      x = grid_x*battle_board_cell_size_px
      y = grid_y*battle_board_cell_size_px + battle_board_cell_size_px_2
      ctx.fillRect x, y, battle_board_cell_size_px, battle_board_cell_size_px
    
    # draw black
    ctx.fillStyle = "#555"
    for grid_x in [0 ... 8]
      continue if (grid_x + grid_y) % 2 == 0
      x = grid_x*battle_board_cell_size_px
      y = grid_y*battle_board_cell_size_px + battle_board_cell_size_px_2
      ctx.fillRect x, y, battle_board_cell_size_px, battle_board_cell_size_px
    
    # border
    ctx.strokeStyle = "#555"
    ctx.lineWidth = 1
    ctx.beginPath()
    x = 8*battle_board_cell_size_px-2
    y0= 8.5*battle_board_cell_size_px-1
    y = 9.5*battle_board_cell_size_px-1
    # 0.5 anti-anti-aliasing
    ctx.moveTo 0+0.5, y0 + 0.5
    ctx.lineTo x+0.5, y0 + 0.5
    ctx.lineTo x+0.5, y  + 0.5
    ctx.lineTo 0+0.5, y  + 0.5
    ctx.lineTo 0+0.5, y0 + 0.5
    ctx.closePath()
    ctx.stroke()
    
    # ###################################################################################################
    #    hover
    # ###################################################################################################
    if @mode_move and @_last_hover_cell
      {x,y} = @_last_hover_cell
      if y > 3
        y += 0.5 if y == 8
        x *= battle_board_cell_size_px
        y *= battle_board_cell_size_px
        ctx.fillStyle = "#ff0"
        ctx.fillRect x, y, battle_board_cell_size_px, battle_board_cell_size_px
      
    
    return
  
  
  # ###################################################################################################
  #    layer fg
  # ###################################################################################################
  has_redraw_changes_fg : true
  redraw_fg: ()->
    if @request_emulator_step_fn?
      if @request_emulator_step_fn(@state)
        @has_redraw_changes_fg = true
    return if !@has_redraw_changes_fg
    @has_redraw_changes_fg = false
    
    return if !@state
    canvas = @$canvas_fg
    ctx = canvas.getContext "2d"
    # WTF clear
    canvas.width  = canvas.width
    canvas.height = canvas.height
    
    # ###################################################################################################
    #    TODO MOVE config
    # ###################################################################################################
    # icon
    # TODO refactor
    sx = board_icon_sx
    sy = board_icon_sy
    sx_2 = sx/2
    sy_2 = sy/2
    
    hp_bar_xpad = 10
    hp_bar_sx = battle_board_cell_size_px - 2*hp_bar_xpad
    hp_bar_sy = 5
    
    hp_bar_ox = -battle_board_cell_size_px_2 + hp_bar_xpad
    hp_bar_oy = -battle_board_cell_size_px_2/2
    # ###################################################################################################
    
    for id, unit of @state.final_state.board_unit_hash
      {side} = unit
      x = unit.x*battle_board_cell_size_px + battle_board_cell_size_px_2
      y = unit.y*battle_board_cell_size_px + battle_board_cell_size_px_2
      if unit.y == 8
        y += battle_board_cell_size_px_2
      # TODO z scale
      img = unit_type2image_hash[unit.type]
      
      if unit.is_hover
        ctx.strokeStyle = "#ee0"
        ctx.lineWidth = 5
        ctx.strokeRect x-battle_board_cell_size_px_2, y-battle_board_cell_size_px_2, battle_board_cell_size_px, battle_board_cell_size_px
      
      if @mode_move and unit == @drag_unit
        ctx.strokeStyle = "#0e0"
        ctx.lineWidth = 5
        ctx.strokeRect x-battle_board_cell_size_px_2, y-battle_board_cell_size_px_2, battle_board_cell_size_px, battle_board_cell_size_px
        
      
      if !img.loaded
        ctx.fillStyle = "#ff0"
        ctx.fillRect x-sx_2, y-sy_2, sx, sy
        @has_redraw_changes_fg = true
      else
        ctx.drawImage img, x-sx_2, y-sy_2
      
      
      # hp bar
      switch side
        when 0
          ctx.fillStyle = "#0f0"
        when 1
          ctx.fillStyle = "#f00"
      
      hp_ratio = unit.hp100/unit.hp_max100
      ctx.fillRect x+hp_bar_ox, y+hp_bar_oy, hp_bar_sx*hp_ratio, hp_bar_sy
      
    
    return
  
  # ###################################################################################################
  #    layer hover
  # ###################################################################################################
  has_redraw_changes_hover : true
  redraw_hover : ()->
    return if !@has_redraw_changes_hover
    @has_redraw_changes_hover = false
    canvas = @$canvas_hover
    ctx = canvas.getContext "2d"
    # WTF clear
    canvas.width  = canvas.width
    canvas.height = canvas.height
    
    return if !@mode_move
    
    sx = board_icon_sx
    sy = board_icon_sy
    sx_2 = sx/2
    sy_2 = sy/2
    
    img = unit_type2image_hash[@drag_unit.type]
    
    if !img.loaded
      @has_redraw_changes_hover = true
      return
    
    x = @_last_x
    y = @_last_y
    
    ctx.drawImage img, x-sx_2, y-sy_2
    
    return
  
  # ###################################################################################################
  #    hover helper
  # ###################################################################################################
  mode_move : false
  drag_unit : null
  
  _last_hover_cell : null # {x,y,unit?}
  _last_x : 0
  _last_y : 0
  get_hover_cell : (event)->
    {x:mx,y:my} = rel_mouse_coords event
    @_last_x = mx
    @_last_y = my
    # suboptimal. Bruteforce all UI elements
    
    for col, grid_x in @state.final_state.board_place_mx
      x0= grid_x*buy_board_cell_size_px
      x1= x0 + buy_board_cell_size_px
      for value, grid_y in col
        y0 = grid_y*buy_board_cell_size_px
        y0 += buy_board_cell_size_px_2 if grid_y == 8
        y1= y0 + buy_board_cell_size_px
        
        if (x0 < mx < x1) and (y0 < my < y1)
          return {
            x : grid_x
            y : grid_y
            unit : value
          }
      
    return null
  
  hover_cell_cmp : (a, b)->
    return false if !!a != !!b
    return true if !a
    
    return false if a.x != b.x
    return false if a.y != b.y
    return false if a.unit?.id != b.unit?.id
    true
  
  # ###################################################################################################
  #    handlers
  # ###################################################################################################
  
  mouse_move  : (event)->
    hover_cell = @get_hover_cell event
    if hover_change = !@hover_cell_cmp @_last_hover_cell, hover_cell
      @_last_hover_cell?.unit?.is_hover = false
      hover_cell?.unit?.is_hover = true
      
      @_last_hover_cell = hover_cell
      @has_redraw_changes_fg = true
    
    if @mode_move
      @has_redraw_changes_hover = true
      if hover_change
        @has_redraw_changes_bg = true
    
    return
  
  mouse_out   : ()->
    if @_last_hover_cell?
      @_last_hover_cell?.unit?.is_hover = false
      @_last_hover_cell = null
      @has_redraw_changes_fg = true
    return
  
  mouse_down  : ()->
    hover_cell = @get_hover_cell event
    return if !hover_cell?.unit
    @mode_move = true
    @drag_unit = hover_cell.unit
    @has_redraw_changes_fg = true
  
  _drag_finish : ()->
    @mode_move = false
    @drag_unit = null
    @has_redraw_changes_fg = true
    @has_redraw_changes_bg = true
    @has_redraw_changes_hover = true
    
  mouse_up    : (event)->
    return if !@mode_move
    
    hover_cell = @get_hover_cell event
    if !hover_cell or hover_cell.y <= 3
      return @_drag_finish()
    
    if hover_cell.x == @drag_unit.x and hover_cell.y == @drag_unit.y
      return @_drag_finish()
    
    
    # add action
    action = new Player_action
    
    if dst_unit = @state.final_state.board_place_mx[hover_cell.x][hover_cell.y]
      action.type = Player_action.SWAP
      action.unit_id = @drag_unit.id
      action.unit_id2= dst_unit.id
      action.x  = @drag_unit.x
      action.y  = @drag_unit.y
      action.x2 = dst_unit.x
      action.y2 = dst_unit.y
    else
      action.type = Player_action.MOVE
      action.unit_id = @drag_unit.id
      action.x = hover_cell.x
      action.y = hover_cell.y
    
    try
      @state.action_add action
      @on_change?()
    catch err
      perr err
    
    @_drag_finish()
    
    @mouse_move event
  
  
  # ###################################################################################################
  #    unused handlers
  # ###################################################################################################
  key_down    : ()->
  key_up      : ()->
  key_press   : ()->
  
  mouse_click : ()->
  focus_out   : ()->
  mouse_wheel : ()->
  