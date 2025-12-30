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

initCursor :: proc() -> Cursor {
	cursor := Cursor {
		position = rl.GetMousePosition(),
		style    = CursorStyle.Default,
	}
	enable(&cursor)
	return cursor
}

drawCursor :: proc(self: ^Cursor) {
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

changeCursorStyle :: proc(self: ^Cursor, newStyle: CursorStyle) {
	if self.style == newStyle do return
	self.style = newStyle
}
