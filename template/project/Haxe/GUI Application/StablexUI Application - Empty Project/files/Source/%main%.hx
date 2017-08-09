package;

class %main% extends openfl.display.Sprite {
	public function new () {
		super();
		
		openfl.Lib.current.stage.addChild(this);
		
		ru.stablex.ui.UIBuilder.init();
		ru.stablex.ui.UIBuilder.buildFn("Assets/XmlGui/%main%.xml")().show();
	}
}
