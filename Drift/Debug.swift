import Foundation

func DLog(message: String = "", file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
    let url: NSURL = NSURL(fileURLWithPath: file)
	print("[\(url.lastPathComponent) \(function):\(line)] \(message)")
}
