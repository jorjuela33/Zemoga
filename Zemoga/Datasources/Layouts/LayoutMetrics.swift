//
//  LayoutMetrics.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

typealias SupplementaryViewConfigurationCallback = (UICollectionReusableView, DataSource, IndexPath) -> Void

class SectionMetrics {
    static let globalSection = Int.max
    static let measureHeight: CGFloat = 100
    static let pinnedHeaderZIndex = 10000
    static let rowHeightRemainder: CGFloat = -1001
    static let variableRowHeight: CGFloat = -1000

    /// the color to use for the background of a cell in this section
    var backgroundColor: UIColor = .white

    /// the spacing between columns in the section.
    var columnSpacing: CGFloat = 0

    /// supplementary views footers
    var footers: [SupplementaryViewMetrics] = []

    /// supplementary views headers
    var headers: [SupplementaryViewMetrics] = []

    /// if the section have a placeholder
    var hasPlaceholder = false

    /// padding around the cells for this section.
    var padding: UIEdgeInsets = .zero

    /// the size of each row in the section.
    var rowSize: CGSize = CGSize(width: 44, height: 44)

    /// the spacing between rows in the section.
    var rowSpacing: CGFloat = 0

    /// The color to use when a cell becomes highlighted or selected
    var selectedBackgroundColor: UIColor = .white

    /// the color to use when drawing the row separators
    var separatorColor: UIColor = .lightGray

    /// the color to use when drawing the section separator below this section
    var sectionSeparatorColor: UIColor = .white

    /// insets for the section separator drawn below this section
    var separatorInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

    /// insets for the section separator drawn below this section
    var sectionSeparatorInsets: UIEdgeInsets = .zero

    /// should the section separator be shown
    var showsColumnSeparator = false

    /// should the section separator be shown at the bottom of the last section
    var showsSectionSeparatorWhenLastSection = false

    // MARK: Instance methods

    /// update these metrics with the values from another metrics.
    func applyValues(from metrics: SectionMetrics) {
        backgroundColor = metrics.backgroundColor
        columnSpacing = metrics.columnSpacing
        headers.append(contentsOf: metrics.headers)
        footers.append(contentsOf: metrics.footers)
        rowSize = metrics.rowSize
        rowSpacing = metrics.rowSpacing
        sectionSeparatorColor = metrics.sectionSeparatorColor
        selectedBackgroundColor = metrics.selectedBackgroundColor
        separatorColor = metrics.separatorColor

        if metrics.hasPlaceholder {
            hasPlaceholder = true
        }

        if metrics.padding != .zero {
            padding = metrics.padding
        }

        if metrics.separatorInsets != .zero {
            separatorInsets = metrics.separatorInsets
        }

        if metrics.sectionSeparatorInsets != .zero {
            sectionSeparatorInsets = metrics.sectionSeparatorInsets
        }

        if metrics.showsSectionSeparatorWhenLastSection {
            showsSectionSeparatorWhenLastSection = metrics.showsSectionSeparatorWhenLastSection
        }

        if metrics.hasPlaceholder {
            hasPlaceholder = true
        }
    }

    /// perform a deep copy and creates a new instance
    func copy() -> SectionMetrics {
        let metrics = SectionMetrics()
        metrics.backgroundColor = backgroundColor
        metrics.columnSpacing = columnSpacing
        metrics.footers = footers
        metrics.headers = headers
        metrics.hasPlaceholder = hasPlaceholder
        metrics.padding = padding
        metrics.rowSpacing = rowSpacing
        metrics.rowSize = rowSize
        metrics.selectedBackgroundColor = selectedBackgroundColor
        metrics.separatorColor = separatorColor
        metrics.sectionSeparatorColor = sectionSeparatorColor
        metrics.separatorInsets = separatorInsets
        metrics.sectionSeparatorInsets = sectionSeparatorInsets
        metrics.showsColumnSeparator = showsColumnSeparator
        metrics.showsSectionSeparatorWhenLastSection = showsSectionSeparatorWhenLastSection
        return metrics
    }

    /// create a new header associated with a specific data source
    func newHeader(ofClass clss: AnyClass) -> SupplementaryViewMetrics {
        let header = SupplementaryViewMetrics(supplementaryViewClass: clss)
        headers.append(header)
        return header
    }
}

class SupplementaryViewMetrics {
    /// the background color that should be used for this supplementary view.
    var backgroundColor: UIColor?

    /// A block that can be used to configure the supplementary view after it is created.
    var configurationCallback: SupplementaryViewConfigurationCallback?

    /// the height of the supplementary view
    var height: CGFloat = 0

    /// should the supplementary view be hidden?
    var isHidden = false

    /// padding around supplementary view.
    var padding: UIEdgeInsets = .zero

    /// reuse identifier.
    let reuseIdentifier: String

    /// the background color shown when this header is selected.
    var selectedBackgroundColor: UIColor?

    /// Should this supplementary view be pinned to the top of the view when scrolling? Only valid for header supplementary views.
    var shouldPin = false

    /// the class to use when dequeuing an instance of this supplementary view
    let supplementaryViewClass: AnyClass

    /// yes if this supplementary view should be displayed while the placeholder is visible.
    var visibleWhileShowingPlaceholder = true

    // MARK: Initializers

    init(supplementaryViewClass: AnyClass, reuseIdentifier: String? = nil) {
        self.reuseIdentifier = reuseIdentifier ?? String(describing: supplementaryViewClass.self)
        self.supplementaryViewClass = supplementaryViewClass
    }
}
