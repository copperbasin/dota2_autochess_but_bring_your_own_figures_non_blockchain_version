class window.Board_battle_controller
  state : null # emulator.State
  request_emulator_step_fn : null # remplaceable
  
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
    # TODO
    return
  
  
  # ###################################################################################################
  #    fg
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
    sx = 30
    sy = 30
    sx_2 = sx/2
    sy_2 = sy/2
    
    hp_bar_xpad = 10
    hp_bar_sx = battle_board_cell_size_px - 2*hp_bar_xpad
    hp_bar_sy = 5
    
    hp_bar_ox = -battle_board_cell_size_px_2 + hp_bar_xpad
    hp_bar_oy = -battle_board_cell_size_px_2/2
    # ###################################################################################################
    
    for unit in @state.unit_list
      {side} = unit
      x = unit.x*battle_board_cell_size_unit2px
      y = unit.y*battle_board_cell_size_unit2px
      # TODO z scale
      img = unit_type2image_hash[unit.type]
      
      if !img.loaded
        ctx.fillStyle = "#ff0"
        ctx.fillRect x-sx_2, y-sy_2, sx, sy
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
  #    unused handlers
  # ###################################################################################################
  key_down    : ()->
  key_up      : ()->
  key_press   : ()->
  
  mouse_move  : ()->
  mouse_out   : ()->
  mouse_down  : ()->
  mouse_up    : ()->
  mouse_click : ()->
  focus_out   : ()->
  mouse_wheel : ()->
  