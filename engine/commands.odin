package engine

import rl "vendor:raylib"

SpaceType :: enum {
	Screen,
	World,
}

DrawTextCommand :: struct {
	position: [2]i32,
	size:     [2]i32,
	color:    rl.Color,
	text:     Maybe(cstring),
	space:    SpaceType,
}

DrawCursorCommand :: struct {
	newStyle: CursorStyle,
}

DrawCommand :: union {
	DrawTextCommand,
	DrawCursorCommand,
}

deleteDrawCommand :: proc(self: ^DrawCommand) {}
