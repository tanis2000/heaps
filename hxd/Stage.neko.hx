package hxd;
import hxd.Key in K;
import lime.app.Config;
import lime.app.Application;
import lime.ui.Window;

//@:coreApi
class Stage {

	var resizeEvents : List<Void -> Void>;
	var eventTargets : List<Event -> Void>;

	public var width(get, never) : Int;
	public var height(get, never) : Int;
	public var mouseX(get, never) : Int;
	public var mouseY(get, never) : Int;
	public var mouseLock(get, set) : Bool;
	public var vsync(get, set) : Bool;

	var app : lime.app.Application;
	var window : lime.ui.Window;
	var windowWidth = 800;
	var windowHeight = 600;
	var curMouseX = 0;
	var curMouseY = 0;

	static var CODEMAP = [for( i in 0...2048 ) i];

	function new(title:String, width:Int, height:Int) {
		trace("neko Stage new start");
		this.windowWidth = width;
		this.windowHeight = height;
		eventTargets = new List();
		resizeEvents = new List();

		window = new Window();
		window.title = title;
		window.width = width;
		window.height = height;
		app = new Application();
		var wc = { 
			hardware: true,
			title: title,
			width: width,
			height: height
			}
		var appConfig = {
			windows: [wc]
		}
		app.create(appConfig);
		trace(lime.app.Application.current.renderer.type);
		// TODO: bind the events here and create an event handler
		app.onUpdate.add(onUpdate);
		app.renderer.onRender.add(onRender);
		trace("neko Stage new end");
	}

	public dynamic function onClose() : Bool {
		return true;
	}

	public function event( e : hxd.Event ) : Void {
		for( et in eventTargets )
			et(e);
	}

	public function addEventTarget(et : Event -> Void) : Void {
		eventTargets.add(et);
	}

	public function removeEventTarget(et : Event -> Void) : Void {
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
		window.resize(width, height);
	}

	public function setFullScreen( v : Bool ) : Void {
		window.fullscreen = v;
	}

	function get_mouseX() : Int {
		return curMouseX;
	}

