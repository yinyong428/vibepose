import XCTest
@testable import VibePose

final class AutoCaptureCoachCopyResolverTests: XCTestCase {
    func testResolvesStaticStatesToExpectedKeys() {
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.idle), "coach.idle")
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.noPerson), "coach.no_person")
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.aligning(0.32)), "coach.aligning")
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.ready(0.81)), "coach.ready")
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.perfect(0.94)), "coach.perfect")
    }

    func testResolvesCountdownStateToDynamicKey() {
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.countdown(3)), "coach.countdown_3")
        XCTAssertEqual(AutoCaptureCoachCopyResolver.resolve(.countdown(1)), "coach.countdown_1")
    }
}
