//
//  OnboardingView.swift
//  SnapCollab
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "photo.stack.fill",
            title: "Anıları Bir Araya Getirin",
            subtitle: "Arkadaşlarınızla ortak albümler oluşturun ve özel anları birlikte saklayın",
            color: .blue
        ),
        OnboardingPage(
            image: "person.2.fill",
            title: "Kolayca Paylaşın",
            subtitle: "Davet kodları ile arkadaşlarınızı albümlerinize ekleyin. Herkesin fotoğrafları tek yerde",
            color: .green
        ),
        OnboardingPage(
            image: "heart.fill",
            title: "Favorilerinizi Seçin",
            subtitle: "Beğendiğiniz fotoğrafları favorilerinize ekleyin ve kolayca bulun",
            color: .red
        ),
        OnboardingPage(
            image: "shield.checkered",
            title: "Güvenli ve Özel",
            subtitle: "Fotoğraflarınız güvenle korunur. Sadece albüm üyeleri erişebilir",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Atla") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(currentPage < pages.count - 1 ? 1 : 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : .secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button("Devam Et") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(OnboardingButtonStyle(color: pages[currentPage].color))
                        
                    } else {
                        Button("Başlayalım!") {
                            onComplete()
                        }
                        .buttonStyle(OnboardingButtonStyle(color: pages[currentPage].color))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    let threshold: CGFloat = 50
                    if gesture.translation.width > threshold && currentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    } else if gesture.translation.width < -threshold && currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                }
        )
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.image)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(page.color)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(page.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let subtitle: String
    let color: Color
}

struct OnboardingButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    init() {
        hasCompletedOnboarding = false
        
        // Normal kod bu olacak (test ettikten sonra):
        // hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
