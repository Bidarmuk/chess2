extends Control

@onready var play_button = $VBoxContainer/Play
@onready var share_button = $VBoxContainer/ShareGit
@onready var quit_button = $VBoxContainer/Quit
@onready var popup = $popup/popup
@onready var timer = $HideTimer
func _ready():
	play_button.text = "Играть"
	share_button.text = "Поделиться"
	quit_button.text = "Выход"

	play_button.pressed.connect(play_press)
	share_button.pressed.connect(share_press)
	timer.timeout.connect(on_timer_timeout)
	quit_button.pressed.connect(quit_press)

func play_press():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func share_press():
	DisplayServer.clipboard_set("https://github.com/Bidarmuk/3dChess")
	popup.visible = true
	timer.start()
	
func on_timer_timeout():
	popup.visible = false

func quit_press():
	get_tree().quit()
