import XCTest
import CryptoSwift
import Crypto
@testable import App

public class AppTests: XCTestCase {
    func testBCrypt() {
        do {
            let hash = try BCrypt.hash("password")
            print(hash)
        } catch let error {
            print(error)
        }
    }
}
