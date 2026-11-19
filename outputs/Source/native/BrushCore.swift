import Foundation
import AppKit
import zlib
import ImageIO

enum BrushError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(s) = self { return s }; return nil }
}
struct ZipEntry { let name: String; let method: Int; let flags: Int; let compressed: Int; let size: Int; let offset: Int; let crc: UInt32 }
struct BrushZip {
    let bytes: Data
    var entries: [String: ZipEntry] = [:]
    init(_ url: URL) throws {
        let n = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard n <= 512 * 1024 * 1024 else { throw BrushError.invalid("檔案超過 512 MB 預覽限制") }
        bytes = try Data(contentsOf: url, options: .mappedIfSafe)
        guard bytes.count >= 22 else { throw BrushError.invalid("不是有效的 ZIP 筆刷檔") }
        var end: Int? = nil
        for p in stride(from: bytes.count - 22, through: max(0, bytes.count - 65557), by: -1) {
            if u32(p) == 0x06054b50 && p + 22 + u16(p + 20) == bytes.count { end = p; break }
        }
        guard let e = end, u16(e+4) == 0, u16(e+6) == 0, u16(e+8) == u16(e+10), u16(e+10) < 65535 else { throw BrushError.invalid("不支援 ZIP64、分卷或損壞的 ZIP") }
        var p = u32(e+16)
        let directoryEnd = p + u32(e+12)
        guard directoryEnd <= e else { throw BrushError.invalid("ZIP 目錄損壞") }
        for _ in 0..<u16(e+10) {
            guard p >= 0, p+46 <= directoryEnd, u32(p) == 0x02014b50 else { throw BrushError.invalid("ZIP 目錄損壞") }
            let l = u16(p+28), extra = u16(p+30), comment = u16(p+32)
            guard p+46+l+extra+comment <= directoryEnd else { throw BrushError.invalid("ZIP 目錄截斷") }
            guard let name = String(data: bytes.subdata(in: p+46..<p+46+l), encoding: .utf8), entries[name] == nil else { throw BrushError.invalid("ZIP 路徑重複或編碼無效") }
            entries[name] = ZipEntry(name:name, method:u16(p+10), flags:u16(p+8), compressed:u32(p+20), size:u32(p+24), offset:u32(p+42), crc:UInt32(u32(p+16)))
            p += 46+l+extra+comment
        }
    }
    func u16(_ p: Int) -> Int { Int(bytes[p]) | Int(bytes[p+1]) << 8 }
    func u32(_ p: Int) -> Int { u16(p) | u16(p+2) << 16 }
    func read(_ name: String, limit: Int = 16*1024*1024) throws -> Data {
        guard let e = entries[name] else { throw BrushError.invalid("找不到 \(name)") }
        guard e.size <= limit, e.compressed <= 32*1024*1024, e.flags & 1 == 0, [0,8].contains(e.method), e.offset+30 <= bytes.count else { throw BrushError.invalid("ZIP 項目超出限制或不支援") }
        let p = e.offset
        guard u32(p) == 0x04034b50 else { throw BrushError.invalid("ZIP 標頭損壞") }
        let start = p+30+u16(p+26)+u16(p+28)
        guard start <= bytes.count, e.compressed <= bytes.count-start else { throw BrushError.invalid("ZIP 資料截斷") }
        let input = bytes.subdata(in: start..<start+e.compressed)
        var result: Data
        if e.method == 0 { result = input } else {
            var stream = z_stream()
            guard inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { throw BrushError.invalid("解壓縮初始化失敗") }
            defer { inflateEnd(&stream) }
            result = Data(count: max(1,e.size))
            let code = input.withUnsafeBytes { src in result.withUnsafeMutableBytes { dst in
                stream.next_in = UnsafeMutablePointer(mutating: src.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(input.count)
                stream.next_out = dst.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(dst.count)
                return inflate(&stream, Z_FINISH)
            }}
            guard code == Z_STREAM_END, stream.total_out == e.size, stream.total_in == input.count else { throw BrushError.invalid("ZIP 解壓縮失敗") }
            result.count = e.size
        }
        let crc = result.withUnsafeBytes { crc32(0, $0.bindMemory(to: Bytef.self).baseAddress, uInt(result.count)) }
        guard result.count == e.size, UInt32(crc) == e.crc else { throw BrushError.invalid("ZIP 校驗失敗") }
        return result
    }
}
struct BrushItem {
    let name: String
    let png: Data?
}
struct BrushDocument {
    let name: String
    let brushes: [BrushItem]
    init(_ url: URL) throws {
        let zip = try BrushZip(url)
        var title = url.deletingPathExtension().lastPathComponent
        var ids: [String] = []
        if url.pathExtension.lowercased() == "brushset" {
            if zip.entries["brushset.plist"] != nil {
                let data = try zip.read("brushset.plist", limit:1024*1024)
                guard let plist = try PropertyListSerialization.propertyList(from:data,format:nil) as? [String:Any], let ordered = plist["brushes"] as? [String] else { throw BrushError.invalid("筆刷組清單格式無效") }
                ids = ordered
                if let name = plist["name"] as? String { title = name }
            } else {
                ids = zip.entries.keys.filter { $0.hasSuffix("/QuickLook/Thumbnail.png") && $0.split(separator:"/").count == 3 }.map { String($0.split(separator:"/")[0]) }.sorted()
            }
        } else { ids = [""] }
        guard !ids.isEmpty, ids.count <= 500 else { throw BrushError.invalid("筆刷組為空或超過 500 支預覽限制") }
        var items: [BrushItem] = []
        var total = 0
        for (i,id) in ids.enumerated() {
            guard !id.contains("/"), !id.contains("\\"), id != ".." else { throw BrushError.invalid("筆刷識別碼無效") }
            let prefix = id.isEmpty ? "" : id+"/"
            var label = ids.count == 1 && id.isEmpty ? title : "筆刷 \(i+1)"
            if zip.entries[prefix+"Brush.archive"] != nil,
               let archive = try? zip.read(prefix+"Brush.archive",limit:4*1024*1024),
               let plist = try? PropertyListSerialization.propertyList(from:archive,format:nil) as? [String:Any],
               let objects = plist["$objects"] as? [Any],
               let xml = try? PropertyListSerialization.data(fromPropertyList:plist,format:.xml,options:0),
               let text = String(data:xml,encoding:.utf8) {
                // XML represents binary plist UIDs as CF$UID dictionaries. Resolve only the name string.
                let pattern = #"<key>name</key>\s*<dict>\s*<key>CF\$UID</key>\s*<integer>([0-9]+)</integer>"#
                if let regex = try? NSRegularExpression(pattern:pattern),
                   let match = regex.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)),
                   let range = Range(match.range(at:1),in:text), let index = Int(text[range]), objects.indices.contains(index), let value = objects[index] as? String { label = value }
            }
            var png: Data? = nil
            let key = prefix+"QuickLook/Thumbnail.png"
            if zip.entries[key] != nil {
                let data = try zip.read(key)
                total += data.count
                guard total <= 128*1024*1024 else { throw BrushError.invalid("預覽圖片總量超過 128 MB") }
                guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache:false] as CFDictionary), let props = CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any], let width = props[kCGImagePropertyPixelWidth] as? Int, let height = props[kCGImagePropertyPixelHeight] as? Int, width > 0, height > 0, width <= 8192, height <= 8192, width*height <= 16_000_000, NSBitmapImageRep(data:data) != nil else { throw BrushError.invalid("筆觸圖片無效或超過尺寸限制") }
                png = data
            }
            items.append(BrushItem(name:label,png:png))
        }
        name = title; brushes = items
    }
    func thumbnail(to url: URL) throws {
        let shown = Array(brushes.prefix(6))
        let size = NSSize(width:800,height:CGFloat(110+shown.count*108))
        let image = NSImage(size:size)
        image.lockFocus()
        NSColor(calibratedWhite:0.10,alpha:1).setFill(); NSRect(origin:.zero,size:size).fill()
        let attrs: [NSAttributedString.Key:Any] = [.font:NSFont.systemFont(ofSize:28,weight:.semibold),.foregroundColor:NSColor.white]
        (name as NSString).draw(in:NSRect(x:28,y:size.height-55,width:740,height:40),withAttributes:attrs)
        ("\(brushes.count) 支筆刷" as NSString).draw(at:NSPoint(x:28,y:size.height-82),withAttributes:[.font:NSFont.systemFont(ofSize:18),.foregroundColor:NSColor.lightGray])
        for (i,b) in shown.enumerated() {
            let rect = NSRect(x:28,y:size.height-210-CGFloat(i*108),width:744,height:94)
            NSColor(calibratedWhite:0.17,alpha:1).setFill(); NSBezierPath(roundedRect:rect,xRadius:10,yRadius:10).fill()
            if let png = b.png, let stroke = NSImage(data:png) {
                let scale = min((rect.width-28)/stroke.size.width,(rect.height-14)/stroke.size.height)
                let s = NSSize(width:stroke.size.width*scale,height:stroke.size.height*scale)
                stroke.draw(in:NSRect(x:rect.midX-s.width/2,y:rect.midY-s.height/2,width:s.width,height:s.height))
            } else { ("缺少筆觸預覽" as NSString).draw(at:rect.origin,withAttributes:attrs) }
        }
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data:tiff), let png = rep.representation(using:.png,properties:[:]) else { throw BrushError.invalid("無法產生縮圖") }
        try png.write(to:url,options:.atomic)
    }
    func json() throws -> Data {
        try JSONSerialization.data(withJSONObject:["name":name,"brushes":brushes.map { ["name":$0.name,"png":$0.png?.base64EncodedString() ?? ""] }])
    }
}
