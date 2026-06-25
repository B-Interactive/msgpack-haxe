package org.msgpack.tests.unit;

import org.msgpack.MsgPack;
import utest.Test;
import utest.Assert;

/**
 * Array round-trips, flat and nested.
 */
class ArrayTests extends Test {
	function testFlatArray() {
		var a = [3, 2, 1, 7, 8, 9];
		var d:Array<Dynamic> = MsgPack.decode(MsgPack.encode(a));
		Assert.isTrue(Std.isOfType(d, Array));
		Assert.equals(a.length, d.length);
		for (i in 0...a.length)
			Assert.equals(a[i], d[i]);
	}

	function testNestedArray() {
		var a:Array<Dynamic> = [1, [2, 3, [4, 5]], "x"];
		var d:Array<Dynamic> = MsgPack.decode(MsgPack.encode(a));
		Assert.equals(1, d[0]);
		var inner:Array<Dynamic> = d[1];
		Assert.equals(2, inner[0]);
		Assert.equals(3, inner[1]);
		var deepest:Array<Dynamic> = inner[2];
		Assert.equals(4, deepest[0]);
		Assert.equals(5, deepest[1]);
		Assert.equals("x", d[2]);
	}
}
