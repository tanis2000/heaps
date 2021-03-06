package h3d.mat;

@:enum abstract PbrMode(String) {
	var PBR = "PBR";
	var Overlay = "Overlay";
	var Decal = "Decal";
	var BeforeTonemapping = "BeforeTonemapping";
	var Distortion = "Distortion";
}

@:enum abstract PbrBlend(String) {
	var None = "None";
	var Alpha = "Alpha";
	var Add = "Add";
	var AlphaAdd = "AlphaAdd";
	var Multiply = "Multiply";
	var AlphaMultiply = "AlphaMultiply";
}

@:enum abstract PbrDepthTest(String) {
	var Less = "Less";
	var LessEqual = "LessEqual";
	var Greater = "Greater";
	var GreaterEqual = "GreaterEqual";
	var Always = "Always";
	var Never = "Never";
	var Equal = "Equal";
	var NotEqual= "NotEqual";
}

@:enum abstract PbrStencilOp(String) {
	var Keep = "Keep";
	var Zero = "Zero";
	var Replace = "Replace";
	var Increment = "Increment";
	var IncrementWrap = "IncrementWrap";
	var Decrement = "Decrement";
	var DecrementWrap = "DecrementWrap";
	var Invert = "Invert";
}

@:enum abstract PbrStencilCompare(String) {
	var Always = "Always";
	var Never = "Never";
	var Equal = "Equal";
	var NotEqual = "NotEqual";
	var Greater = "Greater";
	var GreaterEqual = "GreaterEqual";
	var Less = "Less";
	var LessEqual = "LessEqual";
}

typedef PbrProps = {
	var mode : PbrMode;
	var blend : PbrBlend;
	var shadows : Bool;
	var culling : Bool;
	var depthTest : PbrDepthTest;
	var colorMask : Int;
	@:optional var alphaKill : Bool;
	@:optional var emissive : Float;
	@:optional var parallax : Float;
	
	var enableStencil : Bool;
	@:optional var stencilCompare : PbrStencilCompare;
	@:optional var stencilPassOp : PbrStencilOp;
	@:optional var stencilFailOp : PbrStencilOp;
	@:optional var depthFailOp : PbrStencilOp;
	@:optional var stencilValue : Int;
	@:optional var stencilWriteMask : Int;
	@:optional var stencilReadMask : Int;

	@:optional var drawOrder : Int;
}

class PbrMaterial extends Material {

	override function set_blendMode(b:BlendMode) {
		if( mainPass != null ) {
			mainPass.setBlendMode(b);
			mainPass.depthWrite = b == None;
		}
		return this.blendMode = b;
	}

	override function set_receiveShadows(b) {
		// don't add shadows shader here, we are not in forward
		return receiveShadows = b;
	}

	override function getDefaultProps( ?type : String ) : Any {
		var props : PbrProps;
		switch( type ) {
		case "particles3D", "trail3D":
			props = {
				mode : PBR,
				blend : Alpha,
				shadows : false,
				culling : false,
				depthTest : Less,
				colorMask : 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3,
				enableStencil : false,
			};
		case "ui":
			props = {
				mode : Overlay,
				blend : Alpha,
				shadows : false,
				culling : false,
				alphaKill : true,
				depthTest : Less,
				colorMask : 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3,
				enableStencil : false,
			};
		case "decal":
			props = {
				mode : Decal,
				blend : Alpha,
				shadows : false,
				culling : true,
				depthTest : Less,
				colorMask : 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3,
				enableStencil : false,
			};
		default:
			props = {
				mode : PBR,
				blend : None,
				shadows : true,
				culling : true,
				depthTest : Less,
				colorMask : 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3,
				enableStencil : false,
			};
		}
		return props;
	}

