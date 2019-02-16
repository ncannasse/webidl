import SplitoutModule.Point;
import SplitoutModule.Context;
import SplitoutModule.Init as SplitoutModuleInit;

class Splitout {

	public static function main() {
		SplitoutModuleInit.init(startApp);
	}

	public static function startApp() {
		var p1 = new Point();		
		p1.x = 4;
		p1.y = 5;
		var p2 = new Point(7,8);
		var p = p1.op_add(p2);
		trace('Result = ${p.x},${p.y} len=${p.length()}');
		p1.delete();
		p2.delete();
		p.delete();

		var c1 = new Context();
		c1.test();
	}
}