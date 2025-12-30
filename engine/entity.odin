package engine

// TODO : change to any function (interface ?)
OnClickAction :: proc() -> string
// TODO : change to any function (interface ?)
OnHoverAction :: proc() -> string

// Object to store a texture and
// its current coordinates
Entity :: struct {
	id:        string,
	position:  Coordinate2D,
	textureId: string,
	active:    bool,
	onClick:   OnClickAction,
	onHover:   OnHoverAction,
}

newEntity :: proc(
	id: string,
	textureId: string,
	position: Coordinate2D = [2]f32{},
	onClick: OnClickAction = noAction,
	onHover: OnHoverAction = noAction,
) -> Entity {
	return Entity{id, position, textureId, false, onClick, onHover}
}

setActivity :: proc(self: ^Entity, activity: bool) {
	self.active = activity
}

// Move the entity by `movement`
// This function does not erase the current position by `movement`!
moveEntity :: proc(self: ^Entity, movement: Coordinate2D, gameCtx: ^GameContext) {
	newPosition := self.position + movement
	if newPosition.x < 0 ||
	   newPosition.x > f32(gameCtx.world.size.x) ||
	   newPosition.y < 0 ||
	   newPosition.y > f32(gameCtx.world.size.y) {
		return
	}
	self.position = newPosition
}

setEntityPosition :: proc(self: ^Entity, newPosition: Coordinate2D, gameCtx: ^GameContext) {
	self.position = newPosition
}

noAction :: proc() -> string {
	return "..."
}

actionSayMiaouh :: proc() -> string {
	return "Miaouh!"
}

actionSayGrrh :: proc() -> string {
	return "Grrrrh..."
}
