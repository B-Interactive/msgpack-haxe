package org.msgpack.tests.unit;

import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ds.StringMap;
import sys.FileSystem;
import sys.io.File;
import org.msgpack.MsgPack;
import org.msgpack.Decoder.DecodeOption;
import utest.Test;
import utest.Assert;

/**
 * Checks the wire format matches Node's `@msgpack/msgpack` in both directions:
 *   - Haxe encodes -> Node decodes and validates.
 *   - Node encodes -> Haxe decodes via AsMap and asserts.
 *   - A fixed value (small ints / fixstr / bool / nil) is byte-for-byte identical.
 *
 * How it works: a small CommonJS helper is written to a temp dir and run with
 * Sys.command("node", ...). It requires the installed module by absolute path;
 * nothing is downloaded. If node or the module isn't found, the test skips
 * instead of failing.
 *
 * Run with: haxe tests_cpp.hxml
 * Needs node on PATH and an installed `@msgpack/msgpack`. Set MSGPACK_NODE_MODULE
 * to its path, or the test walks up from the cwd looking for
 * node_modules/@msgpack/msgpack.
 */
class NodeParityTests extends Test {
	var dir:String;
	var modPath:String;
	var helper:String;

	function setup() {
		dir = null;
		modPath = resolveModule();
		if (!hasNode() || modPath == null) {
			return;
		}

		dir = Path.join([Sys.getCwd(), "tests_tmp_parity_" + Std.int(Sys.time() * 1000)]);
		try {
			FileSystem.createDirectory(dir);
			helper = Path.join([dir, "parity.cjs"]);
			File.saveContent(helper, helperScript());
		} catch (e:Dynamic) {
			dir = null;
		}
	}

	function teardown() {
		if (dir != null) {
			deleteRecursive(dir);
			dir = null;
		}
	}

	static function hasNode():Bool {
		try {
			return Sys.command("node", ["--version"]) == 0;
		} catch (e:Dynamic) {
			return false;
		}
	}

	// Find the installed @msgpack/msgpack module:
	//   1. MSGPACK_NODE_MODULE env var, or
	//   2. walk up from the cwd looking for node_modules/@msgpack/msgpack.
	// Returns null (so the test skips) if neither is found.
	static function resolveModule():String {
		var env = Sys.getEnv("MSGPACK_NODE_MODULE");
		if (env != null && env != "" && FileSystem.exists(env)) {
			return env;
		}

		var rel = "node_modules/@msgpack/msgpack";
		// Walk up the parent folders, stopping at the root.
		var dir = Path.normalize(Sys.getCwd());
		var depth = 0;
		while (depth < 64) {
			if (FileSystem.exists(Path.join([dir, rel]))) {
				return Path.join([dir, rel]);
			}
			var slash = dir.lastIndexOf("/");
			if (slash <= 0) {
				break;
			}
			dir = dir.substr(0, slash);
			depth++;
		}
		return null;
	}

	// The value used in both directions.
	function buildMap():StringMap<Dynamic> {
		var m = new StringMap<Dynamic>();
		m.set("i", 42);
		m.set("neg", -7);
		m.set("f", 1.5);
		m.set("b", true);
		m.set("n", null);
		m.set("arr", [1, 2, 3]);
		var nested = new StringMap<Dynamic>();
		nested.set("x", 1);
		m.set("nested", nested);
		var bin = Bytes.alloc(3);
		bin.set(0, 1);
		bin.set(1, 2);
		bin.set(2, 3);
		m.set("bin", bin);
		return m;
	}

	function runNode(args:Array<String>):Int {
		try {
			return Sys.command("node", [helper].concat(args));
		} catch (e:Dynamic) {
			return -1;
		}
	}

	function testForwardHaxeToNode() {
		if (dir == null) {
			Assert.warn("node or @msgpack/msgpack unavailable - skipping forward parity");
			return;
		}

		var inPath = Path.join([dir, "fwd.msgpack"]);
		var resPath = Path.join([dir, "fwd.result"]);
		File.saveBytes(inPath, MsgPack.encode(buildMap()));

		var code = runNode(["decode-check", modPath, inPath, resPath]);
		Assert.equals(0, code, "node decode-check should exit 0");
		Assert.isTrue(FileSystem.exists(resPath), "node should write a result file");
		var res = File.getContent(resPath);
		Assert.isTrue(res.indexOf("OK") == 0, 'node validation failed: $res');
	}

