//
//  CommonModifiers.swift
//  GPTalks
//
//  Created by Zabir Raihan on 19/07/2024.
//

import SwiftUI
//import VisualEffectView

struct CommonInputStyling: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            #if os(macOS) || targetEnvironment(macCatalyst)
            .background(.bar)
            #else
            .background(
//                VisualEffect(
//                    colorTint: colorScheme == .dark ? .black : .white,
//                    colorTintAlpha: 0.7,
//                    blurRadius: 15,
//                    scale: 1
//                )
//                BlurView(style: .systemUltraThinMaterial, tintColor: colorScheme == .dark ? .black : .white, tintAlpha: 0.8)
//                .ignoresSafeArea()
                .background
            )
                #if os(visionOS)
                .background(.regularMaterial)
                #endif
            #endif
            .ignoresSafeArea()
        
    }
    
    private var verticalPadding: CGFloat {
#if os(macOS) || targetEnvironment(macCatalyst)
        14
#else
        9
#endif
    }
}

//#Preview {
//    CommonModifiers()
//}
