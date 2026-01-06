package main

import "core:flags"
import "core:log"
import "core:os"
import "core:strings"
import "editor"
import "engine"
import "game"
import rl "vendor:raylib"

// Necessary imports for debug
import "core:fmt"
import "core:mem"
_ :: fmt
_ :: mem

EDITOR_BACKGROUND_COLOR: rl.Color : rl.BLUE
GAME_BACKGROUND_COLOR: rl.Color : {20, 20, 20, 255}

// Define a struct representing your options
GameOptions :: struct {
	enableeditor: bool `usage:"Enable the editor and debug function"`,
	verbose:      bool `usage:"Debug level in logger"`,
	highdpi:      bool `usage:"Enable HighDPI"`,
	vsync:        bool `usage:"Vsync activation"`,
	fpslimit:     i32 `usage:"Limit of FPS"`,
}

enable_editor: bool = false

main :: proc() {
	// Parse the flags
	opt: GameOptions
	style := flags.Parsing_Style.Unix
	if len(os.args) > 1 do flags.parse_or_exit(&opt, os.args[1:], style)

	config_flags: rl.ConfigFlags
	if opt.vsync do config_flags += {rl.ConfigFlag.VSYNC_HINT}
	if opt.highdpi do config_flags += {rl.ConfigFlag.WINDOW_HIGHDPI}
	if opt.verbose do context.logger.lowest_level = .Debug
	if opt.enableeditor do enable_editor = true

	context.logger = log.create_console_logger(opt.verbose ? .Debug : .Info)
	defer log.destroy_console_logger(context.logger)
	engine.init_logging(context.logger)

	// https://odin-lang.org/docs/overview/#tracking-allocator
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				log.warnf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.warnf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	// Free all remaining objects in the temp_allocator of the current context
	defer free_all(context.temp_allocator)

	// All raylib logs belong now to Odin
	rl.SetTraceLogCallback(engine.rl_log)

	// .WINDOW_RESIZABLE to check - (needs to check for dynamic render target resizing)
	rl.SetConfigFlags(config_flags)

	rl.InitWindow(0, 0, "Odin + Raylib")
	defer rl.CloseWindow()

	if nb_monitors := rl.GetMonitorCount(); nb_monitors == 0 {
		log.fatal("no monitor found")
	}

	screen_width: i32 = rl.GetMonitorWidth(0)
	screen_height: i32 = rl.GetMonitorHeight(0)
	when ODIN_OS == .Darwin {
		screen_height -= 70 // Resize to handle the menu bar of macOS
	}
	rl.SetWindowSize(screen_width, screen_height)

	log.debugf("set screen with dimension %dx%d", screen_height, screen_width)

	// Load cyber default as editor theme
	if enable_editor do rl.GuiLoadStyle(editor.EditorStyles[.DARK])

	assets, load_assets_err := engine.load_assets()
	if load_assets_err != nil {
		log.fatal("No assets found - no forward")
		return
	}

	levels, load_levels_err := game.load_levels()
	if load_levels_err != nil {
		log.fatal("No assets found - no forward")
		return
	}
	defer game.delete_levels(&levels)

	// Init the context of the game
	// TODO : should be in the heap !!!!
	ctx := engine.GameContext{}
	ctx.assets = new(engine.AssetContext)
	ctx.assets.levels = levels
	engine.init_world(&ctx.world, ctx.assets, u32(screen_width), u32(screen_height))
	ctx.quit = false
	ctx.editor_context = editor.initEditorContext()

	// Do not forget to free all object from the game context
	defer engine.delete_game_context(&ctx)

	when ODIN_DEBUG {
		assert(len(levels) >= 1)
	}

	// Take the first level
	ctx.current_level = &ctx.assets.levels[0]
	// Center the camera to target the center of the level
	ctx.world.camera.object.offset = {f32(screen_width) / 2, f32(screen_height) / 2}
	ctx.world.camera.object.target = {
		f32(ctx.current_level.dimensions.x) / 2.0,
		f32(ctx.current_level.dimensions.y) / 2.0,
	}

	for entity, idx in ctx.current_level.entities {
		log.infof(
			"[LEVEL %s] [%d] loading asset with id '%s'",
			ctx.current_level.name,
			idx,
			entity.id,
		)

		texture_file: Maybe(string) = nil
		for asset in assets {
			if asset.id == entity.texture_id {
				texture_file = asset.texture_file
			}
		}
		if texture_file == nil {
			log.errorf("texture with id '%s' not found", entity.texture_id)
			continue
		}

		engine.add_entity(
			&ctx.world,
			// Copy the strings as everything is stored in temp_allocator
			engine.on_click(
				strings.clone(entity.id),
				strings.clone(texture_file.(string)),
				entity.position,
				on_click = engine.action_say_miaouh,
				on_hover = engine.action_say_grrh,
			),
		)
	}

	if opt.fpslimit > 0 {
		log.infof("setting limit of %d FPS", opt.fpslimit)
		rl.SetTargetFPS(opt.fpslimit)
	}

	for !rl.WindowShouldClose() && !ctx.quit {
		engine.update_game(&ctx)

		rl.BeginDrawing()
		rl.ClearBackground(
			ctx.editor_context.enabled ? EDITOR_BACKGROUND_COLOR : GAME_BACKGROUND_COLOR,
		)

		engine.render_game(&ctx)
		if enable_editor do engine.render_editor(&ctx)
		rl.EndDrawing()

		// Force to free all allocations in the current context
		free_all(context.temp_allocator)
	}
}
