import AppKit
import Foundation

if CommandLine.arguments.count >= 4 && CommandLine.arguments[1] == "--thumbnail" {
    do { try BrushDocument(URL(fileURLWithPath:CommandLine.arguments[2])).thumbnail(to:URL(fileURLWithPath:CommandLine.arguments[3])); exit(0) }
    catch { fputs(error.localizedDescription+"\n",stderr); exit(1) }
}
if CommandLine.arguments.count >= 3 && CommandLine.arguments[1] == "--inspect" {
    do { let doc = try BrushDocument(URL(fileURLWithPath:CommandLine.arguments[2])); FileHandle.standardOutput.write(try doc.json()); exit(0) }
    catch { fputs(error.localizedDescription+"\n",stderr); exit(1) }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu(); let root = NSMenuItem(); menu.addItem(root)
        let sub = NSMenu(); root.submenu = sub
        let about = NSMenuItem(title:"關於 Brushes Preview",action:#selector(NSApplication.orderFrontStandardAboutPanel(_:)),keyEquivalent:""); sub.addItem(about)
        sub.addItem(.separator())
        let open = NSMenuItem(title:"開啟筆刷…",action:#selector(choose),keyEquivalent:"o"); open.target = self; sub.addItem(open)
        sub.addItem(NSMenuItem(title:"結束",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")); NSApp.mainMenu = menu
        if windows.isEmpty { choose() }
    }
    @objc func choose() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { panel.urls.forEach(show) } }
    func application(_ sender: NSApplication, openFiles filenames: [String]) { filenames.forEach { show(URL(fileURLWithPath:$0)) }; sender.reply(toOpenOrPrint:.success) }
    func show(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let document = try BrushDocument(url)
            let window = NSWindow(contentRect:NSRect(x:0,y:0,width:820,height:700),styleMask:[.titled,.closable,.resizable,.miniaturizable],backing:.buffered,defer:false)
            window.title = "\(document.name) · \(document.brushes.count) 支筆刷"
            window.contentView = makeBrushView(document)
            window.center(); window.makeKeyAndOrderFront(nil); windows.append(window); NSApp.activate(ignoringOtherApps:true)
        } catch { let alert = NSAlert(error:error); alert.runModal() }
    }
}
let app = NSApplication.shared
let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
