import SwiftUI

struct InfoOverlay: View {
    let info: ImageInfo?
    
    var body: some View {
        if let info = info {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "doc")
                        .font(.system(size: 12))
                    Text(info.filename)
                        .font(.system(size: 12, design: .monospaced))
                }
                
                HStack {
                    Image(systemName: "aspectratio")
                        .font(.system(size: 12))
                    Text("\(info.width) × \(info.height) px")
                        .font(.system(size: 12, design: .monospaced))
                }
                
                HStack {
                    Image(systemName: "externaldrive")
                        .font(.system(size: 12))
                    Text(info.fileSizeFormatted)
                        .font(.system(size: 12, design: .monospaced))
                }
                
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                    Text(info.format)
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(16)
            .transition(.opacity)
        }
    }
}
