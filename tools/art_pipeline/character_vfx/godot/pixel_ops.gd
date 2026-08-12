extends RefCounted


static func parse_hex(value: String) -> PackedInt32Array:
	return PackedInt32Array([
		value.substr(1, 2).hex_to_int(),
		value.substr(3, 2).hex_to_int(),
		value.substr(5, 2).hex_to_int(),
	])


static func nearest_source_index(
	destination_index: int, source_size: int, destination_size: int
) -> int:
	if source_size <= 0 or destination_size <= 0:
		return -1
	if destination_index < 0 or destination_index >= destination_size:
		return -1
	return mini(source_size - 1, floori(float(destination_index * source_size) / destination_size))


static func resize_nearest(source: Image, width: int, height: int) -> Image:
	var source_image := source.duplicate() as Image
	source_image.convert(Image.FORMAT_RGBA8)
	var source_data := source_image.get_data()
	var result_data := PackedByteArray()
	result_data.resize(width * height * 4)
	for y: int in range(height):
		var source_y := nearest_source_index(y, source_image.get_height(), height)
		for x: int in range(width):
			var source_x := nearest_source_index(x, source_image.get_width(), width)
			var source_offset := (source_y * source_image.get_width() + source_x) * 4
			var result_offset := (y * width + x) * 4
			for channel: int in range(4):
				result_data[result_offset + channel] = source_data[source_offset + channel]
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, result_data)


static func key_and_threshold(source: Image, background: PackedInt32Array, threshold: int) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	for pixel_index: int in range(image.get_width() * image.get_height()):
		var offset := pixel_index * 4
		var is_background := (
			data[offset] == background[0]
			and data[offset + 1] == background[1]
			and data[offset + 2] == background[2]
		)
		if is_background or data[offset + 3] < threshold:
			for channel: int in range(4):
				data[offset + channel] = 0
		else:
			data[offset + 3] = 255
	return Image.create_from_data(
		image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data
	)


static func palette_map(source: Image, palette: Array[PackedInt32Array]) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	for pixel_index: int in range(image.get_width() * image.get_height()):
		var offset := pixel_index * 4
		if data[offset + 3] == 0:
			for channel: int in range(4):
				data[offset + channel] = 0
			continue
		var best := palette[0]
		var best_distance := 1 << 62
		for candidate: PackedInt32Array in palette:
			var red_delta := int(data[offset]) - candidate[0]
			var green_delta := int(data[offset + 1]) - candidate[1]
			var blue_delta := int(data[offset + 2]) - candidate[2]
			var distance := (
				red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta
			)
			if distance < best_distance:
				best = candidate
				best_distance = distance
		data[offset] = best[0]
		data[offset + 1] = best[1]
		data[offset + 2] = best[2]
		data[offset + 3] = 255
	return Image.create_from_data(
		image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data
	)


static func _opaque(data: PackedByteArray, width: int, x: int, y: int) -> bool:
	return data[(y * width + x) * 4 + 3] == 255


static func remove_small_components(source: Image, minimum_size: int) -> Image:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	if minimum_size <= 1:
		return image
	var width := image.get_width()
	var height := image.get_height()
	var data := image.get_data()
	var visited := PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for y: int in range(height):
		for x: int in range(width):
			var start := y * width + x
			if visited[start] == 1 or not _opaque(data, width, x, y):
				continue
			var queue: Array[int] = [start]
			var component: Array[int] = []
			visited[start] = 1
			var cursor := 0
			while cursor < queue.size():
				var current := queue[cursor]
				cursor += 1
				component.append(current)
				var current_x := current % width
				var current_y := current / width
				for direction: Vector2i in directions:
					var neighbor_x := current_x + direction.x
					var neighbor_y := current_y + direction.y
					if neighbor_x < 0 or neighbor_y < 0 or neighbor_x >= width or neighbor_y >= height:
						continue
					var neighbor := neighbor_y * width + neighbor_x
					if visited[neighbor] == 0 and _opaque(data, width, neighbor_x, neighbor_y):
						visited[neighbor] = 1
						queue.append(neighbor)
			if component.size() < minimum_size:
				for pixel_index: int in component:
					var offset := pixel_index * 4
					for channel: int in range(4):
						data[offset + channel] = 0
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)


static func opaque_bounds(source: Image) -> Dictionary:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var data := image.get_data()
	var left := width
	var top := height
	var right := -1
	var bottom := -1
	for y: int in range(height):
		for x: int in range(width):
			if not _opaque(data, width, x, y):
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	return {
		"valid": right >= 0,
		"left": left,
		"top": top,
		"right": right,
		"bottom": bottom,
	}


