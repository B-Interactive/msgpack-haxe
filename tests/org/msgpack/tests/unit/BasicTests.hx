package org.msgpack.tests.unit;

import haxe.io.Bytes;
import org.msgpack.MsgPack;
import utest.Test;
import utest.Assert;

/**
 * Scalar and Bytes round-trips through encode/decode.
 */
class BasicTests extends Test {
	function roundTrip<T>(a:T):Dynamic {
		return MsgPack.decode(MsgPack.encode(a));
	}

	function testScalars() {
		Assert.isNull(roundTrip(null));
		Assert.isTrue(Std.isOfType(roundTrip(true), Bool));
		Assert.isTrue(Std.isOfType(roundTrip(1000), Int));
		Assert.isTrue(Std.isOfType(roundTrip(1.01), Float));
		Assert.isTrue(Std.isOfType(roundTrip("ab"), String));

		Assert.equals(null, roundTrip(null));
		Assert.isTrue(roundTrip(true));
		Assert.equals(1000, roundTrip(1000));
		Assert.isTrue(Math.abs(1.01 - (roundTrip(1.01) : Float)) <= 0.00000001);
		Assert.equals("ab", roundTrip("ab"));
	}

	function testBytes() {
		var d:Bytes = roundTrip(Bytes.ofString("ab"));
		var a = Bytes.ofString("ab");
		Assert.equals(a.length, d.length);
		Assert.equals(a.toString(), d.toString());
	}
}
