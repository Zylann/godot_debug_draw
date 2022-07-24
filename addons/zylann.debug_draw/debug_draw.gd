
## @brief Single-file autoload for debug drawing and printing.
## Draw and print on screen from anywhere in a single line of code.
## Find it quickly by naming it "DDD".

# TODO Thread-safety
# TODO 2D functions

extends CanvasLayer

## @brief How many frames HUD text lines remain shown after being invoked.
const TEXT_LINGER_FRAMES = 5
## @brief How many frames lines remain shown after being drawn.
const LINES_LINGER_FRAMES = 1
## @brief Color of the text drawn as HUD
const TEXT_COLOR = Color.white
## @brief Background color of the text drawn as HUD
const TEXT_BG_COLOR = Color(0.3, 0.3, 0.3, 0.8)

# 2D

var _canvas_item : CanvasItem = null
var _texts := {}
var _font : Font = null

# 3D

var _boxes := []
var _box_pool := []
var _box_mesh : Mesh = null
var _line_material_pool := []

var _lines := []
var _line_immediate_geometry : ImmediateGeometry


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	layer = 100
	# Get default font
	# Meh
	var c := Control.new()
	add_child(c)
	_font = c.get_font("font")
	c.queue_free()
	
	_line_immediate_geometry = ImmediateGeometry.new()
	_line_immediate_geometry.material_override = _get_line_material()
	add_child(_line_immediate_geometry)


## @brief Draws the unshaded outline of a 3D cube.
## @param position: world-space position of the center of the cube
## @param size: size of the cube in world units
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_cube(position: Vector3, size: float, color: Color = Color.white, linger := 0):
	draw_box(position, Vector3(size, size, size), color, linger)


## @brief Draws the unshaded outline of a 3D box.
## @param position: world-space position of the center of the box
## @param size: size of the box in world units
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_box(position: Vector3, size: Vector3, color: Color = Color.white, linger_frames = 0):
	var mi := _get_box()
	var mat := _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.translation = position
	mi.scale = size
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES + linger_frames
	})


## @brief Draws the unshaded outline of a 3D transformed cube.
## @param trans: transform of the cube. The basis defines its size.
## @param color
func draw_transformed_cube(trans: Transform, color: Color = Color.white):
	var mi := _get_box()
	var mat := _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.transform = Transform(trans.basis, trans.origin - trans.basis * Vector3(0.5,0.5,0.5))
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES
	})


## @brief Draws the basis of the given transform using 3 lines
##        of color red for X, green for Y, and blue for Z.
## @param transform
## @param scale: extra scale applied on top of the transform
func draw_axes(transform: Transform, scale = 1.0):
	draw_ray_3d(transform.origin, transform.basis.x, scale, Color(1,0,0))
	draw_ray_3d(transform.origin, transform.basis.y, scale, Color(0,1,0))
	draw_ray_3d(transform.origin, transform.basis.z, scale, Color(0,0,1))


## @brief Draws the unshaded outline of a 3D box.
## @param aabb: world-space box to draw as an AABB
## @param color
## @param linger_frames: optionally makes the box remain drawn for longer
func draw_box_aabb(aabb: AABB, color = Color.white, linger_frames = 0):
	var mi := _get_box()
	var mat := _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.translation = aabb.position
	mi.scale = aabb.size
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES + linger_frames
	})


## @brief Draws an unshaded 3D line.
## @param a: begin position in world units
## @param b: end position in world units
## @param color
func draw_line_3d(a: Vector3, b: Vector3, color: Color):
	_lines.append([
		a, b, color,
		Engine.get_frames_drawn() + LINES_LINGER_FRAMES,
	])


## @brief Draws an unshaded 3D line defined as a ray.
## @param origin: begin position in world units
## @param direction
## @param length: length of the line in world units
## @param color
func draw_ray_3d(origin: Vector3, direction: Vector3, length: float, color : Color):
	draw_line_3d(origin, origin + direction * length, color)