static func anchor_in_cell(
	source: Image, cell_size: Vector2i, anchor_x: int, foot_y: int
) -> Dictionary:
	var source_image := source.duplicate() as Image
	source_image.convert(Image.FORMAT_RGBA8)
	var bounds := opaque_bounds(source_image)
	if not bool(bounds["valid"]):
		return {"error": "frame opaque_pixels expected=>0 actual=0"}
	var center_x := floori(float(int(bounds["left"]) + int(bounds["right"])) / 2.0)
	var dx := anchor_x - center_x
	var dy := foot_y - int(bounds["bottom"])
	var result_data := PackedByteArray()
	result_data.resize(cell_size.x * cell_size.y * 4)
	result_data.fill(0)
	var source_data := source_image.get_data()
	for y: int in range(source_image.get_height()):
		for x: int in range(source_image.get_width()):
			var source_offset := (y * source_image.get_width() + x) * 4
			if source_data[source_offset + 3] == 0:
				continue
			var destination_x := x + dx
			var destination_y := y + dy
			if (
				destination_x <= 0
				or destination_y <= 0
				or destination_x >= cell_size.x - 1
				or destination_y >= cell_size.y - 1
			):
				return {
					"error": "frame border-contact source=%d,%d destination=%d,%d cell=%dx%d"
					% [x, y, destination_x, destination_y, cell_size.x, cell_size.y]
				}
			var destination_offset := (destination_y * cell_size.x + destination_x) * 4
			for channel: int in range(4):
				result_data[destination_offset + channel] = source_data[source_offset + channel]
	var result := Image.create_from_data(
		cell_size.x, cell_size.y, false, Image.FORMAT_RGBA8, result_data
	)
	var anchored := opaque_bounds(result)
	return {
		"image": result,
		"anchor": {
			"source_left": bounds["left"],
			"source_top": bounds["top"],
			"source_right": bounds["right"],
			"source_bottom": bounds["bottom"],
			"source_center_x": center_x,
			"dx": dx,
			"dy": dy,
			"anchored_left": anchored["left"],
			"anchored_top": anchored["top"],
			"anchored_right": anchored["right"],
			"anchored_bottom": anchored["bottom"],
			"anchored_center_x": floori(
				float(int(anchored["left"]) + int(anchored["right"])) / 2.0
			),
		},
	}


static func composite_atlas(cells: Array[Dictionary]) -> Image:
	var width := 768
	var height := 384
	var data := PackedByteArray()
	data.resize(width * height * 4)
	data.fill(0)
	for cell: Dictionary in cells:
		var image: Image = cell["image"]
		var source := image.get_data()
		var origin_x := int(cell["column"]) * 192
		var origin_y := int(cell["row"]) * 192
		for y: int in range(192):
			for x: int in range(192):
				var source_offset := (y * 192 + x) * 4
				var destination_offset := ((origin_y + y) * width + origin_x + x) * 4
				for channel: int in range(4):
					data[destination_offset + channel] = source[source_offset + channel]
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data)


static func _grayscale(red: int, green: int, blue: int) -> int:
	return floori(float(77 * red + 150 * green + 29 * blue + 128) / 256.0)


static func build_contact_sheet(atlas: Image) -> Image:
	var source := atlas.duplicate() as Image
	source.convert(Image.FORMAT_RGBA8)
	var source_data := source.get_data()
	var width := 1536
	var height := 256
	var result := PackedByteArray()
	result.resize(width * height * 4)
	var backgrounds: Array[PackedInt32Array] = [
		parse_hex("#E8DFCF"), parse_hex("#1B2230"), parse_hex("#808080")
	]
	for panel: int in range(3):
		var background := backgrounds[panel]
		for y: int in range(height):
			for x: int in range(panel * 512, panel * 512 + 512):
				var offset := (y * width + x) * 4
				result[offset] = background[0]
				result[offset + 1] = background[1]
				result[offset + 2] = background[2]
				result[offset + 3] = 255
		for row: int in range(2):
			for column: int in range(4):
				for y: int in range(72):
					var source_y := row * 192 + nearest_source_index(y, 192, 72)
					for x: int in range(72):
						var source_x := column * 192 + nearest_source_index(x, 192, 72)
						var source_offset := (source_y * 768 + source_x) * 4
						var destination_x := panel * 512 + column * 128 + 28 + x
						var destination_y := row * 128 + 28 + y
						var destination_offset := (destination_y * width + destination_x) * 4
						if source_data[source_offset + 3] == 0:
							continue
						if panel == 2:
							var gray := _grayscale(
								source_data[source_offset],
								source_data[source_offset + 1],
								source_data[source_offset + 2]
							)
							for channel: int in range(3):
								result[destination_offset + channel] = gray
						else:
							for channel: int in range(3):
								result[destination_offset + channel] = source_data[
									source_offset + channel
								]
						result[destination_offset + 3] = 255
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, result)
