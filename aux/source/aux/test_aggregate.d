module aux.test_aggregate;

version(unittest) import unit_threaded : Name;

// this is initial attempt to separate tests to different files

version(unittest) @Name("aggregate+orientation")
unittest
{
	import unit_threaded : should, be;
	import std.experimental.allocator.mallocator : Mallocator;
	import automem.vector : Vector;

	import aux.model : Order, Orientation, MeasureVisitor, makeModel,
		TreePathVisitor, logger, visitForward;

	static struct OrientationState
	{
		string label;
		Orientation orientation;
	}

	static struct SizeState
	{
		string label;
		double size;

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
			if (size.approxEqual(other.size))
				return 0;
			if (size < other.size)
				return -1;
			return 1;
		}
	}

	static struct PositionState
	{
		string label;
		int[] path;
		double[2] pos;

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
			return 1;
		}
	}

	static struct MeasureVisitor2
	{
		MeasureVisitor mvisitor;
		alias mvisitor this;

		Vector!(OrientationState, Mallocator) output_orientation;
		Vector!(SizeState, Mallocator) output_size;

		this(float width, float height) @nogc
		{
			mvisitor = MeasureVisitor(width, height, Orientation.Vertical);
		}

		void enterNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
		{
			output_orientation.put(OrientationState("enterNode   " ~ Model.stringof ~ " ", orientation));

			mvisitor.enterNode!order(data, model);

			output_size.put(SizeState("enterNode   " ~ Model.stringof ~ " ", model.size));
		}

		void leaveNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
		{
			mvisitor.leaveNode!order(data, model);

			output_size.put(SizeState("leaveNode   " ~ Model.stringof ~ " ", model.size));
			output_orientation.put(OrientationState("leaveNode   " ~ Model.stringof ~ " ", orientation));
		}

		void processLeaf(Order order, Data, Model)(ref const(Data) data, ref Model model)
		{
			output_orientation.put(OrientationState("processLeaf " ~ Model.stringof ~ " ", orientation));

			mvisitor.processLeaf!order(data, model);

			output_size.put(SizeState("processLeaf " ~ Model.stringof ~ " ", model.size));
		}
	}

	static struct RenderVisitor
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
			tpvisitor.enterNode!order(data, model);

			output_position.put(PositionState("enterNode   " ~ Model.stringof ~ " ", tree_path.value[].dup, position));
		}

		void leaveNode(Order order, Data, Model)(ref const(Data) data, ref Model model)
		{
			tpvisitor.leaveNode!order(data, model);

			output_position.put(PositionState("leaveNode   " ~ Model.stringof ~ " ", tree_path.value[].dup, position));
		}

		void processLeaf(Order order, Data, Model)(ref const(Data) data, ref Model model)
		{
			tpvisitor.processLeaf!order(data, model);

			output_position.put(PositionState("processLeaf " ~ Model.stringof ~ " ", tree_path.value[].dup, position));
		}
	}

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
		auto mv = MeasureVisitor2(120, 9);
		model.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(V) ", Orientation.Vertical), 
			OrientationState("processLeaf ScalarModel!(a) ",    Orientation.Vertical), 
			OrientationState("processLeaf ScalarModel!(b) ",    Orientation.Vertical), 
			OrientationState("processLeaf ScalarModel!(c) ",    Orientation.Vertical), 
			OrientationState("leaveNode   AggregateModel!(V) ", Orientation.Vertical)
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(V) ", 10), 
			SizeState("processLeaf ScalarModel!(a) ",    10), 
			SizeState("processLeaf ScalarModel!(b) ",    10), 
			SizeState("processLeaf ScalarModel!(c) ",    10), 
			SizeState("leaveNode   AggregateModel!(V) ", 40)
		];

		auto rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		debug logger.trace("------ RenderVisitor V ---------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(V) ", [],  [0,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",    [0], [0, 10]), 
			PositionState("processLeaf ScalarModel!(b) ",    [1], [0, 20]), 
			PositionState("processLeaf ScalarModel!(c) ",    [2], [0, 30]), 
			PositionState("leaveNode   AggregateModel!(V) ", [],  [0, 30])
		];

		rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		rv.path_position = 50;
		rv.path.value = [0];
		debug logger.trace("------ RenderVisitor V ---------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		rv.output_position[].should.be == [
			PositionState("processLeaf ScalarModel!(a) ",    [0], [0, 50]), 
			PositionState("processLeaf ScalarModel!(b) ",    [1], [0, 60]), 
			PositionState("processLeaf ScalarModel!(c) ",    [2], [0, 70]), 
			PositionState("leaveNode   AggregateModel!(V) ", [],  [0, 70])
		];
	}
	{
		const data = H(1, 'z');
		auto model = makeModel(data);
		auto mv = MeasureVisitor2(120, 9);
		model.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(H) ", Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",    Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(b) ",    Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(c) ",    Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(H) ", Orientation.Horizontal),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(H) ", 121.0000), 
			SizeState("processLeaf ScalarModel!(a) ",     40.3333), 
			SizeState("processLeaf ScalarModel!(b) ",     40.3333), 
			SizeState("processLeaf ScalarModel!(c) ",     40.3333), 
			SizeState("leaveNode   AggregateModel!(H) ", 121.0000)
		];

		auto rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		model.visitForward(data, rv);

		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(H) ", [],  [ 0.0000, 0]), 
			PositionState("processLeaf ScalarModel!(a) ",    [0], [ 0.0000, 0]), 
			PositionState("processLeaf ScalarModel!(b) ",    [1], [40.3333, 0]), 
			PositionState("processLeaf ScalarModel!(c) ",    [2], [80.6667, 0]), 
			PositionState("leaveNode   AggregateModel!(H) ", [],  [80.6667, 0])
		];
	}
	{
		const data = VH(1, H(1, 'z'), 'z');
		auto model = makeModel(data);
		auto mv = MeasureVisitor2(120, 9);
		model.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(VH) ", Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Vertical  ), 
			OrientationState("enterNode   AggregateModel!(h) ",  Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(h) ",  Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Vertical  ), 
			OrientationState("leaveNode   AggregateModel!(VH) ", Orientation.Vertical  ),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(VH) ",  10), 
			SizeState("processLeaf ScalarModel!(a) ",      10), 
			SizeState("enterNode   AggregateModel!(h) ",  121), 
			SizeState("leaveNode   AggregateModel!(h) ",  121), 
			SizeState("processLeaf ScalarModel!(b) ",      10), 
			SizeState("leaveNode   AggregateModel!(VH) ",  40),
		];

		auto rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		model.visitForward(data, rv);

		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(VH) ", [],  [0, 0]), 
			PositionState("processLeaf ScalarModel!(a) ",     [0], [0, 10]), 
			PositionState("enterNode   AggregateModel!(h) ",  [1], [0, 20]), 
			PositionState("leaveNode   AggregateModel!(h) ",  [1], [0, 20]), 
			PositionState("processLeaf ScalarModel!(b) ",     [2], [0, 30]), 
			PositionState("leaveNode   AggregateModel!(VH) ", [],  [0, 30]),
		];

		mv = MeasureVisitor2(120, 9);
		model.h.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(VH) ", Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Vertical  ), 
			OrientationState("enterNode   AggregateModel!(h) ",  Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(c) ",     Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(h) ",  Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Vertical  ), 
			OrientationState("leaveNode   AggregateModel!(VH) ", Orientation.Vertical  ),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(VH) ", 10.0), 
			SizeState("processLeaf ScalarModel!(a) ",     10.0), 
			SizeState("enterNode   AggregateModel!(h) ", 121.0), 
			SizeState("processLeaf ScalarModel!(a) ",     40.3333), 
			SizeState("processLeaf ScalarModel!(b) ",     40.3333), 
			SizeState("processLeaf ScalarModel!(c) ",     40.3333), 
			SizeState("leaveNode   AggregateModel!(h) ", 121.0), 
			SizeState("processLeaf ScalarModel!(b) ",     10.0), 
			SizeState("leaveNode   AggregateModel!(VH) ", 40.0),
		];

		rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		debug logger.trace("------ RenderVisitor HV --------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(VH) ", [],     [ 0.0000, 0]), 
			PositionState("processLeaf ScalarModel!(a) ",     [0],    [ 0.0000, 10]), 
			PositionState("enterNode   AggregateModel!(h) ",  [1],    [ 0.0000, 20]), 
			PositionState("processLeaf ScalarModel!(a) ",     [1, 0], [ 0.0000, 20]), 
			PositionState("processLeaf ScalarModel!(b) ",     [1, 1], [40.3333, 20]), 
			PositionState("processLeaf ScalarModel!(c) ",     [1, 2], [80.6667, 20]), 
			PositionState("leaveNode   AggregateModel!(h) ",  [1],    [80.6667, 20]), 
			PositionState("processLeaf ScalarModel!(b) ",     [2],    [ 0.0000, 30]), 
			PositionState("leaveNode   AggregateModel!(VH) ", [],     [ 0.0000, 30]),
		]; 
	}
	{
		const data = HV(1, V(1, 'z'), 'z');
		auto model = makeModel(data);
		auto mv = MeasureVisitor2(120, 9);
		model.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(HV) ", Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Horizontal), 
			OrientationState("enterNode   AggregateModel!(v) ",  Orientation.Vertical  ), 
			OrientationState("leaveNode   AggregateModel!(v) ",  Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(HV) ", Orientation.Horizontal),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(HV) ", 121), 
			SizeState("processLeaf ScalarModel!(a) ",     40.3333), 
			SizeState("enterNode   AggregateModel!(v) ",  10), 
			SizeState("leaveNode   AggregateModel!(v) ",  10), 
			SizeState("processLeaf ScalarModel!(b) ",     40.3333), 
			SizeState("leaveNode   AggregateModel!(HV) ", 121),
		];

		auto rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		debug logger.trace("------ RenderVisitor HV --------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		/*
		<---------------------HV: 121-------------------->
		<-HV.a: 40.3333-><-HV.v: 40.333-><-HV.b: 40.3333-> // 40.3333 = 121/3.0
		*/
		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(HV) ", [],  [ 0, 0]), 
			PositionState("processLeaf ScalarModel!(a) ",     [0], [ 0, 0]), 
			PositionState("enterNode   AggregateModel!(v) ",  [1], [40.3333, 0]), 
			PositionState("leaveNode   AggregateModel!(v) ",  [1], [40.3333, 0]), 
			PositionState("processLeaf ScalarModel!(b) ",     [2], [80.6667, 0]), 
			PositionState("leaveNode   AggregateModel!(HV) ", [],  [80.6667, 0]),
		];

		model.size.should.be == 121;

		mv = MeasureVisitor2(120, 9);
		model.v.collapsed = false;
		model.visitForward(data, mv);

		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(HV) ", Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Horizontal), 
			OrientationState("enterNode   AggregateModel!(v) ",  Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(a) ",     Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(c) ",     Orientation.Vertical  ), 
			OrientationState("leaveNode   AggregateModel!(v) ",  Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(b) ",     Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(HV) ", Orientation.Horizontal),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(HV) ", 121), 
			SizeState("processLeaf ScalarModel!(a) ",     40.333), 
			SizeState("enterNode   AggregateModel!(v) ",  10), 
			SizeState("processLeaf ScalarModel!(a) ",     10), 
			SizeState("processLeaf ScalarModel!(b) ",     10), 
			SizeState("processLeaf ScalarModel!(c) ",     10), 
			SizeState("leaveNode   AggregateModel!(v) ",  40), 
			SizeState("processLeaf ScalarModel!(b) ",     40.333), 
			SizeState("leaveNode   AggregateModel!(HV) ", 121),
		];

		rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		debug logger.trace("------ RenderVisitor HV --------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		/*
		<---------------------HV: 121-------------------->
		<-HV.a: 40.3333-><-HV.v: 40.333-><-HV.b: 40.3333-> // 40.3333 = 121/3.0
		                 /\               /\
		                 || HV.v.a: 10    ||
		                 \/               ||
		                 /\               ||
		                 || HV.v.b: 10    || 30
		                 \/               ||
		                 /\               ||
		                 || HV.v.c: 10    ||
		                 \/               \/
		*/
		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(HV) ", [],     [ 0.0000,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",     [0],    [ 0.0000,  0]), 
			PositionState("enterNode   AggregateModel!(v) ",  [1],    [40.3333,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",     [1, 0], [40.3333, 10]), 
			PositionState("processLeaf ScalarModel!(b) ",     [1, 1], [40.3333, 20]), 
			PositionState("processLeaf ScalarModel!(c) ",     [1, 2], [40.3333, 30]), 
			PositionState("leaveNode   AggregateModel!(v) ",  [1],    [40.3333, 30]), 
			PositionState("processLeaf ScalarModel!(b) ",     [2],    [80.6667,  0]), 
			PositionState("leaveNode   AggregateModel!(HV) ", [],     [80.6667,  0]),
		];
	}
	{
		const data = HVHV(1, HV(2, V(3, 'x'), 'y'), 'z');
		auto model = makeModel(data);
		auto mv = MeasureVisitor2(120, 9);
		model.collapsed = false;
		model.hv.collapsed = false;
		model.hv.v.collapsed = false;
		model.visitForward(data, mv);

		/*
		HVHV HVHV.a HVHV.hv HVHV.hv.a HVHV.hv.v    HVHV.hv.b HVHV.b
		                              HVHV.hv.v.a
		                              HVHV.hv.v.b
		*/
		mv.output_orientation[].should.be == [
			OrientationState("enterNode   AggregateModel!(HVHV) ", Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",       Orientation.Horizontal), 
			OrientationState("enterNode   AggregateModel!(hv) ",   Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(a) ",       Orientation.Horizontal), 
			OrientationState("enterNode   AggregateModel!(v) ",    Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(a) ",       Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(b) ",       Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(c) ",       Orientation.Vertical  ), 
			OrientationState("leaveNode   AggregateModel!(v) ",    Orientation.Vertical  ), 
			OrientationState("processLeaf ScalarModel!(b) ",       Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(hv) ",   Orientation.Horizontal), 
			OrientationState("processLeaf ScalarModel!(b) ",       Orientation.Horizontal), 
			OrientationState("leaveNode   AggregateModel!(HVHV) ", Orientation.Horizontal),
		];

		mv.output_size[].should.be == [
			SizeState("enterNode   AggregateModel!(HVHV) ", 121), 
			SizeState("processLeaf ScalarModel!(a) ",       40.3333), 
			SizeState("enterNode   AggregateModel!(hv) ",   40.3333), 
			SizeState("processLeaf ScalarModel!(a) ",       13.4444), 
			SizeState("enterNode   AggregateModel!(v) ",    10), 
			SizeState("processLeaf ScalarModel!(a) ",       10), 
			SizeState("processLeaf ScalarModel!(b) ",       10), 
			SizeState("processLeaf ScalarModel!(c) ",       10), 
			SizeState("leaveNode   AggregateModel!(v) ",    40), 
			SizeState("processLeaf ScalarModel!(b) ",       13.4444), 
			SizeState("leaveNode   AggregateModel!(hv) ",   40.3333), 
			SizeState("processLeaf ScalarModel!(b) ",       40.3333), 
			SizeState("leaveNode   AggregateModel!(HVHV) ", 121),
		];

		auto rv = RenderVisitor(120, 9, Orientation.Vertical);
		rv.position = 0;
		debug logger.trace("------ RenderVisitor HVHV ------------------");
		model.visitForward(data, rv);
		debug logger.trace("--------------------------------------------");

		/*
		<-HVHV: 121 ----------------------------------------------------------------------------------------------->
		<-HVHV.a: 40.3333-><-HVHV.hv: 40.3333-----------------------------------------------><-- HVHV.b: 40.3333 --> // 40.3333 = 121/3.0
		                   <-HVHV.hv.a: 13.4444-><-HVHV.hv.v: 13.4444-><-HVHV.hv.b: 13.4444->                        // 13.4444 = 40.3333/3.0
		                                         /\                  /\
		                                         || HVHV.hv.v: 10    ||
		                                         \/                  ||
		                                         /\                  ||
		                                         || HVHV.hv.a: 10    || 30
		                                         \/                  ||
		                                         /\                  ||
		                                         || HVHV.hv.a: 10    ||
		                                         \/                  \/
		*/
		rv.output_position[].should.be == [
			PositionState("enterNode   AggregateModel!(HVHV) ", [],        [  0.0000,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",       [0],       [  0.0000,  0]), 
			PositionState("enterNode   AggregateModel!(hv) ",   [1],       [ 40.3333,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",       [1, 0],    [ 40.3333,  0]), 
			PositionState("enterNode   AggregateModel!(v) ",    [1, 1],    [ 53.7778,  0]), 
			PositionState("processLeaf ScalarModel!(a) ",       [1, 1, 0], [ 53.7778, 10]), 
			PositionState("processLeaf ScalarModel!(b) ",       [1, 1, 1], [ 53.7778, 20]), 
			PositionState("processLeaf ScalarModel!(c) ",       [1, 1, 2], [ 53.7778, 30]), 
			PositionState("leaveNode   AggregateModel!(v) ",    [1, 1],    [ 53.7778, 30]), 
			PositionState("processLeaf ScalarModel!(b) ",       [1, 2],    [ 67.2223,  0]), 
			PositionState("leaveNode   AggregateModel!(hv) ",   [1],       [ 67.2223,  0]), 
			PositionState("processLeaf ScalarModel!(b) ",       [2],       [ 80.6667,  0]), 
			PositionState("leaveNode   AggregateModel!(HVHV) ", [],        [ 80.6667,  0]),
		];
	}
}
