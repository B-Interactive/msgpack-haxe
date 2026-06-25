package org.msgpack.tests.unit;

import org.msgpack.MsgPack;
import org.msgpack.Decoder.DecodeOption;
import utest.Test;
import utest.Assert;

/**
 * Checks the AsObject path (reflection-based, kept for compatibility).
 */
class ObjectTests extends Test {
	function testObjectRoundTrip() {
		var d = MsgPack.decode(MsgPack.encode({a: 10, b: "abc"}), DecodeOption.AsObject);
		Assert.isTrue(Reflect.hasField(d, "a"));
		Assert.isTrue(Reflect.hasField(d, "b"));
		Assert.equals(10, Reflect.field(d, "a"));
		Assert.equals("abc", Reflect.field(d, "b"));
	}
}