	override function getDefaultModelProps() : Any {
		var props : PbrProps = getDefaultProps();
		props.blend = switch( blendMode ) {
			case None: None;
			case Alpha: Alpha;
			case Add: Add;
			case Multiply: Multiply;
			case AlphaMultiply: AlphaMultiply;
			default: throw "Unsupported Model blendMode "+blendMode;
		}
		props.depthTest = switch (mainPass.depthTest) {
			case Always: Always;
			case Never: Never;
			case Equal: Equal;
			case NotEqual: NotEqual;
			case Greater: Greater;
			case GreaterEqual: GreaterEqual;
			case Less: Less;
			case LessEqual: LessEqual;
		}
		return props;
	}

	function resetProps() {
		var props : PbrProps = props;
		// Remove superfluous shader
		mainPass.removeShader(mainPass.getShader(h3d.shader.VolumeDecal));
		mainPass.removeShader(mainPass.getShader(h3d.shader.pbr.StrengthValues));
		mainPass.removeShader(mainPass.getShader(h3d.shader.pbr.AlphaMultiply));
		mainPass.removeShader(mainPass.getShader(h3d.shader.Parallax));
		// Backward compatibility
		if( !Reflect.hasField(props, "depthTest") ) Reflect.setField(props, "depthTest", Less);
		if( !Reflect.hasField(props, "colorMask") ) Reflect.setField(props, "colorMask", 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3);
		if( !Reflect.hasField(props, "enableStencil") ) Reflect.setField(props, "enableStencil", false);
		// Remove unused fields
		if( props.emissive == 0 )
			Reflect.deleteField(props,"emissive");
		if( !props.enableStencil ) {
			Reflect.deleteField(props, "stencilWriteMask");
			Reflect.deleteField(props, "stencilReadMask");
			Reflect.deleteField(props, "stencilValue");
			Reflect.deleteField(props, "stencilFailOp");
			Reflect.deleteField(props, "depthFailOp");
			Reflect.deleteField(props, "stencilPassOp");
			Reflect.deleteField(props, "stencilCompare");
		} 
	}

	override function refreshProps() {
		resetProps();
		var props : PbrProps = props;

		// Preset
		switch( props.mode ) {
		case PBR:
			mainPass.setPassName("default");
		case BeforeTonemapping:
			mainPass.setPassName("beforeTonemapping");
			var e = mainPass.getShader(h3d.shader.Emissive);
			if( e == null ) e = mainPass.addShader(new h3d.shader.Emissive(props.emissive));
			e.emissive = props.emissive;
		case Distortion:
			mainPass.setPassName("distortion");
			mainPass.depthWrite = false;
		case Overlay:
			mainPass.setPassName("overlay");
		case Decal:
			mainPass.setPassName("decal");
			var vd = mainPass.getShader(h3d.shader.VolumeDecal);
			if( vd == null ) {
				vd = new h3d.shader.VolumeDecal(1,1);
				vd.setPriority(-1);
				mainPass.addShader(vd);
			}
			var sv = mainPass.getShader(h3d.shader.pbr.StrengthValues);
			if( sv == null ) {
				sv = new h3d.shader.pbr.StrengthValues();
				mainPass.addShader(sv);
			}
		}

		// Blend modes
		switch( props.blend ) {
		case None:
			mainPass.setBlendMode(None);
			mainPass.depthWrite = true;
		case Alpha:
			mainPass.setBlendMode(Alpha);
			mainPass.depthWrite = false;
		case Add:
			mainPass.setBlendMode(Add);
			mainPass.depthWrite = false;
		case AlphaAdd:
			mainPass.setBlendMode(AlphaAdd);
			mainPass.depthWrite = false;
		case Multiply:
			mainPass.setBlendMode(Multiply);
			mainPass.depthWrite = false;
		case AlphaMultiply:
			if( mainPass.getShader(h3d.shader.pbr.AlphaMultiply) == null ) {
				var s = new h3d.shader.pbr.AlphaMultiply();
				s.setPriority(-1);
				mainPass.addShader(s);
			}
			mainPass.setBlendMode(AlphaMultiply);
			mainPass.depthWrite = false;
		}

		// Enable/Disable AlphaKill
		var tshader = textureShader;
		if( tshader != null ) {
			tshader.killAlpha = props.alphaKill;
			tshader.killAlphaThreshold = 0.5;
		}

		mainPass.culling = props.culling ? Back : None;

		shadows = props.shadows;
		if( shadows ) getPass("shadow").culling = mainPass.culling;

		mainPass.depthTest = switch (props.depthTest) {
			case Less: Less;
			case LessEqual: LessEqual;
			case Greater: Greater;
			case GreaterEqual: GreaterEqual;
			case Always: Always;
			case Never: Never;
			case Equal: Equal;
			case NotEqual : NotEqual;
			default: Less;
		}

		// Get values from specular texture
		var emit = props.emissive == null ? 0 : props.emissive;
		var tex = mainPass.getShader(h3d.shader.pbr.PropsTexture);
		var def = mainPass.getShader(h3d.shader.pbr.PropsValues);
		if( tex == null && def == null ) {
			def = new h3d.shader.pbr.PropsValues();
			mainPass.addShader(def);
		}
		if( tex != null ) tex.emissive = emit;
		if( def != null ) def.emissive = emit;

		// Parallax
		var ps = mainPass.getShader(h3d.shader.Parallax);
		if( props.parallax > 0 ) {
			if( ps == null ) {
				ps = new h3d.shader.Parallax();
				mainPass.addShader(ps);
			}
			ps.amount = props.parallax;
			ps.heightMap = specularTexture;
			ps.heightMapChannel = A;
		} else if( ps != null )
			mainPass.removeShader(ps);

		setColorMask();

		setStencil();

		mainPass.layer = props.drawOrder == null ? 0 : props.drawOrder;
	}

