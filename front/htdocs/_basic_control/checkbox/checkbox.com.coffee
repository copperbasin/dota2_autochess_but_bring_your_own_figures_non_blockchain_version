module.exports =
  render : ()->
    div
      input {
        type      : "checkbox"
        checked   : @props.value or false
        on_change : @on_change
        style     : @props.style or {}
      }
      @props.children or @props.label
    
  on_change : (event)->
    value = !!event.target.checked
    @props.on_change(value)
    return
  