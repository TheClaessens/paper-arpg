extends GutTest

# Assertions compare dynamic values (settings, shader parameters), which are Variant by design.
@warning_ignore_start("unsafe_call_argument")

var settings: GameSettings


func before_each() -> void:
	settings = autofree(GameSettings.new())


func test_starts_with_declared_defaults() -> void:
	assert_eq(settings.get_value(&"pixelated"), true)


func test_set_value_emits_changed() -> void:
	watch_signals(settings)
	assert_eq(settings.set_value(&"pixelated", false), OK)
	assert_eq(settings.get_value(&"pixelated"), false)
	assert_signal_emitted_with_parameters(settings, "changed", [&"pixelated", false])


func test_setting_same_value_does_not_emit() -> void:
	watch_signals(settings)
	settings.set_value(&"pixelated", true)
	assert_signal_not_emitted(settings, "changed")


func test_rejects_unknown_key() -> void:
	assert_eq(settings.set_value(&"nope", true), ERR_DOES_NOT_EXIST)


func test_rejects_wrong_type() -> void:
	assert_eq(settings.set_value(&"pixelated", 1), ERR_INVALID_PARAMETER)
	assert_eq(settings.get_value(&"pixelated"), true)


func test_set_from_text_parses_bools() -> void:
	for text: String in ["0", "false", "OFF"]:
		settings.set_value(&"pixelated", true)
		assert_eq(settings.set_from_text(&"pixelated", text), OK, text)
		assert_eq(settings.get_value(&"pixelated"), false, text)
	for text: String in ["1", "true", "On"]:
		settings.set_value(&"pixelated", false)
		assert_eq(settings.set_from_text(&"pixelated", text), OK, text)
		assert_eq(settings.get_value(&"pixelated"), true, text)


func test_set_from_text_rejects_garbage() -> void:
	assert_eq(settings.set_from_text(&"pixelated", "maybe"), ERR_PARSE_ERROR)
	assert_eq(settings.get_value(&"pixelated"), true)