	function setColorMask() {
		var props : PbrProps = props;
		mainPass.setColorMask(	props.colorMask & (1<<0) > 0 ? true : false, 
								props.colorMask & (1<<1) > 0 ? true : false, 
								props.colorMask & (1<<2) > 0 ? true : false, 
								props.colorMask & (1<<3) > 0 ? true : false);
	}

	function setStencil() {
		var props : PbrProps = props;
		if( props.enableStencil ) {

			if( !Reflect.hasField(props, "stencilFailOp") ) 	Reflect.setField(props, "stencilFailOp", Keep);
			if( !Reflect.hasField(props, "depthFailOp") ) 		Reflect.setField(props, "depthFailOp", Keep);
			if( !Reflect.hasField(props, "stencilPassOp") ) 	Reflect.setField(props, "stencilPassOp", Replace);
			if( !Reflect.hasField(props, "stencilCompare") ) 	Reflect.setField(props, "stencilCompare", Always);
			if( !Reflect.hasField(props, "stencilValue") ) 		Reflect.setField(props, "stencilValue", 0);
			if( !Reflect.hasField(props, "stencilReadMask") ) 	Reflect.setField(props, "stencilReadMask", 0);
			if( !Reflect.hasField(props, "stencilWriteMask") ) 	Reflect.setField(props, "stencilWriteMask", 0);

			inline function getStencilOp( op : PbrStencilOp ) : Data.StencilOp {
				return switch op {
					case Keep:Keep;
					case Zero:Zero;
					case Replace:Replace;
					case Increment:Increment;
					case IncrementWrap:IncrementWrap;
					case Decrement:Decrement;
					case DecrementWrap:DecrementWrap;
					case Invert:Invert;
				}
			}

			inline function getStencilCompare( op : PbrStencilCompare ) : Data.Compare {
				return switch op {
					case Always:Always;
					case Never:Never;
					case Equal:Equal;
					case NotEqual:NotEqual;
					case Greater:Greater;
					case GreaterEqual:GreaterEqual;
					case Less:Less;
					case LessEqual:LessEqual;
				}
			}

			var s = new Stencil();
			s.setFunc(getStencilCompare(props.stencilCompare), props.stencilValue, props.stencilReadMask, props.stencilWriteMask);
			s.setOp(getStencilOp(props.stencilFailOp), getStencilOp(props.depthFailOp), getStencilOp(props.stencilPassOp));
			mainPass.stencil = s;
		}
		else {
			mainPass.stencil = null;
		}
	}