## @brief Adds a text monitoring line to the HUD, from the provided value.
## It will be shown as such: - {key}: {text}
## Multiple calls with the same `key` will override previous text.
## @param key: identifier of the line
## @param text: text to show next to the key
func set_text(key: String, value):
	_texts[key] = {
		"text": value if typeof(value) == TYPE_STRING else str(value),
		"frame": Engine.get_frames_drawn() + TEXT_LINGER_FRAMES
	}


func _get_box() -> MeshInstance:
	var mi : MeshInstance
	if len(_box_pool) == 0:
		mi = MeshInstance.new()
		if _box_mesh == null:
			_box_mesh = _create_wirecube_mesh(Color.white)
		mi.mesh = _box_mesh
		add_child(mi)
	else:
		mi = _box_pool[-1]
		_box_pool.pop_back()
	return mi


func _recycle_box(mi: MeshInstance):
	mi.hide()
	_box_pool.append(mi)


func _get_line_material() -> SpatialMaterial:
	var mat : SpatialMaterial
	if len(_line_material_pool) == 0:
		mat = SpatialMaterial.new()
		mat.flags_unshaded = true
		mat.vertex_color_use_as_albedo = true
	else:
		mat = _line_material_pool[-1]
		_line_material_pool.pop_back()
	return mat


func _recycle_line_material(mat: SpatialMaterial):
	_line_material_pool.append(mat)


func _process(delta: float):
	_process_boxes()
	_process_lines()
	_process_canvas()


func _process_3d_boxes_delayed_free(items: Array):
	var i := 0
	while i < len(items):
		var d = items[i]
		if d.frame <= Engine.get_frames_drawn():
			_recycle_line_material(d.node.material_override)
			d.node.queue_free()
			items[i] = items[len(items) - 1]
			items.pop_back()
		else:
			i += 1


func _process_boxes():
	_process_3d_boxes_delayed_free(_boxes)

	# Progressively delete boxes in pool
	if len(_box_pool) > 0:
		var last = _box_pool[-1]
		_box_pool.pop_back()
		last.queue_free()


func _process_lines():
	_line_immediate_geometry.clear()
	_line_immediate_geometry.begin(Mesh.PRIMITIVE_LINES)
	
	for line in _lines:
		var p1 : Vector3 = line[0]
		var p2 : Vector3 = line[1]
		var color : Color = line[2]
		
		_line_immediate_geometry.set_color(color)
		_line_immediate_geometry.add_vertex(p1)
		_line_immediate_geometry.add_vertex(p2)
	
	_line_immediate_geometry.end()
	
	# Delayed removal
	var i := 0
	while i < len(_lines):
		var item = _lines[i]
		var frame = item[3]
		if frame <= Engine.get_frames_drawn():
			_lines[i] = _lines[len(_lines) - 1]
			_lines.pop_back()
		else:
			i += 1


func _process_canvas():
	# Remove text lines after some time
	for key in _texts.keys():
		var t = _texts[key]
		if t.frame <= Engine.get_frames_drawn():
			_texts.erase(key)

	# Update canvas
	if _canvas_item == null:
		_canvas_item = Node2D.new()
		_canvas_item.position = Vector2(8, 8)
		_canvas_item.connect("draw", self, "_on_CanvasItem_draw")
		add_child(_canvas_item)
	_canvas_item.update()


func _on_CanvasItem_draw():
	var ci := _canvas_item

	var ascent := Vector2(0, _font.get_ascent())
	var pos := Vector2()
	var xpad := 2
	var ypad := 1
	var font_offset := ascent + Vector2(xpad, ypad)
	var line_height := _font.get_height() + 2 * ypad

	for key in _texts.keys():
		var t = _texts[key]
		var text := str(key, ": ", t.text, "\n")
		var ss := _font.get_string_size(text)
		ci.draw_rect(Rect2(pos, Vector2(ss.x + xpad * 2, line_height)), TEXT_BG_COLOR)
		ci.draw_string(_font, pos + font_offset, text, TEXT_COLOR)
		pos.y += line_height


static func _create_wirecube_mesh(color := Color.white) -> ArrayMesh:
	var positions := PoolVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var colors := PoolColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices := PoolIntArray([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

