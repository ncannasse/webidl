# Haxe WebIDL

This library allows to access any C++ library from Haxe/JS (using Emscripten or Web Assembly) and Haxe/HashLink by simply defining an idl file.

For a complete example, see the [sample](https://github.com/ncannasse/webidl/tree/master/sample)

## Installing

```bash
git clone https://github.com/ncannasse/webidl.git # Clone the repo
haxelib dev webidl webidl # Set the webidl package install directory to the cloned repo
```

## Usage

Given the following IDL file describing a C++ library:

```java
interface Point {
    attribute long x;
    attribute long y;
    void Point();
    void Point( long x, long y );
    [Operator="*",Ref] Point op_add( [Const,Ref] Point p );
    double length();
};
```

And the following Haxe code (**strictly typed** thanks to IDL definitions):

```haxe
class Sample {

    public static function main() {
	var p1 = new Point();
	p1.x = 4;
	p1.y = 5;
	var p2 = new Point(7,8);
	var p = p1.op_add(p2);
	trace('Result = ${p.x},${p.y} len=${p.length()}');
	p1.delete();
	p2.delete();
	p.delete();
    }
	
}
```

This compiles to the following Javascript:

```js
// Generated by Haxe 4.0.0
(function () { "use strict";
var Sample = function() { };
Sample.main = function() {
    var this1 = _eb_Point_new0();
    var p1 = this1;
    _eb_Point_set_x(p1,4);
    _eb_Point_set_y(p1,5);
    var this2 = _eb_Point_new2(7,8);
    var p2 = this2;
    var p = _eb_Point_op_add1(p1,p2);
    console.log("Result = " + _eb_Point_get_x(p) + "," + _eb_Point_get_y(p) + " len=" + _eb_Point_length0(p));
    _eb_Point_delete(p1);
    _eb_Point_delete(p2);
    _eb_Point_delete(p);
};
Sample.main();
})();
```

Haxe webidl can be used for both Haxe/JS and Haxe/HashLink, the cpp bindings generated are the same for both platforms.

