package engine

import rl "vendor:raylib"

CursorStyle :: enum {
	Default,
	Pointing,
}

Cursor :: struct {
	position: Coordinate2D,
	style:    CursorStyle,
	hidden:   bool,
}

init_cursor :: proc() -> Cursor {
	cursor := Cursor {
		position = rl.GetMousePosition(),
		style    = CursorStyle.Default,
	}
	enable(&cursor)
	return cursor
}

draw_cursor :: proc(self: ^Cursor) {
	if self.hidden do return
	switch self.style {
	case CursorStyle.Default:
		rl.SetMouseCursor(rl.MouseCursor.DEFAULT)
	case CursorStyle.Pointing:
		rl.SetMouseCursor(rl.MouseCursor.POINTING_HAND)
	}
}

enable :: proc(self: ^Cursor) {
	self.hidden = false
	rl.EnableCursor()
	rl.ShowCursor()
}

hidden :: proc(self: ^Cursor) {
	self.hidden = true
	rl.DisableCursor() // TODO : check if hidden means disabled in this case...
	rl.HideCursor()
}

change_cursor_style :: proc(self: ^Cursor, new_style: CursorStyle) {
	if self.style == new_style do return
	self.style = new_style
}
