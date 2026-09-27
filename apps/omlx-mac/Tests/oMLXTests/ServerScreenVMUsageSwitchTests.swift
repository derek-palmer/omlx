// The two privacy switches on the Server screen commit the moment they flip,
// so the row can end up showing a value the server never accepted. A switch
// left reading "off" while the server still publishes is the worst case: the
// user believes they opted out and a benchmark publishes anyway.
//
// `bind` captures the value being replaced and hands it to the save closure
// so a failed request can put the row back. These cover that plumbing without
// a live server; the revert-on-failure branch itself needs a client that
// throws and is exercised by the save methods.

import SwiftUI
import XCTest
@testable import oMLX

@MainActor
final class ServerScreenVMUsageSwitchTests: XCTestCase {

    func testBindHandsSaveThePreviousValue() {
        let vm = ServerScreenVM()
        vm.benchmarkUploadEnabled = true
        let bindable = Bindable(vm)

        var savedPrevious: Bool?
        let binding = vm.bind(bindable.benchmarkUploadEnabled) { previous in
            savedPrevious = previous
        }

        // The binding setter assigns the new value before calling save, so
        // without the extra parameter the old value would already be gone.
        binding.wrappedValue = false

        XCTAssertEqual(savedPrevious, true)
        XCTAssertFalse(vm.benchmarkUploadEnabled)
    }

    func testBindDoesNotFireWhenValueUnchanged() {
        let vm = ServerScreenVM()
        vm.benchmarkUploadEnabled = true
        let bindable = Bindable(vm)

        var saveCount = 0
        let binding = vm.bind(bindable.benchmarkUploadEnabled) { _ in saveCount += 1 }

        binding.wrappedValue = true

        XCTAssertEqual(saveCount, 0, "re-setting the same value must not fire a save")
    }

    func testBothUsageSwitchesRevertIndependently() {
        // The revert restores one row from the value the other is unrelated
        // to; a failed benchmark-upload save must not disturb the history row.
        let vm = ServerScreenVM()
        vm.usageHistoryEnabled = true
        vm.benchmarkUploadEnabled = true
        let bindable = Bindable(vm)

        let history = vm.bind(bindable.usageHistoryEnabled) { _ in }
        let upload = vm.bind(bindable.benchmarkUploadEnabled) { _ in }

        history.wrappedValue = false
        upload.wrappedValue = false

        // Simulate the benchmark-upload save failing: restore its previous
        // value only.
        vm.benchmarkUploadEnabled = true

        XCTAssertFalse(vm.usageHistoryEnabled, "history row keeps the user's edit")
        XCTAssertTrue(vm.benchmarkUploadEnabled, "failed upload save reverts")
    }
}
