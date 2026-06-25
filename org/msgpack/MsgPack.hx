package org.msgpack;

import haxe.io.Bytes;
import org.msgpack.Decoder.DecodeOption;

/**
 * Main entry point for MessagePack encode/decode.
 *
 * `encode` takes a supported Haxe value (null, Bool, Int, Float, Int64,
 * String, haxe.io.Bytes, Array, IMap, or an anonymous object) and returns
 * MessagePack `Bytes`.
 *
 * `decode` needs a complete value buffer (see `Decoder`). Pass
 * `DecodeOption.AsMap` to decode maps into IntMap/StringMap; the default
 * `AsObject` returns an anonymous object and is kept for backward compatibility.
 */
class MsgPack {

	public static inline function encode(d:Dynamic):Bytes {
		return new Encoder(d).getBytes();
	}

	public static inline function decode(b:Bytes, ?option:DecodeOption):Dynamic {
		if (option == null)
            option = DecodeOption.AsObject;

		return new Decoder(b, option).getResult();
	}

}
