//
//  HeartParticlesView.swift
//  SnapCollab
//
//  Heart particles animation for favorite interactions
//

import SwiftUI

struct HeartParticlesView: View {
    @State private var particles: [HeartParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundStyle(.red.opacity(particles[index].opacity))
                    .offset(x: particles[index].x, y: particles[index].y)
                    .scaleEffect(particles[index].scale)
                    .animation(.easeOut(duration: 1.5), value: particles[index].y)
                    .animation(.easeOut(duration: 1.5), value: particles[index].opacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: particles[index].scale)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = []
        
        for _ in 0..<8 {
            let particle = HeartParticle(
                x: CGFloat.random(in: -30...30),
                y: 0,
                opacity: 1.0,
                scale: CGFloat.random(in: 0.8...1.2)
            )
            particles.append(particle)
        }
        
        // Animate particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                for index in particles.indices {
                    particles[index].y = CGFloat.random(in: -80 ... -40)
                    particles[index].x += CGFloat.random(in: -20 ... 20)
                    particles[index].opacity = 0.0
                    particles[index].scale *= 0.5
                }
            }
        }
    }
}

struct HeartParticle {
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
}
