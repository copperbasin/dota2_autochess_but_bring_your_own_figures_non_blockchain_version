str = """
;warrior
;druid
;mage
;hunter
;assasin
;mech
;shaman
;knight
;demon_hunter
;warlock
"""
window.class_list = str.split("\n").map (str)->
  [display_name, name] = str.split(";").map((t)->t.trim())
  display_name = display_name or name.replace(/_/g, " ").capitalize()
  {display_name, name}

str = """
;orc
;beast
;ogre
;undead
;goblin
;troll
;elf
;human
;demon
;elemental
;naga
;dwarf
;dragon
"""
window.spec_list = str.split("\n").map (str)->
  [display_name, name] = str.split(";").map((t)->t.trim())
  display_name = display_name or name.replace(/_/g, " ").capitalize()
  {display_name, name}

str = """
10001;                   ;axe                ;1;warrior       ;orc
10002;                   ;enchantress        ;1;druid         ;beast
10003;                   ;ogre_magi          ;1;mage          ;ogre
10004;                   ;tusk               ;1;warrior       ;beast
10005;                   ;drow_ranger        ;1;hunter        ;undead
10006;                   ;bounty_hunter      ;1;assasin       ;goblin
10007;                   ;clockwerk          ;1;mech          ;goblin
10008;s. shaman          ;shadow_shaman      ;1;shaman        ;troll
10009;                   ;batrider           ;1;knight        ;troll
10010;                   ;tinker             ;1;mech          ;goblin
10011;                   ;anti-mage          ;1;demon_hunter  ;elf
20001;                   ;crystal_maiden     ;2;mage          ;human
20002;                   ;beastmaster        ;2;hunter        ;orc
20003;                   ;juggernaut         ;2;warrior       ;orc
20004;                   ;timbersaw          ;2;mech          ;goblin
20005;                   ;queen_of_pain      ;2;assasin       ;demon
20006;                   ;puck               ;2;mage          ;elf
20007;                   ;witch_doctor       ;2;warlock       ;troll
20008;                   ;slardar            ;2;warrior       ;naga
20009;                   ;chaos_knight       ;2;knight        ;demon
20010;treant p.          ;treant_protector   ;2;druid         ;elf
30001;                   ;luna               ;3;knight        ;elf
30002;                   ;lycan              ;3;warrior       ;hunter
30003;                   ;venomancer         ;3;warlock       ;beast
30004;                   ;omniknight         ;3;knight        ;human
30005;                   ;razor              ;3;mage          ;elemental
30006;                   ;windranger         ;3;hunter        ;elf
30007;phantom a.         ;phantom_assassin   ;3;assasin       ;elf
30008;                   ;abaddon            ;3;knight        ;undead
30009;                   ;sand_king          ;3;assasin       ;beast
30010;                   ;slark              ;3;assasin       ;naga
30011;                   ;sniper             ;3;hunter        ;dwarf
30012;                   ;viper              ;3;assasin       ;dragon
30013;                   ;shadow_fiend       ;3;warlock       ;demon
30014;                   ;lina               ;3;mage          ;human
40001;                   ;doom               ;4;warrior       ;demon
40002;                   ;kunkka             ;4;warrior       ;human
40003;                   ;troll_warlord      ;4;warrior       ;troll
40004;K.O.T.L.           ;keeper_of_the_light;4;mage          ;human
40005;                   ;necrophos          ;4;warlock       ;undead
40006;templar a.         ;templar_assassin   ;4;assasin       ;elf
40007;                   ;alchemist          ;4;warlock       ;goblin
40008;                   ;disruptor          ;4;shaman        ;orc
40009;                   ;medusa             ;4;hunter        ;naga
40010;                   ;dragon_knight      ;4;knight        ;human
50001;                   ;gyrocopter         ;5;mech          ;dwarf
50002;                   ;lich               ;5;mage          ;undead
50003;                   ;tidehunter         ;5;hunter        ;naga
50004;                   ;enigma             ;5;warlock       ;elemental
50005;                   ;techies            ;5;mech          ;goblin
"""
# window.unit_list = str.split("\n").map (str)->
#   [id, display_name, type, level, _class, spec] = str.split(";").map((t)->t.trim())
#   display_name = display_name or type.replace(/_/g, " ")
#   if id
#     id = +id
#   else
#     id = undefined
  
#   level = +level
#   {
#     id
#     display_name
#     type
#     level
#     class: _class
#     spec
#   }

window.dev_script_gen = (opt = {})->
  opt.price ?= 400
  res_list = []
  level_hash = {
    1 : 1
    2 : 1
    3 : 1
    4 : 1
    5 : 1
  }
  for unit in unit_list
    id_lo = level_hash[unit.level]++
    id = 10000*unit.level + id_lo
    id = unit.id or id
    
    res_list.push """
    dictnew prices !
    #{opt.price} create-price
    #{unit.level} add-price
    prices @ create-unit-prices
    #{id} add-units-list
    """
  
  res_list.join "\n\n"

window.unit_type2image_hash = {}
window.unit_id_hash = {}
unit_type_hash = {}
for unit in unit_list
  unit_type_hash[unit.type] = unit
  unit_id_hash[unit.id] = unit
  img = new Image
  do (img)->
    img.onload = ()->
      img.loaded = true
  img.src = "/img/dota/#{unit.type}_icon.png"
  unit_type2image_hash[unit.type] = img
# factory for battle units
window.battle_unit_create = (opt)->
  {
    type
    side
    grid_x
    grid_y
    star_lvl
  } = opt
  if !blueprint = unit_type_hash[type]
    perr "can't create unit #{type}"
    return null
  
  side ?= 0
  # we should not display unit with uninitialized coords
  grid_x ?= -1
  grid_y ?= -1
  
  ret = new emulator.Unit
  ret.x = grid_x*battle_board_cell_size_unit + battle_board_cell_size_unit_2
  ret.y = grid_y*battle_board_cell_size_unit + battle_board_cell_size_unit_2
  ret.side = side
  
  ret.hp100 = blueprint.hp*100
  ret.mp100 = blueprint.mana*100
  # ret.mp_reg100 = blueprint.mana_regen
  
  ret.hp_max100 = ret.hp100
  ret.mp_max100 = ret.mp100
  # TODO support damage random range
  ret.ad100 = blueprint.attack_damage_max*100
  ret.as    = blueprint.attack_rate*100
  ret.ar    = blueprint.attack_range
  ret.ar2   = ret.ar*ret.ar
  ret.armor = blueprint.armor
  
  # user LATER
  ret.spec = blueprint.spec
  ret.class= blueprint.class
  
  ret.type = blueprint.type
  ret.display_name = blueprint.display_name
  ret.move_type = blueprint.move_type
  
  # TODO fix me
  ret.fsm_ref = emulator.fsm_craft {attack_type: "melee"}
  
  # inject
  ret.star_lvl = star_lvl
  
  ret
  