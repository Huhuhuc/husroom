extends CharacterBody2D


# 状态机枚举
enum State {
	IDEL,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
}


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var graphics: Node2D = $Graphics
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var hand_checker: RayCast2D = $Graphics/HandChecker



# 角色在地面的状态列表
const GROUND_STATES := [State.IDEL,State.RUNNING,State.LANDING]
# 移动速度
const RUN_SPEED := 160.0
# 地面移动加速度
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
# 空中转体加速度
const AIR_ACCELERATION := RUN_SPEED / 0.02
# 是负数的原因是因为在2D空间中y轴向上为负
const JUMP_VELOCITY := -320.0
# 获取引擎给的重力加速度
var default_gravity := ProjectSettings.get("physics/2d/default_gravity") as float
# 当前状态
var current_state := State.IDEL
# 当前是否第一帧
var is_first_tick := false 


# 使用事件回调函数_unhandled_input()判断是否按下jump按键
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	# 短按轻跳，长按大跳
	if event.is_action_released("jump") :
		jump_request_timer.stop()
		if  velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2


# 执行对应状态
func tick_physics(state:State,delta: float) -> void:
	print("tick_physics: state=", state, " velocity=", velocity, " is_on_floor=", is_on_floor())
	match state:
		State.IDEL:
			move(default_gravity,delta)
		State.RUNNING:
			move(default_gravity,delta)
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity,delta)
		State.FALL:
			move(default_gravity,delta)
		State.LANDING:
			stand(delta)
			
		State.WALL_SLIDING:
			move(default_gravity / 3 , delta)
			graphics.scale.x = get_wall_normal().x
			
	is_first_tick = false


# 移动
func move(gravity:float, delta: float) -> void:
	# 获取按键输入
	var direction :=  Input.get_axis("move_left","move_right")
	# 如果在地面则获取地面加速度，如果不在地面，则获取空中转体加速度
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	# 修改速度向量
	velocity.x = move_toward(velocity.x, direction*RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	
	# 如果在移动，并且是向左移动，那么将角色水平翻转
	if not is_zero_approx(direction):
		graphics.scale.x = -1 if  direction < 0 else +1
	
	move_and_slide()


# 站立
func stand(delta: float) -> void:
	# 如果在地面则获取地面加速度，如果不在地面，则获取空中转体加速度
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	# 修改速度向量
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()


# 获取下一个状态
func get_next_state(state:State) -> State:
	# 在地板上或在郊狼时间内，表示能起跳
	var can_jump := is_on_floor() or coyote_timer.time_left >0
	# 能起跳且按下jump按键，则表示应当起跳
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
	# 获取按键输入
	var direction :=  Input.get_axis("move_left","move_right")
	# 是否站立状态
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	print("get_next_state: current_state=", state, " is_still=", is_still, " direction=", direction, " velocity.x=", velocity.x)
	match state:
		State.IDEL:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
			
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDEL
				
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
				
		State.FALL:
			if is_on_floor():
				return State.LANDING if is_still else State.RUNNING
			if is_on_wall() and hand_checker.is_colliding() and foot_checker.is_colliding():
				return State.WALL_SLIDING
				
		State.LANDING:
			if not is_still:
				return State.RUNNING
			if not animation_player.is_playing():
				return State.IDEL 
			
			
		State.WALL_SLIDING:
			if is_on_floor():
				return State.IDEL
			if not is_on_wall():
				return State.FALL
				
	
	return state


# 状态转换
func transition_state(from: State, to:State)->void:
	print("transition_state: from=", from, " to=", to)
	# 之前不处于在地面的状态要切换到地面状态
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
		
	match to:
		State.IDEL:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
			
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			# 关闭郊狼时间，防止空中再次起跳
			coyote_timer.stop()
			# 关闭跳跃预输入
			jump_request_timer.stop()
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
	
		State.LANDING:
			animation_player.play("landing")
			
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
		
	is_first_tick = true
