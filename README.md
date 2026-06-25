[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](license.txt) [![Haxelib Version](https://img.shields.io/github/release/aaulia/msgpack-haxe.svg?style=flat&label=haxelib)](http://lib.haxe.org/p/msgpack-haxe)

msgpack-haxe
============

MessagePack (http://msgpack.org) serialization library for Haxe

How to install:
-------------
Simply use `haxelib git` to use this github repo or `haxelib install msgpack-haxe` to use the one in the haxelib repository.

Supported Type:
-------------
* Null
* Bool
* Int
* Float
* Object
* Bytes
* String
* Array
* IntMap/StringMap
* Int64

Example code:
-------------
``` haxe
package;
import org.msgpack.MsgPack;

class Example {
    public static function main() {
        var i = { a: 1, b: 2, c: "Hello World!" };
        var m = MsgPack.encode(i);
        var o = MsgPack.decode(m);

        trace(i);
        trace(m.toHex());
        trace(o);
    }
}
```

Decode options:
-------------
`MsgPack.decode(bytes, option)` takes a `DecodeOption`:

* `AsMap` (recommended for native/C++): maps become an `IntMap` or `StringMap`.
  Uses no reflection, so it is safe with DCE / `-final`.
* `AsObject` (default): maps become an anonymous object. Uses reflection. Kept
  for backward compatibility.

Notes:
-------------
* `decode` needs a complete `Bytes` value. The library does no stream framing,
  so splitting messages is up to you.
* Unsigned 64-bit (`0xcf`) is not decoded; it throws instead of returning a
  lossy value. Don't send unsigned 64-bit.
* Haxe `Int` is signed 32-bit, so values >= 2^31 can't be sent as unsigned
  int32. Pass them as `Float` or `Int64`.
* Strings use the UTF-8 byte length as their prefix, so multibyte strings work
  with other MessagePack libraries.

Tests:
-------------
Built on `utest` and run on the C++ target:

```
haxe tests_check.hxml   # type-check only, no compiler needed
haxe tests_cpp.hxml     # build + run on C++
haxe tests_dce.hxml     # build + run on C++ with -dce full
```

The cross-language tests use `node` and the `@msgpack/msgpack` module. They skip
automatically if neither is found. Set `MSGPACK_NODE_MODULE` to a specific path,
or the suite looks for `node_modules/@msgpack/msgpack` up from the current folder.
