module = emulator
class module.Projectile
  _remove          : false
  _last_update_tick: 0
  @uid        : 0
  
  uid         : 0
  side        : 0
  # ###################################################################################################
  #    position + move
  # ###################################################################################################
  x           : 0
  y           : 0
  
  ms          : 1000
  # TODO ms here
  
  target      : null
  
  # hd = half distance
  hd_next_tick: 0
  
  
  effect      : ()-> # REPLACE ME
  
  constructor : ()->
    @uid = module.Projectile.uid++
  
  assert_cmp : (t)->
    ### !pragma coverage-skip-block ###
    error_list = []
    error_list.push "@uid         != t.uid          #{@uid        } != #{t.uid        }" if @uid          != t.uid         
    error_list.push "@x           != t.x            #{@x          } != #{t.x          }" if @x            != t.x           
    error_list.push "@y           != t.y            #{@y          } != #{t.y          }" if @y            != t.y           
    error_list.push "@side        != t.side         #{@side       } != #{t.side       }" if @side         != t.side        
    error_list.push "@ms          != t.ms           #{@ms         } != #{t.ms         }" if @ms           != t.ms          
    error_list.push "@target.uid  != t.target.uid   #{@target.uid } != #{t.target.uid }" if @target.uid   != t.target.uid  
    
    # error_list.push "@hd_next_tick!= t.hd_next_tick #{@hd_next_tick} != #{t.hd_next_tick}" if @hd_next_tick != t.hd_next_tick
    if error_list.length
      throw new Error error_list.join ";\n"
    
    return
  