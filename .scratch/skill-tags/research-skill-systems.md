# Research: how skill systems are structured, and how this repo compares

Researched 2026-11-21. Sources are linked per claim; **[community]** marks a claim that rests only on a community source. The Unreal API reference pages (FGameplayAbilitySpec, FGameplayEffectAttributeCaptureDefinition, BindAbilityActivationToInputComponent) render with JavaScript and gave no text to a fetch, so the member-level GAS details come from tranek's GASDocumentation (community).

## Summary

- The character (or a component on it) **owns** the skills it has. Ownership is a list of granted skills, filled by whatever grants them: equipment, class data, gems in sockets.
- **Input binding is a separate, thin layer**: a mapping from an input or slot to an owned skill. In PoE the skill bar is a UI element that assigns skills to keys; the same skill can appear wherever the player puts it.
- **Activation lives with the owner and the skill**, not with the binding: the owner's `TryActivate` asks the skill `CanActivate` (tags, cost, cooldown), runs it, and the skill **commits** cost and cooldown.
- **Cooldown is owner-side state** (in GAS, a timed effect on the owner that grants a cooldown tag), so it keeps running whatever the bar shows.
- **Modifiers** are owned by the character and aggregated per number. GAS sums multipliers; PoE sums "increased" and multiplies each "more".
- **Snapshot**: a use packs its values into a spec that spawned things (projectiles) carry. PoE snapshots short-lived effects but deliberately made persistent ones (minions, auras) update live.
- **Tags** describe a skill and gate activation (required/blocked tags on the owner, blocking and cancelling other skills).

## Unreal Gameplay Ability System (GAS)

**Ownership.** "You need to attach an Ability System Component to an Actor for it to use Gameplay Abilities"; the component "is responsible for adding and removing abilities to an Actor" ([overview][ue-understand]). "Before an Actor can use an Ability, its Ability System Component must be granted that Ability", via `GiveAbility` with an `FGameplayAbilitySpec` ([using abilities][ue-using]). The spec carries the ability class, level, bound input and the `SourceObject` that granted it ([GASDocumentation 4.6.3][tranek-grant], community). In Epic's Lyra sample, abilities come in Ability Sets granted by pawn data or by equipment, and "Parties that grant Lyra Ability Sets, such as Game Features or Equipment, are responsible for tracking" them ([Abilities in Lyra][ue-lyra]).

**Input binding.** The ASC can bind input actions and "assign those inputs to `GameplayAbilities` when you grant them"; a pressed input activates its ability "if the `GameplayTag` requirements are met" ([4.6.2][tranek-input], community). The input is a field on the spec, not a separate object. Lyra replaces numeric IDs with input tags, and an ability's activation policy decides how it reacts: `OnInputTriggered` ("activated once"), `WhileInputActive` ("activated continuously for as long as the associated Input Tag is triggered"), `OnSpawn` ([Lyra][ue-lyra]). GAS itself documents no press buffer; a queue would sit in the ASC or a subclass of it.

**Activation.** `CanActivateAbility` "lets the caller know whether or not an Ability is available"; `CallActivateAbility` runs it without checking; `CommitAbility` "will apply the cost" and cooldowns ([using abilities][ue-using]). `CanActivateAbility` checks tags, cost (`CheckCost`), cooldown (`CheckCooldown`) and active instances; `CommitAbility` calls `CommitCost` and `CommitCooldown`, "the last chance for the `GameplayAbility` to fail" ([4.6.4][tranek-activate], [4.6.12][tranek-cost], community). The call goes owner → ability: `ASC.TryActivateAbility` → `ability.CanActivateAbility` → `ActivateAbility`.

**Cooldown.** A cooldown is a Duration GameplayEffect applied to the owner that grants a cooldown tag; "the `GA` actually checks for the presence of the `Cooldown Tag`". The tag is unique "per `GameplayAbility` or per ability slot (if your game has interchangeable abilities assigned to slots that share a cooldown)" ([4.5.15][tranek-cd], community). The official overview only says abilities support "cooldowns and assigning resource costs" ([overview][ue-understand]).

**Modifiers.** Gameplay Effects "modify an Actor's attributes and Gameplay Tags" ([overview][ue-understand]); attributes keep a base and a current value, the current value being "the value after all modifiers" ([attributes][ue-attr]). Operations are Add, Multiply, Divide, Override, aggregated as `((Base + Additive) * Multiplicitive) / Division`, and "all `Multiply` and `Divide` `Modifiers` are added together before multiplying" ([4.5.4][tranek-mods], community). So GAS's Multiply behaves like PoE's "increased"; it has no built-in "more".

