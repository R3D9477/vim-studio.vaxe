package;

import snow.api.Debug.*;
import snow.types.Types;
import snow.modules.opengl.GL;

@:log_as('app')
class %main% extends snow.App {
	override function config (config:AppConfig) : AppConfig {
		config.window.title = "%title%";
		return config;
	}
	
	override function ready() : Void {
		log("%title% is ready");
		app.window.onrender = render;
	}
	
	override function onkeyup (keycode:Int, _,_, mod:ModState, _,_) : Void
		if(keycode == Key.escape)
			app.shutdown();
	
	function render (window:snow.system.window.Window) : Void {
		GL.clearColor(1.0, 1.0, 1.0, 1.0);
		GL.clear(GL.COLOR_BUFFER_BIT);
	}
}
