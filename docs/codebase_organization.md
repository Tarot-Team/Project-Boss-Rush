# Codebase Organization Pass

This project is already moving in a good direction with `assets/`, `items/`, and `room_types/`. The root folder is doing too much work, though. A good target layout would be:

```text
res://
  project.godot
  addons/
  assets/
    attacks/
    player/
    enemy/
    ui/
    world/
  src/
    autoload/
      events.gd
      global.gd
    combat/
      ability_kit.gd
      character_combat.gd
      projectiles/
      melee/
    actors/
      player/
      enemies/
    rooms/
    systems/
      interaction/
      level_manager.gd
    ui/
      hud/
      menus/
  docs/
```

Recommended migration order:

1. Move leaf scenes first: projectiles, cooldown slots, hearts, pause/death screens.
2. Move their scripts with them and update only `res://` references that point to those exact files.
3. Move player/enemy scenes after the smaller scenes are stable.
4. Move autoload scripts last, because `project.godot` and scene startup depend on them.
5. Keep generated/imported files out of the root. Put `.pixil`, `.paint`, and throwaway `.tmp` scenes under an `assets/source/` or `archive/` folder once you are sure nothing references them.

General style rules for future files:

- Prefer exported `PackedScene`, `Texture2D`, and `SpriteFrames` resources over hard-coded `res://` paths inside gameplay code.
- Put child nodes in the scene tree when they are part of the object, then use `@onready` references in the script.
- Keep direct collision numbers behind named constants such as `CharacterCombat.LAYER_ENEMY`.
- Let rooms own room behavior, player own player ability state, and projectiles own their movement/damage rules.
- Avoid adding groups to every child collision node. Usually the root gameplay object should be in the group, and hitboxes can ask their parent.
