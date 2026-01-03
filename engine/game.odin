package engine

import "core:fmt"
import rl "vendor:raylib"

getInputs :: proc(ctx: ^GameContext) {
	// Check for "Modifier" key (Ctrl or Command)
	if rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.LEFT_SUPER) {
		// Debug camera
		if rl.IsKeyPressed(.C) do ctx.debugMode.camera = !ctx.debugMode.camera
		// Debug informations
		if rl.IsKeyPressed(.I) do ctx.debugMode.informations = !ctx.debugMode.informations
		// Debug entities
		if rl.IsKeyPressed(.E) do ctx.debugMode.entities = !ctx.debugMode.entities
	}
}

cameraMovement :: proc(ctx: ^GameContext) {
	STEP :: 5

	if rl.IsKeyDown(.LEFT_SHIFT) {
		if rl.IsKeyDown(.UP) {
			if ctx.world.camera.object.zoom >= 5.0 {return}
			ctx.world.camera.object.zoom += 0.01
		} else if rl.IsKeyDown(.DOWN) {
			if ctx.world.camera.object.zoom <= 0.2 {return}
			ctx.world.camera.object.zoom -= 0.01
		}
		return
	}

	if rl.IsKeyDown(.LEFT) {
		ctx.world.camera.object.target.x -= STEP
	} else if rl.IsKeyDown(.RIGHT) {
		ctx.world.camera.object.target.x += STEP
	}

	if rl.IsKeyDown(.UP) {
		ctx.world.camera.object.target.y -= STEP
	} else if rl.IsKeyDown(.DOWN) {
		ctx.world.camera.object.target.y += STEP
	}

}

DebugMode :: struct {
	camera:       bool,
	entities:     bool,
	informations: bool,
}

// Handles all the information to run the game
GameContext :: struct {
	world:     World,
	assets:    ^AssetContext,
	quit:      bool,
	debugMode: DebugMode,
}

deleteGameContext :: proc(self: ^GameContext) {
	deleteAssetContext(self.assets)
	deleteWorld(&self.world)
	free(self.assets)
}

// Update physics, inputs, etc.
update_game :: proc(self: ^GameContext) {
	getInputs(self)
	cameraMovement(self)
	self.world.cursor.position = rl.GetMousePosition()
	pointingToEntity: bool = false
	for &entity in self.world.entities {
		if rl.CheckCollisionPointRec(
			self.world.cursor.position,
			rl.Rectangle {
				x = entity.position.x,
				y = entity.position.y,
				width = f32(self.world.assets.textures[entity.textureId].width),
				height = f32(self.world.assets.textures[entity.textureId].height),
			},
		) {
			pointingToEntity = true
			if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
				rl.DrawText(
					fmt.ctprintf("%s", entity.onClick()),
					20,
					self.world.size.y - 40,
					15,
					rl.RED,
				)
			} else {
				rl.DrawText(
					fmt.ctprintf("%s", entity.onHover()),
					20,
					self.world.size.y - 40,
					15,
					rl.RED,
				)
			}
		}
		// moveEntity(&entity, movement, self)
	}
	if pointingToEntity do changeCursorStyle(&self.world.cursor, CursorStyle.Pointing)
	else do changeCursorStyle(&self.world.cursor, CursorStyle.Default)
}

// Render all entities of the game
render_game :: proc(self: ^GameContext) {
	beginCamera(&self.world.camera)
	for &entity in self.world.entities {
		rTexture := getTexture(self.assets, entity.textureId)
		if rTexture == nil do continue
		texture := rTexture.(rl.Texture)
		rl.DrawTextureV(texture, entity.position, rl.WHITE)
	}
	// Draw the cursor with its latest associated style
	drawCursor(&self.world.cursor)
	endCamera(&self.world.camera)
}

render_ui :: proc(self: ^GameContext) {
	beginCamera(&self.world.camera)

	if self.debugMode.camera {
		drawDynamicGrid(&self.world.camera)
	}

	if self.debugMode.entities {
		for &entity in self.world.entities {
			rTexture := getTexture(self.assets, entity.textureId)
			if rTexture == nil do continue
			texture := rTexture.(rl.Texture)

			// Draw Entity ID and Box in world space
			rl.DrawText(
				fmt.ctprintf("%s", entity.id),
				i32(entity.position.x),
				i32(entity.position.y - 15),
				10,
				rl.BLACK,
			)
			rl.DrawRectangleLinesEx(
				{entity.position.x, entity.position.y, f32(texture.width), f32(texture.height)},
				1.0 / self.world.camera.object.zoom, // Keep lines thin regardless of zoom
				rl.BLACK,
			)
		}
	}

	endCamera(&self.world.camera)

	if self.debugMode.informations {
		rl.DrawFPS(10, 10)

		// Define a panel area for our debug info
		debug_panel_rect := rl.Rectangle{10, 40, 300, 160}

		// RayGui Window Box
		rl.GuiWindowBox(debug_panel_rect, "ENGINE DEBUGGER")

		// Draw info inside the panel using GuiLabel
		curr_y: f32 = 70
		spacing: f32 = 24

		rl.GuiLabel({20, curr_y, 280, 20}, fmt.ctprint("Project: msw project"))
		curr_y += spacing

		cam_str := fmt.ctprintf(
			"Cam target: %.1f, %.1f (z: %.2f)",
			self.world.camera.object.target.x,
			self.world.camera.object.target.y,
			self.world.camera.object.zoom,
		)
		rl.GuiLabel({20, curr_y, 280, 20}, cam_str)
		curr_y += spacing

		cursor_str := fmt.ctprintf(
			"Cursor World: %.1f, %.1f",
			self.world.cursor.position.x,
			self.world.cursor.position.y,
		)
		rl.GuiLabel({20, curr_y, 280, 20}, cursor_str)
		curr_y += spacing

		// Example Toggle button to show how RayGui handles input
		if rl.GuiButton({20, curr_y, 120, 24}, "RESET CAMERA") {
			self.world.camera.object.target = {0, 0}
			self.world.camera.object.zoom = 1.0
		}
	}
}
