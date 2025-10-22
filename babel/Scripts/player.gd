extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const GROUND_DECEL = 20.0
const AIR_DRAG = 5.0

func _physics_process(delta: float):
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump input
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("ui_up") and velocity.y < 0: #multiplies velocity y by 0.4 to do variable jump height stuff
		velocity.y *= 0.4

	# left & right movement
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		if is_on_floor():
			# ground decel
			velocity.x = lerp(velocity.x, 0.0, GROUND_DECEL * delta)
		else:
			# air decel
			velocity.x = lerp(velocity.x, 0.0, AIR_DRAG * delta)

	move_and_slide()
