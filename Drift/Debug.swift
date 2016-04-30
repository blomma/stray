import Foundation

func DLog(message: String = "", file: String = #file, line: Int = #line, function: String = #function) {
    let url: NSURL = NSURL(fileURLWithPath: file)
	print("[\(url.lastPathComponent) \(function):\(line)] \(message)")
}
