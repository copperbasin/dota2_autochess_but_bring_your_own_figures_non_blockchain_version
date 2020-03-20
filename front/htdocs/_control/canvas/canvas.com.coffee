# TODO touch events. Maybe Hammer
module.exports =
  mounted : false
  mount_done : ()->
    @mounted = true
    draw = ()=>
      return if !@mounted
      @canvas_actualize()
      requestAnimationFrame draw
      @props.canvas_cb? @refs.canvas
    draw()
    @props.ref_textarea? @refs.textarea
  
  unmount : ()->
    @mounted = false
  
  props_change : ()->
    @props.gui?.refresh()
  
  canvas_actualize : ()->
    {canvas} = @refs
    if canvas
      {width, height} = canvas.getBoundingClientRect()
      width = Math.floor width *devicePixelRatio
      height= Math.floor height*devicePixelRatio
      if canvas.width != width or canvas.height != height
        canvas.width  = width
        canvas.height = height
    return
  
  render : ()->
    div {
      style:
        width: "100%"
        height: "100%"
    }
      canvas {
        ref : "canvas"
        style:
          width: "100%"
          height: "100%"
        
        on_click    : @mouse_click
        onMouseDown : @mouse_down
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
  mouse_up    : (event)->@props.gui?.mouse_up(event)
  mouse_out   : (event)->@props.gui?.mouse_out(event)
  mouse_move  : (event)->@props.gui?.mouse_move(event)
  mouse_wheel : (event)->@props.gui?.mouse_wheel(event)
  focus_out   : (event)->@props.gui?.focus_out(event)
  