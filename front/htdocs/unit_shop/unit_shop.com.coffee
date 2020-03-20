module.exports =
  state : {
    filter_level        : 'none'
    filter_only_combo   : "false" # NOT used now
    filter_class_list   : []
    filter_spec_list    : []
    
    balance : -1
    # key id
    # to buy
    to_buy_unit_hash  : {}
    
    buy_in_progress   : false
    buy_status        : ''
  }
  
  check_same : (t)->
    for unit in @props.available_unit_list
      return true if t.type == unit.type
    false
  
  check_class : (t)->
    for unit in @props.available_unit_list
      continue if t.type == unit.type
      return true if t.class == unit.class
    false
  
  check_spec : (t)->
    for unit in @props.available_unit_list
      continue if t.type == unit.type
      return true if t.spec == unit.spec
    false
  
  
  listener_balance: null
  listener_price  : null
  listener_count  : null
  mount: ()->
    # TODO throttle
    ton.on "balance", @listener_balance = (balance)=>
      @set_state {balance}
    ton.on "price_update", @listener_price = ()=>
      @force_update()
    ton.on "count_update", @listener_count = ()=>
      @force_update()
  
  unmount : ()->
    ton.off "balance",      @listener_balance
    ton.off "price_update", @listener_price
    ton.off "count_update", @listener_count
  
  buy : ()->
    @set_state {buy_in_progress: true}
    old_owned_hash = clone ton.owned_hash
    await call_later defer()
    
    id_list = []
    for id,count of @state.to_buy_unit_hash
      id_list.push +id
      ws_ton.write {
        player_id : localStorage.player_id
        switch  : "buy_unit"
        id      : id
        level   : ton.unit_price_hash[id].level
        count
      }
    
    await setTimeout defer(), 1000
    successful = false
    for retry in [0 ... 30]
      # debugger
      ton.unit_count_request id_list
      await setTimeout defer(), 1000
      
      to_buy_unit_hash = clone @state.to_buy_unit_hash
      change_count = 0
      for k,old_val of old_owned_hash
        new_val = ton.owned_hash[k]
        continue if new_val.count == old_val.count
        diff = new_val.count - old_val.count
        if diff > 0
          old_owned_hash[k] = new_val
          change_count++
        to_buy_unit_hash[k] -= diff
      
      puts "change_count=#{change_count}"
      continue if change_count == 0
      
      @set_state {to_buy_unit_hash}
      await call_later defer()
      buy_left = 0
      for k,v of @state.to_buy_unit_hash
        buy_left += v
      puts "buy_left=#{buy_left}"
      if buy_left == 0
        successful = true
        break
    
    @set_state {
      buy_in_progress : false
      buy_status      : if successful then 'successful' else 'failed'
    }
    return
  
  render : ()->
    filter_level        = if @state.filter_level == 'none' then null else +@state.filter_level.trim()
    filter_only_combo   = JSON.parse @state.filter_only_combo
    
    table {
      class: "h_layout_table reset_font center_pad"
      style:
        width : 420+650
    }
      tbody
        tr
          td {colSpan: 2}
            level_count_owned_hash = {
              1:0
              2:0
              3:0
              4:0
              5:0
            }
            level_count_equipped_hash = {
              1:0
              2:0
              3:0
              4:0
              5:0
            }
            for unit in unit_list
              if count = ton.owned_hash[unit.id]?.count
                level_count_owned_hash[unit.level] += count
                if equip_count = ton.unit_battle_hash[unit.id]
                  equip_count = Math.min equip_count, count
                  level_count_equipped_hash[unit.level] += equip_count
            
            puts level_count_equipped_hash
            
            table {class: "table center_pad"}
              tr
                th {rowSpan:4}, "Your figures by level"
                th "Level"
                for level in [1 .. 5]
                  td level
              tr
                th "Count"
                for level in [1 .. 5]
                  td level_count_owned_hash[level]
              tr
                th "Owned"
                for level in [1 .. 5]
                  td
                    # TODO component
                    if level_count_owned_hash[level] >= min_figure_match_count
                      img {
                        class : "s_icon"
                        src : "img/yes.png"
                      }
                    else
                      img {
                        class : "s_icon"
                        src : "img/no.png"
                      }
              tr
                th
                  span "Bring to battle "
                  Button {
                    label : "All"
                    on_click : ()=>
                      for id,unit of ton.owned_hash
                        ton.unit_battle_hash[id] = unit.count
                      ton.save()
                      @force_update()
                  }
                for level in [1 .. 5]
                  td
                    # TODO component
                    if level_count_equipped_hash[level] >= min_figure_match_count
                      img {
                        class : "s_icon"
                        src : "img/yes.png"
                      }
                    else
                      img {
                        class : "s_icon"
                        src : "img/no.png"
                      }
        tr
          td {
            style:
              width: 320
          }
            table
              tbody
                tr
                  td {class:"shop_filter_title"}, "Level"
                  td {
                    class:"shop_filter_value"
                    style:
                      width: 300
                  }
                    Tab_bar {
                      hash : {
                        # DO NOT DELETE SPACE
                        'none': 'None'
                        ' 1': '1'
                        ' 2': '2'
                        ' 3': '3'
                        ' 4': '4'
                        ' 5': '5'
                      }
                      center : true
                      value: @state.filter_level
                      on_change : (filter_level)=>
                        @set_state {filter_level}
                    }
                # if @props.available_unit_list?
                #   tr
                #     td "Only combo"
                #     td
                #       Tab_bar {
                #         hash : {
                #           'true': 'Yes'
                #           'false': 'No'
                #         }
                #         center : true
                #         value: @state.filter_only_combo
                #         on_change : (filter_only_combo)=>
                #           @set_state {filter_only_combo}
                #       }
                tr
                  td {colSpan: 2}, "Class"
                for _class in class_list
                  do (_class)=>
                    tr {
                      on_click : (include)=>
                        {filter_class_list} = @state
                        if filter_class_list.has _class.name
                          filter_class_list.remove _class.name
                        else
                          filter_class_list.push _class.name
                        @set_state {filter_class_list}
                    }
                      td {class:"shop_filter_title", colSpan:2}
                        # TODO better checkbox
                        Checkbox {
                          label : _class.display_name
                          value : @state.filter_class_list.has _class.name
                          on_change : (include)=>
                            {filter_class_list} = @state
                            if include
                              filter_class_list.push _class.name
                            else
                              filter_class_list.remove _class.name
                            @set_state {filter_class_list}
                        }
                tr
                  td {colSpan: 2}, "Spec"
                for spec in spec_list
                  do (spec)=>
                    tr {
                      on_click : (include)=>
                        {filter_spec_list} = @state
                        if filter_spec_list.has spec.name
                          filter_spec_list.remove spec.name
                        else
                          filter_spec_list.push spec.name
                        @set_state {filter_spec_list}
                    }
                      td {class:"shop_filter_title", colSpan: 2}
                        # TODO better checkbox
                        Checkbox {
                          label : spec.display_name
                          value : @state.filter_spec_list.has spec.name
                          on_change : (include)=>
                            {filter_spec_list} = @state
                            if include
                              filter_spec_list.push spec.name
                            else
                              filter_spec_list.remove spec.name
                            @set_state {filter_spec_list}
                        }
                tr
                  td {colSpan : 2}
                    total_count = 0
                    total_cost  = 0
                    for id,v of @state.to_buy_unit_hash
                      if price = ton.unit_price_hash[id]?.price
                        total_cost += v*price
                        total_count += v
                    div "Total cost: #{(total_cost*1e-9).toFixed(9)}"
                    if @state.buy_in_progress
                      Start_button {
                        disabled: true
                        label: "Buy in progress"
                      }
                    else if total_count == 0
                      Start_button {
                        disabled: true
                        label: "Buy"
                      }
                    else
                      Start_button {
                        label: "Buy #{total_count}"
                        on_click : ()=>@buy()
                      }
                    switch @state.buy_status
                      when "successful"
                        span "successful"
                      when "failed"
                        span "failed"
          td {
            style:
              width: 650
          }
            div {
              class: "scroll_container"
              style:
                height: 753
            }
              colSpan = 9
              table {class:"table shop_table"}
                tbody
                  tr
                    th {
                      style:
                        width: 22
                    }
                    th {
                      style:
                        width: 120
                    }, "Name"
                    th "Lvl"
                    th "Class"
                    th "Spec"
                    th "Bring to battle"
                    th "Owned"
                    th "Price (nano)"
                    th "To buy"
                  limit = @props.limit or 14 # any level fits
                  left = limit
                  for unit in @props.shop_unit_list
                    continue if filter_level?         and unit.level != filter_level
                    if @props.available_unit_list?
                      # NOT USED now
                      check_same  = @check_same  unit
                      check_class = @check_class unit
                      check_spec  = @check_spec  unit
                      continue if filter_only_combo and (!check_class and !check_spec)
                    else
                      check_same = check_class = check_spec = false
                    
                    need_check = @state.filter_spec_list.length or @state.filter_class_list.length
                    pass = false
                    pass = true if @state.filter_spec_list.length and @state.filter_spec_list.has unit.spec
                    pass = true if @state.filter_class_list.length and @state.filter_class_list.has unit.class
                    continue if need_check and !pass
                    
                    if left == 0
                      tr
                        td {colSpan}, "use filters"
                      break
                    left--
                    default_class = ""
                    
                    tr
                      td {class : default_class}
                        Unit_icon_render {unit, s:true}
                      td {class: if check_same then "check_pass" else default_class}
                        unit.display_name
                      td {class : default_class}
                        unit.level
                      td {class: if check_class then "check_pass" else default_class}
                        unit.class
                      td {class: if check_spec then "check_pass" else default_class}
                        unit.spec
                      td {class: default_class}
                        do (unit)=>
                          Number_input {
                            value : ton.unit_battle_hash[unit.id] or 0
                            on_change : (value)=>
                              ton.unit_battle_hash[unit.id] = value
                              ton.save()
                              @force_update()
                          }
                      td {class: default_class}
                        if ton.owned_hash[unit.id]?
                          ton.owned_hash[unit.id].count
                        else
                          "?"
                      td {class: default_class}
                        ton.unit_price_hash[unit.id]?.price or "?"
                      td {class: default_class}
                        do (unit)=>
                          Number_input {
                            value : @state.to_buy_unit_hash[unit.id] or 0
                            on_change : (value)=>
                              value = 0 if value < 0 # плохо работает, но хотя бы так
                              to_buy_unit_hash = clone @state.to_buy_unit_hash
                              to_buy_unit_hash[unit.id] = value
                              @set_state {to_buy_unit_hash}
                          }
                  if left == limit
                    tr
                      td {colSpan}, "No units"
  