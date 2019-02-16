#ifdef EMSCRIPTEN

#include <emscripten.h>
		#define HL_PRIM
		#define HL_NAME(n)	EMSCRIPTEN_KEEPALIVE eb_##n
		#define DEFINE_PRIM(ret, name, args)
		#define _OPT(t) t*
		#define _GET_OPT(value,t) *value
#define alloc_ref(r, _) r
		#define alloc_ref_const(r,_) r
		#define _ref(t)			t
		#define _unref(v)		v
		#define free_ref(v) delete (v)
		#define HL_CONST const

#else

#define HL_NAME(x) libpoint_##x
#include <hl.h>
		#define _IDL _BYTES
		#define _OPT(t) vdynamic *
		#define _GET_OPT(value,t) (value)->v.t
#define alloc_ref(r, _) r
		#define alloc_ref_const(r,_) r
		#define _ref(t)			t
		#define _unref(v)		v
		#define free_ref(v) delete (v)
		#define HL_CONST const

#endif

#include <math.h>
#include "point.h"

#include "context.h"
#include "stdio.h"

extern "C" {

static void finalize_Point( _ref(Point)* _this ) { free_ref(_this); }
HL_PRIM void HL_NAME(Point_delete)( _ref(Point)* _this ) {
	free_ref(_this);
}
DEFINE_PRIM(_VOID, Point_delete, _IDL);
static void finalize_Context( _ref(Context)* _this ) { free_ref(_this); }
HL_PRIM void HL_NAME(Context_delete)( _ref(Context)* _this ) {
	free_ref(_this);
}
DEFINE_PRIM(_VOID, Context_delete, _IDL);
HL_PRIM int HL_NAME(Point_get_x)( _ref(Point)* _this ) {
	return _unref(_this)->x;
}
HL_PRIM int HL_NAME(Point_set_x)( _ref(Point)* _this, int value ) {
	_unref(_this)->x = (value);
	return value;
}
DEFINE_PRIM(_I32,Point_get_x,_IDL);
DEFINE_PRIM(_I32,Point_set_x,_IDL _I32);

HL_PRIM int HL_NAME(Point_get_y)( _ref(Point)* _this ) {
	return _unref(_this)->y;
}
HL_PRIM int HL_NAME(Point_set_y)( _ref(Point)* _this, int value ) {
	_unref(_this)->y = (value);
	return value;
}
DEFINE_PRIM(_I32,Point_get_y,_IDL);
DEFINE_PRIM(_I32,Point_set_y,_IDL _I32);

HL_PRIM _ref(Point)* HL_NAME(Point_new0)() {
	return alloc_ref((new Point()),Point);
}
DEFINE_PRIM(_IDL, Point_new0,);

HL_PRIM _ref(Point)* HL_NAME(Point_new2)(int x, int y) {
	return alloc_ref((new Point(x, y)),Point);
}
DEFINE_PRIM(_IDL, Point_new2, _I32 _I32);

HL_PRIM _ref(Point)* HL_NAME(Point_op_add1)(_ref(Point)* _this, _ref(Point)* p) {
	return alloc_ref(new Point(*_unref(_this) + (*_unref(p))),Point);
}
DEFINE_PRIM(_IDL, Point_op_add1, _IDL _IDL);

HL_PRIM double HL_NAME(Point_length0)(_ref(Point)* _this) {
	return _unref(_this)->length();
}
DEFINE_PRIM(_F64, Point_length0, _IDL);

HL_PRIM _ref(Context)* HL_NAME(Context_new0)() {
	return alloc_ref((new Context()),Context);
}
DEFINE_PRIM(_IDL, Context_new0,);

HL_PRIM void HL_NAME(Context_test0)(_ref(Context)* _this) {
	_unref(_this)->test();
}
DEFINE_PRIM(_VOID, Context_test0, _IDL);

}
