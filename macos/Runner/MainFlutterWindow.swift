import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    super.awakeFromNib()                              // ①

    // set your minimum size right on this window
    self.minSize = NSSize(width: 1024, height: 768)   // ②

    // now hook up Flutter
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)
  }
}
