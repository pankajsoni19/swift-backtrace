
#if os(Linux)
import Glibc
import CBacktrace

private let state = backtrace_create_state(CommandLine.arguments[0], /* BACKTRACE_SUPPORTS_THREADS */ 1, nil, nil)
#endif

typealias CBacktraceErrorCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ msg: UnsafePointer<CChar>?, _ errnum: CInt) -> Void
typealias CBacktraceFullCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ lineno: CInt, _ function: UnsafePointer<CChar>?) -> CInt
typealias CBacktraceSimpleCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt) -> CInt
typealias CBacktraceSyminfoCallback = @convention(c) (_ data: UnsafeMutableRawPointer?, _ pc: UInt, _ filename: UnsafePointer<CChar>?, _ symval: UInt, _ symsize: UInt) -> Void

private let fullCallback: CBacktraceFullCallback? = {
    data, pc, filename, lineno, function in

    var str = "0x"
    str.append(String(pc, radix: 16))
    if let function = function {
        str.append(", ")
        var fn = String(cString: function)
        if fn.hasPrefix("$s") || fn.hasPrefix("$S") {
            fn = _stdlib_demangleName(fn)
        }
        str.append(fn)
    }
    if let filename = filename {
        str.append(" at ")
        str.append(String(cString: filename))
        str.append(":")
        str.append(String(lineno))
    }
    str.append("\n")
    
    Backtrace.log(str: str)
    
    return 0
}

private let errorCallback: CBacktraceErrorCallback? = {
    data, msg, errnum in
    if let msg = msg {
        Backtrace.log(str: String(cString: msg))
    }
}

public enum Backtrace {
    
    public typealias BACKTRACE_LOG_CALLBACK = (_: String) -> ()
    public static var BACK_TRACE_LOG_CALLBACK_HANDLER: BACKTRACE_LOG_CALLBACK? = nil

    public static func log(str: String) {
        BACK_TRACE_LOG_CALLBACK_HANDLER?(str)
    }
    
    public static func install() {
        #if os(Linux)
        setupHandler(signal: SIGILL) { _ in
            backtrace_full(state, /* skip */ 0, fullCallback, errorCallback, nil)
        }
        setupHandler(signal: SIGSEGV) { _ in
            backtrace_full(state, /* skip */ 0, fullCallback, errorCallback, nil)
        }
        #endif
    }

    public static func print() {
        #if os(Linux)
        backtrace_full(state, /* skip */ 0, fullCallback, errorCallback, nil)
        #endif
    }

    #if os(Linux)
    private static func setupHandler(signal: Int32, handler: @escaping @convention(c) (CInt) -> Void) {
        typealias sigaction_t = sigaction
        let sa_flags = CInt(SA_NODEFER) | CInt(bitPattern: CUnsignedInt(SA_RESETHAND))
        var sa = sigaction_t(__sigaction_handler: unsafeBitCast(handler, to: sigaction.__Unnamed_union___sigaction_handler.self),
                             sa_mask: sigset_t(),
                             sa_flags: sa_flags,
                             sa_restorer: nil)
        withUnsafePointer(to: &sa) { ptr -> Void in
            sigaction(signal, ptr, nil)
        }
    }
    #endif
}
