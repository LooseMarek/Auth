import Foundation
import XCTest
@testable import AuthClient

final class PasswordValidatorTests: XCTestCase {

    // MARK: - testMinimumLength_boundary

    func testMinimumLength_boundary() {
        // 7 characters — below minimum, should fail
        XCTAssertFalse(
            PasswordValidator.isValidLength("abcdefg"),
            "A 7-character password must fail the minimum-length check"
        )

        // 8 characters — exactly at minimum, should pass
        XCTAssertTrue(
            PasswordValidator.isValidLength("abcdefgh"),
            "A password of exactly \(PasswordValidator.minimumLength) characters must pass the minimum-length check"
        )

        // 9 characters — above minimum, should pass
        XCTAssertTrue(
            PasswordValidator.isValidLength("abcdefghi"),
            "A 9-character password must pass the minimum-length check"
        )
    }

    // MARK: - Named constant

    func testMinimumLengthConstantIsEight() {
        XCTAssertEqual(PasswordValidator.minimumLength, 8, "The minimum password length must be the named constant 8")
    }
}
