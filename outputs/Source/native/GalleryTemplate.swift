import Foundation
struct GalleryTemplate {
    static func html(document: BrushDocument, source: (Int, BrushItem) -> String) throws -> String {
        guard let url = Bundle.main.url(forResource:"gallery",withExtension:"json"),
              let asset = try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as? [String:String],
              let frame = asset["frame"], let card = asset["staticCard"], let css = asset["css"] else { throw BrushError.invalid("缺少筆刷畫廊資源") }
        func escape(_ value: String) -> String { value.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;").replacingOccurrences(of:"'",with:"&#39;") }
        func fill(_ text: String, _ values: [String:String]) -> String {
            let regex = try! NSRegularExpression(pattern:"__(SET_NAME|COUNT|HINT|BRUSH_NAME|INDEX|IMAGE_SRC|BRUSH_CARDS)__")
            var output=text
            for match in regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).reversed() {
                guard let whole=Range(match.range,in:text), let key=Range(match.range(at:1),in:text), let value=values[String(text[key])] else { continue }
                output.replaceSubrange(whole,with:value)
            }
            return output
        }
        let rows = document.brushes.enumerated().map { index,brush -> String in
            var template = card.replacingOccurrences(of:"<link[^>]*rel=\"preload\"[^>]*/>",with:"",options:.regularExpression)
            if brush.png == nil { template=template.replacingOccurrences(of:"<img[^>]*/>",with:"<p>此筆刷沒有內建筆觸預覽</p>",options:.regularExpression) }
            return fill(template,["BRUSH_NAME":escape(brush.name),"INDEX":String(format:"%02d",index+1),"IMAGE_SRC":escape(source(index,brush))])
        }.joined()
        let body = fill(frame,["SET_NAME":escape(document.name),"COUNT":String(document.brushes.count),"HINT":"筆觸總覽","BRUSH_CARDS":rows])
        return "<!doctype html><html lang=\"zh-Hant\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>\(escape(document.name))</title><style>\(css)</style></head><body>\(body)</body></html>"
    }
}
