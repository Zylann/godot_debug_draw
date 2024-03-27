Debug drawing utility
==========================

This is a small debug drawing script, which you can setup as an auto-load singleton. It lets you print text on the screen, draw boxes or lines from anywhere in your code. It is mostly geared towards 3D at the moment.


Usage
-------

Once installed under `addons/zylann.debug_draw`, add the `debug_draw.gd` script as an auto-load to your project and start using it as a singleton.

Example with a singleton named `DebugDraw`:

```gdscript
func _process(delta):
	# Some test variables, usually you'd get them from game logic
	var time = Time.get_ticks_msec() / 1000.0
	var box_pos = Vector3(0, sin(time * 4.0), 0)
	var line_begin = Vector3(-1, sin(time * 4.0), 0)
	var line_end = Vector3(1, cos(time * 4.0), 0)

	DebugDraw.draw_box(box_pos, Vector3(1, 2, 1), Color(0, 1, 0))
	DebugDraw.draw_box_aabb(AABB(Vector3(3, 0, 0), Vector3(2, 1, 1)), Color(0, 1, 0.5))
	DebugDraw.draw_line_3d(line_begin, line_end, Color(1, 1, 0))
	DebugDraw.draw_axes(Transform3D(Basis().rotated(Vector3(0,1,0), time), Vector3(-2, 0, 0)))
	DebugDraw.draw_cube(Vector3(-1, 2, 0), 0.1, Color(sin(time * 10.0) * 0.5 + 0.5, 0.5, 0.5))
	
	var cube_trans = Transform3D(
			Basis().scaled(Vector3(2,1,0.5)).rotated(Vector3(0,1,0), time).rotated(Vector3(1,0,0),
			0.5*time), Vector3(-3.5, 0, 0))
	DebugDraw.draw_transformed_cube(cube_trans, Color(1,0.5,0))
	
	DebugDraw.set_text("Time", str(time))
	DebugDraw.set_text("Frames drawn", str(Engine.get_frames_drawn()))
	DebugDraw.set_text("FPS", str(Engine.get_frames_per_second()))
	DebugDraw.set_text("delta", str(delta))
	
	DebugDraw.draw_mesh(_mesh, 
		Transform3D(Basis().rotated(Vector3(1,1,0.5).normalized(), time), Vector3(3.5,0,3)),
		Color(0.5+0.5*sin(time*2.0), 0.5+0.5*cos(time*2.0), 1.0))
```

![image](https://github.com/Zylann/godot_debug_draw/assets/1311555/10daabb8-a21e-4ec1-a8ff-f1507e31d28c)
