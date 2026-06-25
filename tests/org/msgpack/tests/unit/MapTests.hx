package org.msgpack.tests.unit;

import haxe.ds.IntMap;
import haxe.ds.StringMap;
import org.msgpack.MsgPack;
import org.msgpack.Decoder.DecodeOption;
import utest.Test;
import utest.Assert;

/**
 * Checks the AsMap path returns a usable IntMap / StringMap.
 */
class MapTests extends Test {
	function testIntMap() {
		var im = new IntMap<String>();
		im.set(1, "one");
		im.set(3, "Three");
		im.set(9, "Nine");

		var d = MsgPack.decode(MsgPack.encode(im), DecodeOption.AsMap);
		Assert.isTrue(Std.isOfType(d, IntMap));

		var ni:IntMap<Dynamic> = cast d;
		for (k in im.keys())
			Assert.isTrue(ni.exists(k) && ni.get(k) == im.get(k));
	}

	function testStringMap() {
		var sm = new StringMap<Int>();
		sm.set("one", 1);
		sm.set("Three", 3);
		sm.set("Nine", 9);

		var d = MsgPack.decode(MsgPack.encode(sm), DecodeOption.AsMap);
		Assert.isTrue(Std.isOfType(d, StringMap));

		var ns:Map<String, Dynamic> = cast d;
		for (k in sm.keys())
			Assert.isTrue(ns.exists(k) && ns.get(k) == sm.get(k));
	}

	function testEmptyMap() {
		var sm = new StringMap<Int>();
		var d = MsgPack.decode(MsgPack.encode(sm), DecodeOption.AsMap);
		Assert.isTrue(Std.isOfType(d, StringMap));
		var ns:Map<String, Dynamic> = cast d;
		Assert.equals(0, Lambda.count(ns));
	}
}
