extends SceneTree


func _initialize() -> void:
	var lexer := GDCLexer.new()

	var source := """
character BullyWalker

dialogue introduction:
	say "Hello!"
	autoadvance 1.5

	choice:
		"Who are you?":
			say "Your worst nightmare."
			event start_boss_fight

	end
"""

	var tokens := lexer.tokenize(source)

	for token in tokens:
		print(
			"Type: ", GDCToken.Type.keys()[token.type],
			" | Value: ", token.value,
			" | Line: ", token.line
		)

	quit()