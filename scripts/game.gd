extends Node3D

const Piece = preload("res://scripts/piece.gd")
const PIECE_PATH = "res://models/pieces/"
const BOARD_SIZE = 8
const HIGHLIGHT_TILE = preload("res://scenes/highlight_tile.tscn")
const MOVE_HIGHLIGHT_TILE = preload("res://scenes/highlight_move.tscn")

var last_move_highlights: Array[Node3D] = []
var highlights: Array[Node3D] = []
var white_win_texture = preload("res://assets/white_wins.png")
var black_win_texture = preload("res://assets/black_wins.png")
var move_history: Array = []

var board = []
var pieces = []
var selected_piece: Node3D = null
var is_white_turn := true
var is_dragging := false
var legal_moves: = []
var drag_offset: Vector3 = Vector3.ZERO
var en_passant_target: Vector2i = Vector2i(-1, -1) # клетка, куда можно ударить на проходе

@onready var camera = $Camera3D
@onready var move_log = $MoveLog  # путь до инстанса на сцене
@onready var white_moves_box = $MoveLog/Panel/GridContainer/white_moves
@onready var black_moves_box = $MoveLog/Panel/GridContainer/black_moves
@onready var toggle_log_checkbox = $MoveLog/CheckBox
@onready var moves_log_panel = $MoveLog/Panel
@onready var promotion_menu = $PromotionMenu
@onready var cam_white: Node3D = $CameraPositionWhite
@onready var cam_black: Node3D = $CameraPositionBlack
@onready var auto_cam_toggle: CheckBox = $CanvasLayer/Control/AutoCameraToggle
var auto_camera = true 
@onready var game_over_panel = $CanvasLayer2/GameOverPanel
@onready var title_label = game_over_panel.get_node("TitleLabel")
@onready var restart_button = game_over_panel.get_node("RestartButton")
@onready var menu_button = game_over_panel.get_node("MenuButton")
@onready var quit_button = game_over_panel.get_node("QuitButton")
@onready var victory_image = $CanvasLayer2/GameOverPanel/VictoryImage
@onready var undo_button = $Button





func _ready():
	init_board()
	_spawn_board()
	_place_all_pieces()
	set_camera()
	promotion_menu.connect("piece_promoted", Callable(self, "_on_piece_promoted"))
	toggle_log_checkbox.toggled.connect(_on_log_checkbox_toggled)
	auto_cam_toggle.toggled.connect(_on_auto_camera_toggled)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	undo_button.pressed.connect(_on_undo_pressed)

func _on_auto_camera_toggled(enabled: bool):
	auto_camera = enabled
	
func _on_log_checkbox_toggled(visible: bool) -> void:
	moves_log_panel.visible = not visible
	
func _on_undo_pressed():
	undo_move()
	
func _on_restart_pressed():
	print("RESTART clicked")
	get_tree().paused = false
	get_tree().reload_current_scene()
	game_over_panel.visible = false

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenuScene/MainMenuScene.tscn")

func _on_quit_pressed():
	get_tree().quit()
	
	
func init_board():
	board.resize(BOARD_SIZE)
	for x in range(BOARD_SIZE):
		board[x] = []
		for y in range(BOARD_SIZE):
			board[x].append(null)
			
func _spawn_board():
	var board_scene = load("res://models/Chessboard2.glb")
	var board_instance = board_scene.instantiate()
	add_child(board_instance)
	
func set_camera():
	camera.position = Vector3(7, 14, -7)
	camera.look_at(Vector3(7, 0, -7), Vector3.UP) #убрать фиксацию + выбора угла
	
func place(name, type: int, white: bool, x: int, y: int):
	var path = PIECE_PATH + name + ".glb"
	var piece_scene = load(path)
	var piece_model = piece_scene.instantiate()
	
	# мб лишний слой
	var piece_node = Node3D.new()
	piece_node.add_child(piece_model)
	
	# Area3D + Collision
	var area = Area3D.new()
	area.name = "ClickArea"
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.5, 5, 1.5)  # криво для короля/королевы/слона
	#RayCast не пропускает кажры где теряет фигуру
	shape.shape = box
	area.add_child(shape)
	piece_node.add_child(area)
	
	area.input_event.connect(_on_piece_clicked.bind(piece_node))
	
	piece_node.set_script(Piece)
	piece_node.piece_type = type
	piece_node.is_white = white
	piece_node.board_position = Vector2(x, y) #при отсутсв колизии почти не утопаетs
	piece_node.position = Vector3(2 * x, 0.5, 2 * y - 14) #если угол >45 то фигуры дрожат
	#!!!опустить фигуры!!!
	
	add_child(piece_node)
	board[x][y] = piece_node
	pieces.append(piece_node)

