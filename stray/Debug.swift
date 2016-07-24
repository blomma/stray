import Foundation

func DLog(_ message: String = "", file: String = #file, line: Int = #line, function: String = #function) {
    let url: URL = URL(fileURLWithPath: file)
	print("[\(url.lastPathComponent) \(function):\(line)] \(message)")
}
