extends Control
## Shown between chapters (and after the last built one), so the game never
## ends on a blank screen. The save made just before is kept. A carries on into
## the next chapter if it's built, or returns to the title.

## [completion flag, heading, title, next heading, next title, next is built]
const STAGES := [
	["epilogue_completed", "THE END", "The First Train of Tomorrow", "Thank you for playing", "Reno and Lumi will be back.", false],
	["chapter_10_completed", "CHAPTER 10 COMPLETE", "Where Two Worlds Meet", "Next: Epilogue", "The First Train of Tomorrow", true],
	["chapter_09_completed", "CHAPTER 9 COMPLETE", "The Keeper of Forgotten Years", "Next: Chapter 10", "Where Two Worlds Meet", true],
	["chapter_08_completed", "CHAPTER 8 COMPLETE", "The Night the Worlds Touched", "Next: Chapter 9", "The Keeper of Forgotten Years", true],
	["chapter_07_completed", "CHAPTER 7 COMPLETE", "The Guardian of the Eastern Mountains", "Next: Chapter 8", "The Night the Worlds Touched", true],
	["chapter_06_completed", "CHAPTER 6 COMPLETE", "The Midnight Carnival", "Next: Chapter 7", "The Guardian of the Eastern Mountains", true],
	["chapter_05_completed", "CHAPTER 5 COMPLETE", "A Thousand Flowers, One Promise", "Next: Chapter 6", "The Midnight Carnival", true],
	["chapter_04_completed", "CHAPTER 4 COMPLETE", "The Rubber Grove at Midnight", "Next: Chapter 5", "A Thousand Flowers, One Promise", true],
	["chapter_03_completed", "CHAPTER 3 COMPLETE", "The Town That Forgot Its Name", "Next: Chapter 4", "The Rubber Grove at Midnight", true],
	["chapter_02_completed", "CHAPTER 2 COMPLETE", "Whispers Along the River", "Next: Chapter 3", "The Town That Forgot Its Name", true],
	["chapter_01_completed", "CHAPTER 1 COMPLETE", "The Last Train to Bandar Senja", "Next: Chapter 2", "The river remembers.", true],
	["", "PROLOGUE COMPLETE", "The Great Escape", "Next: Chapter 1", "The Last Train to Bandar Senja", true],
]

## Chapters whose content exists in this build: the next one past these goes to the title.
const BUILT_UP_TO := 8

var _continue := true


static func stage() -> Array:
	for s: Array in STAGES:
		if s[0] == "" or GameState.get_flag(s[0]):
			return s
	return STAGES[-1]


static func chapter_number(s: Array) -> int:
	if s[0] == "":
		return 0
	if s[0] == "epilogue_completed":
		return 11
	return int(s[0].substr(8, 2))


func _ready() -> void:
	InputManager.set_base_mode(InputManager.Mode.CUTSCENE)
	var bg := ColorRect.new()
	bg.color = Color("#1a1838")
	bg.size = Vector2(240, 160)
	add_child(bg)
	var s := stage()
	var next := chapter_number(s) + 1
	_continue = s[5] and next <= BUILT_UP_TO
	var next_label := "Epilogue" if next == 11 else "Chapter %d" % next
	var lines := [
		[s[1], 16, Assets.UI_GOLD, 28],
		[s[2], 8, Assets.UI_TEXT, 50],
		[s[3], 8, Color("#9fb0d8"), 80],
		[s[4], 8, Assets.UI_TEXT, 92],
		["Your game is saved." if _continue or not s[5] else "%s isn't built yet. Saved." % next_label, 8, Color("#9fb0d8"), 118],
		["Press A to begin " + next_label if _continue else "Press A to return to the title", 8, Assets.UI_GOLD, 140],
	]
	for l: Array in lines:
		var label := Label.new()
		label.text = l[0]
		label.add_theme_font_size_override("font_size", l[1])
		label.add_theme_color_override("font_color", l[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(0, l[3])
		label.size = Vector2(240, 20)
		add_child(label)


func _process(_delta: float) -> void:
	if InputManager.just_pressed("confirm", InputManager.Mode.CUTSCENE):
		get_tree().change_scene_to_file("res://scenes/exploration.tscn" if _continue else "res://scenes/title.tscn")
