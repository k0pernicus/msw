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
	// Maybe it does not make sense to keep the cursor command here
	// It can be in a sort of "event queue" and handled there
	DrawCursorCommand,
}

deleteDrawCommand :: proc(self: ^DrawCommand) {}
