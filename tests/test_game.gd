extends GutTest
## The main scene, run as the game runs it. Its HUD elements reach the player's Character through
## exports that the game scene sets by node path (the Skill bar HUD's and the pause menu's player,
## and the pause menu's Skill bar HUD). A path that leads nowhere loads as null without an error:
## instancing the scene leaves the export null, which the assertions catch, and running it catches
## the errors its nodes log as they get ready. GUT fails a test on any engine error or warning too,
## so this one also fails if the main scene logs one as it gets ready or in its first physics step.


func test_the_hud_reaches_the_one_player_of_the_game_scene() -> void:
	var main_scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene") as String)
	var game := main_scene.instantiate()
	add_child_autofree(game)
	await wait_physics_frames(1)
	var players := game.find_children("*", "Player", true, false)
	assert_eq(players.size(), 1, "one player's Character in the running game")
	var player: Player = players[0]
	assert_eq(player.owner, game, "the game scene's own, not a Level's")
	var skill_bar_hud: SkillBarHud = game.get_node("HUD/SkillBarHud")
	var menu: PauseMenu = game.get_node("HUD/PauseMenu")
	assert_eq(skill_bar_hud.player, player, "the Skill bar HUD's player")
	assert_eq(menu.player, player, "the pause menu's player")
	assert_eq(menu.hud, skill_bar_hud, "the pause menu's Skill bar HUD")
