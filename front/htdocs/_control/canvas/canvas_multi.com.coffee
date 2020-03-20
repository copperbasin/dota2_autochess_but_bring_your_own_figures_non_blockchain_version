# TODO touch events. Maybe Hammer
module.exports =
  mounted : false
  mount_done : ()->
    @mounted = true
    draw = ()=>
      return if !@mounted
      @canvas_actualize()
      requestAnimationFrame draw
      canvas_hash = {}
      for name in @props.layer_list
        canvas_hash[name] = @refs[name]
      @props.canvas_cb? canvas_hash
    draw()
    @props.ref_textarea? @refs.textarea
  
  unmount : ()->
    @mounted = false
  
  props_change : ()->
    @props.gui?.refresh()
  
  canvas_actualize : ()->
    canvas_list = []
    for name in @props.layer_list
      continue if !canvas = @refs[name]
      canvas_list.push canvas
    
    {box} = @refs
    {width, height} = box.getBoundingClientRect()
    width = -1 + Math.floor width *devicePixelRatio
    height= -1 + Math.floor height*devicePixelRatio
    for canvas in canvas_list
      if canvas.width != width or canvas.height != height
        canvas.width  = width
        canvas.height = height
    return
  
  render : ()->
    div {
      ref   : "box"
      style :
        width   : "100%"
        height  : "100%"
    }
      for name in @props.layer_list or []
        # div {
          # style:
            # position: "relative"
        # }
          canvas {
            ref   : name
            style :
              position: "absolute"
              # width   : "100%"
              # height  : "100%"
            
            on_click    : @mouse_click
            onMouseDown : @mouse_down
            onMouseUp   : @mouse_up
            onMouseMove : @mouse_move
            onMouseOut  : @mouse_out
            onWheel     : @mouse_wheel
          }
      textarea {
        ref       : "textarea"
        onKeyDown : @key_down
        onKeyUp   : @key_up
        onKeyPress: @key_press
        onBlur    : @focus_out
        style :
          position: "absolute"
          # top     : 0 # DEBUG
          # left    : 0 # DEBUG
          top     : -1000
          left    : -1000
      }
  
  key_down    : (event)->@props.gui?.key_down(event)
  key_up      : (event)->@props.gui?.key_up(event)
  key_press   : (event)->@props.gui?.key_press(event)
  
  mouse_click : (event)->
    @refs.textarea.focus()
    @props.gui?.mouse_click(event)
  
  mouse_down  : (event)->@props.gui?.mouse_down(event)
  mouse_up    : (event)->
    @refs.textarea.focus()
    @props.gui?.mouse_up(event)
  
  mouse_out   : (event)->@props.gui?.mouse_out(event)
  mouse_move  : (event)->@props.gui?.mouse_move(event)
  mouse_wheel : (event)->@props.gui?.mouse_wheel(event)
  focus_out   : (event)->@props.gui?.focus_out(event)
  