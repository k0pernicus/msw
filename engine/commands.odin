package engine

import rl "vendor:raylib"

DrawCommandType :: enum {
	Text,
}

SpaceType :: enum {
	Camera,
	World,
}

DrawCommand :: struct {
	type:     DrawCommandType,
	position: [2]i32,
	size:     [2]i32,
	color:    rl.Color,
	text:     Maybe(cstring),
	space:    SpaceType,
}

deleteDrawCommand :: proc(self: ^DrawCommand) {}
