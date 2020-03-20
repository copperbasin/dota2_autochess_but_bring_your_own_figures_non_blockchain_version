module.exports =
  state :
    balance : -1
    address : "???"
  
  listener_balance : null
  listener_address : null
  mount : ()->
    bg_change "img/shop_bg.jpg"
    @set_state {
      balance: ton.balance
      address: ton.address
    }
    ton.on "balance", @listener_balance = (balance)=>
      @set_state {balance}
    ton.on "address", @listener_address = (address)=>
      @set_state {address}
    
  unmount : ()->
    ton.off "balance", @listener_balance
    ton.off "address", @listener_address
  
  render : ()->
    div {class: "center pad_top"}
      div {class: "background_pad"}
        div {
          style:
            textAlign:"left"
            position: "abosolute"
        }
          Back_button {
            on_click : ()=>
              router_set "main"
          }
        balance = @state.balance
        if balance == -1
          balance = '?'
        else
          balance = balance.toFixed(9)
        div "Address: #{@state.address}"
        div "Balance: #{balance} gramm"
        Unit_shop {
          # костыль
          available_unit_list : []
          shop_unit_list      : unit_list
          limit               : 100500
        }
  