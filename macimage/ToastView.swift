import SwiftUI

enum ToastType {
    case success, error, info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return Color(red: 0.34, green: 0.79, blue: 0.47)  // Softer green
        case .error: return Color(red: 0.95, green: 0.35, blue: 0.35)     // Softer red
        case .info: return Color(red: 0.35, green: 0.55, blue: 0.95)      // Softer blue
        }
    }
    
    var bgColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.08)
        case .error: return Color.red.opacity(0.08)
        case .info: return Color.blue.opacity(0.08)
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 10)
                    .fill(type.bgColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [type.color.opacity(0.2), Color.primary.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 14, y: 5)
        .shadow(color: type.color.opacity(0.06), radius: 6, y: 2)
        .transition(.opacity.combined(with: .move(edge: .top).combined(with: .scale(scale: 0.95))))
    }
}