class FloatArray
{
public:
	FloatArray() {}

	FloatArray(int size)
	{
		list = new float[size];
	}

	float Get(int index)
	{
		return list[index];
	}

	void Set(int index, float value)
	{
		list[index] = value;
	}

	float* GetPtr() {
		return list;
	}

private: 
	float* list;
};