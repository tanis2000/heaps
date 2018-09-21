package hxd;

class Stage {

	var resizeEvents : List<Void -> Void>;
	var eventTargets : List<Event -> Void>;

	public var width(get, never) : Int;
	public var height(get, never) : Int;
	public var mouseX(get, never) : Int;
	public var mouseY(get, never) : Int;
	public var mouseLock(get, set) : Bool;
	public var vsync(get, set) : Bool;
	public var isFocused(get, never) : Bool;

	public var limeApp: LimeApp;
	var windowWidth = 800;
	var windowHeight = 600;

	function new(title:String, width:Int, height:Int) : Void {
		trace('Stage new');
		eventTargets = new List();
		resizeEvents = new List();
		this.windowWidth = width;
		this.windowHeight = height;
		limeApp = new LimeApp(this, width, height);
	}

	public function execLimeApp() {
		limeApp.exec();
	}

	public dynamic function onClose() : Bool {
		return true;
	}

	public function event( e : hxd.Event ) : Void {
		for( et in eventTargets )
			et(e);
	}

	public function addEventTarget( et : Event->Void ) : Void {
		eventTargets.add(et);
	}

	public function removeEventTarget( et : Event->Void ) : Void {
		for( e in eventTargets )
			if( Reflect.compareMethods(e,et) ) {
				eventTargets.remove(e);
				break;
			}
	}

	public function addResizeEvent( f : Void -> Void ) : Void {
		resizeEvents.push(f);
	}

	public function removeResizeEvent( f : Void -> Void ) : Void {
		for( e in resizeEvents )
			if( Reflect.compareMethods(e,f) ) {
				resizeEvents.remove(f);
				break;
			}
	}

	function onResize(e:Dynamic) : Void {
		for( r in resizeEvents )
			r();
	}

	public function resize( width : Int, height : Int ) : Void {
	}

	public function setFullScreen( v : Bool ) : Void {
	}

	static var inst : Stage = null;
	public static function getInstance() : Stage {
		return inst;
	}

	function get_mouseX() : Int {
		return 0;
	}

	function get_mouseY() : Int {
		return 0;
	}

	function get_width() : Int {
		return windowWidth;
	}

	function get_height() : Int {
		return windowHeight;
	}

	function get_mouseLock() : Bool {
		return false;
	}

	function set_mouseLock( v : Bool ) : Bool {
		if( v ) throw "Not implemented";
		return false;
	}

	function get_vsync() : Bool return true;

	function set_vsync( b : Bool ) : Bool {
		if( !b ) throw "Can't disable vsync on this platform";
		return true;
	}

	function get_isFocused() : Bool return true;

}

class LimeApp extends lime.app.Application {
	private var stage: Stage;

	public function new(stage: Stage, width: Int, height: Int) {
		trace('LimeApp new');
		super();
		this.stage = stage;
		createWindow ({ width: width, height: height });
	}

	public override function update (deltaTime:Int) {
		//stage.loopFunc();
		//trace('update');
		@:privateAccess System.mainLoop();
	}
	public override function render (context:lime.graphics.RenderContext):Void {
    }
}