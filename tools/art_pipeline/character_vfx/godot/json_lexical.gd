extends RefCounted

var _text := ""
var _index := 0
var _types: Dictionary = {}
var _duplicates: Array[String] = []
var _nul_escapes: Array[String] = []


func analyze(text: String) -> Dictionary:
	_text = text
	_index = 0
	_types = {}
	_duplicates = []
	_nul_escapes = []
	_skip_whitespace()
	var detail := _parse_value("")
	_skip_whitespace()
	if detail.is_empty() and _index != _text.length():
		detail = "trailing JSON content index=%d" % _index
	return {
		"ok": detail.is_empty(),
		"detail": detail,
		"types": _types,
		"duplicates": _duplicates,
		"nul_escapes": _nul_escapes,
	}


func _skip_whitespace() -> void:
	while _index < _text.length() and _text[_index] in [" ", "\t", "\r", "\n"]:
		_index += 1


func _pointer(path: String, key: String) -> String:
	var escaped := key.replace("~", "~0").replace("/", "~1")
	return "%s/%s" % [path, escaped]


func _parse_value(path: String) -> String:
	_skip_whitespace()
	var detail := ""
	if _index >= _text.length():
		detail = "unexpected end of JSON"
	else:
		var character := _text[_index]
		if character == "{":
			_types[path] = "object"
			detail = _parse_object(path)
		elif character == "[":
			_types[path] = "array"
			detail = _parse_array(path)
		elif character == '"':
			_types[path] = "string"
			var token := _parse_string_token()
			if not token["ok"]:
				detail = token["detail"]
			elif token["contains_nul_escape"]:
				_nul_escapes.append(path)
		elif character == "t":
			_types[path] = "bool"
			detail = _consume_literal("true")
		elif character == "f":
			_types[path] = "bool"
			detail = _consume_literal("false")
		elif character == "n":
			_types[path] = "null"
			detail = _consume_literal("null")
		elif character == "-" or character.is_valid_int():
			detail = _parse_number(path)
		else:
			detail = "unexpected JSON token index=%d" % _index
	return detail


func _parse_object(path: String) -> String:
	_index += 1
	_skip_whitespace()
	var detail := ""
	var keys: Dictionary = {}
	if _index < _text.length() and _text[_index] == "}":
		_index += 1
		return detail
	while detail.is_empty():
		if _index >= _text.length() or _text[_index] != '"':
			detail = "object key expected index=%d" % _index
			break
		var token := _parse_string_token()
		if not token["ok"]:
			detail = token["detail"]
			break
		var key := String(token["value"])
		if keys.has(key):
			_duplicates.append(_pointer(path, key))
		keys[key] = true
		_skip_whitespace()
		if _index >= _text.length() or _text[_index] != ":":
			detail = "object colon expected index=%d" % _index
			break
		_index += 1
		detail = _parse_value(_pointer(path, key))
		if not detail.is_empty():
			break
		_skip_whitespace()
		if _index >= _text.length():
			detail = "unterminated object"
			break
		if _text[_index] == "}":
			_index += 1
			break
		if _text[_index] != ",":
			detail = "object comma expected index=%d" % _index
			break
		_index += 1
		_skip_whitespace()
	return detail


func _parse_array(path: String) -> String:
	_index += 1
	_skip_whitespace()
	var detail := ""
	var item_index := 0
	if _index < _text.length() and _text[_index] == "]":
		_index += 1
		return detail
	while detail.is_empty():
		detail = _parse_value(_pointer(path, str(item_index)))
		if not detail.is_empty():
			break
		item_index += 1
		_skip_whitespace()
		if _index >= _text.length():
			detail = "unterminated array"
			break
		if _text[_index] == "]":
			_index += 1
			break
		if _text[_index] != ",":
			detail = "array comma expected index=%d" % _index
			break
		_index += 1
		_skip_whitespace()
	return detail


func _parse_string_token() -> Dictionary:
	var start := _index
	_index += 1
	var detail := ""
	var closed := false
	var contains_nul_escape := false
	while _index < _text.length():
		var character := _text[_index]
		if character == '"':
			_index += 1
			closed = true
			break
		if character == "\n" or character == "\r":
			detail = "newline in JSON string index=%d" % _index
			break
		if character == "\\":
			_index += 1
			if _index >= _text.length():
				detail = "unterminated JSON escape"
				break
			var escape := _text[_index]
			if escape not in ['"', "\\", "/", "b", "f", "n", "r", "t", "u"]:
				detail = "invalid JSON escape index=%d" % _index
				break
			if escape == "u":
				if _index + 4 >= _text.length():
					detail = "short unicode escape index=%d" % _index
					break
				for offset: int in range(1, 5):
					if _text[_index + offset] not in "0123456789abcdefABCDEF":
						detail = "invalid unicode escape index=%d" % _index
						break
				if not detail.is_empty():
					break
				if _text.substr(_index + 1, 4).to_lower() == "0000":
					contains_nul_escape = true
				_index += 4
		_index += 1
	if detail.is_empty() and not closed:
		detail = "unterminated JSON string"
	var value := ""
	if detail.is_empty():
		var raw := _text.substr(start, _index - start)
		var parsed: Variant = JSON.parse_string(raw)
		if typeof(parsed) != TYPE_STRING:
			detail = "invalid JSON string token"
		else:
			value = String(parsed)
	return {
		"ok": detail.is_empty(),
		"detail": detail,
		"value": value,
		"contains_nul_escape": contains_nul_escape,
	}


func _consume_literal(literal: String) -> String:
	var detail := ""
	if _text.substr(_index, literal.length()) != literal:
		detail = "invalid JSON literal index=%d" % _index
	else:
		_index += literal.length()
	return detail


func _parse_number(path: String) -> String:
	var start := _index
	var detail := ""
	if _text[_index] == "-":
		_index += 1
	if _index >= _text.length():
		return "truncated JSON number"
	if _text[_index] == "0":
		_index += 1
	elif _text[_index] in "123456789":
		while _index < _text.length() and _text[_index].is_valid_int():
			_index += 1
	else:
		detail = "invalid JSON integer index=%d" % _index
	var is_integer := true
	if detail.is_empty() and _index < _text.length() and _text[_index] == ".":
		is_integer = false
		_index += 1
		var fraction_start := _index
		while _index < _text.length() and _text[_index].is_valid_int():
			_index += 1
		if _index == fraction_start:
			detail = "invalid JSON fraction index=%d" % _index
	if detail.is_empty() and _index < _text.length() and _text[_index] in ["e", "E"]:
		is_integer = false
		_index += 1
		if _index < _text.length() and _text[_index] in ["+", "-"]:
			_index += 1
		var exponent_start := _index
		while _index < _text.length() and _text[_index].is_valid_int():
			_index += 1
		if _index == exponent_start:
			detail = "invalid JSON exponent index=%d" % _index
	if detail.is_empty():
		_types[path] = "integer" if is_integer else "number"
		var token := _text.substr(start, _index - start)
		if JSON.parse_string(token) == null:
			detail = "invalid JSON number token"
	return detail
