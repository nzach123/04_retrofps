extends Node3D

@onready var animation_player = $AnimationPlayer

@onready var weapons = $Weapons.get_children()

var weapons_unlocked = []
var cur_slot = 0
var cur_weapon = null

@onready var nearby_monsters_alert_area_small = $NearbyMonstersAlertAreaSmall
@onready var nearby_monsters_alert_area_large = $NearbyMonstersAlertAreaLarge
@onready var los_ray_cast_3d = $LOSRayCast3D


func _ready() -> void:
	for weapon in weapons:
		if !weapon.silent_weapon:
			weapon.fired.connect(alert_enemies_on_fired)
		if weapon.has_method("set_bodies_to_exclude"):
			weapon.set_bodies_to_exclude([get_parent().get_parent()])
	disable_all_weapons()
	for _i in range(weapons.size()):
		weapons_unlocked.append(false)
	weapons_unlocked[0] = true
	switch_to_weapon_slot(0)
	
func attack(input_just_pressed: bool, input_held: bool):
	if cur_weapon is Weapon:
		cur_weapon.attack(input_just_pressed, input_held)

func enable_weapon(weapon : Weapon):
	if weapon == null:
		return
	var weapon_ind = weapon.get_index()
	var weapons_already_unlocked = weapons_unlocked[weapon_ind]
	weapons_unlocked[weapon_ind] = true
	if !weapons_already_unlocked:
		switch_to_weapon_slot(weapon_ind)
	
func disable_all_weapons():
	for weapon in weapons:
		if weapon.has_method("set_active"):
			weapon.set_active(false)
		else:
			weapon.hide()
	
func switch_to_previous_weapon():
	for i in range(weapons.size()):
		var wrapped_ind = wrapi(cur_slot - 1 - i, 0, weapons.size())
		if switch_to_weapon_slot(wrapped_ind):
			break
	
	
func switch_to_next_weapon():
	for i in range(weapons.size()):
		var wrapped_ind = wrapi(cur_slot - 1 + i, 0, weapons.size())
		if switch_to_weapon_slot(wrapped_ind):
			break
	
func switch_to_weapon_slot(slot_ind: int)->bool:
	if slot_ind > weapons.size() or slot_ind < 0:
		return false
	if weapons_unlocked.size() == 0 or !weapons_unlocked[slot_ind]:
		return false
	disable_all_weapons()
	cur_slot = slot_ind
	cur_weapon = weapons[cur_slot]
	if cur_weapon.has_method("set_active"):
		cur_weapon.set_active(true)
	else:
		cur_weapon.show()
	return true
	
func update_animation(velocity: Vector3, grounded: bool):
	if cur_weapon is Weapon and !cur_weapon.is_idle():
		animation_player.play("RESET")
	elif !grounded or velocity.length() < 5.0:
		animation_player.play("RESET", 0.5)
	else:
		animation_player.play("moving", 0.5)
		
func alert_enemies_on_fired():
	for monster in nearby_monsters_alert_area_small.get_overlapping_bodies():
		if monster is Monster:
			monster.alert()
			
	for monster in nearby_monsters_alert_area_large.get_overlapping_bodies():
		if monster is Monster:
			los_ray_cast_3d.enabled = true
			los_ray_cast_3d.target_position = los_ray_cast_3d.to_local(monster.vision_manager.global_position)
			los_ray_cast_3d.force_raycast_update()
			if !los_ray_cast_3d.is_colliding():
				monster.alert()
			los_ray_cast_3d.enabled = false
			
func get_weapon_from_pickup_type(weapon_type: Pickup.WEAPONS) -> Weapon:
	match weapon_type:
		Pickup.WEAPONS.MACHINE_GUN:
			return $Weapons/MachineGun
		Pickup.WEAPONS.SHOTGUN:
			return $Weapons/Shotgun
		Pickup.WEAPONS.ROCKET_LAUNCHER:
			return $Weapons/RocketLauncher
	return null	
			
		
			
