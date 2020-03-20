window.rand_seed = 1

rand_a   = 16807
rand_b   = 0
rand_mod = (2**31 - 1)

window._rand = ()->
  window.rand_seed = (rand_a*window.rand_seed + rand_b) % rand_mod
  
window.rand_range = (a, b)->
  val = _rand()
  (val % (b-a+1)) + a
  
window.rand_list = (list)->
  # idx = rand_range(0, list.length- 1)
  val = _rand()
  idx = (val % list.length)
  list[idx]

window.__debug_rand_test = (n = 100000)->
  for max in [1 ... 20]
    hash = {}
    for i in [0 ... n]
      key = rand_range(0, max)
      hash[key] ?= 0
      hash[key]++
    
    kv_list = []
    for k,v of hash
      kv_list.push {k,v}
    
    kv_list.sort (a,b)->a.v-b.v
    kv_list = kv_list.map ({k, v})-> {k, v: (1-v/(n/(max+1))).toFixed(2)}
    console.table kv_list
  return
