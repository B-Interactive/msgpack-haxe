package org.msgpack.tests;

import org.msgpack.tests.unit.BasicTests;
import org.msgpack.tests.unit.ArrayTests;
import org.msgpack.tests.unit.MapTests;
import org.msgpack.tests.unit.ObjectTests;
import org.msgpack.tests.unit.Int64Tests;
import org.msgpack.tests.unit.TypeCoverageTests;
import org.msgpack.tests.unit.ContractTests;
#if (cpp || neko || hl)
import org.msgpack.tests.unit.NodeParityTests;
#end
import utest.Runner;
import utest.ui.Report;

/**
 * Test runner: adds each test class and runs them.
 */
class MsgPackTests {
	public static function main() {
		var runner = new Runner();

		runner.addCase(new BasicTests());
		runner.addCase(new ArrayTests());
		runner.addCase(new MapTests());
		runner.addCase(new ObjectTests());
		runner.addCase(new Int64Tests());

		// Type-coverage and decode-contract checks.
		runner.addCase(new TypeCoverageTests());
		runner.addCase(new ContractTests());

		// Node cross-language tests need sys + a node binary, so build them only
		// on sys targets. They skip if node is unavailable.
		#if (cpp || neko || hl)
		runner.addCase(new NodeParityTests());
		#end

		Report.create(runner);
		runner.run();
	}
}