func _place_all_pieces():
	for x in range(8):
		place("PawnW", Piece.PieceType.PAWN, true, x, 6)
		place("PawnB", Piece.PieceType.PAWN, false, x, 1)

	place("KnightW", Piece.PieceType.KNIGHT, true, 1, 7)
	place("KnightW", Piece.PieceType.KNIGHT, true, 6, 7)
	place("KnightB", Piece.PieceType.KNIGHT, false, 1, 0)
	place("KnightB", Piece.PieceType.KNIGHT, false, 6, 0)

	place("BishopW", Piece.PieceType.BISHOP, true, 2, 7)
	place("BishopW", Piece.PieceType.BISHOP, true, 5, 7)
	place("BishopB", Piece.PieceType.BISHOP, false, 2, 0)
	place("BishopB", Piece.PieceType.BISHOP, false, 5, 0)

	place("RookW", Piece.PieceType.ROOK, true, 0, 7)
	place("RookW", Piece.PieceType.ROOK, true, 7, 7)
	place("RookB", Piece.PieceType.ROOK, false, 0, 0)
	place("RookB", Piece.PieceType.ROOK, false, 7, 0)

	place("QueenW", Piece.PieceType.QUEEN, true, 3, 7)
	place("QueenB", Piece.PieceType.QUEEN, false, 3, 0)

	place("KingW", Piece.PieceType.KING, true, 4, 7)
	place("KingB", Piece.PieceType.KING, false, 4, 0)

func show_legal_moves(moves):
	for move in moves:
		var highlight = HIGHLIGHT_TILE.instantiate()
		highlight.position = piece_to_world(move) - Vector3(0, 0.14, 0) #vishe doski
		add_child(highlight)
		highlights.append(highlight)
		
func clear_legal_moves():
	for h in highlights:
		h.queue_free()
	highlights.clear()
		
func show_last_move(from: Vector2i, to: Vector2i):
	for h in last_move_highlights:
		h.queue_free()
	last_move_highlights.clear()

	for pos in [from, to]:
		var highlight = MOVE_HIGHLIGHT_TILE.instantiate()
		highlight.position = piece_to_world(pos) - Vector3(0, 0.14, 0)
		add_child(highlight)
		last_move_highlights.append(highlight)

#сётчик ходов
func log_move(from: Vector2i, to: Vector2i, piece_type: Piece.PieceType, is_white: bool):

	var col
	if is_white:
		col = white_moves_box
	else:
		col = black_moves_box
		var panel = move_log.get_node("Panel")
		panel.custom_minimum_size.y = white_moves_box.size.y + 25
	var move_str = piece_symbol(piece_type, is_white) + position_to_chess_notation(from) + "→" + position_to_chess_notation(to)
	var label = Label.new()
	label.text = move_str
	col.add_child(label)
	
	

func position_to_chess_notation(pos: Vector2i) -> String:
	var file = char(97 + pos.x)  # 0=a 1=b и тд
	var rank = str(8 - pos.y)    # y=0 
	return file + rank

func piece_symbol(piece_type: Piece.PieceType, is_white: bool) -> String:
	if is_white:
		match piece_type:
			Piece.PieceType.PAWN: return "♙"
			Piece.PieceType.KNIGHT: return "♘"
			Piece.PieceType.BISHOP: return "♗"
			Piece.PieceType.ROOK: return "♖"
			Piece.PieceType.QUEEN: return "♕"
			Piece.PieceType.KING: return "♔"
	else:
		match piece_type:
			Piece.PieceType.PAWN: return "♙"
			Piece.PieceType.KNIGHT: return "♞"
			Piece.PieceType.BISHOP: return "♝"
			Piece.PieceType.ROOK: return "♜"
			Piece.PieceType.QUEEN: return "♛"
			Piece.PieceType.KING: return "♚"
	
	return "?"  # мало что может быть



	

	
func get_mouse_board_position() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var plane = Plane(Vector3.UP, 0.5)
	var intersect_pos = plane.intersects_ray(from, to)
	if intersect_pos != null:
		return intersect_pos
	else:
		return Vector3.ZERO

func _on_piece_clicked(_camera, event, _click_position, normal, shape_idx, piece_node):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_piece = piece_node
		if piece_node.is_white == is_white_turn:
			is_dragging = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			legal_moves = piece_node.get_legal_moves(board)
			show_legal_moves(legal_moves)
			var mouse_board_pos = get_mouse_board_position()
			if mouse_board_pos != null:
				drag_offset = piece_node.position - mouse_board_pos
			else:
				drag_offset = Vector3.ZERO
			print("выбрана     ", selected_piece)
		else:
			print("Сейчас ход другой стороны")

