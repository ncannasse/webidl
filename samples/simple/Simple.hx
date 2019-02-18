import SimpleModule.Point;
import SimpleModule.Context;
import SimpleModule.Init as SimpleModuleInit;

class Simple {

	public static function main() {
		SimpleModuleInit.init(startApp);
	}

	public static function startApp() {
		/** Point */
		var p1 = new Point();		
		p1.x = 4;
		p1.y = 5;
		var p2 = new Point(7,8);
		var p = p1.op_add(p2);
		trace('Result = ${p.x},${p.y} len=${p.length()}');
		p1.delete();
		p2.delete();
		p.delete();

		/** Context */
		var context = new Context();
		context.test();
	}
}