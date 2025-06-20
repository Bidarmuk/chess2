extends Node3D
class_name Piece

enum PieceType { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

var piece_type: PieceType
var is_white: bool
var board_position: Vector2i
var has_moved: bool = false    # будет устанавливаться в true после первого хода (нужно для рокировки)
var en_passant_target: Vector2i = Vector2i(-1, -1) # клетка где можно ударить на проходе



static func is_check(board: Array, king_pos: Vector2i, is_white: bool) -> bool:
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)  ]
	for dir in directions:
		var nx = king_pos.x + dir.x
		var ny = king_pos.y + dir.y
		while nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var piece = board[nx][ny]
			if piece != null:
				if piece.is_white == is_white:
					break
				if dir.x == 0 or dir.y == 0:
					if piece.piece_type == PieceType.ROOK or piece.piece_type == PieceType.QUEEN:
						return true
				else:
					if piece.piece_type == PieceType.BISHOP or piece.piece_type == PieceType.QUEEN:
						return true
				break
			nx += dir.x
			ny += dir.y

	var knight_offsets = [ Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2), Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]
	for offset in knight_offsets:
		var nx = king_pos.x + offset.x
		var ny = king_pos.y + offset.y
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var piece = board[nx][ny]
			if piece != null and piece.is_white != is_white and piece.piece_type == PieceType.KNIGHT:
				return true

	var pawn_dir = -1 if is_white else 1
	for dx in [-1, 1]:
		var nx = king_pos.x + dx
		var ny = king_pos.y + pawn_dir
		if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var piece = board[nx][ny]
			if piece != null and piece.is_white != is_white and piece.piece_type == PieceType.PAWN:
				return true

	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx = king_pos.x + dx
			var ny = king_pos.y + dy
			if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
				var piece = board[nx][ny]
				if piece != null and piece.is_white != is_white and piece.piece_type == PieceType.KING:
					return true

	return false


func slide(board, directions: Array) -> Array:
	var x = board_position.x
	var y = board_position.y
	var moves = []
	for dir in directions:
		var nx = x + dir.x
		var ny = y + dir.y
		while nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
			var target = board[nx][ny]
			if target == null:
				moves.append(Vector2i(nx, ny))
			elif target.is_white != is_white:
				moves.append(Vector2i(nx, ny))
				break
			else:
				break
			nx += dir.x
			ny += dir.y
	return moves
	
	
func get_legal_moves(board: Array):
	
	var moves = []
	var x = board_position.x
	var y = board_position.y
	
	match piece_type:
		PieceType.PAWN:
			var forward = -1 if is_white else 1
			var start_row = 6 if is_white else 1
			
			# Обычный ход
			if y + forward >= 0 and y + forward < 8 and board[x][y + forward] == null:
				moves.append(Vector2i(x, y + forward))
				if y == start_row and board[x][y + 2 * forward] == null:
					moves.append(Vector2i(x, y + 2 * forward))
					
					
			for dx in [-1, 1]:
				var nx = x + dx
				var ny = y + forward
				if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
					if board[nx][y] != null and board[nx][y].piece_type == PieceType.PAWN and board[nx][y].is_white != is_white:
						moves.append(Vector2i(nx, ny))
					var target = board[nx][ny]
					if target != null and target.is_white != is_white:
						moves.append(Vector2i(nx, ny))
					if Vector2i(nx, ny) == en_passant_target:
						moves.append(Vector2i(nx, ny))
						
						
						
		PieceType.KNIGHT:
			var offsets = [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2), Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)]
			for offset in offsets:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
					var target = board[nx][ny]
					if target == null or target.is_white != is_white:
						moves.append(Vector2i(nx, ny))

		PieceType.BISHOP:
			moves += slide(board, [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)])

		PieceType.ROOK:
			moves += slide(board, [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)])

		PieceType.QUEEN:
			moves += slide(board, [ Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0), Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)])

		PieceType.KING:
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var nx = x + dx
					var ny = y + dy
					if nx >= 0 and nx < 8 and ny >= 0 and ny < 8:
						var target = board[nx][ny]
						if target == null or target.is_white != is_white:
							moves.append(Vector2i(nx, ny))

			if not has_moved and not is_check(board, board_position, is_white):
				var row = 7 if is_white else 0

				var rook = board[7][row]
				if rook != null and rook.piece_type == PieceType.ROOK and not rook.has_moved:
					if board[5][row] == null and board[6][row] == null:
						# Проверяем, что король сейчас не в шахе, и поля f и g не атакуются
						var king_pos = board_position
						if not is_check(board, Vector2i(5, row), is_white) and not is_check(board, Vector2i(6, row), is_white):
							moves.append(Vector2i(6, row))

				rook = board[0][row]
				if rook != null and rook.piece_type == PieceType.ROOK and not rook.has_moved:
					if board[1][row] == null and board[2][row] == null and board[3][row] == null:
						if not is_check(board, Vector2i(2, row), is_white) and not is_check(board, Vector2i(3, row), is_white):
							moves.append(Vector2i(2, row))

	var legal = []
	for move in moves:
		var old_x = board_position.x
		var old_y = board_position.y
		var captured = board[move.x][move.y]

		board[old_x][old_y] = null
		board[move.x][move.y] = self
		board_position = move
		var king_pos = move if piece_type == PieceType.KING else null
		if king_pos == null:
			for i in range(8):
				for j in range(8):
					var p = board[i][j]
					if p != null and p.piece_type == PieceType.KING and p.is_white == is_white:
						king_pos = Vector2i(i, j)
						break
				if king_pos != null:
					break

		if not is_check(board, king_pos, is_white):
			legal.append(move)

		board_position = Vector2i(old_x, old_y)
		board[old_x][old_y] = self
		board[move.x][move.y] = captured

	return legal
