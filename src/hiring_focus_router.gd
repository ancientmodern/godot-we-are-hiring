class_name HiringFocusRouter
extends RefCounted

var section := ""
var index := 0
var item_count := 0
var columns := 1
var _restored_indices: Dictionary = {}


func configure(next_section: String, next_item_count: int, next_columns: int = 1, preferred_index: int = -1) -> int:
	if not section.is_empty() and item_count > 0:
		_restored_indices[section] = index
	section = next_section
	item_count = maxi(0, next_item_count)
	columns = maxi(1, next_columns)
	var restored := int(_restored_indices.get(section, 0))
	index = preferred_index if preferred_index >= 0 else restored
	index = clampi(index, 0, maxi(0, item_count - 1))
	return index


func set_index(next_index: int) -> int:
	index = clampi(next_index, 0, maxi(0, item_count - 1))
	if not section.is_empty() and item_count > 0:
		_restored_indices[section] = index
	return index


func move(direction: Vector2i, wrap: bool = false) -> int:
	if item_count <= 1 or direction == Vector2i.ZERO:
		return index
	if columns <= 1:
		var delta := direction.y if direction.y != 0 else direction.x
		return set_index(_step(index, delta, item_count, wrap))

	var row := index / columns
	var column := index % columns
	var row_count := int(ceil(float(item_count) / float(columns)))
	if direction.x != 0:
		column = _step(column, direction.x, columns, wrap)
	if direction.y != 0:
		row = _step(row, direction.y, row_count, wrap)
	var candidate := row * columns + column
	if candidate >= item_count:
		# Ragged final rows keep the closest real target in the requested row.
		candidate = item_count - 1
	return set_index(candidate)


func remember_current() -> void:
	if not section.is_empty() and item_count > 0:
		_restored_indices[section] = index


func restored_index(for_section: String) -> int:
	return int(_restored_indices.get(for_section, 0))


func has_focus() -> bool:
	return item_count > 0 and index >= 0 and index < item_count


func _step(value: int, delta: int, count: int, wrap: bool) -> int:
	if count <= 0:
		return 0
	if wrap:
		return posmod(value + signi(delta), count)
	return clampi(value + signi(delta), 0, count - 1)