**Snapshot.** "Gameplay Effect Specs are the runtime versions of Gameplay Effects" ([effects][ue-effects]). "It is common to pass a `GameplayEffectSpec` to a projectile created from an ability that the projectile can apply to the target it hits later" ([4.5.9][tranek-spec], community). "Snapshotting captures the `Attribute` when the `GameplayEffectSpec` is created whereas not snapshotting captures the `Attribute` when the `GameplayEffectSpec` is applied", chosen per captured attribute with `bSnapshot` ([4.5.12][tranek-exec], community).

**Tags.** Official editor fields: Activation Required Tags ("can only be activated if the activating Actor or Component has all of these Tags"), Activation Blocked Tags, Block Abilities With Tag, Cancel Abilities With Tag, Activation Owned Tags ([using abilities][ue-using]). Ability Tags are "just `GameplayTags` to describe the `GameplayAbility`" ([4.6.9][tranek-tags], community).

## Godot

Godot has no ability system; these are the structural rules it gives.

- Scenes should have "no dependencies" where possible; a parent provides a child's dependencies (signals "should be used only to 'respond' to behavior, not start it"; methods are "Used to start behavior"; callables, node references) ([scene organization][godot-scene]).
- Siblings "should only be aware of their own hierarchies while an ancestor mediates their communications" ([scene organization][godot-scene]).
- "Each scene manages its own state information" is the case against a global autoload; autoloads fit "systems with a wide scope" ([autoloads][godot-autoload]).
- Resources are "nearly as lightweight as Object/RefCounted" but show in the Inspector; RefCounted is for "the majority of cases where one needs data in a custom class" ([node alternatives][godot-alt]).
- The InputMap gives "named input *actions*, to which you can assign any number of input events" ([input examples][godot-input]): action and binding are separate.

## Path of Exile and Diablo

- "Skills in Path of Exile are items - gems that grant abilities when socketed into equipment"; "A wide range of support gems allow the behaviour of skills to be modified" ([pathofexile.com/game][poe-game]).
- The skill bar "is an element of the user interface used to assign skills to keys"; it lists every socketed skill, the same skill can appear more than once, and the bar "will remember a skills location on the bar" when gems move ([Skill bar][poewiki-bar], community).
- Flat stats add; "increased"/"reduced" are "summed with other additive stats of the same scope"; "more"/"less" multiply, e.g. 200% increased and 100% more on 1000 gives 6000 ([Stat][poewiki-stat], community).
- GGG's 2014 manifesto removed snapshotting for persistent effects: "removing an aura mana reservation item will terminate its effect", and minions, totems, traps and mines update with gear ([Snapshotting, GGG][poe-snap]). Damage over time, debuffs, and "Non-damage properties of skill effects, such as area of effect or projectile speed" still snapshot ([Snapshot][poewiki-snap], community).
- Gem tags "are not intended to indicate whether a skill gem can be supported" or whether modifiers apply ([Skill gem][poewiki-gem], community).
- Diablo IV: no first-party page on skill assignment was found. Third-party guides describe a hotbar filled from unlocked skills ([Prima][d4-prima], secondary).

## Unity

The Input System docs: actions "separate the purpose of an input from the device controls which perform that input"; "The association between an Action and the device controls ... is a binding" ([Actions][unity-actions]). No first-party ability system.

## Comparison

| | GAS | PoE | This repo |
|---|---|---|---|
| Owning skills | ASC holds granted `FGameplayAbilitySpec`s | Gems socketed in items | Player's Skill child nodes |
| Input binding | InputID / input tag on the spec | Skill bar, a UI assigning skills to keys | SkillBar's 5 slots; Controls and SkillBarHud call `press` |
| Activation, can-activate | ASC `TryActivate` → ability `CanActivate` → `Commit` | (not documented) | `SkillBar._use` checks `is_ready`; Player aims and calls `use` |
| Cooldown | Duration effect on the owner, checked by tag | per skill | `cooldown_left` on Skill, ticked by SkillBar's `_cooling` list |
| Modifiers | GE modifiers, multipliers summed | flat, increased summed, more multiplied | Player's `modifiers` list; `Skill.stack` follows PoE |
| Snapshot | GE spec, passed to projectiles; `bSnapshot` per capture | DoT, debuffs, projectile properties; not minions or auras | `Skill.snapshot()` per use, handed to the projectile |
| Tags | describe, require, block, cancel | gem tags describe | Skill tags describe and filter Modifiers |