func _input(event):
	if is_dragging and selected_piece != null and event is InputEventMouseMotion:
		var pos = get_mouse_board_position()
		if pos != null:
			selected_piece.position = pos + drag_offset

	if is_dragging and event is InputEventMouseButton and not event.pressed:
		is_dragging = false
		snap_piece_to_board(selected_piece)
		selected_piece = null
	
	
func snap_piece_to_board(piece: Node3D):
	var pos = piece.position
	var x = round(pos.x / 2)
	var y = round((pos.z + 14) / 2)
	var target = Vector2i(x, y)
	
	if x < 0 or x >= BOARD_SIZE or y < 0 or y >= BOARD_SIZE:
		print("Вне доски")
		piece.position = piece_to_world(piece.board_position)
		return
		
	var legal = piece.get_legal_moves(board)
	if target not in legal:
		print("Нерабочий ход")
		piece.position = piece_to_world(piece.board_position)
		return
	
	var occupying_piece = board[x][y]
	var old_pos = piece.board_position
	move_history.append({
 		"piece": piece,
		"from": old_pos,
		"to": target,
		"captured": occupying_piece,
		"was_first_move": piece.has_moved})
		
		
	#взятие "на проходе"
	if piece.piece_type == Piece.PieceType.PAWN and occupying_piece == null and Vector2i(x, y) == en_passant_target:
		var dir = -1 if piece.is_white else 1
		var captured_pawn = board[x][y - dir]
		if captured_pawn != null and captured_pawn.piece_type == Piece.PieceType.PAWN:
			captured_pawn.queue_free()
			pieces.erase(captured_pawn)
			board[x][y - dir] = null
	elif occupying_piece != null:
		occupying_piece.queue_free()
		pieces.erase(occupying_piece)
	
	board[old_pos.x][old_pos.y] = null
	show_last_move(old_pos, Vector2i(x, y))
	board[x][y] = piece
	piece.board_position = target
	piece.position = piece_to_world(target)
	
	# Обновление на проходе
	en_passant_target = Vector2i(-1, -1)
	if piece.piece_type == Piece.PieceType.PAWN:
		var delta_y = abs(piece.board_position.y - old_pos.y)
		if delta_y == 2:
			en_passant_target = Vector2i(piece.board_position.x, (piece.board_position.y + old_pos.y) / 2)
	
	is_white_turn = !is_white_turn
	if auto_camera:
		rotate_camera(is_white_turn)
	var king_pos = find_king_position(board, is_white_turn)
	check_for_stalemate_or_checkmate()
	log_move(old_pos, Vector2i(x, y), piece.piece_type, piece.is_white)
	for h in highlights:
		h.queue_free()
	highlights.clear()
	piece.has_moved = true
	

	
	# повышение пешки
	if piece.piece_type == Piece.PieceType.PAWN:
		var promotion_row = 0 if piece.is_white else 7
		if piece.board_position.y == promotion_row:
			await get_tree().create_timer(0.1).timeout
			promotion_menu.show_with_piece(piece)
			await promotion_menu.piece_promoted
			return
	
	# рокировка
	if piece.piece_type == Piece.PieceType.KING:
		y = target.y
		if target.x == 6 and (y == 0 or y == 7):
			var rook = board[7][y]
			board[7][y] = null
			rook.position = piece_to_world(Vector2i(5, y))
			rook.board_position = Vector2i(5, y)
			board[5][y] = rook
		elif target.x == 2 and (y == 0 or y == 7):
			var rook = board[0][y]
			board[0][y] = null
			rook.position = piece_to_world(Vector2i(3, y))
			rook.board_position = Vector2i(3, y)
			board[3][y] = rook
	
	print("Фигура поставлена в  ", x, y)

	
	
func piece_to_world(board_pos: Vector2i) -> Vector3:
	return Vector3(2 * board_pos.x, 0.15, 2 * board_pos.y - 14)
	
func rotate_camera(to_white: bool):
	var target = cam_white if to_white else cam_black
	camera.global_transform.origin = target.global_transform.origin
	camera.global_transform.basis = target.global_transform.basis


var waiting_for_promotion = false
func show_promotion_menu(pawn):
	promotion_menu.visible = true
	waiting_for_promotion = true
	promotion_menu.current_pawn = pawn
	
