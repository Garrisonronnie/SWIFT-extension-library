// SnapPlus.swift
// Fully independent Swift layout helper library
// Author: Ronnie Garrison
// License: MIT

import UIKit

public class SnapPlus {
    
    public init() {}
    
    // MARK: - Responsive Layouts
    public func applyResponsiveLayout(to view: UIView, constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.activate(constraints)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public func applyResponsiveLayoutWithScaling(to view: UIView, baseSize: CGSize, constraints: [NSLayoutConstraint]) {
        let scaleX = UIScreen.main.bounds.width / baseSize.width
        let scaleY = UIScreen.main.bounds.height / baseSize.height
        
        for constraint in constraints {
            guard constraint.firstAttribute == .width || constraint.firstAttribute == .height,
                  constraint.relation == .equal else { continue }
            constraint.constant *= min(scaleX, scaleY)
        }
        NSLayoutConstraint.activate(constraints)
        view.layoutIfNeeded()
    }
    
    // MARK: - Conflict Detection
    public func detectConflicts(in view: UIView) -> [String] {
        var conflicts: [String] = []
        let constraints = view.constraints
        for i in 0..<constraints.count {
            for j in i+1..<constraints.count {
                if constraints[i].firstItem === constraints[j].firstItem &&
                   constraints[i].firstAttribute == constraints[j].firstAttribute &&
                   constraints[i].secondItem === constraints[j].secondItem &&
                   constraints[i].priority == constraints[j].priority {
                    conflicts.append("Conflict between \(constraints[i]) and \(constraints[j])")
                }
            }
        }
        return conflicts
    }
    
    public func autoFixConflicts(in view: UIView) {
        let conflicts = detectConflicts(in: view)
        for conflict in conflicts {
            print("AutoFix Conflict: \(conflict)")
        }
        view.constraints.filter { $0.priority < .required }.forEach { view.removeConstraint($0) }
        view.layoutIfNeeded()
    }
    
    // MARK: - Animated / Dynamic Layout Changes
    public func animateConstraints(on view: UIView, duration: TimeInterval = 0.3, springDamping: CGFloat = 0.8, changes: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: springDamping, initialSpringVelocity: 0.5, options: [.allowUserInteraction], animations: {
            changes()
            view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - Cross-Device Scaling
    public func adaptiveScale(for view: UIView, baseSize: CGSize) {
        let scaleX = UIScreen.main.bounds.width / baseSize.width
        let scaleY = UIScreen.main.bounds.height / baseSize.height
        
        view.constraints.forEach { constraint in
            guard constraint.firstAttribute == .width || constraint.firstAttribute == .height,
                  constraint.relation == .equal else { return }
            constraint.constant *= min(scaleX, scaleY)
        }
        view.layoutIfNeeded()
    }
    
    // MARK: - Essentials
    public func batchActivateConstraints(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.activate(constraints)
    }
    
    public func batchDeactivateConstraints(_ constraints: [NSLayoutConstraint]) {
        NSLayoutConstraint.deactivate(constraints)
    }
    
    public func addDebugOverlay(to view: UIView, color: UIColor = .red, alpha: CGFloat = 0.2) {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = color.withAlphaComponent(alpha)
        overlay.isUserInteractionEnabled = false
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
    }
    
    public func safeAreaAwareConstraints(for view: UIView, relativeTo parent: UIView) -> [NSLayoutConstraint] {
        [
            view.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor),
            view.leadingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.bottomAnchor)
        ]
    }
}
