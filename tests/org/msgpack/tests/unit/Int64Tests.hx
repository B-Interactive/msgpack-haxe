package org.msgpack.tests.unit;

import haxe.Int64;
import org.msgpack.MsgPack;
import utest.Test;
import utest.Assert;

/**
 * Int64 round-trips, using Haxe 4 APIs (Int64.isInt64, .high/.low).
 *
 * Also checks the encoder tells Int64 from a plain Int at the wire level
 * (Int64 -> 0xd3 marker, plain Int -> fixint). This matters because on cpp
 * Int64.isInt64(plainInt) can return true.
 */
class Int64Tests extends Test {
	function testInt64RoundTrip() {
		var d:Dynamic = MsgPack.decode(MsgPack.encode(Int64.make(1, 2)));
		Assert.isTrue(Int64.isInt64(d));
		var v:Int64 = d;
		Assert.equals(1, v.high);
		Assert.equals(2, v.low);
	}

	function testInt64EncodesAsInt64Marker() {
		// A true 64-bit value (high != 0) must emit the 0xd3 marker. (On cpp a
		// small Int64 that fits 32 bits may encode as a compact int, which is
		// fine; this tests the wide case.)
		var e = MsgPack.encode(Int64.make(1, 7));
		Assert.equals(0xd3, e.get(0));
		Assert.equals(9, e.length); // 1 marker + 4 high + 4 low
	}

	function testPlainIntEncodesAsFixint() {
		// A plain Int is handled before the Int64 branch, so a small Int emits a
		// single fixint byte, never the 0xd3 marker.
		var e = MsgPack.encode(7);
		Assert.equals(1, e.length);
		Assert.equals(7, e.get(0));

		// And it round-trips back as a plain Int.
		var d:Dynamic = MsgPack.decode(e);
		Assert.isTrue(Std.isOfType(d, Int));
		Assert.equals(7, d);
	}
}
