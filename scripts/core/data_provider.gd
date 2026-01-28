class_name DataProvider
extends Node
## Loads star history data and provides efficient lookups by date.
##
## Loads pre-cached JSON data from res://data/star_history.json and provides
## O(log n) date lookups via binary search. This class bridges the data file
## and the timeline/rendering systems.

## Emitted when data has been successfully loaded and parsed.
signal data_loaded

## Path to the star history JSON file.
const DATA_PATH := "res://data/star_history.json"

var _repository: String = ""
var _fetched_at: String = ""
var _total_stars: int = 0
var _history: Array[Dictionary] = []
var _is_loaded: bool = false


func _ready() -> void:
	_load_data()


## Returns true if data has been loaded successfully.
func is_loaded() -> bool:
	return _is_loaded


## Returns the repository name from the data file.
func get_repository() -> String:
	return _repository


## Returns when the data was fetched (ISO 8601 timestamp).
func get_fetched_at() -> String:
	return _fetched_at


## Returns the total star count (final value in history).
func get_total_stars() -> int:
	return _total_stars


## Returns the earliest date in the history.
func get_first_date() -> String:
	if _history.is_empty():
		return ""
	return _history[0].get("date", "")


## Returns the most recent date in the history.
func get_last_date() -> String:
	if _history.is_empty():
		return ""
	return _history[_history.size() - 1].get("date", "")


## Returns the number of data points in the history.
func get_history_size() -> int:
	return _history.size()


## Returns the star count for a given date.
## Uses binary search for O(log n) lookup efficiency.
## Returns 0 for dates before the first data point.
## Returns total_stars for dates after the last data point.
func get_star_count(date: String) -> int:
	if _history.is_empty():
		return 0

	# Handle edge cases
	var first_date := get_first_date()
	var last_date := get_last_date()

	if date < first_date:
		return 0

	if date >= last_date:
		return _total_stars

	# Binary search for the date or the nearest earlier date
	var index := _binary_search(date)
	if index < 0:
		return 0

	return _history[index].get("stars", 0)


## Returns the date at a specific index in the history.
## Returns empty string if index is out of bounds.
func get_date_at_index(index: int) -> String:
	if index < 0 or index >= _history.size():
		return ""
	return _history[index].get("date", "")


## Returns the star count at a specific index in the history.
## Returns 0 if index is out of bounds.
func get_stars_at_index(index: int) -> int:
	if index < 0 or index >= _history.size():
		return 0
	return _history[index].get("stars", 0)


## Binary search to find the index of a date or the nearest earlier date.
## Returns -1 if the date is before all entries.
func _binary_search(date: String) -> int:
	var left: int = 0
	var right: int = _history.size() - 1
	var result: int = -1

	while left <= right:
		var mid: int = left + (right - left) / 2
		var mid_date: String = _history[mid].get("date", "")

		if mid_date == date:
			return mid
		elif mid_date < date:
			result = mid  # This could be the answer if no exact match
			left = mid + 1
		else:
			right = mid - 1

	return result


func _load_data() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if not file:
		push_error("DataProvider: Failed to open %s - %s" % [DATA_PATH, FileAccess.get_open_error()])
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("DataProvider: Failed to parse JSON - %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return

	var data: Variant = json.data
	if not data is Dictionary:
		push_error("DataProvider: Expected root JSON object to be a Dictionary")
		return

	_parse_data(data)


func _parse_data(data: Dictionary) -> void:
	_repository = data.get("repository", "")
	_fetched_at = data.get("fetched_at", "")
	_total_stars = data.get("total_stars", 0)

	var history_data: Variant = data.get("history", [])
	if not history_data is Array:
		push_error("DataProvider: Expected 'history' to be an Array")
		return

	_history.clear()
	for entry: Variant in history_data:
		if entry is Dictionary:
			_history.append(entry)

	# Verify history is sorted (should be, but validate)
	if not _is_history_sorted():
		push_warning("DataProvider: History data was not sorted, sorting now")
		_history.sort_custom(_compare_entries_by_date)

	_is_loaded = true
	data_loaded.emit()


func _is_history_sorted() -> bool:
	for i in range(1, _history.size()):
		var prev_date: String = _history[i - 1].get("date", "")
		var curr_date: String = _history[i].get("date", "")
		if prev_date > curr_date:
			return false
	return true


func _compare_entries_by_date(a: Dictionary, b: Dictionary) -> bool:
	return a.get("date", "") < b.get("date", "")
