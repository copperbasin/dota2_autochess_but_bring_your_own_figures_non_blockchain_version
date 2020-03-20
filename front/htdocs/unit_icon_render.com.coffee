module.exports =
  render : ()->
    {unit} = @props
    if unit
      style = {}
      if @props.s
        style = {
          width : 20
          height: 20
        }
      if @props.l
        style = {
          width : 60
          height: 60
        }
      if @props.xl
        style = {
          width : 80
          height: 80
        }
      if @props.xxl
        style = {
          width : 100
          height: 100
        }
      img {
        src : "img/dota/#{unit.type}_icon.png"
        style
      }
    else
      img
      
  