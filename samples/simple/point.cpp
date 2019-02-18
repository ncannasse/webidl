#include <math.h>
#include "point.h"

double Point::length() {
	return sqrt(x * x + y * y);
}
