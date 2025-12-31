package game

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

ASSETS_FOLDER :: "assets/"
LEVELS_DESCRIPTION :: "levels.json"

Coordinate2D :: [2]f32

EntityDesc :: struct {
	id:        string `json:"id"`,
	textureId: string `json:"texture_id"`,
	position:  Coordinate2D `json:"position"`,
}

deleteEntities :: proc(entites: ^[]EntityDesc) {
	for &entity in entites {
		delete_string(entity.id)
		delete_string(entity.textureId)
	}
}

TileDesc :: struct {
	id:        string `json:"id"`,
	textureId: string `json:"texture_id"`,
	position:  Coordinate2D `json:"position"`,
}

deleteTiles :: proc(tiles: ^[]TileDesc) {
	for &tile in tiles {
		delete_string(tile.id)
		delete_string(tile.textureId)
	}
}

Level :: struct {
	name:     string `json:"name"`,
	entities: []EntityDesc `json:"entities"`,
	tiles:    []TileDesc `json:"tiles"`,
}

deleteLevels :: proc(levels: ^[]Level) {
	for &level in levels {
		delete_string(level.name)
		deleteEntities(&level.entities)
		deleteTiles(&level.tiles)
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

loadLevels :: proc() -> ([]Level, LevelError) {
	levelsDescPath := strings.concatenate([]string{ASSETS_FOLDER, LEVELS_DESCRIPTION})
	defer delete(levelsDescPath)
	if !os.exists(levelsDescPath) do return nil, .OpenFileErr
	fd, openErr := os.open(levelsDescPath, os.O_RDONLY)
	if openErr != nil {
		fmt.eprintfln("[ERROR] error opening levels description file: %s", openErr)
		return nil, .OpenFileErr
	}
	fileSize, sizeErr := os.file_size(fd)
	if sizeErr != nil {
		fmt.eprintfln("[ERROR] error getting size of assets description file: %s", openErr)
		return nil, .GetFileSizeErr
	}
	fileContent: []u8 = make([]u8, fileSize)
	defer delete(fileContent)
	if readBytes, err := os.read(fd, fileContent); err != nil || readBytes == 0 {
		fmt.eprintfln("[ERROR] error reading levels description file: %s", err)
		return nil, .ReadFileErr
	}
	description: []Level

	// TODO : Check for a leak here
	if err := json.unmarshal(fileContent, &description); err != nil {
		fmt.eprintfln("[ERROR] error unmarshalling levels description file: %s", err)
		return nil, .UnmarshalErr
	}
	return description, nil
}

saveLevel :: proc(
	levels: ^[]Level,
	levelToSave: Level,
	filename: string = LEVELS_DESCRIPTION,
) -> LevelError {
	levelIdx: int = -1
	for level, idx in levels {
		if level.name == levelToSave.name {
			levelIdx = idx
		}
	}

	if levelIdx == -1 {
		unimplemented("implement the missing part in saving new level !!!")
	}

	levels[levelIdx] = levelToSave

	data, marshalError := json.marshal(levels^)
	defer delete(data)

	if marshalError != nil {
		return .MarshalErr
	}

	levelsDescPath := strings.concatenate([]string{ASSETS_FOLDER, filename})
	defer delete(levelsDescPath)

	if success := os.write_entire_file(levelsDescPath, data); !success {
		fmt.eprintfln("[ERROR] error writing bytes in file at path '%s'", levelsDescPath)
		return .SaveFileErr
	}

	return nil
}
