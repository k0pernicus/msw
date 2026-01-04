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

enableEditor: bool = false

main :: proc() {
	// Parse the flags
	opt: GameOptions
	style := flags.Parsing_Style.Unix
	if len(os.args) > 1 do flags.parse_or_exit(&opt, os.args[1:], style)

	configFlags: rl.ConfigFlags
	if opt.vsync do configFlags += {rl.ConfigFlag.VSYNC_HINT}
	if opt.highdpi do configFlags += {rl.ConfigFlag.WINDOW_HIGHDPI}
	if opt.verbose do context.logger.lowest_level = .Debug
	if opt.enableeditor do enableEditor = true

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
	rl.SetConfigFlags(configFlags)

	rl.InitWindow(0, 0, "Odin + Raylib")
	defer rl.CloseWindow()

	if nbMonitors := rl.GetMonitorCount(); nbMonitors == 0 {
		log.fatal("no monitor found")
	}

	screenWidth: i32 = rl.GetMonitorWidth(0)
	screenHeight: i32 = rl.GetMonitorHeight(0)
	when ODIN_OS == .Darwin {
		screenHeight -= 70 // Resize to handle the menu bar of macOS
	}
	rl.SetWindowSize(screenWidth, screenHeight)

	log.debugf("set screen with dimension %dx%d", screenHeight, screenWidth)

	// Load cyber default as editor theme
	if enableEditor do rl.GuiLoadStyle(editor.EditorStyles[.DARK])

	assets, loadAssetsErr := engine.loadAssets()
	if loadAssetsErr != nil {
		log.fatal("No assets found - no forward")
		return
	}

	levels, loadLevelsErr := game.loadLevels()
	if loadLevelsErr != nil {
		log.fatal("No assets found - no forward")
		return
	}
	defer game.deleteLevels(&levels)

	// Init the context of the game
	// TODO : should be in the heap !!!!
	ctx := engine.GameContext{}
	ctx.assets = new(engine.AssetContext)
	ctx.assets.levels = levels
	engine.initWorld(&ctx.world, ctx.assets, u32(screenWidth), u32(screenHeight))
	ctx.quit = false
	ctx.editorContext = editor.initEditorContext()

	// Do not forget to free all object from the game context
	defer engine.deleteGameContext(&ctx)

	when ODIN_DEBUG {
		assert(len(levels) >= 1)
	}

	// Take the first level
	ctx.currentLevel = &ctx.assets.levels[0]
	// Center the camera to target the center of the level
	ctx.world.camera.object.offset = {f32(screenWidth) / 2, f32(screenHeight) / 2}
	ctx.world.camera.object.target = {
		f32(ctx.currentLevel.dimensions.x) / 2.0,
		f32(ctx.currentLevel.dimensions.y) / 2.0,
	}

	for entity, idx in ctx.currentLevel.entities {
		log.infof(
			"[LEVEL %s] [%d] loading asset with id '%s'",
			ctx.currentLevel.name,
			idx,
			entity.id,
		)

		textureFile: Maybe(string) = nil
		for asset in assets {
			if asset.id == entity.textureId {
				textureFile = asset.textureFile
			}
		}
		if textureFile == nil {
			log.errorf("texture with id '%s' not found", entity.textureId)
			continue
		}

		engine.addEntity(
			&ctx.world,
			// Copy the strings as everything is stored in temp_allocator
			engine.newEntity(
				strings.clone(entity.id),
				strings.clone(textureFile.(string)),
				entity.position,
				onClick = engine.actionSayMiaouh,
				onHover = engine.actionSayGrrh,
			),
		)
	}

	if opt.fpslimit > 0 {
		log.infof("setting limit of %d FPS", opt.fpslimit)
		rl.SetTargetFPS(opt.fpslimit)
	}

	for !rl.WindowShouldClose() && !ctx.quit {
		engine.updateGame(&ctx)

		rl.BeginDrawing()
		rl.ClearBackground(
			ctx.editorContext.enabled ? EDITOR_BACKGROUND_COLOR : GAME_BACKGROUND_COLOR,
		)

		engine.renderGame(&ctx)
		if enableEditor do engine.renderUI(&ctx)
		rl.EndDrawing()

		// Force to free all allocations in the current context
		free_all(context.temp_allocator)
	}
}
