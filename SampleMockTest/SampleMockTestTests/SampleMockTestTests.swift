//
//  SampleMockTestTests.swift
//  SampleMockTestTests
//
//  Created by Ragul kts on 28/05/20.
//  Copyright © 2020 Ragul kts. All rights reserved.
//

import XCTest
@testable import SampleMockTest
import Mocker

class SampleMockTestTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_fetch_user_data_success() {
        
        let serviceUrl = URL(string: "http://yourserviceurl.com")!

        let responseFile = "Resources/users-api-response-success"
        guard let mockResponse = dataFromTestBundleFile(fileName: responseFile, withExtension: "json") else {
            return
        }
        
        // Set up the mock to return the test data gathered above
        let mockService = Mock(url: serviceUrl, dataType: Mock.DataType.json, statusCode: 200,
                               data: [Mock.HTTPMethod.get : mockResponse])
        mockService.register()
        
        let exp = expectation(description: "exp")
        
        let dataTask = URLSession.shared.dataTask(with: serviceUrl) { (data, _, error) in
            XCTAssertNil(error)
            
            guard let dataDict = self.verifyAndConvertToDictionary(data: data) else {
                exp.fulfill()
                return
            }

            XCTAssertEqual(dataDict["name"] as? String, "Ragul")
            
            exp.fulfill()

        }
        dataTask.resume()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func test_fetch_user_data_unknown_user() {
        
        let serviceUrl = URL(string: "http://yourserviceurl.com")!
                
        let responseFile = "Resources/users-api-response-error"
        guard let mockResponse = dataFromTestBundleFile(fileName: responseFile, withExtension: "json") else {
            return
        }

        let mockService = Mock(url: serviceUrl, dataType: Mock.DataType.json, statusCode: 401,
                               data: [Mock.HTTPMethod.get: mockResponse])
        mockService.register()
        
        let exp = expectation(description: "exp")
        
        let dataTask = URLSession.shared.dataTask(with: serviceUrl) { (data, _, error) in
            XCTAssertNil(error)
            
            guard let dataDict = self.verifyAndConvertToDictionary(data: data) else {
                exp.fulfill()
                return
            }
            
            XCTAssertEqual(dataDict["errorCode"] as? Int, 2031)
            XCTAssertEqual(dataDict["errorMessage"] as? String, "Unknown user")
            
            exp.fulfill()
            
        }
        dataTask.resume()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func test_fetch_user_data_error_unauthorized() {
        
        let serviceUrl = URL(string: "http://yourserviceurl.com")!
        
        let emptyData = "".data(using: .utf8)!
        
        let mockService = Mock(url: serviceUrl, dataType: Mock.DataType.json, statusCode: 401,
                               data: [Mock.HTTPMethod.get: emptyData])
        mockService.register()
        
        let exp = expectation(description: "exp")
        
        let dataTask = URLSession.shared.dataTask(with: serviceUrl) { (data, response, _) in
            XCTAssertNotNil(response as? HTTPURLResponse)
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            XCTAssertEqual(httpResponse.statusCode, 401)
            XCTAssertNotNil(data)

            exp.fulfill()
            
        }
        dataTask.resume()
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    func verifyAndConvertToDictionary(data: Data?) -> [String: Any]? {
        
        XCTAssertNotNil(data)
        guard let data = data else { return nil }

        do {
            let dataObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dataDict = dataObject as? [String: Any] else {
                XCTFail("data object is not of type [String: Any]. dataObject=\(dataObject )")
                return nil
            }
            
            return dataDict
        } catch {
            XCTFail("Error from JSONSerialization.jsonObject; error=\(error)")
            return nil
        }
    }
    
    func dataFromTestBundleFile(fileName: String, withExtension fileExtension: String) -> Data? {
        
        let testBundle = Bundle(for: SampleMockTestTests.self)
        let resourceUrl = testBundle.url(forResource: fileName, withExtension: fileExtension)!
        do {
            let data = try Data(contentsOf: resourceUrl)
            return data
        } catch {
            XCTFail("Error reading data from resource file \(fileName).\(fileExtension)")
            return nil
        }
    }
}
