import XCTest
import UIKit
@testable import VibePose

final class CaptureResultFactoryTests: XCTestCase {
    func testPrefersStillPhotoWhenAvailable() throws {
        let stillImage = makeImage(color: .red)
        let fallbackImage = makeImage(color: .blue)

        let result = CaptureResultFactory.makeResult(
            stillImage: stillImage,
            fallbackImage: fallbackImage,
            templateDisplayNameKey: "pose.template.test.title",
            score: 0.94,
            trigger: .automatic,
            capturedAt: Date(timeIntervalSince1970: 100)
        )

        let unwrapped = try XCTUnwrap(result)
        XCTAssertEqual(unwrapped.representation, .stillPhoto)
        XCTAssertEqual(unwrapped.trigger, .automatic)
        XCTAssertEqual(unwrapped.templateDisplayNameKey, "pose.template.test.title")
        XCTAssertEqual(unwrapped.score, 0.94, accuracy: 0.0001)
        XCTAssertEqual(unwrapped.capturedAt, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(unwrapped.image.pngData(), stillImage.pngData())
    }

    func testFallsBackToLiveFrameWhenStillPhotoIsMissing() throws {
        let fallbackImage = makeImage(color: .blue)

        let result = CaptureResultFactory.makeResult(
            stillImage: nil,
            fallbackImage: fallbackImage,
            templateDisplayNameKey: "pose.template.test.title",
            score: 0.82,
            trigger: .manual,
            capturedAt: Date(timeIntervalSince1970: 200)
        )

        let unwrapped = try XCTUnwrap(result)
        XCTAssertEqual(unwrapped.representation, .liveFrameFallback)
        XCTAssertEqual(unwrapped.trigger, .manual)
        XCTAssertEqual(unwrapped.image.pngData(), fallbackImage.pngData())
    }

    func testReturnsNilWhenNoImageIsAvailable() {
        let result = CaptureResultFactory.makeResult(
            stillImage: nil,
            fallbackImage: nil,
            templateDisplayNameKey: "pose.template.test.title",
            score: 0.65,
            trigger: .manual,
            capturedAt: Date(timeIntervalSince1970: 300)
        )

        XCTAssertNil(result)
    }

    private func makeImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