## Delta

**Already matches.**
- Skills as children of the Player is ownership, the ASC's granted list. The SkillBar holding references, with the same Skill allowed in several slots, is PoE's skill bar. The developer's model, a character has Skills and the bar is how they show up, is already the scene's shape.
- A Snapshot made per use and handed to the projectile is GAS's spec passed to a projectile.
- `Skill.stack` is PoE's stacking, not GAS's.
- `repeats_while_held` on the Skill is Lyra's `WhileInputActive` policy: how a skill reacts to a held input belongs to the skill.
- A Cooldown per Skill "from any slot" is GAS's per-ability cooldown tag.

**Clearly better to move.**
1. **Cooldown ticking out of SkillBar.** `SkillBar._cooling` tracks Skills "whether or not it still sits in a slot": the bar runs state it doesn't own. Each Skill can run its own clock in `_physics_process` and emit `ready_again` itself; SkillBarHud connects to the Skill in each slot. That deletes `_cooling` and `_cool_down` from `skill_bar.gd`.
2. **One use pipeline, on the owner side.** Today it is split: `SkillBar._use` does can-activate, snapshot and commit, and `Player._on_skill_used` aims and runs. In GAS the binding only says "this input, this skill", and the owner runs check → activate → commit. In repo terms: SkillBar emits `used(skill, aim)` (no snapshot), and one Player method does `is_ready` → `aim` → `snapshot()` → `start_cooldown` → `use`. An Enemy with Skills and no SkillBar could then share that pipeline, for example as a method on Skill such as `try_use(aim)`.

**A matter of taste.**
- **Press queue and held repeats in SkillBar.** Lyra puts press and hold handling in the ability system component, but the press-order queue is input routing and sits fine with the slots. Keep it there unless Enemies need it.
- **SkillBar as a Player child.** It is the player's binding state (PoE's bar remembers positions), separate from SkillBarHud. It could sit under Controls, but there is no functional gain.
- **The `modifiers` array handed down by reference.** It matches the owner holding effects. A Callable from Player (Godot's dependency injection) would make the link explicit, at the cost of one more indirection.
- **No activation-blocking tags.** GAS uses Required/Blocked tags, but nothing here needs them yet.

[ue-understand]: https://dev.epicgames.com/documentation/en-us/unreal-engine/understanding-the-unreal-engine-gameplay-ability-system
[ue-using]: https://dev.epicgames.com/documentation/en-us/unreal-engine/using-gameplay-abilities-in-unreal-engine
[ue-effects]: https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-effects-for-the-gameplay-ability-system-in-unreal-engine
[ue-attr]: https://dev.epicgames.com/documentation/en-us/unreal-engine/gameplay-attributes-and-attribute-sets-for-the-gameplay-ability-system-in-unreal-engine
[ue-lyra]: https://dev.epicgames.com/documentation/en-us/unreal-engine/abilities-in-lyra-in-unreal-engine
[tranek-grant]: https://github.com/tranek/GASDocumentation#concepts-ga-granting
[tranek-input]: https://github.com/tranek/GASDocumentation#concepts-ga-input
[tranek-activate]: https://github.com/tranek/GASDocumentation#concepts-ga-activating
[tranek-cost]: https://github.com/tranek/GASDocumentation#concepts-ga-commit
[tranek-cd]: https://github.com/tranek/GASDocumentation#concepts-ge-cooldown
[tranek-mods]: https://github.com/tranek/GASDocumentation#concepts-ge-mods
[tranek-spec]: https://github.com/tranek/GASDocumentation#concepts-ge-spec
[tranek-exec]: https://github.com/tranek/GASDocumentation#concepts-ge-ec
[tranek-tags]: https://github.com/tranek/GASDocumentation#concepts-ga-tags
[godot-scene]: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
[godot-autoload]: https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_regular_nodes.html
[godot-alt]: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html
[godot-input]: https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html
[poe-game]: https://www.pathofexile.com/game
[poe-snap]: https://www.pathofexile.com/forum/view-thread/951414
[poewiki-bar]: https://www.poewiki.net/wiki/Skill_bar
[poewiki-stat]: https://www.poewiki.net/wiki/Stat
[poewiki-snap]: https://www.poewiki.net/wiki/Snapshot
[poewiki-gem]: https://www.poewiki.net/wiki/Skill_gem
[d4-prima]: https://primagames.com/tips/how-to-unlock-hot-bar-skill-slots-diablo-4
[unity-actions]: https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Actions.html
