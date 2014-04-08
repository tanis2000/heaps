package h3d.scene;

class CustomObject extends Object {

	public var primitive : h3d.prim.Primitive;
	public var material : h3d.mat.Material;
	
	public function new( prim, ?mat, ?parent ) {
		super(parent);
		this.primitive = prim;
		if( mat == null ) mat = new h3d.mat.Material(null);
		this.material = mat;
	}
	
	override function getBounds( ?b : h3d.col.Bounds, rec = false ) {
		b = super.getBounds(b, rec);
		var tmp = primitive.getBounds().clone();
		tmp.transform3x4(absPos);
		b.add(tmp);
		return b;
	}
	
	override function clone( ?o : Object ) {
		var m = o == null ? new CustomObject(null,material) : cast o;
		m.primitive = primitive;
		m.material = material.clone();
		super.clone(m);
		return m;
	}
	
	override function draw( ctx : RenderContext ) {
		if( material.renderPass > ctx.currentPass ) {
			ctx.addPass(draw);
			return;
		}
		material.setup(ctx);
		ctx.engine.selectMaterial(material);
		primitive.render(ctx.engine);
	}
	
}