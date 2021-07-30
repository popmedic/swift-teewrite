import XCTest
@testable import TeeWrite

class TeeWriterTests: XCTestCase {

    // Test the TeeWriter when just using a update handler for when a write to handle
    func testTeeWriter() throws {
        // assign
        var act = "" // will hold what actually was written
        let exp = "this is a test" // we expect to get this in act
        let expectation = XCTestExpectation() // pause to make sure the writing is done
        // we will write to /dev/null (nothing)
        let file = FileHandle(fileDescriptor: fileno(fopen("/dev/null", "a")))
        // setup our TeeWriter to...
        _ = TeeWriter(handle: file) { data in
            // append anything writen to /dev/null to act
            act += String(data: data, encoding: .ascii) ?? "error"
            expectation.fulfill() // finish up waiting
        }
        file.write(exp.data(using: .ascii)!) // write the expected to the file
        wait(for: [expectation], timeout: 0.2) // wait for the tee write to finish
        // assert
        XCTAssertEqual(act, exp) // make sure we actual got what was expected!
    }

    // Test the TeeWriter init with handle and also handler
    // (when writing to handle also writes to other)
    func testTeeWriterAlsoOther() throws {
        // assign
        let expectation = XCTestExpectation() // pause to make sure the writing is done
        let exp = "this is a test.".data(using: .ascii)! // expected value
        // temp file urls
        let temp1 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp1.txt")
        let temp2 = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp2.txt")
        // open the files
        let file1 = fopen(temp1.path, "a+")
        let file2 = fopen(temp2.path, "a+")
        // set up the file handles
        let handle1 = FileHandle(fileDescriptor: fileno(file1)) // this one will be written to
        let handle2 = FileHandle(fileDescriptor: fileno(file2)) // this one should be written to
        // create the TeeWriter to test, anything written to handle1 also writes to handle2
        _ = TeeWriter(handle1, also: handle2, written: { _ in expectation.fulfill() })
        // act
        handle1.write(exp)  // write to handle1, should also write to handle2 if TeeWriter works
        // wait for the write to be preformed
        wait(for: [expectation], timeout: 0.2)
        // assert
        try handle2.seek(toOffset: 0) // seek to the start of handle2
        let act = try handle2.readToEnd()  // read everything in handle2's file
        XCTAssertEqual(act, exp) // is our actual value the same as the expected value?
        // annihilate
        try FileManager.default.removeItem(at: temp1) // remove temp1.txt
        try FileManager.default.removeItem(at: temp2) // remove temp2.txt
    }
}
