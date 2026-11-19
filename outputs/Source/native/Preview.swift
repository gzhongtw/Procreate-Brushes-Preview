import Foundation
import QuickLookUI
import UniformTypeIdentifiers
@objc(PreviewProvider)
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let reply = QLPreviewReply(dataOfContentType:.html,contentSize:CGSize(width:1080,height:760)) { reply in
            let document = try BrushDocument(request.fileURL)
            reply.title = document.name
            var attachments: [String:QLPreviewReplyAttachment] = [:]
            let html = try GalleryTemplate.html(document:document) { index,brush in
                let cid="brush-\(index).png"
                if let data=brush.png { attachments[cid]=QLPreviewReplyAttachment(data:data,contentType:.png) }
                return "cid:"+cid
            }
            reply.attachments=attachments
            return Data(html.utf8)
        }
        handler(reply,nil)
    }
}
