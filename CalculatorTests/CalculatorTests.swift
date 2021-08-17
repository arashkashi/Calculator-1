//
//  CalculatorTests.swift
//  CalculatorTests
//
//  Created by Arash Kashi on 16.08.21.
//  Copyright © 2021 Andrea Vultaggio. All rights reserved.
//

import XCTest
@testable import Calculator

class CalculatorTests: XCTestCase {
    
    let jsonData = """
        {"time":{"updated":"Aug 16, 2021 07:16:00 UTC","updatedISO":"2021-08-16T07:16:00+00:00","updateduk":"Aug 16, 2021 at 08:16 BST"},"disclaimer":"This data was produced from the CoinDesk Bitcoin Price Index (USD). Non-USD currency data converted using hourly conversion rate from openexchangerates.org","chartName":"Bitcoin","bpi":{"USD":{"code":"USD","symbol":"&#36;","rate":"47,350.7991","description":"United States Dollar","rate_float":47350.7991},"GBP":{"code":"GBP","symbol":"&pound;","rate":"34,201.8136","description":"British Pound Sterling","rate_float":34201.8136},"EUR":{"code":"EUR","symbol":"&euro;","rate":"40,177.4845","description":"Euro","rate_float":40177.4845}}}
        """.data(using: .utf8)!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParsing() throws {

        let result = try! JSONDecoder().decode(BitcoinResponse.self, from: jsonData)
        assert(result.chartName == "Bitcoin")
        assert(result.disclaimer == "This data was produced from the CoinDesk Bitcoin Price Index (USD). Non-USD currency data converted using hourly conversion rate from openexchangerates.org")
        assert(result.bpi["USD"]?.rate_float ?? 0.0 == 47350.7991)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }
}
