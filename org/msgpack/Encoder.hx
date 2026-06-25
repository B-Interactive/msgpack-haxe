package org.msgpack;

import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.Constraints.IMap;

using Reflect;


/**
 * MessagePack encoder. Turns a Haxe value (null, Bool, Int, Float, Int64,
 * String, haxe.io.Bytes, Array, any IMap, or an anonymous object) into
 * MessagePack bytes.
 *
 * Note: Haxe `Int` is signed 32-bit, so values >= 2^31 can't be written as an
 * unsigned int32. Pass them as `Float` or `Int64` instead.
 */
class Encoder {

	static private inline var FLOAT_SINGLE_MIN:Float = 1.40129846432481707e-45;
	static private inline var FLOAT_SINGLE_MAX:Float = 3.40282346638528860e+38;

	static private inline var FLOAT_DOUBLE_MIN:Float = 4.94065645841246544e-324;
	static private inline var FLOAT_DOUBLE_MAX:Float = 1.79769313486231570e+308;

	var o:BytesOutput;

	public function new(d:Dynamic) {
		o = new BytesOutput();
		o.bigEndian = true;

		encode(d);
	}

	function encode(d:Dynamic) {
		switch (Type.typeof(d)) {
			case TNull    : o.writeByte(0xc0);
			case TBool    : o.writeByte(d ? 0xc3 : 0xc2);
			case TInt     : writeInt(d);
			case TFloat   : writeFloat(d);
			
			// Use runtime type checks, not class-name strings: DCE can strip
			// those names and silently break detection. Check Int64 first, then
			// Bytes/String/Array, then any Map via the IMap interface.
			case TClass(c):
				if (Int64.isInt64(d)) writeInt64(d);
				else if (Std.isOfType(d, Bytes)) writeBinary(d);
				else if (Std.isOfType(d, String)) writeString(d);
				else if (Std.isOfType(d, Array)) writeArray(d);
				else if (Std.isOfType(d, IMap)) writeMap(d);
				else throw 'Error: ${Type.getClassName(c)} not supported';

			case TObject  : writeObject(d);
			case TEnum(e) : throw "Error: Enum not supported";
			case TFunction: throw "Error: Function not supported";
			case TUnknown : throw "Error: Unknown Data Type";
		}
	}

	inline function writeInt64(d:Int64) {
		o.writeByte(0xd3);
		o.writeInt32(d.high);
		o.writeInt32(d.low);
	}

	inline function writeInt(d:Int) {
		if (d < -(1 << 5)) {
			// less than negative fixnum ?
			if (d < -(1 << 15)) {
				// signed int 32
				o.writeByte(0xd2);
				o.writeInt32(d);
			} else
			if (d < -(1 << 7)) {
				// signed int 16
				o.writeByte(0xd1);
				o.writeInt16(d);
			} else {
				// signed int 8
				o.writeByte(0xd0);
				o.writeInt8(d);
			}
		} else
		if (d < (1 << 7)) {
			// negative fixnum < d < positive fixnum [fixnum]
			o.writeByte(d & 0x000000ff);
		} else {
			// unsigned land
			if (d < (1 << 8)) {
				// unsigned int 8
				o.writeByte(0xcc);
				o.writeByte(d);
			} else
			if (d < (1 << 16)) {
				// unsigned int 16
				o.writeByte(0xcd);
				o.writeUInt16(d);
			} else {
				// unsigned int 32 
				// TODO: HaXe writeUInt32 ?
				o.writeByte(0xce);
				o.writeInt32(d);
			}
		}
	}

	inline function writeFloat(d:Float) {		
			var a = Math.abs(d);
			if (a > FLOAT_SINGLE_MIN && a < FLOAT_SINGLE_MAX) {
				// Single Precision Floating
				o.writeByte(0xca);
				o.writeFloat(d);
			} else {
				// Double Precision Floating
				o.writeByte(0xcb);
				o.writeDouble(d);
			}
	}

	inline function writeBinary(b:Bytes) {
		var length = b.length;
		if (length < 0x100) {
			// binary 8
			o.writeByte(0xc4);
			o.writeByte(length);
		} else
		if (length < 0x10000) {
			// binary 16
			o.writeByte(0xc5);
			o.writeUInt16(length);
		} else {
			// binary 32
			o.writeByte(0xc6);
			o.writeInt32(length);
		}
		o.write(b);
	}

	inline function writeString(b:String) {
		// The length prefix is the UTF-8 byte length, not the char count.
		// Encode to Bytes first so multibyte strings work with other libraries.
		var bytes = Bytes.ofString(b);
		var length = bytes.length;
		if (length < 0x20) {
			// fix string
			o.writeByte(0xa0 | length);
		} else
		if (length < 0x100) {
			// string 8
			o.writeByte(0xd9);
			o.writeByte(length);
		} else
		if (length < 0x10000) {
			// string 16
			o.writeByte(0xda);
			o.writeUInt16(length);
		} else {
			// string 32
			o.writeByte(0xdb);
			o.writeInt32(length);
		}
		o.write(bytes);
	}

	inline function writeArray(d:Array<Dynamic>) {
		var length = d.length;
		if (length < 0x10) {
			// fix array
			o.writeByte(0x90 | length);
		} else 
		if (length < 0x10000) {
			// array 16
			o.writeByte(0xdc);
			o.writeUInt16(length);
		} else {
			// array 32
			o.writeByte(0xdd);
			o.writeInt32(length);
		}

		for (e in d) {
			encode(e);
		}
	}

	inline function writeMapLength(length:Int) {
		if (length < 0x10) {
			// fix map
			o.writeByte(0x80 | length);
		} else 
		if (length < 0x10000) {
			// map 16
			o.writeByte(0xde);
			o.writeUInt16(length);
		} else {
			// map 32
			o.writeByte(0xdf);
			o.writeInt32(length);
		}		
	}

	inline function writeMap<K, V>(d:Map<K, V>) {
		
		var length = 0;
		for (k in d.keys()) 
			length++;

		writeMapLength(length);
		for (k in d.keys()) { 
			encode(k);
			encode(d.get(k));
		}
	}

	inline function writeObject(d:Dynamic) {
		var f = d.fields();

		// Count inline to avoid a Lambda dependency.
		var length = 0;
		for (k in f) length++;

		writeMapLength(length);
		for (k in f) {
			encode(k);
			encode(d.field(k));
		}
	}

	public inline function getBytes():Bytes {
		return o.getBytes();
	}
}
