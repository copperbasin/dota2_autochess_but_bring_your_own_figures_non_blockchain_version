module.exports =
  render : ()->
    table
      tbody
        tr
          td "HP"
          td {
            style:
              width : 80
          }
            Leaderboard_bar {
              value : @props.hp
              max   : 100
              color : "#5F5"
            }
          td "Gold"
          td {
            style:
              width : 80
          }
            Leaderboard_bar {
              value : @props.gold
              max   : 100
              color : "#FE0"
            }
          td "Exp"
          td {
            style:
              width : 80
          }
            Leaderboard_bar {
              value : @props.exp
              max   : 100
              color : "#FE0"
            }
          td {
            class : "lvl_badge"
          }, @props.lvl