	function testReverseNodeToHaxe() {
		if (dir == null) {
			Assert.warn("node or @msgpack/msgpack unavailable - skipping reverse parity");
			return;
		}

		var outPath = Path.join([dir, "rev.msgpack"]);
		var code = runNode(["encode-map", modPath, outPath]);
		Assert.equals(0, code, "node encode-map should exit 0");
		Assert.isTrue(FileSystem.exists(outPath), "node should write the encoded map");

		var d:Map<String, Dynamic> = cast MsgPack.decode(File.getBytes(outPath), DecodeOption.AsMap);
		Assert.equals(42, d.get("i"));
		Assert.equals(-7, d.get("neg"));
		Assert.isTrue(Math.abs(1.5 - (d.get("f") : Float)) <= 0.0001);
		Assert.equals(true, d.get("b"));
		Assert.isNull(d.get("n"));
		var arr:Array<Dynamic> = d.get("arr");
		Assert.equals(3, arr.length);
		var nested:Map<String, Dynamic> = cast d.get("nested");
		Assert.equals(1, nested.get("x"));
		var bin:Bytes = d.get("bin");
		Assert.equals(3, bin.length);
		Assert.equals(2, bin.get(1));
	}

	function testByteForByteDeterministic() {
		if (dir == null) {
			Assert.warn("node or @msgpack/msgpack unavailable - skipping byte parity");
			return;
		}

		// Values that encode the same everywhere (fixint, negative fixint,
		// fixstr, true, nil) - no float32/64 ambiguity.
		var value:Array<Dynamic> = [1, -1, 127, "hi", true, null];
		var haxeBytes = MsgPack.encode(value);

		var outPath = Path.join([dir, "det.msgpack"]);
		var code = runNode(["encode-det", modPath, outPath]);
		Assert.equals(0, code, "node encode-det should exit 0");
		var nodeBytes = File.getBytes(outPath);

		Assert.equals(haxeBytes.length, nodeBytes.length, "byte length must match");
		Assert.equals(haxeBytes.toHex(), nodeBytes.toHex(), "encodings must be byte-for-byte identical");
	}

	// The CommonJS helper script. Only needs the installed module, passed by
	// absolute path as argv[3].
	static function helperScript():String {
		return "'use strict';\n"
			+ "const fs = require('fs');\n"
			+ "const mode = process.argv[2];\n"
			+ "const modPath = process.argv[3];\n"
			+ "const { encode, decode } = require(modPath);\n"
			+ "function genMap() {\n"
			+ "  return { i: 42, neg: -7, f: 1.5, b: true, n: null, arr: [1,2,3], nested: { x: 1 }, bin: new Uint8Array([1,2,3]) };\n"
			+ "}\n"
			+ "function genDet() { return [1, -1, 127, 'hi', true, null]; }\n"
			+ "function eq(a, b) { return Math.abs(a - b) <= 0.0001; }\n"
			+ "try {\n"
			+ "  if (mode === 'decode-check') {\n"
			+ "    const buf = fs.readFileSync(process.argv[4]);\n"
			+ "    const o = decode(buf);\n"
			+ "    const errs = [];\n"
			+ "    if (o.i !== 42) errs.push('i');\n"
			+ "    if (o.neg !== -7) errs.push('neg');\n"
			+ "    if (!eq(o.f, 1.5)) errs.push('f');\n"
			+ "    if (o.b !== true) errs.push('b');\n"
			+ "    if (o.n !== null) errs.push('n');\n"
			+ "    if (!Array.isArray(o.arr) || o.arr.length !== 3 || o.arr[2] !== 3) errs.push('arr');\n"
			+ "    if (!o.nested || o.nested.x !== 1) errs.push('nested');\n"
			+ "    if (!(o.bin instanceof Uint8Array) || o.bin.length !== 3 || o.bin[1] !== 2) errs.push('bin');\n"
			+ "    fs.writeFileSync(process.argv[5], errs.length === 0 ? 'OK' : ('FAIL:' + errs.join(',')));\n"
			+ "    process.exit(0);\n"
			+ "  } else if (mode === 'encode-map') {\n"
			+ "    fs.writeFileSync(process.argv[4], Buffer.from(encode(genMap())));\n"
			+ "    process.exit(0);\n"
			+ "  } else if (mode === 'encode-det') {\n"
			+ "    fs.writeFileSync(process.argv[4], Buffer.from(encode(genDet())));\n"
			+ "    process.exit(0);\n"
			+ "  }\n"
			+ "  process.exit(2);\n"
			+ "} catch (e) {\n"
			+ "  try { fs.writeFileSync(process.argv[5] || (process.argv[4] + '.err'), 'ERR:' + e.message); } catch (_) {}\n"
			+ "  process.exit(3);\n"
			+ "}\n";
	}

	static function deleteRecursive(path:String):Void {
		try {
			if (!FileSystem.exists(path)) {
				return;
			}
			if (FileSystem.isDirectory(path)) {
				for (entry in FileSystem.readDirectory(path)) {
					deleteRecursive(Path.join([path, entry]));
				}
				FileSystem.deleteDirectory(path);
			} else {
				FileSystem.deleteFile(path);
			}
		} catch (e:Dynamic) {
			// Best-effort cleanup.
		}
	}
}
