module.exports =
  render : ()->
    button {
      class : @props.class
      style : @props.style
      disabled : @props.disabled
      on_click : ()=>
        @props.on_click?()
    }, @props.label