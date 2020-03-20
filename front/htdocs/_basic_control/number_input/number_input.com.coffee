module.exports =
  render : ()->
    # WARNING эта хуйня не понимает нормально точку
    div
      input {
        type        : "number"
        value       : @text
        on_change   : @on_change
        placeholder : @props.placeholder or ''
        pattern     : "-?[0-9]*([\.,][0-9]*)?"
        # pattern     : "^[-0-9\.,]*$"
        step        : @props.step or 1
        style       : @props.style or {}
      }
  props_change : (props)->
    return if props.value == @props.value
    return if props.value == parseFloat @text
    @set_text props
    
  set_text : (props)->
    if props.value?
      if isNaN props.value
        @text = ''
        return
      @text = props.value.toString()
    return
    
  
  mount : ()->
    @set_text @props
    @force_update()
    return
  on_change : (event)->
    value = event.target.value
    @text = value
    @force_update()
    num_value = parseFloat value
    if @props.can_empty and value == ''
      @props.on_change(num_value)
      return
      
    return if isNaN num_value
    @props.on_change?(num_value)
    return
  