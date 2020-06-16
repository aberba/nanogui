module aux.test_traversing;

version (unittest):

import unit_threaded : should, be, Name;
import std.experimental.allocator.mallocator : Mallocator;
import automem.vector : Vector;

import aux.model : Order, makeModel, visitForward, MeasureVisitor, 
	TreePathVisitor, Orientation, visitBackward;

struct PositionState
{
	import std.range : isOutputRange;

	string label;
	int[] path;
	double[2] pos, dest;
	TreePathVisitor.State state;

	@disable this();

	this(string l, int[] p, double[2] ps, double[2] d, TreePathVisitor.State s)
	{
		label = l;
		path = p;
		pos = ps;
		dest = d;
		state = s;
	}

	bool opEquals(ref const(typeof(this)) other) const
	{
		return opCmp(other) == 0;
	}

	int opCmp(ref const(typeof(this)) other) const
	{
		import std.math : approxEqual;

		if (label < other.label)
			return -1;
		if (label > other.label)
			return +1;

		if (path < other.path)
			return -1;
		if (path > other.path)
			return +1;

		if (pos[0].approxEqual(other.pos[0]) && pos[1].approxEqual(other.pos[1]))
			return 0;
		if (pos[0] < other.pos[0])
			return -1;
		if (pos[0] > other.pos[0])
			return -+1;
		if (pos[1] < other.pos[1])
			return -1;

		if (dest[0].approxEqual(other.dest[0]) && dest[1].approxEqual(other.dest[1]))
			return 0;
		if (dest[0] < other.dest[0])
			return -1;
		if (dest[0] > other.dest[0])
			return -+1;
		if (dest[1] < other.dest[1])
			return -1;

		return 1;
	}

	void toString(W)(ref W writer) const @safe
		if (isOutputRange!(W, string))
	{
		import std.algorithm : copy;
		import std.range : put, repeat;
		import std.format : formattedWrite;
		import std.conv : text;

		copy(typeof(this).stringof, writer);
		writer.put('(');
		auto prefix = '\t'.repeat(path.length);
		formattedWrite(writer, "%s%-19s, path: %6s, pos: %3s, dest: %3s, %s", prefix, label, path.text, pos, dest, state);
		writer.put(')');
	}
}

struct CheckingVisitor
{
	TreePathVisitor tpvisitor;
	alias tpvisitor this;

	Vector!(PositionState, Mallocator) output_position;

	@disable this();

	this(float width, float height, Orientation orientation)
	{
		tpvisitor = TreePathVisitor(width, height, orientation);
	}

	void enterNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
	}

	void leaveNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
	}

	void processLeaf(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
	}

	void onEnterTree(Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onEnterTree", tree_path.value[].dup, position, destination, state));
	}

	void onBeforeComplete(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onBeforeComplete", tree_path.value[].dup, position, destination, state));
	}

	void onComplete(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onComplete", tree_path.value[].dup, position, destination, state));
	}

	void onAfterComplete(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onAfterComplete", tree_path.value[].dup, position, destination, state));
	}

	void onBeforeEnterNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onBeforeEnterNode", tree_path.value[].dup, position, destination, state));
	}

	void onAfterEnterNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onAfterEnterNode", tree_path.value[].dup, position, destination, state));
	}

	void onBeforeLeaveNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onBeforeLeaveNode", tree_path.value[].dup, position, destination, state));
	}

	void onAfterLeaveNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onAfterLeaveNode", tree_path.value[].dup, position, destination, state));
	}

	void onBeforeProcessLeaf(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onBeforeProcessLeaf", tree_path.value[].dup, position, destination, state));
	}

	void onAfterProcessLeaf(Order order, Data, Model)(ref const(Data) data, ref Model model)
	{
		output_position.put(PositionState("onAfterProcessLeaf", tree_path.value[].dup, position, destination, state));
	}
}

@Name("forward")
unittest
{
	static struct V
	{
		long a;
		char b;
		string c;
	}

	@("orientation.Horizontal")
	static struct H
	{
		long a;
		char b;
		string c;
	}

	static struct VH
	{
		long a;
		H h;
		char b;
	}

	@("orientation.Horizontal")
	static struct HV
	{
		long a;
		V v;
		char b;
	}

	@("orientation.Horizontal")
	static struct HVHV
	{
		long a;
		HV hv;
		char b;
	}

	static struct VHVH
	{
		long a;
		VH vh;
		char b;
	}

	static struct NestedData2
	{
		short sh;
		@("orientation.Horizontal")
		V h;
		string str;
	}

	static struct Data
	{
		int i;
		float f;
		double d;
		string s;
		NestedData2 data2;
	}

	{
		const data = V(1, 'z');
		auto model = makeModel(data);
		{
			auto mv = MeasureVisitor(120, 9, Orientation.Vertical);
			model.visitForward(data, mv);
		}
		auto cv = CheckingVisitor(120, 9, Orientation.Vertical);
		cv.position = 0;
		model.collapsed = false;
		model.visitForward(data, cv);

		{
			import std;
			writeln(cv.output_position[]);
		}
	}
}