	override function get_specularTexture() {
		var spec = mainPass.getShader(h3d.shader.pbr.PropsTexture);
		return spec == null ? null : spec.texture;
	}

	override function set_specularTexture(t) {
		if( specularTexture == t )
			return t;
		var props : PbrProps = props;
		var emit = props == null || props.emissive == null ? 0 : props.emissive;
		var spec = mainPass.getShader(h3d.shader.pbr.PropsTexture);
		var def = mainPass.getShader(h3d.shader.pbr.PropsValues);
		if( t != null ) {
			if( spec == null ) {
				spec = new h3d.shader.pbr.PropsTexture();
				spec.emissive = emit;
				mainPass.addShader(spec);
			}
			spec.texture = t;
			if( def != null )
				mainPass.removeShader(def);
		} else {
			mainPass.removeShader(spec);
			// default values (if no texture)
			if( def == null ) {
				def = new h3d.shader.pbr.PropsValues();
				def.emissive = emit;
				mainPass.addShader(def);
			}
		}


		// parallax
		var ps = mainPass.getShader(h3d.shader.Parallax);
		if( ps != null ) {
			ps.heightMap = t;
			ps.heightMapChannel = A;
			mainPass.removeShader(ps);
			mainPass.addShader(ps);
		}

		return t;
	}

	override function clone( ?m : BaseMaterial ) : BaseMaterial {
		var m = m == null ? new PbrMaterial() : cast m;
		super.clone(m);
			return m;
	}

	#if editor
	override function editProps() {
		var props : PbrProps = props;
		return new js.jquery.JQuery('
			<dl>
				<dt>Mode</dt>
				<dd>
					<select field="mode">
						<option value="PBR">PBR</option>
						<option value="BeforeTonemapping">Before Tonemapping</option>
						<option value="Albedo">Albedo</option>
						<option value="Overlay">Overlay</option>
						<option value="Distortion">Distortion</option>
						<option value="Decal">Decal</option>
					</select>
				</dd>
				<dt>Blend</dt>
				<dd>
					<select field="blend">
						<option value="None">None</option>
						<option value="Alpha">Alpha</option>
						<option value="Add">Add</option>
						<option value="AlphaAdd">AlphaAdd</option>
						<option value="Multiply">Multiply</option>
						<option value="AlphaMultiply">AlphaMultiply</option>
					</select>
				</dd>
				<dt>Depth Test</dt>
				<dd>
					<select field="depthTest">
						<option value="Less">Less</option>
						<option value="LessEqual">LessEqual</option>
						<option value="Greater">Greater</option>
						<option value="GreaterEqual">GreaterEqual</option>
						<option value="Always">Always</option>
						<option value="Never">Never</option>
						<option value="Equal">Equal</option>
						<option value="NotEqual">NotEqual</option>
					</select>
				</dd>
				<dt>Emissive</dt><dd><input type="range" min="0" max="10" field="emissive"/></dd>
				<dt>Parallax</dt><dd><input type="range" min="0" max="1" field="parallax"/></dd>
				<dt>Shadows</dt><dd><input type="checkbox" field="shadows"/></dd>
				<dt>Culled</dt><dd><input type="checkbox" field="culling"/></dd>
				<dt>AlphaKill</dt><dd><input type="checkbox" field="alphaKill"/></dd>
				<dt>Draw Order</dt><dd><input type="range" min="0" max="10" step="1" field="drawOrder"/></dd>
			</dl>
		');
	}
	#end

}