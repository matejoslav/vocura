import SwiftUI

struct BubbleView: View {
    @ObservedObject var viewModel: WindowManager
    
    var body: some View {
        HStack(spacing: 15) {
            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else if viewModel.isRecording {
                WaveformView(amplitude: $viewModel.audioLevel)
                    .frame(width: 40, height: 40)
            } else if viewModel.statusMessage != nil {
                Image(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Error")
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stateText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                if let error = viewModel.statusMessage {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(4) // Extra space for shadow/glow
    }
    
    var stateText: String {
        if viewModel.isProcessing { return "Processing..." }
        if viewModel.isRecording { return "Listening..." }
        if viewModel.statusMessage != nil { return "Error" }
        return "Ready"
    }
}

struct WaveformView: View {
    @State private var phase: CGFloat = 0
    @Binding var amplitude: Float
    
    var body: some View {
        Canvas { context, size in
            for i in 0..<3 {
                let path = Path { path in
                    let mid = size.height / 2
                    for x in stride(from: 0, to: size.width, by: 1) {
                        let relativeX = CGFloat(x) / size.width
                        let angle = relativeX * .pi * 2 + phase + CGFloat(i) * .pi / 2
                        let sine = sin(angle)
                        let currentAmplitude = CGFloat(amplitude) + 0.1
                        let amp = mid * currentAmplitude
                        let y = mid + sine * amp * 0.5
                        
                        if x == 0 {
                            path.move(to: CGPoint(x: CGFloat(x), y: y))
                        } else {
                            path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                        }
                    }
                }
                let opacity = 0.6 - Double(i) * 0.2
                context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: 1.5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

extension Image {
    init(systemSymbolName: String, accessibilityDescription: String?) {
        self.init(nsImage: NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription) ?? NSImage())
    }
}
