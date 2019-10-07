//
//  SegmentedControlCollectionReusableView.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import UIKit

class SegmentedControlCollectionReusableView: UICollectionReusableView {
    lazy var segmentedControl: UISegmentedControl = {
        let green = #colorLiteral(red: 0.1137254902, green: 0.6784313725, blue: 0.137254902, alpha: 1)
        let segmentedControl = UISegmentedControl(frame: .zero)
        segmentedControl.selectedSegmentTintColor = green
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: green], for: .normal)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()

    // MARK: Initializers

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: Overriden methods

    override func prepareForReuse() {
        super.prepareForReuse()
        segmentedControl.removeTarget(self, action: nil, for: .allEvents)
    }

    // MARK: Private methods

    private func commonInit() {
        addSubview(segmentedControl)
        segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
        segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 15).isActive = true
    }
}
