module.exports =
  render : ()->
    {value, max, color} = @props
    color ?= "#000"
    progress {
      value : value
      max   : max
    }, "#{value}"
    div {class: "progress"}
      div {
        class : "progress_fill"
        style:
          width : "#{Math.round 100*value/max}%"
          background : color
      }
      div { class: "progress_label" }, "#{value}"