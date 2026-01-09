package game

import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strings"

ASSETS_FOLDER :: "assets/"
LEVELS_DESCRIPTION :: "levels.json"

Coordinate2D :: [2]f32
Size2D :: [2]i32

EntityDesc :: struct {
	id:         string `json:"id"`,
	texture_id: string `json:"texture_id"`,
	position:   Coordinate2D `json:"position"`,
}

delete_entities :: proc(entites: ^[dynamic]EntityDesc) {
	for &entity in entites {
		delete_string(entity.id)
	}
}

TileDesc :: struct {
	id:         string `json:"id"`,
	texture_id: string `json:"texture_id"`,
	position:   Coordinate2D `json:"position"`,
}

delete_tiles :: proc(tiles: ^[]TileDesc) {
	for &tile in tiles {
		delete_string(tile.id)
		delete_string(tile.texture_id)
	}
}

Level :: struct {
	name:       string `json:"name"`,
	dimensions: Size2D `json:"dimensions"`,
	entities:   [dynamic]EntityDesc `json:"entities"`,
	tiles:      []TileDesc `json:"tiles"`,
}

delete_levels :: proc(levels: ^[]Level) {
	for &level in levels {
		delete_string(level.name)
		delete_entities(&level.entities)
		delete_tiles(&level.tiles)
		delete_dynamic_array(level.entities)
	}
}

LevelError :: enum {
	GetFileSizeErr,
	ReadFileErr,
	OpenFileErr,
	MarshalErr,
	UnmarshalErr,
	SaveFileErr,
}

load_levels :: proc() -> ([]Level, LevelError) {
	levels_desc_path := strings.concatenate([]string{ASSETS_FOLDER, LEVELS_DESCRIPTION})
	defer delete(levels_desc_path)
	if !os.exists(levels_desc_path) do return nil, .OpenFileErr
	fd, open_err := os.open(levels_desc_path, os.O_RDONLY)
	if open_err != nil {
		log.errorf("error opening levels description file: %s", open_err)
		return nil, .OpenFileErr
	}
	file_size, size_err := os.file_size(fd)
	if size_err != nil {
		log.errorf("error getting size of assets description file: %s", open_err)
		return nil, .GetFileSizeErr
	}
	file_content: []u8 = make([]u8, file_size)
	defer delete(file_content)
	if read_bytes, err := os.read(fd, file_content); err != nil || read_bytes == 0 {
		log.errorf("error reading levels description file: %s", err)
		return nil, .ReadFileErr
	}
	description: []Level

	// TODO : Check for a leak here
	if err := json.unmarshal(file_content, &description); err != nil {
		log.errorf("error unmarshalling levels description file: %s", err)
		return nil, .UnmarshalErr
	}
	return description, nil
}

save_level :: proc(
	levels: ^[]Level,
	level_to_save: Level,
	filename: string = LEVELS_DESCRIPTION,
) -> LevelError {
	level_idx: int = -1
	for level, idx in levels {
		if level.name == level_to_save.name {
			level_idx = idx
		}
	}

	if level_idx == -1 {
		unimplemented("implement the missing part in saving new level !!!")
	}

	levels[level_idx] = level_to_save

	data, marshal_err := json.marshal(levels^)
	defer delete(data)

	if marshal_err != nil {
		return .MarshalErr
	}

	levels_desc_path := strings.concatenate([]string{ASSETS_FOLDER, filename})
	defer delete(levels_desc_path)

	if success := os.write_entire_file(levels_desc_path, data); !success {
		log.errorf("error writing bytes in file at path '%s'", levels_desc_path)
		return .SaveFileErr
	}

	return nil
}
