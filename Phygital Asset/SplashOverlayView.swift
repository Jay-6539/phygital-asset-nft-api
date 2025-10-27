import SwiftUI

struct SplashOverlayView: View {
    @Binding var isShowing: Bool
    @Binding var isContentReady: Bool  // 监听内容是否准备就绪
    
    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var hasShownMinimumTime: Bool = false  // 是否已显示最小时长
    
    private let minimumDisplayTime: Double = 0.8  // 最小显示时间，避免闪烁
    private let maxWaitTime: Double = 2.0  // 最大等待时间
    private let fadeDuration: Double = 0.6  // 放大淡出动画时间（从1.2s缩短到0.6s）
    
    var body: some View {
        // 使用UIScreen获取完整屏幕尺寸
        let screenSize = UIScreen.main.bounds.size
        let logoSize = min(screenSize.width * 0.4, screenSize.height * 0.2)
        
        return ZStack {
            Color.white
            
            // LOGO - 使用VStack/HStack居中，spacing设为0避免任何额外间距
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            Logger.debug("SplashOverlay appeared, starting smart loading...")
            Logger.debug("📐 Screen size: \(screenSize.width) × \(screenSize.height)")
            Logger.debug("📐 LOGO size: \(logoSize) × \(logoSize)")
            Logger.debug("📐 LOGO center should be at: (\(screenSize.width/2), \(screenSize.height/2))")
            
            // 标记最小显示时间已到
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumDisplayTime) {
                hasShownMinimumTime = true
                Logger.debug("Minimum display time reached (\(minimumDisplayTime)s)")
                checkAndFinish()
            }
            
            // 设置最大等待时间保护，避免无限等待
            DispatchQueue.main.asyncAfter(deadline: .now() + maxWaitTime) {
                if !hasShownMinimumTime {
                    hasShownMinimumTime = true
                }
                if isShowing {
                    Logger.warning("Max wait time reached, forcing finish")
                    finishAndFadeOut()
                }
            }
        }
        .onChange(of: isContentReady) { _, ready in
            if ready {
                Logger.success("Content ready signal received")
                checkAndFinish()
            }
        }
    }
    
    /// 检查是否满足完成条件（最小时间 + 内容就绪）
    private func checkAndFinish() {
        guard hasShownMinimumTime && isContentReady else {
            Logger.debug("Waiting... minTime: \(hasShownMinimumTime), contentReady: \(isContentReady)")
            return
        }
        
        Logger.success("Both conditions met, starting fade out")
        finishAndFadeOut()
    }
    
    /// 完成并淡出
    private func finishAndFadeOut() {
        // 动画放大+淡出
        withAnimation(.easeOut(duration: fadeDuration)) {
            logoScale = 3.0
            logoOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            isShowing = false
            Logger.success("Splash overlay dismissed")
        }
    }
}

struct SplashOverlayView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var showing = true
        @State var ready = false
        
        var body: some View {
            SplashOverlayView(isShowing: $showing, isContentReady: $ready)
                .onAppear {
                    // 模拟0.5秒后内容就绪
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        ready = true
                    }
                }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
