import AppKit
func makeBrushView(_ document: BrushDocument) -> NSView {
    let scroll = NSScrollView(); scroll.hasVerticalScroller = true
    let stack = NSStackView(); stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 20; stack.edgeInsets = NSEdgeInsets(top:24,left:24,bottom:24,right:24)
    stack.translatesAutoresizingMaskIntoConstraints = false
    let title = NSTextField(labelWithString:"\(document.name) · \(document.brushes.count) 支筆刷"); title.font = .systemFont(ofSize:24,weight:.semibold); stack.addArrangedSubview(title)
    for b in document.brushes {
        stack.addArrangedSubview(NSTextField(labelWithString:b.name))
        if let png = b.png, let image = NSImage(data:png) {
            let view = NSImageView(image:image); view.imageScaling = .scaleProportionallyUpOrDown
            view.setAccessibilityLabel(b.name+"筆觸預覽")
            view.wantsLayer = true; view.layer?.backgroundColor = NSColor(calibratedWhite:0.12,alpha:1).cgColor
            stack.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo:stack.widthAnchor,constant:-48).isActive = true
            view.heightAnchor.constraint(equalToConstant:180).isActive = true
        } else { stack.addArrangedSubview(NSTextField(labelWithString:"此筆刷沒有內建筆觸預覽")) }
    }
    scroll.documentView = stack
    stack.widthAnchor.constraint(equalTo:scroll.contentView.widthAnchor).isActive = true
    return scroll
}