	function get_mouseY() : Int {
		return curMouseY;
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

	function set_mouseLock(v:Bool) : Bool {
		if( v ) throw "Not implemented";
		return false;
	}


	function get_vsync() : Bool return window.config.vsync;

	function set_vsync( b : Bool ) : Bool {
		window.config.vsync = b;
		return b;
	}

	function onUpdate(dt : Int):Void {
		trace("update");
	}

	function onRender() : Void {
		trace("render");
	}
/*
	var wasBlurred : Bool;

	function onEvent( e : Event ) : Bool {
		var eh = null;
		switch( e.type ) {
		case WindowState:
			switch( e.state ) {
			case Resize:
				windowWidth = window.width;
				windowHeight = window.height;
				onResize(null);
			case Focus:
				#if hldx
				// return to exclusive mode
				if( fullScreenMode == Fullscreen && wasBlurred ) {
					window.displayMode = Borderless;
					window.displayMode = fullScreenMode;
				}
				#end
				wasBlurred = false;
			case Blur:
				wasBlurred = true;
			default:
			}
		case MouseDown:
			curMouseX = e.mouseX;
			curMouseY = e.mouseY;
			eh = new Event(EPush, e.mouseX, e.mouseY);
			// middle button -> 2 / right button -> 1
			eh.button = switch( e.button - 1 ) {
			case 0: 0;
			case 1: 2;
			case 2: 1;
			case x: x;
			}
		case MouseUp:
			curMouseX = e.mouseX;
			curMouseY = e.mouseY;
			eh = new Event(ERelease, e.mouseX, e.mouseY);
			eh.button = switch( e.button - 1 ) {
			case 0: 0;
			case 1: 2;
			case 2: 1;
			case x: x;
			};
		case MouseMove:
			curMouseX = e.mouseX;
			curMouseY = e.mouseY;
			eh = new Event(EMove, e.mouseX, e.mouseY);
		case MouseWheel:
			eh = new Event(EWheel, mouseX, mouseY);
			eh.wheelDelta = -e.wheelDelta;
		#if hlsdl
		case GControllerAdded, GControllerRemoved, GControllerUp, GControllerDown, GControllerAxis:
			@:privateAccess hxd.Pad.onEvent( e );
		case KeyDown:
			eh = new Event(EKeyDown);
			if( e.keyCode & (1 << 30) != 0 ) e.keyCode = (e.keyCode & ((1 << 30) - 1)) + 1000;
			eh.keyCode = CODEMAP[e.keyCode];
			if( eh.keyCode & (K.LOC_LEFT | K.LOC_RIGHT) != 0 ) {
				e.keyCode = eh.keyCode & 0xFF;
				onEvent(e);
			}
		case KeyUp:
			eh = new Event(EKeyUp);
			if( e.keyCode & (1 << 30) != 0 ) e.keyCode = (e.keyCode & ((1 << 30) - 1)) + 1000;
			eh.keyCode = CODEMAP[e.keyCode];
			if( eh.keyCode & (K.LOC_LEFT | K.LOC_RIGHT) != 0 ) {
				e.keyCode = eh.keyCode & 0xFF;
				onEvent(e);
			}
		case TextInput:
			eh = new Event(ETextInput, mouseX, mouseY);
			var c = e.keyCode & 0xFF;
			eh.charCode = if( c < 0x7F )
				c;
			else if( c < 0xE0 )
				((c & 0x3F) << 6) | ((e.keyCode >> 8) & 0x7F);
			else if( c < 0xF0 )
				((c & 0x1F) << 12) | (((e.keyCode >> 8) & 0x7F) << 6) | ((e.keyCode >> 16) & 0x7F);
			else
				((c & 0x0F) << 18) | (((e.keyCode >> 8) & 0x7F) << 12) | (((e.keyCode >> 16) & 0x7F) << 6) | ((e.keyCode >> 24) & 0x7F);
		#elseif hldx
		case KeyDown:
			eh = new Event(EKeyDown);
			eh.keyCode = e.keyCode;
			if( eh.keyCode & (K.LOC_LEFT | K.LOC_RIGHT) != 0 ) {
				e.keyCode = eh.keyCode & 0xFF;
				onEvent(e);
			}
		case KeyUp:
			eh = new Event(EKeyUp);
			eh.keyCode = CODEMAP[e.keyCode];
			if( eh.keyCode & (K.LOC_LEFT | K.LOC_RIGHT) != 0 ) {
				e.keyCode = eh.keyCode & 0xFF;
				onEvent(e);
			}
		case TextInput:
			eh = new Event(ETextInput, mouseX, mouseY);
			eh.charCode = e.keyCode;
		#end
		case Quit:
			return onClose();
		default:
		}
		if( eh != null ) event(eh);
		return true;
	}

	static function initChars() : Void {

		inline function addKey(sdl, keyCode) {
			CODEMAP[sdl] = keyCode;
		}

		// ASCII
		for( i in 0...26 )
			addKey(97 + i, K.A + i);
		for( i in 0...12 )
			addKey(1058 + i, K.F1 + i);

		// NUMPAD
		addKey(1084, K.NUMPAD_DIV);
		addKey(1085, K.NUMPAD_MULT);
		addKey(1086, K.NUMPAD_SUB);
		addKey(1087, K.NUMPAD_ADD);
		addKey(1088, K.NUMPAD_ENTER);
		for( i in 0...9 )
			addKey(1089 + i, K.NUMPAD_1 + i);
		addKey(1098, K.NUMPAD_0);
		addKey(1099, K.NUMPAD_DOT);

		// EXTRA
		var keys = [
			//K.BACKSPACE
			//K.TAB
			//K.ENTER
			1225 => K.LSHIFT,
			1229 => K.RSHIFT,
			1224 => K.LCTRL,
			1228 => K.RCTRL,
			1226 => K.LALT,
			1230 => K.RALT,
			// K.ESCAPE
			// K.SPACE
			1075 => K.PGUP,
			1078 => K.PGDOWN,
			1077 => K.END,
			1074 => K.HOME,
			1080 => K.LEFT,
			1082 => K.UP,
			1079 => K.RIGHT,
			1081 => K.DOWN,
			1073 => K.INSERT,
			127 => K.DELETE,
			//K.NUMPAD_0-9
			//K.A-Z
			//K.F1-F12
			1085 => K.NUMPAD_MULT,
			1087 => K.NUMPAD_ADD,
			1088 => K.NUMPAD_ENTER,
			1086 => K.NUMPAD_SUB,
			1099 => K.NUMPAD_DOT,
			1084 => K.NUMPAD_DIV,
		];
		for( sdl in keys.keys() )
			addKey(sdl, keys.get(sdl));
	}
*/
	static var inst : Stage = null;
	public static function getInstance() : Stage {
		return inst;
	}
}
