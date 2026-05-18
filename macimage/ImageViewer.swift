import SwiftUI

struct ImageViewer: View {
    let image: NSImage
    @Binding var scale: CGFloat
    @Binding var rotation: Double
    @Binding var offset: CGSize
    
    @State private var lastScale: CGFloat = 1.0
    @State private var lastRotation: Double = 0
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .gesture(
                    RotationGesture()
                        .onChanged { angle in
                            rotation = lastRotation + angle.degrees
                        }
                        .onEnded { _ in
                            lastRotation = rotation
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastScale = 1.0
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
        }
    }
}
