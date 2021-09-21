package webidl;

typedef Data = Array<Definition>;

typedef Position = {
	var file : String;
	var line : Int;
	var pos : Int;
}

typedef Definition = {
	var pos : Position;
	var kind : DefinitionKind;
}

enum DefinitionKind {
	DInterface( name : String, attrs : Array<Attrib>, fields : Array<Field> );
	DImplements( type : String, interfaceName : String );
	DEnum( name : String, values : Array<String> );
}

typedef Field = {
	var name : String;
	var kind : FieldKind;
	var pos : Position;
}

enum FieldKind {
	FMethod( args : Array<FArg>, ret : TypeAttr ); // parser doesn't know the difference between method attributes and return attributes, attrs : Array<Attrib> );
	FAttribute( t : TypeAttr );
	DConst( name : String, type : Type, value : String );
}

typedef FArg = { name : String, opt : Bool, t : TypeAttr };
typedef TypeAttr = { var t : Type; var attr : Array<Attrib>; };

enum Type {
	TVoid;
	TChar;
	TInt;
	TShort;
	TFloat;
	TDouble;
	TBool;
	TAny;
	TVoidPtr;
	THString;
	TCustom( id : String );
	TArray( t : Type );
}

enum Attrib {
	// fields
	AValue;
	ARef;
	AConst;
	AOperator( op : String );
	// interfaces
	ANoDelete;
	AStatic;
	AReturn;
	AThrow(msg :String);
	AValidate(expression : String);
	ACObject;
	AInternal(name:String);
	AGet(name:String);
	ASet(name:String);
	APrefix( prefix : String );
	AJSImplementation( name : String );	
}
