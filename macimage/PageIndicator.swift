import SwiftUI

struct PageIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(totalCount, 20), id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
            }
            
            if totalCount > 20 {
                Text("...")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
    }
}
