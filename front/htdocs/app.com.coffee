module.exports =
  state : {
    id      : "bg1"
    last_url: ""
    router  : localStorage.router_start or "main"
    bg1 : {
      opacity: 0
    }
    bg2 : {
      opacity: 0
    }
  }
  mount : ()->
    window.bg_change = (new_url)=>
      return if @state.last_url == new_url
      call_later ()=>
        {id} = @state
        state = {
          last_url : new_url
        }
        state[id] =
          background  : "url(#{JSON.stringify new_url})"
          opacity     : 0.65
        id = if id == "bg1" then "bg2" else "bg1"
        state[id] =
          background  : @state[id].background
          opacity     : 0
        state.id = id
        @set_state state
        return
    window.router_set = (router)=>
      @set_state {router}
  
  render : ()->
    div {id: "wrap"}
      div {id: "bg1", style:@state.bg1}
      div {id: "bg2", style:@state.bg2}
      switch @state.router
        when "main"
          Scene_main_screen {}
        when "queue"
          Scene_queue {}
        when "match"
          Scene_match {}
        when "shop"
          Scene_shop {}
        when "demo_battle"
          Scene_demo_battle {}
        when "play_with_bot"
          Scene_play_with_bot {}
      
  