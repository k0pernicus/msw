package main

import "core:flags"
import "core:os"
import "core:strings"
import "engine"
import "game"
import rl "vendor:raylib"

// Necessary imports for debug
import "core:fmt"
import "core:mem"
_ :: fmt
_ :: mem

BACKGROUND_COLOR: rl.Color : rl.BLUE

WIDTH: i32 : 1280
HEIGHT: i32 : 720

// Define a struct representing your options
GameOptions :: struct {
	highdpi:  bool `usage:"Enable HighDPI"`,
	vsync:    bool `usage:"Vsync activation"`,
	fpslimit: i32 `usage:"Limit of FPS"`,
}

main :: proc() {

	// https://odin-lang.org/docs/overview/#tracking-allocator
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// Free all remaining objects in the temp_allocator of the current context
	defer free_all(context.temp_allocator)

	// Parse the flags
	opt: GameOptions
	style := flags.Parsing_Style.Unix
	if len(os.args) > 1 do flags.parse_or_exit(&opt, os.args[1:], style)

	configFlags: rl.ConfigFlags
	if opt.vsync do configFlags += {rl.ConfigFlag.VSYNC_HINT}
	if opt.highdpi do configFlags += {rl.ConfigFlag.WINDOW_HIGHDPI}

	// .WINDOW_RESIZABLE to check - (needs to check for dynamic render target resizing)
	rl.SetConfigFlags(configFlags)
	rl.InitWindow(WIDTH, HEIGHT, "Odin + Raylib")
	defer rl.CloseWindow()

	assets, loadAssetsErr := engine.loadAssets()
	if loadAssetsErr != nil {
		fmt.eprintln("No assets found - no forward")
		return
	}

	levels, loadLevelsErr := game.loadLevels()
	if loadLevelsErr != nil {
		fmt.eprintln("No levels found - no forward")
		return
	}
	defer game.deleteLevels(&levels)

	// Init the context of the game
	ctx := engine.GameContext{}
	ctx.assets = new(engine.AssetContext)
	ctx.assets.levels = levels
	engine.initWorld(&ctx.world, ctx.assets, WIDTH, HEIGHT)
	ctx.quit = false

	// Do not forget to free all object from the game context
	defer engine.deleteGameContext(&ctx)

	// Take the first level
	level1 := levels[0]

	for entity, idx in level1.entities {
		fmt.printfln(">[LEVEL1] [%d] loading asset with id '%s'", idx, entity.id)

		textureFile: Maybe(string) = nil
		for asset in assets {
			if asset.id == entity.textureId {
				textureFile = asset.textureFile
			}
		}
		if textureFile == nil {
			fmt.eprintfln(">> [ERROR] texture with id '%s' not found", entity.textureId)
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

	if opt.fpslimit > 0 do rl.SetTargetFPS(opt.fpslimit)

	for !rl.WindowShouldClose() && !ctx.quit {
		engine.update_game(&ctx)

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		engine.render_game(&ctx)
		engine.render_ui(&ctx)

		rl.EndDrawing()

		// Force to free all allocations in the current context
		free_all(context.temp_allocator)
	}
}
