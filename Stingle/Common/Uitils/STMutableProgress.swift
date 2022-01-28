//
//  STMutableProgress.swift
//  Stingle
//
//  Created by Khoren Asatryan on 1/27/22.
//

import Foundation

public final class STMutableProgress: Progress {

    public override var totalUnitCount: Int64 {
        get {
            return Int64(children.count)
        }
        set {
            fatalError("Setting the total unit count is not supported for MutableProgress")
        }
    }

    public override var completedUnitCount: Int64 {
        get {
            return Int64(children.filter { $0.key.isCompleted }.count)
        }
        set {
            fatalError("Setting the completed unit count is not supported for MutableProgress")
        }
    }

    public override var fractionCompleted: Double {
        return children.map { $0.key.fractionCompleted }.reduce(0, +) / Double(totalUnitCount)
    }

    /// All the current tracked children.
    private var children: [Progress: NSKeyValueObservation] = [:]

    /// Adds a new child. Will always use a pending unit count of 1.
    ///
    /// - Parameter child: The child to add.
    func addChild(_ child: Progress) {
        willChangeValue(for: \.totalUnitCount)
        children[child] = child.observe(\.fractionCompleted) { [weak self] (progress, _) in
            self?.willChangeValue(for: \.fractionCompleted)
            self?.didChangeValue(for: \.fractionCompleted)

            if progress.isCompleted {
                self?.willChangeValue(for: \.completedUnitCount)
                self?.didChangeValue(for: \.completedUnitCount)
            }
        }
        didChangeValue(for: \.totalUnitCount)
    }

    /// Removes the given child from the progress reporting.
    ///
    /// - Parameter child: The child to remove.
    func removeChild(_ child: Progress) {
        willChangeValue(for: \.fractionCompleted)
        willChangeValue(for: \.completedUnitCount)
        willChangeValue(for: \.totalUnitCount)
        children.removeValue(forKey: child)?.invalidate()
        didChangeValue(for: \.totalUnitCount)
        didChangeValue(for: \.completedUnitCount)
        didChangeValue(for: \.fractionCompleted)
    }

    // MARK: Overriding methods to make sure this class is used correctly.
    public override func addChild(_ child: Progress, withPendingUnitCount inUnitCount: Int64) {
        assert(inUnitCount == 1, "Unit count is ignored and is fixed to 1 for MutableProgress")
        addChild(child)
    }
}

private extension Progress {
    var isCompleted: Bool {
        guard totalUnitCount > 0 else { return true }
        return completedUnitCount >= totalUnitCount
    }
}
