import luxe.Input;
import luxe.Color;
import luxe.Vector;

import mint.Control;
import mint.types.Types;
import mint.render.luxe.*;
import mint.layout.margins.Margins;
import mint.focus.Focus;

import AutoCanvas;

class %main% extends luxe.Game {
	var focus:Focus;
	var layout:Margins;
	var canvas:AutoCanvas;
	var rendering:LuxeMintRender;
	
	override function config(config:luxe.AppConfig)
		return config;
	
	override function ready() {
		rendering = new LuxeMintRender();
		layout = new Margins();
		
		canvas = new AutoCanvas({
			name: "canvas",
			rendering: rendering,
			options: { color: new Color(1,1,1,0) },
			x: 0,
			y: 0,
			w: Luxe.screen.w,
			h: Luxe.screen.h
		});
		
		focus = new Focus(canvas);
		canvas.auto_listen();
	}
}
