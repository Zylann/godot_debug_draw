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
	var time = OS.get_ticks_msec() / 1000.0
	var box_pos = Vector3(0, sin(time * 4.0), 0)
	var line_begin = Vector3(-1, sin(time * 4.0), 0)
	var line_end = Vector3(1, cos(time * 4.0), 0)

	DebugDraw.draw_box(box_pos, Vector3(1, 2, 1), Color(0, 1, 0))
	DebugDraw.draw_line_3d(line_begin, line_end, Color(1, 1, 0))
	DebugDraw.set_text("Time", str(time))
	DebugDraw.set_text("Frames drawn", str(Engine.get_frames_drawn()))
	DebugDraw.set_text("FPS", str(Engine.get_frames_per_second()))
	DebugDraw.set_text("delta", str(delta))
```

![image](https://user-images.githubusercontent.com/1311555/83977160-3f8f5280-a8f6-11ea-8dbb-696f794fcd6a.png)
