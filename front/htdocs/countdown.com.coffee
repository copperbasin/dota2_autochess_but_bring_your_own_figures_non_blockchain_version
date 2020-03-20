module.exports =
  interval : null
  start_ts : 0
  mount : ()->
    @start_ts = @props.start_ts or Date.now()
    @interval = setInterval ()=>
      @force_update()
    , 100
  
  unmount : ()->
    clearInterval @interval
  
  render : ()->
    left_ts = Math.max 0, @props.ts - (Date.now() - @start_ts)
    span left_ts//1000
  