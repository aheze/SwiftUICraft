//
//  Utilities.swift
//  SwiftUICraft
//
//  Created by A. Zheng (github.com/aheze) on 11/7/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

/**
 Some utilities for making things easier.
 */

/// From https://stackoverflow.com/a/46354989/14351818
public extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

func DistanceSquared(from: (x: Int, y: Int), to: (x: Int, y: Int)) -> Int {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}

/// From https://stackoverflow.com/a/43520047/14351818
extension Sequence {
    func group<GroupingType: Hashable>(by key: (Iterator.Element) -> GroupingType) -> [[Iterator.Element]] {
        var groups: [GroupingType: [Iterator.Element]] = [:]
        var groupsOrder: [GroupingType] = []
        forEach { element in
            let key = key(element)
            if case nil = groups[key]?.append(element) {
                groups[key] = [element]
                groupsOrder.append(key)
            }
        }
        return groupsOrder.map { groups[$0]! }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(hex: UInt(hex), alpha: alpha)
    }

    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

struct OverflowLayout: Layout {
    var spacing = CGFloat(10)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: containerWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: offset.x + bounds.minX, y: offset.y + bounds.minY), proposal: .unspecified)
        }
    }

    func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var result: [CGPoint] = []
        var currentPosition: CGPoint = .zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        for size in sizes {
            if currentPosition.x + size.width > containerWidth {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }

            result.append(currentPosition)
            currentPosition.x += size.width
            maxX = max(maxX, currentPosition.x)
            currentPosition.x += spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (result, CGSize(width: maxX, height: currentPosition.y + lineHeight))
    }
}

/// From https://gist.github.com/IanKeen/4d29b48519dca125b21675eeb7623d60
import SwiftUI
@propertyWrapper
struct Storage<T: AppStorageConvertible>: RawRepresentable {
    var rawValue: String { wrappedValue.storedValue }
    var wrappedValue: T

    init?(rawValue: String) {
        guard let value = T(rawValue) else { return nil }
        self.wrappedValue = value
    }

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

extension Binding {
    func binding<T>() -> Binding<T> where Value == Storage<T> {
        return .init(
            get: { wrappedValue.wrappedValue },
            set: { value, transaction in
                self.transaction(transaction).wrappedValue.wrappedValue = value
            }
        )
    }
}

protocol AppStorageConvertible {
    init?(_ storedValue: String)
    var storedValue: String { get }
}

extension RawRepresentable where RawValue: LosslessStringConvertible, Self: AppStorageConvertible {
    init?(_ storedValue: String) {
        guard let value = RawValue(storedValue) else { return nil }
        self.init(rawValue: value)
    }

    var storedValue: String {
        String(describing: rawValue)
    }
}

extension Array: AppStorageConvertible where Element: LosslessStringConvertible {
    public init?(_ storedValue: String) {
        let values = storedValue.components(separatedBy: ",")
        self = values.compactMap(Element.init)
    }

    var storedValue: String {
        return map(\.description).joined(separator: ",")
    }
}
