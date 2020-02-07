extends KinematicBody2D

export (bool) var is_player = true
export (bool) var was_hit = false

signal box_opened

const GRAVITY = 1000.0 # pixels/second/second

# Angle in degrees towards either side that the player can consider "floor"
const WALK_FORCE = 600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 200
const STOP_FORCE = 1300
const JUMP_SPEED = 600
const JUMP_MAX_AIRBORNE_TIME = 0.2
const CLIMB_SPEED = 2

var velocity = Vector2()
var on_air_time = 100
var jumping = false
var crouche = false

var prev_jump_pressed = false

	
func _ready():
	pass
		
func _physics_process(delta):
	check_collision_with_stone_rounded()
	
	# Create forces
	var force = Vector2(0, GRAVITY)
	
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var climb_up = false
	if not jumping:
		climb_up = Input.is_action_pressed("ui_up")
	var climb_down = Input.is_action_pressed("ui_down")
	var jump = Input.is_action_pressed("jump")
	
	var active = walk_left or walk_right or climb_up or climb_down or jump
	
	var stop = true
	
	if walk_left:
		if velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED:
			force.x -= WALK_FORCE
			stop = false
	elif walk_right:
		if velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED:
			force.x += WALK_FORCE
			stop = false
	
	if stop:
		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)
		
		vlen -= STOP_FORCE * delta
		if vlen < 0:
			vlen = 0
		
		velocity.x = vlen * vsign
	
	# Integrate forces to velocity
	velocity += force * delta	
	# Integrate velocity into motion and move
	velocity = move_and_slide(velocity, Vector2(0, -1))
		
	if jumping and velocity.y > 0:
		# If falling, no longer jumping
		jumping = false
	
	if on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping:
		# Jump must also be allowed to happen if the character left the floor a little bit ago.
		# Makes controls more snappy.
		velocity.y = -JUMP_SPEED
		jumping = true
	
	if velocity.length() > 0:
		$Sprite/AnimationPlayer.play()
	else:
		$Sprite/AnimationPlayer.play()
		$Sprite/AnimationPlayer.current_animation = "Idle"
		
	if velocity.x != 0:
    	$AnimatedSprite.animation = "right"
    	$AnimatedSprite.flip_v = false
    	$AnimatedSprite.flip_h = velocity.x < 0
	elif (jumping):	
    	$AnimatedSprite.animation = "jump"
	
		
	on_air_time += delta
	prev_jump_pressed = jump

func _on_WaitAfterIdle_timeout():
	$WaitAfterIdle.stop()
	play_idle_sound()

func _on_RecoverTimer_timeout():
	was_hit = false
	$RecoverTimer.stop()

const idle_sounds = ["ooooh","jippee","hmmm","ehhh"]
func play_idle_sound():
	get_node(idle_sounds[randi() % 4]).play()

const hit_sounds = ["aj1","aj2","aj3"]
func play_hit_sound():
	get_node(hit_sounds[randi() % 3]).play()

func get_tile_on_position(x,y):
	var tilemap = get_parent().get_node("TileMap")
	if not tilemap == null:
		var map_pos = tilemap.world_to_map(Vector2(x,y))
		var id = tilemap.get_cellv(map_pos)
		if id > -1:
			var tilename = tilemap.get_tileset().tile_get_name(id)
			return tilename
		else:
			return ""

func check_collision_with_stone_rounded():
	var x = position.x
	var y = position.y - 50
	if get_tile_on_position(x,y) == "box":
		var tilemap = get_parent().get_node("TileMap")
		if not tilemap == null:
			var map_pos = tilemap.world_to_map(Vector2(x,y))
			tilemap.set_cellv(map_pos, -1)
			emit_signal("box_opened", Vector2(x,y), map_pos)
