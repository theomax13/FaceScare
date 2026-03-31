import XCTest
@testable import FaceScare

final class SensitivityTests: XCTestCase {

    // MARK: - Threshold Values

    func test_lowSensitivity_thresholdIs50Percent() {
        XCTAssertEqual(Sensitivity.low.threshold, 0.50)
    }

    func test_mediumSensitivity_thresholdIs40Percent() {
        XCTAssertEqual(Sensitivity.medium.threshold, 0.40)
    }

    func test_highSensitivity_thresholdIs30Percent() {
        XCTAssertEqual(Sensitivity.high.threshold, 0.30)
    }

    // MARK: - Raw Values

    func test_lowSensitivity_rawValueIsLow() {
        XCTAssertEqual(Sensitivity.low.rawValue, "Low")
    }

    func test_mediumSensitivity_rawValueIsMedium() {
        XCTAssertEqual(Sensitivity.medium.rawValue, "Medium")
    }

    func test_highSensitivity_rawValueIsHigh() {
        XCTAssertEqual(Sensitivity.high.rawValue, "High")
    }

    // MARK: - CaseIterable

    func test_allCases_containsThreeLevels() {
        XCTAssertEqual(Sensitivity.allCases.count, 3)
    }

    func test_allCases_orderedLowMediumHigh() {
        XCTAssertEqual(Sensitivity.allCases, [.low, .medium, .high])
    }

    // MARK: - Threshold Ordering

    func test_thresholds_decreaseFromLowToHigh() {
        XCTAssertGreaterThan(Sensitivity.low.threshold, Sensitivity.medium.threshold)
        XCTAssertGreaterThan(Sensitivity.medium.threshold, Sensitivity.high.threshold)
    }

    // MARK: - Init from RawValue

    func test_initFromRawValue_validValues() {
        XCTAssertEqual(Sensitivity(rawValue: "Low"), .low)
        XCTAssertEqual(Sensitivity(rawValue: "Medium"), .medium)
        XCTAssertEqual(Sensitivity(rawValue: "High"), .high)
    }

    func test_initFromRawValue_invalidValueReturnsNil() {
        XCTAssertNil(Sensitivity(rawValue: "Invalid"))
        XCTAssertNil(Sensitivity(rawValue: ""))
    }
}
