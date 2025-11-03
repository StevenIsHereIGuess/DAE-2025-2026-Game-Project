extends CharacterBody2D

# Movestuff
const GRAVITY_NORMAL: float = 14.5
const GRAVITY_WALL: float = 8.5
const WALL_JUMP_PUSH_FORCE: float = 1000.0
const WALL_JUMP_LOCK_TIME: float = 0.05
const WALL_CONTACT_COYOTE_TIME: float = 0.2

const SPEED = 300.0
const JUMP_VELOCITY = -400
const GROUND_DECEL = 15.0
const AIR_DRAG = 5.0

# le grapple
const GRAPPLE_FORCE: float = 800.0
const GRAPPLE_RANGE: float = 100.0
const GRAPPLE_BOX_SIZE: Vector2 = Vector2(60, 60)
const GRAPPLE_DEBUG_TIME: float = 0.1 #how long the grapple box is active

# state stuff (no not like america)
var wall_jump_lock: float = 0.0
var wall_contact_coyote: float = 0.0
var look_dir_x: int = 1
var is_grappling: bool = false

func _physics_process(delta: float):
	# Wall contact timer
	if !is_on_floor() and is_on_wall():
		wall_contact_coyote = WALL_CONTACT_COYOTE_TIME
	else:
		wall_contact_coyote -= delta
		wall_contact_coyote = max(wall_contact_coyote, 0.0)

	# Gravity
	if !is_on_floor():
		if is_on_wall() and velocity.y > 0:
			velocity.y += GRAVITY_WALL
		else:
			velocity.y += GRAVITY_NORMAL
	
	# Wall jump lock timer
	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta

	# Jump
	if (is_on_floor() or wall_contact_coyote > 0.0) and Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY
		if wall_contact_coyote > 0.0:
			velocity.x = -look_dir_x * WALL_JUMP_PUSH_FORCE
			wall_jump_lock = WALL_JUMP_LOCK_TIME

	if Input.is_action_just_released("ui_up") and velocity.y < 0:
		velocity.y *= 0.2

	# Movement
	if wall_jump_lock <= 0.0:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			velocity.x = direction * SPEED
			look_dir_x = direction
		else:
			if is_on_floor():
				velocity.x = lerp(velocity.x, 0.0, GROUND_DECEL * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, AIR_DRAG * delta)

	# -le grapple input
	if Input.is_action_just_pressed("grapple"):
		var dir = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		).normalized()
		if dir != Vector2.ZERO:
			try_grapple(dir)

	move_and_slide()

# More le grapple stuff
func try_grapple(direction: Vector2):
	var space_state = get_world_2d().direct_space_state
	var box_shape = RectangleShape2D.new()
	box_shape.size = GRAPPLE_BOX_SIZE

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = box_shape
	query.transform = Transform2D(0, global_position + direction * GRAPPLE_RANGE)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_shape(query, 1)

	# the box thingie for le grapple
	debug_draw_box(global_position + direction * GRAPPLE_RANGE, GRAPPLE_BOX_SIZE)

	if result.size() > 0:
		apply_grapple_force(direction)

func apply_grapple_force(direction: Vector2):
	velocity += direction * GRAPPLE_FORCE

# le floating green box
func debug_draw_box(pos: Vector2, size: Vector2):
	var rect = ColorRect.new()
	rect.color = Color(0, 1, 0, 0.3) # semi-transparent green bc green is the best color
	rect.position = pos - size / 2
	rect.size = size
	get_tree().current_scene.add_child(rect)
	await get_tree().create_timer(GRAPPLE_DEBUG_TIME).timeout
	rect.queue_free()
