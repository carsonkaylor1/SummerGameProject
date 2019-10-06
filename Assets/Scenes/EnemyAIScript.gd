extends KinematicBody2D

signal attack_finished
#signal animation_finished
signal enemyInMovementZone

onready var Player = get_parent().get_node("Player")
onready var enemyMovementZones = get_parent().get_node("enemyMovementZones")

const SPEED = 320.0
var health = 100.0
var playerAlive
var react_time = 0
var dir = 1
var attacking = false
var enemyMovementZoneChosen = false
var isEnemyInMovementZone = false
#Used around line 80 to choose a zone to run to only once
var runToZone
var last_position
var t = 0
var rng = RandomNumberGenerator.new()
var in_attack_zone = false
var player_distance
var vel = Vector2()
var state = "idle"
var states = ["idle", "inCombat", "fleeing"]

func _ready():
	playerAlive = !Player.player_dead
	set_process(true)
	
func change_state(var nextState):
	if nextState == "inCombat":
		state = "inCombat"
	if nextState == "fleeing":
		state = "fleeing" #was states[2]?
	if nextState == "idle":
		state = "idle"

func _on_Area2D_area_entered(area: Area2D) -> void:
	pass
	#print(area.name)
	#if area.name == "attackZone":
	#	attacking = true
	#if area.name == "attackZone":
	#	attacking = true
		
# Seperating out playing attack animations into chooseable attacks
func choose_attack(attack):
	if attack == "light_flurry":
		#print("ATTACKING")
		# Light flurry plays individual attack animations faster
		$AnimatedSprite.speed_scale = 1.85
		$AnimatedSprite.play("redguard_attack")
		yield(get_node("AnimatedSprite"), "animation_finished")
		$AnimatedSprite.play("redguard_attack")
		yield(get_node("AnimatedSprite"), "animation_finished")
		$AnimatedSprite.play("redguard_attack")
		yield(get_node("AnimatedSprite"), "animation_finished")
		#emit_signal("attack_finished")
		#print("made it here")
		attacking = false
		change_state("fleeing")
		
	elif attack == "one_time_attack":
		$AnimatedSprite.speed_scale = 1.85
		$AnimatedSprite.play("redguard_attack")
		yield(get_node("AnimatedSprite"), "animation_finished")
		attacking = false
		change_state("fleeing")
		#$AnimatedSprite.speed_scale = 1
	# Add more attack types ...

func ai_get_direction(target):
	#print("got movement direction")
	return (target.position - self.position).normalized()

func _physics_process(delta):
	#var dis_to_player = Player.global_position - self.global_position
	#var distance = dis_to_player.length()
	#var direction = dis_to_player.normalize()

	if state == "inCombat":
		if attacking == false:
			#position = position.linear_interpolate(Player.position, 0.01)
			dir = (Player.position - position).normalized()
			var motion = dir * SPEED * delta
			print("motionx:", motion.x)
			if (motion.x > 0):
				$AnimatedSprite.set_flip_h(true)
			else:
				$AnimatedSprite.set_flip_h(false)
			$AnimatedSprite.play("redguard_running")
			position += motion
			
		if attacking == true:
			#"light flurry" attack
			choose_attack("one_time_attack")
			#attacking = false
			yield(self, "attack_finished")
			# Change state to flee after attack
			attacking = false
			#change_state("fleeing")
		
	if(state == "fleeing"):
		#print("fleeing")
		#position += position.linear_interpolate(Vector2(1,0), 0.5)
		#move_and_slide(Vector2(-100, 0))
		if(in_attack_zone == true):
			attacking = true
			change_state("inCombat")
		
		else:
		#Choose corner to run to
			if enemyMovementZoneChosen == false:
			# If enemy is still in players attack zone, chose between fleeing and fighting
				if(in_attack_zone == true): 
					rng.randomize()
					var random_decision = rng.randi_range(0, 1)
					print("Decision: ")
					print(random_decision)
					match random_decision:
						0: 
							runToZone = chooseMovementZone()
							enemyMovementZoneChosen = true
						1:
							attacking = true
							enemyMovementZoneChosen = false
							change_state("inCombat")
				# If enemy is outside of player's attack zone, choose between fleeing and running towards player to attack
				else:
					rng.randomize()
					var random_decision = rng.randi_range(0, 1)
					match random_decision:
						0:
							runToZone = chooseMovementZone()
							enemyMovementZoneChosen = true
						1: 
							attacking = false
							change_state("inCombat") 
			
			if enemyMovementZoneChosen == true:	
				dir = ai_get_direction(runToZone)
				var motion = (dir * SPEED * delta)
				if (motion.x > 0):
					$AnimatedSprite.set_flip_h(true)
				else:
					$AnimatedSprite.set_flip_h(false)
				$AnimatedSprite.play("redguard_running")
				position += motion
			
			
				if isEnemyInMovementZone:
			#	attacking = false
					enemyMovementZoneChosen = false
					change_state("inCombat")
				
			#enemyMovementZoneChosen = false
		
		
	if state == "idle":
		player_distance = abs(Player.position.x - position.x)
		if(playerAlive && player_distance < 400):
			change_state("inCombat")
		else:
			$AnimatedSprite.play("redguard_idle")

func chooseMovementZone():
	var runToIndex = range(0,4)[randi()%range(0,4).size()]
	var runToZone = enemyMovementZones.zones[runToIndex]
	#print("run to zone returned: ", runToZone)
	return runToZone

func _on_enemyMovementZones_area_entered(area: Area2D) -> void:
	print(area.name)
	print("in a movement zone")
	isEnemyInMovementZone = true
	#return isEnemyInMovementZone


func _on_enemyMovementZones_area_exited(area: Area2D) -> void:
	print("left movement zone")
	isEnemyInMovementZone = false


func _on_SenseArea_area_entered(area: Area2D):
	print(area.name)
	if area.name == "attackZone":
		attacking = true
		in_attack_zone = true
		isEnemyInMovementZone = false
	if area.is_in_group("EnemyMovementZone"):
		print("zone entered")
		isEnemyInMovementZone = true
		attacking = false

func _on_SenseArea_area_exited(area):
	if area.name == "attackZone":
		in_attack_zone = false
		print("left attack zone")
