extends CanvasLayer

signal piece_promoted(piece_type)

var current_pawn: Piece = null

func show_promotion_menu(pawn):
	current_pawn = pawn
	show()
	
func show_with_piece(pawn: Piece):
	current_pawn = pawn
	show()
	
func _ready():
	$Control/Queen.connect("pressed", Callable(self, "_on_queen_pressed"))
	$Control/Rook.connect("pressed", Callable(self, "_on_rook_pressed"))
	$Control/Bishop.connect("pressed", Callable(self, "_on_bishop_pressed"))
	$Control/Knight.connect("pressed", Callable(self, "_on_knight_pressed"))

func _on_queen_pressed():
	emit_signal("piece_promoted", Piece.PieceType.QUEEN)
	visible = false

func _on_rook_pressed():
	emit_signal("piece_promoted", Piece.PieceType.ROOK)
	visible = false

func _on_bishop_pressed():
	emit_signal("piece_promoted", Piece.PieceType.BISHOP)
	visible = false

func _on_knight_pressed():
	emit_signal("piece_promoted", Piece.PieceType.KNIGHT)
	visible = false