func _on_piece_promoted(new_type):
	var pos = promotion_menu.current_pawn.board_position
	var is_white = promotion_menu.current_pawn.is_white
	remove_child(promotion_menu.current_pawn)

	var piece_name = ""
	if new_type == Piece.PieceType.QUEEN:
		piece_name = "QueenW" if is_white else "QueenB"
	elif new_type == Piece.PieceType.ROOK:
		piece_name = "RookW" if is_white else "RookB"
	elif new_type == Piece.PieceType.BISHOP:
		piece_name = "BishopW" if is_white else "BishopB"
	elif new_type == Piece.PieceType.KNIGHT:
		piece_name = "KnightW" if is_white else "KnightB"
	else:
		piece_name = "QueenW"

	var path = "res://models/pieces/" + piece_name + ".glb"
	print(piece_name)
	print(path)
	var piece_scene = load(path)
	var piece_model = piece_scene.instantiate()
	var piece_node = Node3D.new()
	piece_node.set_script(Piece)
	piece_node.piece_type = new_type
	piece_node.is_white = is_white
	piece_node.board_position = pos
	piece_node.position = piece_to_world(pos)

	piece_node.add_child(piece_model)

	var area = Area3D.new()
	area.name = "ClickArea"
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.5, 5, 1.5)
	shape.shape = box
	area.add_child(shape)
	piece_node.add_child(area)
	area.input_event.connect(_on_piece_clicked.bind(piece_node))

	add_child(piece_node)

	
	board[pos.x][pos.y] = piece_node
	pieces.append(piece_node)
	
	promotion_menu.visible = false


	
func find_king_position(board: Array, is_white: bool) -> Vector2i:
	for x in range(8):
		for y in range(8):
			var piece = board[x][y]
			if piece != null and piece.is_white == is_white and piece.piece_type == Piece.PieceType.KING:
				return Vector2i(x, y)
	return Vector2i(-1, -1)
	
func check_for_stalemate_or_checkmate():
	var current_color = is_white_turn
	var has_legal_move = false
	var king_pos: Vector2i
	
	# ищем короля
	for x in range(8):
		for y in range(8):
			var piece = board[x][y]
			if piece != null and piece.piece_type == Piece.PieceType.KING and piece.is_white == current_color:
				king_pos = Vector2i(x, y)
				break

	# остались ли у короля ходы
	for x in range(8):
		for y in range(8):
			var piece = board[x][y]
			if piece != null and piece.is_white == current_color:
				var moves = piece.get_legal_moves(board)
				for move in moves:
					var simulated_board = simulate_move(board, piece, Vector2i(x, y), move)
					var new_king_pos = move if piece.piece_type == Piece.PieceType.KING else king_pos
					if not Piece.is_check(simulated_board, new_king_pos, current_color):
						has_legal_move = true
						break
				if has_legal_move:
					break

	# мат или пат
	if not has_legal_move:
		if Piece.is_check(board, king_pos, current_color):
			show_game_over(!current_color, true)
		else:
			show_game_over(false, false)

			
			
func simulate_move(board_state, from_piece, from_pos: Vector2i, to_pos: Vector2i) -> Array:
	var new_board = []
	for i in range(8):
		new_board.append(board_state[i].duplicate(true))
	
	var moving_piece = new_board[from_pos.x][from_pos.y]
	new_board[from_pos.x][from_pos.y] = null
	new_board[to_pos.x][to_pos.y] = moving_piece
	return new_board

func show_game_over(victor_is_white: bool, is_checkmate: bool):
	game_over_panel.show()

	if is_checkmate:
		if victor_is_white:
			victory_image.texture = white_win_texture
			title_label.text = "Мат! Победили белые"
		else:
			victory_image.texture = black_win_texture
			title_label.text = "Мат! Победили чёрные"
	else:
		title_label.text = "Пат! Ничья"
		
		
func undo_move():
	if move_history.is_empty():
		print("Нет ходов для отката")
		return
		
	var last = move_history.pop_back()
	
	var piece = last["piece"]
	var from = last["from"]
	var to = last["to"]
	var captured = last["captured"]

 
	board[to.x][to.y] = null
	piece.board_position = from
	piece.position = piece_to_world(from)
	piece.has_moved = last["was_first_move"]

 
	board[from.x][from.y] = piece

 # Восстанавливаем съеденную фигуру
	if captured != null:
		if not captured.is_inside_tree():
			add_child(captured)
		captured.visible = true
		captured.set_physics_process(true)
		captured.set_process(true)
		captured.board_position = to
		captured.position = piece_to_world(to)
		board[to.x][to.y] = captured
		pieces.append(captured)
	is_white_turn = !is_white_turn
	print("Откат хода")




	
