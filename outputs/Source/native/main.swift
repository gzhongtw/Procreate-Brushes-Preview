import AppKit
import Foundation
import WebKit

if CommandLine.arguments.count >= 4 && CommandLine.arguments[1] == "--thumbnail" {
    do { try BrushDocument(URL(fileURLWithPath:CommandLine.arguments[2])).thumbnail(to:URL(fileURLWithPath:CommandLine.arguments[3])); exit(0) }
    catch { fputs(error.localizedDescription+"\n",stderr); exit(1) }
}
if CommandLine.arguments.count >= 3 && CommandLine.arguments[1] == "--inspect" {
    do { let doc = try BrushDocument(URL(fileURLWithPath:CommandLine.arguments[2])); FileHandle.standardOutput.write(try doc.json()); exit(0) }
    catch { fputs(error.localizedDescription+"\n",stderr); exit(1) }
}
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var windows: [NSWindow] = []
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        func section(_ title: String) -> NSMenu {
            let item = NSMenuItem(title:title,action:nil,keyEquivalent:"")
            let submenu = NSMenu(title:title); item.submenu = submenu; menu.addItem(item); return submenu
        }
        let appMenu = section("Brushes Preview")
        appMenu.addItem(NSMenuItem(title:"關於 Brushes Preview",action:#selector(NSApplication.orderFrontStandardAboutPanel(_:)),keyEquivalent:""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title:"隱藏 Brushes Preview",action:#selector(NSApplication.hide(_:)),keyEquivalent:"h"))
        let hideOthers = NSMenuItem(title:"隱藏其他",action:#selector(NSApplication.hideOtherApplications(_:)),keyEquivalent:"h")
        hideOthers.keyEquivalentModifierMask = [.command,.option]; appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title:"全部顯示",action:#selector(NSApplication.unhideAllApplications(_:)),keyEquivalent:""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title:"結束 Brushes Preview",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"))
        let fileMenu = section("檔案")
        let open = NSMenuItem(title:"開啟筆刷…",action:#selector(choose),keyEquivalent:"o"); open.target = self; fileMenu.addItem(open)
        fileMenu.addItem(NSMenuItem(title:"關閉視窗",action:#selector(NSWindow.performClose(_:)),keyEquivalent:"w"))
        let editMenu = section("編輯")
        editMenu.addItem(NSMenuItem(title:"拷貝",action:Selector(("copy:")),keyEquivalent:"c"))
        editMenu.addItem(NSMenuItem(title:"全選",action:Selector(("selectAll:")),keyEquivalent:"a"))
        let windowMenu = section("視窗")
        windowMenu.addItem(NSMenuItem(title:"最小化",action:#selector(NSWindow.performMiniaturize(_:)),keyEquivalent:"m"))
        let fullscreen = NSMenuItem(title:"進入全螢幕",action:#selector(NSWindow.toggleFullScreen(_:)),keyEquivalent:"f")
        fullscreen.keyEquivalentModifierMask = [.command,.control]; windowMenu.addItem(fullscreen)
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title:"全部移至最前",action:#selector(NSApplication.arrangeInFront(_:)),keyEquivalent:""))
        NSApp.windowsMenu = windowMenu; NSApp.mainMenu = menu
        if windows.isEmpty { choose() }
    }
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow { windows.removeAll { $0 === window } }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { choose() }; return true
    }
    @objc func choose() { let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; if panel.runModal() == .OK { panel.urls.forEach(show) } }
    func application(_ sender: NSApplication, openFiles filenames: [String]) { filenames.forEach { show(URL(fileURLWithPath:$0)) }; sender.reply(toOpenOrPrint:.success) }
    func show(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let document = try BrushDocument(url)
            let window = NSWindow(contentRect:NSRect(x:0,y:0,width:1080,height:760),styleMask:[.titled,.closable,.resizable,.miniaturizable],backing:.buffered,defer:false)
            window.title = "\(document.name) · \(document.brushes.count) 支筆刷"
            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences.allowsContentJavaScript = false
            let gallery = WKWebView(frame:.zero,configuration:configuration)
            gallery.setValue(false,forKey:"drawsBackground")
            let html = try GalleryTemplate.html(document:document) { _,brush in
                guard let png = brush.png else { return "" }
                return "data:image/png;base64,"+png.base64EncodedString()
            }
            window.contentView = gallery
            window.minSize = NSSize(width:420,height:360)
            window.delegate = self
            window.isReleasedWhenClosed = false
            gallery.loadHTMLString(html,baseURL:nil)
            window.center(); window.makeKeyAndOrderFront(nil); windows.append(window); NSApp.activate(ignoringOtherApps:true)
        } catch { let alert = NSAlert(error:error); alert.runModal() }
    }
}
let app = NSApplication.shared
let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
