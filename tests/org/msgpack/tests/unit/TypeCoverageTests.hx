package org.msgpack.tests.unit;

import haxe.Int64;
import haxe.io.Bytes;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import org.msgpack.MsgPack;
import org.msgpack.Decoder.DecodeOption;
import utest.Test;
import utest.Assert;

/**
 * Round-trip coverage of every supported type and the int encoding boundaries
 * (fixnum / 8 / 16 / 32, positive and negative). Only the supported int range is
 * tested, since Haxe Int is signed 32-bit.
 */
class TypeCoverageTests extends Test {
	function rt<T>(a:T):Dynamic {
		return MsgPack.decode(MsgPack.encode(a));
	}

	function testNullAndBool() {
		Assert.isNull(rt(null));
		Assert.equals(true, rt(true));
		Assert.equals(false, rt(false));
	}

	function testIntBoundaries() {
		// Positive: fixnum, uint8, uint16, int32 range.
		var positives = [0, 1, 127, 128, 255, 256, 65535, 65536, 1000000, 2147483647];
		for (v in positives)
			Assert.equals(v, rt(v));

		// Negative: fixnum, int8, int16, int32.
		var negatives = [-1, -32, -33, -128, -129, -32768, -32769, -2147483648];
		for (v in negatives)
			Assert.equals(v, rt(v));
	}

	function testFloats() {
		// Single-precision value (0xca) and a double (0xcb).
		var single:Float = 1.5;
		Assert.isTrue(Math.abs(single - (rt(single) : Float)) <= 0.0001);

		var dbl:Float = 1.7976931348623157e+200;
		Assert.equals(dbl, (rt(dbl) : Float));

		var neg:Float = -3.14159;
		Assert.isTrue(Math.abs(neg - (rt(neg) : Float)) <= 0.0001);
	}

	function testStrings() {
		Assert.equals("", rt(""));
		Assert.equals("hello", rt("hello"));
		// Multibyte UTF-8, where byte length differs from char count.
		var utf8 = "caf\u00e9 \u00fc \u6f22\u5b57";
		Assert.equals(utf8, rt(utf8));
	}

	function testBytes() {
		var raw = Bytes.alloc(4);
		raw.set(0, 0x00);
		raw.set(1, 0xff);
		raw.set(2, 0x10);
		raw.set(3, 0x7f);
		var d:Bytes = rt(raw);
		Assert.equals(raw.length, d.length);
		for (i in 0...raw.length)
			Assert.equals(raw.get(i), d.get(i));
	}

	function testInt64() {
		var v = Int64.make(0x12345678, 0x7654321);
		var d:Dynamic = rt(v);
		Assert.isTrue(Int64.isInt64(d));
		var got:Int64 = d;
		Assert.equals(0x12345678, got.high);
		Assert.equals(0x7654321, got.low);
	}

	function testStringMapNested() {
		var m = new StringMap<Dynamic>();
		m.set("i", 42);
		m.set("neg", -7);
		m.set("f", 1.25);
		m.set("b", true);
		m.set("n", null);
		m.set("arr", [1, 2, 3]);
		var inner = new StringMap<Dynamic>();
		inner.set("x", "y");
		m.set("nested", inner);

		var d:Map<String, Dynamic> = cast MsgPack.decode(MsgPack.encode(m), DecodeOption.AsMap);
		Assert.equals(42, d.get("i"));
		Assert.equals(-7, d.get("neg"));
		Assert.isTrue(Math.abs(1.25 - (d.get("f") : Float)) <= 0.0001);
		Assert.equals(true, d.get("b"));
		Assert.isNull(d.get("n"));
		var arr:Array<Dynamic> = d.get("arr");
		Assert.equals(3, arr.length);
		var nested:Map<String, Dynamic> = cast d.get("nested");
		Assert.equals("y", nested.get("x"));
	}

	function testIntMap() {
		var m = new IntMap<Dynamic>();
		m.set(1, "a");
		m.set(100, "b");
		var d:IntMap<Dynamic> = cast MsgPack.decode(MsgPack.encode(m), DecodeOption.AsMap);
		Assert.equals("a", d.get(1));
		Assert.equals("b", d.get(100));
	}
}
