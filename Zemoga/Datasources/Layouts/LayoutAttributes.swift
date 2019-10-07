//
//  LayoutAttributes.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

typealias LayoutMeasureCallback = (Int, CGRect) -> CGSize

class CollectionViewGridLayoutAttributes: UICollectionViewLayoutAttributes {
    /// The background color for the view
    var backgroundColor: UIColor = .clear

    /// column index
    var columnIndex = 0

    /// If this is a header, is it pinned to the top of the collection view?
    var isPinnedHeader = false

    /// Used by supplementary items
    var padding: UIEdgeInsets = .zero

    /// The background color when selected
    var selectedBackgroundColor: UIColor = .clear

    /// Y offset when not pinned
    var unpinnedY: CGFloat = 0
}

class GridLayoutSeparatorView: UICollectionReusableView {

    // MARK: Instance methods

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        guard let collectionViewGridLayoutAttributes = layoutAttributes as? CollectionViewGridLayoutAttributes else {
            super.apply(layoutAttributes)
            return
        }

        backgroundColor = collectionViewGridLayoutAttributes.backgroundColor
    }
}

class GridItemInfo {
    var columnIndex: Int = 0
    var frame: CGRect = .zero
    var needSizeUpdate = false
}

class GridLayoutRowInfo {
    var frame: CGRect = .zero
    var items: [GridItemInfo] = []
}

class GridLayoutSupplementaryViewInfo {
    var backgroundColor: UIColor = .clear
    var isHeader = false
    var isHidden = false
    var isPlaceholder = false
    var isVisibleWhileShowingPlaceholder = false
    var frame: CGRect = .zero
    var height: CGFloat = 0
    var padding: UIEdgeInsets = .zero
    var selectedBackgroundColor: UIColor = .clear
    var shouldPin = false
}

class GridLayoutSectioInfo {
    var backgroundAttribute: CollectionViewGridLayoutAttributes?
    var backgroundColor: UIColor = .clear
    var columnSpacing: CGFloat = 0
    var frame: CGRect = .zero
    weak var layoutInfo: GridLayoutInfo?
    var footers: [GridLayoutSupplementaryViewInfo] = []
    var headers: [GridLayoutSupplementaryViewInfo] = []
    var nonPinnableAttributes: [CollectionViewGridLayoutAttributes] = []
    var insets: UIEdgeInsets = .zero
    var items: [GridItemInfo] = []
    var numberOfColumns = 0
    var placeholder: GridLayoutSupplementaryViewInfo?
    var pinnableAttribues: [CollectionViewGridLayoutAttributes] = []
    var rows: [GridLayoutRowInfo] = []
    var rowSpacing: CGFloat = 0
    var sectionSeparatorInsets: UIEdgeInsets = .zero
    var selectedBackgroundColor: UIColor = .clear
    var sectionSeparatorColor: UIColor = .clear
    var showsColumnSeparator = true
    var showsSectionSeparatorWhenLastSection = false
    var separatorColor = UIColor.lightGray
    var separatorInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)

    // MARK: Instance methods

    func addItem() -> GridItemInfo {
        let gridItemInfo = GridItemInfo()
        items.append(gridItemInfo)
        return gridItemInfo
    }

    func addRow() -> GridLayoutRowInfo {
        let gridLayoutRowInfo = GridLayoutRowInfo()
        rows.append(gridLayoutRowInfo)
        return gridLayoutRowInfo
    }

    func addSupplementaryViewAsHeader(_ header: Bool) -> GridLayoutSupplementaryViewInfo {
        let gridLayoutSupplementaryViewInfo = GridLayoutSupplementaryViewInfo()
        gridLayoutSupplementaryViewInfo.isHeader = header
        if header {
            headers.append(gridLayoutSupplementaryViewInfo)
        } else {
            footers.append(gridLayoutSupplementaryViewInfo)
        }

        return gridLayoutSupplementaryViewInfo
    }

    func addSupplementaryViewAsPlaceholder() -> GridLayoutSupplementaryViewInfo {
        let gridLayoutSupplementaryViewInfo = GridLayoutSupplementaryViewInfo()
        gridLayoutSupplementaryViewInfo.isHeader = true
        placeholder = gridLayoutSupplementaryViewInfo
        return gridLayoutSupplementaryViewInfo
    }

    func computeLayoutWithOrigin(
        _ start: CGFloat,
        measureItemCallback: LayoutMeasureCallback? = nil,
        measureSupplementaryItemCallback: LayoutMeasureCallback? = nil
        ) {

        let availableHeight = (layoutInfo?.height ?? 0) - start
        let numberOfItems = items.count
        var originY = start
        var rowHeight: CGFloat = 0
        let width = layoutInfo?.width ?? 0

        for (headerIndex, headerInfo) in headers.enumerated() where numberOfItems > 0 || headerInfo.isVisibleWhileShowingPlaceholder {
            guard !headerInfo.isHidden else { continue }

            if let measureSupplementaryItemCallback = measureSupplementaryItemCallback, headerInfo.height == 0 {
                headerInfo.frame = CGRect(x: 0, y: originY, width: width, height: UIView.layoutFittingExpandedSize.height)
                headerInfo.height = measureSupplementaryItemCallback(headerIndex, headerInfo.frame).height
            }

            headerInfo.frame = CGRect(x: 0, y: originY, width: width, height: headerInfo.height)
            originY += headerInfo.height
        }

        if let placeholder = self.placeholder {
            let height = availableHeight - originY - start
            placeholder.height = height
            placeholder.frame = CGRect(x: 0, y: originY, width: width, height: height)
            originY += height
        }

        rows.removeAll()
        if numberOfItems > 0 {
            var columnIndex = 0
            var originX: CGFloat = insets.left
            originY += insets.top

            for (itemIndex, item) in items.enumerated() {
                var height = item.frame.height
                var row = addRow()
                if item.frame.height == SectionMetrics.rowHeightRemainder {
                    height += (layoutInfo?.height ?? 0) - originY
                }

                if columnIndex % numberOfColumns == 0 {
                    originX = insets.left
                    originY += rowHeight
                    rowHeight = 0
                    if !row.items.isEmpty {
                        row = addRow()
                    }

                    if itemIndex > 0 {
                        originY += rowSpacing
                    }

                    row.frame = CGRect(x: originX, y: originY, width: width, height: rowHeight)
                } else {
                    originX += item.frame.width + columnSpacing
                }

                if item.needSizeUpdate {
                    item.needSizeUpdate = false
                    item.frame = CGRect(x: originX, y: originY, width: item.frame.width, height: height)
                    height = measureItemCallback?(itemIndex, item.frame).height ?? 0
                }

                if rowHeight < height {
                    rowHeight = height
                }

                row.items.append(item)
                item.frame = CGRect(x: originX, y: originY, width: item.frame.width, height: rowHeight)
                item.columnIndex = columnIndex

                var rowFrame = row.frame
                rowFrame.size.height = rowHeight
                row.frame = rowFrame
                columnIndex += 1
            }

            originY += rowHeight + insets.bottom

            for footerInfo in footers {
                guard !footerInfo.isHidden else { continue }

                let height = footerInfo.height
                footerInfo.frame = CGRect(x: 0, y: originY, width: width, height: height)
                originY += height
            }
        }

        frame = CGRect(x: 0, y: start, width: width, height: originY - start)
    }
}

