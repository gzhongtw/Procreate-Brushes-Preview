import AppKit
import QuickLookThumbnailing
@objc(ThumbnailProvider)
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        do {
            let document = try BrushDocument(request.fileURL)
            let size = request.maximumSize
            let reply = QLThumbnailReply(contextSize:size, currentContextDrawing: { () -> Bool in
                NSColor(calibratedWhite:0.12,alpha:1).setFill(); NSRect(origin:.zero,size:size).fill()
                let items = Array(document.brushes.prefix(4))
                let h = size.height / CGFloat(max(1,items.count))
                for (i,item) in items.enumerated() {
                    if let data = item.png, let image = NSImage(data:data) {
                        let scale = min((size.width-16)/image.size.width,(h-8)/image.size.height)
                        let s = NSSize(width:image.size.width*scale,height:image.size.height*scale)
                        image.draw(in:NSRect(x:(size.width-s.width)/2,y:size.height-CGFloat(i+1)*h+(h-s.height)/2,width:s.width,height:s.height))
                    }
                }
                return true
            })
            handler(reply,nil)
        } catch { handler(nil,error) }
    }
}
