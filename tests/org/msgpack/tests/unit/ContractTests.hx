package org.msgpack.tests.unit;

import haxe.io.Bytes;
import org.msgpack.MsgPack;
import utest.Test;
import utest.Assert;

/**
 * Checks unsigned 64-bit (0xcf) throws instead of decoding to a lossy value.
 */
class ContractTests extends Test {
	function testUInt64Throws() {
		// 0xcf marker plus 8 bytes is the MessagePack uint64 form.
		var b = Bytes.alloc(9);
		b.set(0, 0xcf);
		for (i in 1...9)
			b.set(i, 0xff);

		var threw = false;
		var message:String = null;
		try {
			MsgPack.decode(b);
		} catch (e:Dynamic) {
			threw = true;
			message = Std.string(e);
		}

		Assert.isTrue(threw, "decoding a uint64 (0xcf) must throw");
		Assert.isTrue(message != null && message.indexOf("64") != -1,
			"the throw should be descriptive about unsigned 64-bit");
	}
}
