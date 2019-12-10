import Foundation
import ZenRetailCore

let zenRetail = ZenRetail()

signal(SIGINT, SIG_IGN)
let s = DispatchSource.makeSignalSource(signal: SIGINT)
s.setEventHandler {
    zenRetail.stop()
}
s.resume()

try zenRetail.start()
