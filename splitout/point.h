
class Point {
public:
	int x;
	int y;
	Point() {
		x = 0;
		y = 0;
	}
	Point(const Point &p) {
		x = p.x;
		y = p.y;
	}
	Point(int x, int y) {
		this->x = x;
		this->y = y;
	}
	Point operator +( const Point &p ) {
		return Point(x + p.x, y + p.y);
	}
	double length();
};
