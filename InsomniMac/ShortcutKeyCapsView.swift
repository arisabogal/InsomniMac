//
//  ShortcutKeyCapsView.swift
//  InsomniMac
//
//  Created by Codex on 3/30/26.
//

import SwiftUI

struct ShortcutKeyCapsView: View {
    enum Style {
        case regular
        case overlayCompact
    }

    @Environment(\.colorScheme) private var colorScheme

    let parts: [String]
    var style: Style = .regular

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(parts, id: \.self) { part in
                Text(part)
                    .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(foregroundColor)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .frame(minWidth: minimumWidth)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(backgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor, radius: 1, y: 1)
            }
        }
    }

    private var foregroundColor: Color {
        if style == .overlayCompact {
            return .white.opacity(0.96)
        }
        return colorScheme == .dark ? .white.opacity(0.95) : .black.opacity(0.82)
    }

    private var backgroundColor: Color {
        if style == .overlayCompact {
            return Color(red: 0.16, green: 0.17, blue: 0.19)
        }
        return colorScheme == .dark
        ? Color.white.opacity(0.14)
        : Color(nsColor: .windowBackgroundColor)
    }

    private var borderColor: Color {
        if style == .overlayCompact {
            return .white.opacity(0.22)
        }
        return colorScheme == .dark
        ? Color.white.opacity(0.18)
        : Color.black.opacity(0.12)
    }

    private var shadowColor: Color {
        if style == .overlayCompact {
            return .black.opacity(0.28)
        }
        return colorScheme == .dark
        ? Color.black.opacity(0.24)
        : Color.black.opacity(0.08)
    }

    private var spacing: CGFloat { style == .overlayCompact ? 3 : 10 }
    private var fontSize: CGFloat { style == .overlayCompact ? 11 : 15 }
    private var horizontalPadding: CGFloat { style == .overlayCompact ? 6 : 12 }
    private var verticalPadding: CGFloat { style == .overlayCompact ? 4 : 8 }
    private var minimumWidth: CGFloat { style == .overlayCompact ? 25 : 44 }
    private var cornerRadius: CGFloat { style == .overlayCompact ? 6 : 10 }
}
