//
//  CollectionViewGridLayout.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

private extension UICollectionReusableView {

    func preferredLayoutSizeFittingSize(_ size: CGSize) -> CGSize {
        frame.size = systemLayoutSizeFitting(size, withHorizontalFittingPriority: .defaultHigh, verticalFittingPriority: .fittingSizeLevel)
        return frame.size
    }
}

struct Kind {
    let indexPath: IndexPath
    let kind: String
}

extension Kind: Hashable {

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(indexPath.hashValue ^ kind.hashValue)
    }
}

class GridLayoutInfo {
    var contentOffsetY: CGFloat = 0
    var height: CGFloat = 0
    var sections: [Int: GridLayoutSectioInfo] = [:]
    var width: CGFloat = 0

    // MARK: Instance methods

    func addSection(at index: Int) -> GridLayoutSectioInfo {
        let gridLayoutSectionInfo = GridLayoutSectioInfo()
        gridLayoutSectionInfo.layoutInfo = self
        sections[index] = gridLayoutSectionInfo
        return gridLayoutSectionInfo
    }

    func invalidate() {
        sections.removeAll()
    }
}

class CollectionViewGridLayout: UICollectionViewFlowLayout {
    private var cachedAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var contentOffsetDelta: CGPoint = .zero
    private let gridLayoutColumnSeparatorKind = "gridLayoutColumnSeparatorKind"
    private let gridLayoutGlobalHeaderBackgroundKind = "gridLayoutGlobalHeaderBackgroundKind"
    private let gridLayoutRowSeparatorKind = "gridLayoutRowSeparatorKind"
    private let gridLayoutSectionSeparatorKind = "gridLayoutSectionSeparatorKind"
    private var gridLayoutInfo: GridLayoutInfo?
    private var indexPathToItemAttributes: [IndexPath: CollectionViewGridLayoutAttributes] = [:]
    private var isPreparingLayout = false
    private var kindToDecorationAttributes: [Kind: CollectionViewGridLayoutAttributes] = [:]
    private var kindToSupplementaryViewAttributes: [Kind: CollectionViewGridLayoutAttributes] = [:]
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    private var layoutIsValid = false
    private var layoutMetricsAreValid = false
    private var layoutSize: CGSize = .zero
    private var insertedIndexPaths = Set<IndexPath>()
    private var insertedSections = Set<Int>()
    private var oldKindToDecorationAttributes: [Kind: CollectionViewGridLayoutAttributes] = [:]
    private var oldKindToSupplementaryViewAttributes: [Kind: CollectionViewGridLayoutAttributes] = [:]
    private var oldIndexPathToItemAttributes: [IndexPath: CollectionViewGridLayoutAttributes] = [:]
    private var pinnableAttributes: [CollectionViewGridLayoutAttributes] = []
    private var reloadedSections = Set<Int>()
    private var removedIndexPaths = Set<IndexPath>()
    private var removedSections = Set<Int>()
    private var shouldInvalidateLayoutMetrics = false
    private var totalNumberOfItems = 0

    override var collectionViewContentSize: CGSize {
        return layoutSize
    }

    override class var layoutAttributesClass: AnyClass {
        return CollectionViewGridLayoutAttributes.self
    }

    // MARK: Initializers

    override init() {
        super.init()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: Overriden methods

    override func finalLayoutAttributesForDisappearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
        ) -> UICollectionViewLayoutAttributes? {

        let section = decorationIndexPath.count > 1 ? decorationIndexPath.section : SectionMetrics.globalSection
        let isRemoved = removedSections.contains(section)
        let isReloaded = reloadedSections.contains(section)
        let kind = Kind(indexPath: decorationIndexPath, kind: elementKind)
        if let result = oldKindToDecorationAttributes[kind] {
            result.alpha = isRemoved ? 0 : 1
            if kindToDecorationAttributes[kind] == nil && isReloaded {
                result.alpha = 0
            }

            return finalLayoutAttributesForAttributes(result)
        }

        return nil
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        insertedIndexPaths.removeAll()
        insertedSections.removeAll()
        reloadedSections.removeAll()
        removedIndexPaths.removeAll()
        removedSections.removeAll()
    }

    override func indexPathsToDeleteForDecorationView(ofKind elementKind: String) -> [IndexPath] {
        return oldKindToDecorationAttributes
            .filter({ $0.key.kind == elementKind && kindToDecorationAttributes[$0.key] == nil })
            .compactMap({ $0.key.indexPath })
    }

    override func initialLayoutAttributesForAppearingDecorationElement(
        ofKind elementKind: String,
        at decorationIndexPath: IndexPath
        ) -> UICollectionViewLayoutAttributes? {

        let kind = Kind(indexPath: decorationIndexPath, kind: elementKind)
        if let result = kindToDecorationAttributes[kind] {
            return initialLayoutAttributesForAttributes(result)
        }

        return nil
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        if context.invalidateEverything {
            layoutIsValid = false
            layoutMetricsAreValid = false
        }

        if layoutIsValid {
            layoutMetricsAreValid = !(context.invalidateDataSourceCounts || shouldInvalidateLayoutMetrics)
            layoutIsValid = !context.invalidateDataSourceCounts
        }

        super.invalidateLayout(with: context)
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let bounds = collectionView?.bounds ?? .zero
        shouldInvalidateLayoutMetrics = (newBounds.size.width != bounds.size.width) || (newBounds.origin.x != bounds.origin.x)
        filterSpecialAttributes()
        return super.invalidationContext(forBoundsChange: newBounds)
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let kind = Kind(indexPath: indexPath, kind: elementKind)
        return kindToDecorationAttributes[kind]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        filterSpecialAttributes()
        return layoutAttributes.filter({ $0.frame.intersects(rect) })
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let gridLayoutInfo = gridLayoutInfo, indexPath.section >= 0 || indexPath.section < gridLayoutInfo.sections.count else {
            return nil
        }

        if let attributtes = indexPathToItemAttributes[indexPath] {
            return attributtes
        }

        guard let section = gridLayoutInfo.sections[indexPath.section], indexPath.row >= 0 && indexPath.row < section.items.count else {
            return nil
        }

        let item = section.items[indexPath.row]
        let newAttribute = CollectionViewGridLayoutAttributes(forCellWith: indexPath)
        newAttribute.backgroundColor = section.backgroundColor
        newAttribute.columnIndex = item.columnIndex
        newAttribute.frame = item.frame
        newAttribute.isHidden = isPreparingLayout
        newAttribute.selectedBackgroundColor = section.selectedBackgroundColor
        if !isPreparingLayout {
            indexPathToItemAttributes[indexPath] = newAttribute
        }

        return newAttribute
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let sectionIndex = indexPath.count == 1 ? SectionMetrics.globalSection : indexPath.section
        let itemIndex = indexPath.count == 1 ? indexPath.startIndex : indexPath.item
        let kind = Kind(indexPath: indexPath, kind: elementKind)
        if let attributes = kindToSupplementaryViewAttributes[kind] {
            return attributes
        }

        if let section = gridLayoutInfo?.sections[sectionIndex] {
            var frame: CGRect = .zero
            var supplementaryViewInfo: GridLayoutSupplementaryViewInfo?
            var supplementaryViews: [GridLayoutSupplementaryViewInfo] = []

            if elementKind == collectionElementKindPlaceholder {
                supplementaryViewInfo = section.placeholder
            } else {
                if elementKind == UICollectionView.elementKindSectionHeader {
                    supplementaryViews = section.headers
                } else if elementKind == UICollectionView.elementKindSectionFooter {
                    supplementaryViews = section.footers
                }

                if itemIndex < 0 || itemIndex >= supplementaryViews.count {
                    return nil
                }

                supplementaryViewInfo = supplementaryViews[itemIndex]
            }

            let attributes = CollectionViewGridLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
            if isPreparingLayout {
                attributes.isHidden = true
            }

            frame = supplementaryViewInfo?.frame ?? .zero
            attributes.backgroundColor = supplementaryViewInfo?.backgroundColor ?? section.backgroundColor
            attributes.frame = frame
            attributes.padding = supplementaryViewInfo?.padding ?? .zero
            attributes.selectedBackgroundColor = section.selectedBackgroundColor

            if !isPreparingLayout {
                kindToSupplementaryViewAttributes[kind] = attributes
            }

            return attributes
        }

        return nil
    }

    override func prepare() {
        if
            /// collectionView
            let collectionView = collectionView,

            /// datasource
            let datasource = collectionView.dataSource as? DataSource, !isPreparingLayout && !layoutMetricsAreValid {

            isPreparingLayout = true

            let contentInset = collectionView.contentInset
            var globalNonPinningHeight: CGFloat = 0
            let insets = collectionView.refreshControl?.isRefreshing == true ? 0 : contentInset.bottom + contentInset.top
            let height = collectionView.safeAreaLayoutGuide.layoutFrame.height - insets
            let layoutMetrics = datasource.snapshotMetrics()
            let numberOfSections = collectionView.numberOfSections
            let paddingBottom: CGFloat = 15
            var shouldInvalidate = false
            var start: CGFloat = 0
            let width = collectionView.bounds.width - contentInset.left - contentInset.right

            resetLayout()

            if !layoutIsValid {
                gridLayoutInfo?.height = height
                gridLayoutInfo?.width = collectionView.bounds.width - contentInset.left - contentInset.right

                if let globalMetrics = layoutMetrics[SectionMetrics.globalSection] {
                    createSection(with: globalMetrics, at: SectionMetrics.globalSection)
                }

                for index in 0..<numberOfSections {
                    if let metrics = layoutMetrics[index] {
                        createSection(with: metrics, at: index)
                    }
                }
            }

            layoutIsValid = true
            layoutAttributes.removeAll()
            pinnableAttributes.removeAll()
            totalNumberOfItems = 0

            if let globalSection = gridLayoutInfo?.sections[SectionMetrics.globalSection] {
                globalSection.computeLayoutWithOrigin(start) { index, _ in
                    let indexPath = IndexPath(index: index)
                    shouldInvalidate = shouldInvalidate || true
                    return self.measureSupplementalItemOfKind(UICollectionView.elementKindSectionHeader, at: indexPath)
                }

                addLayoutAttributesForSection(globalSection, at: SectionMetrics.globalSection)
                globalNonPinningHeight = heightOfAttributes(globalSection.headers)
            }

            for sectionIndex in 0..<numberOfSections {
                if let attributes = layoutAttributes.last {
                    start = attributes.frame.maxY
                }

                if let section = gridLayoutInfo?.sections[sectionIndex] {
                    section.computeLayoutWithOrigin(
                        start,
                        measureItemCallback: { index, frame in
                            let indexPath = IndexPath(row: index, section: sectionIndex)
                            return datasource.collectionView(collectionView, sizeFittingSize: frame.size, forItemAt: indexPath)
                    },
                        measureSupplementaryItemCallback: { index, _ in
                            let indexPath = IndexPath(row: index, section: sectionIndex)
                            shouldInvalidate = shouldInvalidate || true
                            return self.measureSupplementalItemOfKind(UICollectionView.elementKindSectionHeader, at: indexPath)
                    })

                    addLayoutAttributesForSection(section, at: sectionIndex)
                }
            }

            if let attributes = layoutAttributes.last {
                start = attributes.frame.maxY
            }

            var layoutHeight = start
            let isLayoutHeightLessThanHeight = layoutHeight - globalNonPinningHeight < height
            if let gridLayoutInfo = gridLayoutInfo, gridLayoutInfo.contentOffsetY >= globalNonPinningHeight && isLayoutHeightLessThanHeight {
                layoutHeight = height + globalNonPinningHeight
            }

            layoutMetricsAreValid = true
            layoutSize = CGSize(width: width, height: layoutHeight + paddingBottom)
            isPreparingLayout = false
            filterSpecialAttributes()

            if shouldInvalidate {
                invalidateLayout()
            }
        }

        super.prepare()
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        insertedIndexPaths.removeAll()
        insertedSections.removeAll()
        reloadedSections.removeAll()
        removedIndexPaths.removeAll()
        removedSections.removeAll()

        for updatedItem in updateItems {
            switch updatedItem.updateAction {
            case .delete:
                if let indexPath = updatedItem.indexPathBeforeUpdate {
                    if indexPath.item == NSNotFound {
                        removedSections.insert(indexPath.section)
                    } else {
                        removedIndexPaths.insert(indexPath)
                    }
                }

            case .insert:
                if let indexPath = updatedItem.indexPathAfterUpdate {
                    if indexPath.item == NSNotFound {
                        insertedSections.insert(indexPath.section)
                    } else {
                        insertedIndexPaths.insert(indexPath)
                    }
                }

            case .reload:
                if let indexPath = updatedItem.indexPathAfterUpdate, indexPath.item == NSNotFound {
                    reloadedSections.insert(indexPath.section)
                }

            default: break
            }
        }

        let contentOffset = collectionView?.contentOffset ?? .zero
        let newContentOffset = targetContentOffset(forProposedContentOffset: contentOffset)
        contentOffsetDelta = CGPoint(x: newContentOffset.x - contentOffset.x, y: newContentOffset.y - contentOffset.y)
        super.prepare(forCollectionViewUpdates: updateItems)
    }

    // MARK: Private methods

    private func addHeaderAttributes(forSection section: GridLayoutSectioInfo, atIndex index: Int) {
        let isGlobalSection = index == SectionMetrics.globalSection
        for (headerIndex, header) in section.headers.enumerated() where !section.items.isEmpty || header.isVisibleWhileShowingPlaceholder {
            guard header.height > 0 && !header.isHidden else { continue }

            let indexPath = isGlobalSection ? IndexPath(index: headerIndex) : IndexPath(row: headerIndex, section: index)
            let attributes = CollectionViewGridLayoutAttributes(
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                with: indexPath
            )
            attributes.backgroundColor = header.backgroundColor
            attributes.frame = header.frame
            attributes.isHidden = false
            attributes.isPinnedHeader = false
            attributes.padding = header.padding
            attributes.selectedBackgroundColor = header.selectedBackgroundColor
            attributes.zIndex = 1000
            layoutAttributes.append(attributes)

            if header.shouldPin {
                pinnableAttributes.append(attributes)
                section.pinnableAttribues.append(attributes)
            } else if isGlobalSection {
                section.nonPinnableAttributes.append(attributes)
            }

            let kind = Kind(indexPath: indexPath, kind: UICollectionView.elementKindSectionHeader)
            kindToSupplementaryViewAttributes[kind] = attributes
        }
    }

    private func addRowAttributes(forSection section: GridLayoutSectioInfo, atIndex index: Int) {
        let hairline: CGFloat = UIScreen.main.scale > 1 ? 0.5 : 1
        var itemIndex = 0
        let shouldShowColumnsSeparator = section.numberOfColumns > 1 && section.showsColumnSeparator

        for (rowIndex, row) in section.rows.enumerated() where !row.items.isEmpty {
            totalNumberOfItems += 1
            if rowIndex > 0 && totalNumberOfItems > 0 {
                let indexPath = IndexPath(row: rowIndex, section: index)
                let kind = Kind(indexPath: indexPath, kind: gridLayoutRowSeparatorKind)
                let separatorAttributes = CollectionViewGridLayoutAttributes(forDecorationViewOfKind: gridLayoutRowSeparatorKind, with: indexPath)
                let width = section.frame.width - section.separatorInsets.left - section.separatorInsets.right
                separatorAttributes.backgroundColor = section.separatorColor
                separatorAttributes.frame = CGRect(x: section.separatorInsets.left, y: row.frame.origin.y, width: width, height: hairline)
                layoutAttributes.append(separatorAttributes)
                kindToDecorationAttributes[kind] = separatorAttributes
            }

            for item in row.items {
                if item.columnIndex != NSNotFound && item.columnIndex < section.numberOfColumns - 1 && shouldShowColumnsSeparator {
                    if totalNumberOfItems > 0 {
                        let indexPath = IndexPath(row: rowIndex * section.numberOfColumns + item.columnIndex, section: index)
                        let attribute = CollectionViewGridLayoutAttributes(forDecorationViewOfKind: gridLayoutColumnSeparatorKind, with: indexPath)
                        let kind = Kind(indexPath: indexPath, kind: gridLayoutColumnSeparatorKind)
                        var separatorFrame = item.frame
                        separatorFrame.origin.x = item.frame.maxX
                        separatorFrame.size.width = 1
                        attribute.backgroundColor = section.separatorColor
                        attribute.frame = separatorFrame
                        layoutAttributes.append(attribute)
                        kindToDecorationAttributes[kind] = attribute
                    }
                }

                let indexPath = IndexPath(row: itemIndex, section: index)
                let newAttribute = CollectionViewGridLayoutAttributes(forCellWith: indexPath)
                newAttribute.backgroundColor = section.backgroundColor
                newAttribute.columnIndex = item.columnIndex
                newAttribute.isHidden = false
                newAttribute.frame = item.frame
                newAttribute.selectedBackgroundColor = section.selectedBackgroundColor
                layoutAttributes.append(newAttribute)
                indexPathToItemAttributes[indexPath] = newAttribute
                itemIndex += 1
            }
        }
    }

    private func addLayoutAttributesForSection(_ section: GridLayoutSectioInfo, at index: Int) {
        let hairline: CGFloat = UIScreen.main.scale > 1 ? 0.5 : 1
        let isGlobalSection = index == SectionMetrics.globalSection
        let numberOfItems = section.items.count

        if isGlobalSection {
            let indexPath = IndexPath(index: 0)
            let backgroundAttribute = CollectionViewGridLayoutAttributes(
                forDecorationViewOfKind: gridLayoutGlobalHeaderBackgroundKind,
                with: indexPath
            )
            backgroundAttribute.backgroundColor = section.backgroundColor
            backgroundAttribute.frame = section.frame
            backgroundAttribute.isPinnedHeader = false
            backgroundAttribute.isHidden = false
            backgroundAttribute.zIndex = -1
            layoutAttributes.append(backgroundAttribute)
            section.backgroundAttribute = backgroundAttribute

            let kind = Kind(indexPath: indexPath, kind: gridLayoutGlobalHeaderBackgroundKind)
            kindToDecorationAttributes[kind] = backgroundAttribute
        }

        addHeaderAttributes(forSection: section, atIndex: index)

        if let lastAttribute = layoutAttributes.last, lastAttribute.representedElementKind != gridLayoutSectionSeparatorKind {
            if totalNumberOfItems > 0 {
                let indexPath = IndexPath(row: 0, section: index)
                let separatorAttributes = CollectionViewGridLayoutAttributes(forDecorationViewOfKind: gridLayoutSectionSeparatorKind, with: indexPath)
                let kind = Kind(indexPath: indexPath, kind: gridLayoutSectionSeparatorKind)
                let width = section.frame.width - section.sectionSeparatorInsets.left - section.sectionSeparatorInsets.right
                separatorAttributes.backgroundColor = section.separatorColor
                separatorAttributes.frame = CGRect(x: section.sectionSeparatorInsets.left, y: section.frame.origin.y, width: width, height: hairline)
                layoutAttributes.append(separatorAttributes)
                kindToDecorationAttributes[kind] = separatorAttributes
            }
        }

        if let placeholder = section.placeholder {
            let indexPath = IndexPath(row: 0, section: index)
            let kind = Kind(indexPath: indexPath, kind: collectionElementKindPlaceholder)
            let attribute = CollectionViewGridLayoutAttributes(forSupplementaryViewOfKind: collectionElementKindPlaceholder, with: indexPath)
            attribute.frame = placeholder.frame
            layoutAttributes.append(attribute)
            kindToDecorationAttributes[kind] = attribute
        }

        addRowAttributes(forSection: section, atIndex: index)

        for (footerIndex, footer) in section.footers.enumerated() where numberOfItems > 0 && footer.height > 0 && !footer.isHidden {
            let indexPath = IndexPath(row: footerIndex, section: index)
            let attribute = CollectionViewGridLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: indexPath)
            let kind = Kind(indexPath: indexPath, kind: UICollectionView.elementKindSectionFooter)
            attribute.backgroundColor = section.backgroundColor
            attribute.isHidden = false
            attribute.frame = footer.frame
            attribute.padding = footer.padding
            attribute.selectedBackgroundColor = section.selectedBackgroundColor
            layoutAttributes.append(attribute)
            indexPathToItemAttributes[indexPath] = attribute
            kindToDecorationAttributes[kind] = attribute
        }
    }

    private func applyBottomPinning(toAttributes attributes: [CollectionViewGridLayoutAttributes], maxY: CGFloat) -> CGFloat {
        var maxY = maxY
        for attribute in attributes {
            if attribute.frame.maxY < maxY {
                attribute.frame.origin.y = maxY - attribute.frame.height
                maxY = attribute.frame.maxY
            }

            attribute.zIndex = SectionMetrics.pinnedHeaderZIndex
        }
        return maxY
    }

    private func applyTopPinning(toAttributes attributes: [CollectionViewGridLayoutAttributes], minY: CGFloat) -> CGFloat {
        var minY = minY
        for attribute in attributes where attribute.frame.origin.y < minY {
            attribute.frame.origin.y = 0
            minY = attribute.frame.maxY
        }
        return minY
    }

    private func commonInit() {
        register(GridLayoutSeparatorView.self, forDecorationViewOfKind: gridLayoutColumnSeparatorKind)
        register(GridLayoutSeparatorView.self, forDecorationViewOfKind: gridLayoutGlobalHeaderBackgroundKind)
        register(GridLayoutSeparatorView.self, forDecorationViewOfKind: gridLayoutSectionSeparatorKind)
        register(GridLayoutSeparatorView.self, forDecorationViewOfKind: gridLayoutRowSeparatorKind)
        scrollDirection = .vertical
    }

    private func createSection(with metrics: SectionMetrics, at sectionIndex: Int) {
        guard let collectionView = collectionView else { return }

        let isGlobalSection = sectionIndex == SectionMetrics.globalSection
        let isVariableRowHeight = metrics.rowSize.height == SectionMetrics.variableRowHeight
        var rowHeight = metrics.rowSize.height
        let numberOfItemsInSection = isGlobalSection ? 0 : collectionView.numberOfItems(inSection: sectionIndex)

        if isVariableRowHeight {
            rowHeight = SectionMetrics.measureHeight
        }

        if let section = gridLayoutInfo?.addSection(at: sectionIndex) {
            let availableWidthSpacing = (collectionView.bounds.width - metrics.padding.left - metrics.padding.right - metrics.columnSpacing)
            let numberOfColumns = Int(availableWidthSpacing / metrics.rowSize.width)

            section.backgroundColor = metrics.backgroundColor
            section.columnSpacing = metrics.columnSpacing
            section.insets = metrics.padding
            section.numberOfColumns = numberOfColumns > 0 ? numberOfColumns : 1
            section.rowSpacing = metrics.rowSpacing
            section.sectionSeparatorColor = metrics.sectionSeparatorColor
            section.sectionSeparatorInsets = metrics.sectionSeparatorInsets
            section.selectedBackgroundColor = metrics.selectedBackgroundColor
            section.separatorColor = metrics.separatorColor
            section.separatorInsets = metrics.separatorInsets
            section.showsColumnSeparator = metrics.showsColumnSeparator
            section.showsSectionSeparatorWhenLastSection = metrics.showsSectionSeparatorWhenLastSection

            for headerInfo in metrics.headers {
                let header = section.addSupplementaryViewAsHeader(true)
                header.backgroundColor = headerInfo.backgroundColor ?? section.backgroundColor
                header.height = headerInfo.height
                header.isHidden = headerInfo.isHidden
                header.padding = headerInfo.padding
                header.isVisibleWhileShowingPlaceholder = headerInfo.visibleWhileShowingPlaceholder
                header.selectedBackgroundColor = headerInfo.selectedBackgroundColor ?? section.selectedBackgroundColor
                header.shouldPin = headerInfo.shouldPin
            }

            for footerInfo in metrics.footers where footerInfo.height > 0 {
                let footer = section.addSupplementaryViewAsHeader(false)
                footer.backgroundColor = footerInfo.backgroundColor ?? section.backgroundColor
                footer.height = footerInfo.height
                footer.isHidden = footerInfo.isHidden
                footer.selectedBackgroundColor = footerInfo.selectedBackgroundColor ?? section.selectedBackgroundColor
            }

            if metrics.hasPlaceholder {
                let placeholder = section.addSupplementaryViewAsPlaceholder()
                placeholder.height = gridLayoutInfo?.height ?? 0
            } else {
                for _ in 0..<numberOfItemsInSection {
                    let item = section.addItem()
                    let marginLeftAndRight = section.insets.left + section.insets.right
                    var width = metrics.rowSize.width
                    if width + marginLeftAndRight >= UIScreen.main.bounds.width {
                        width = UIScreen.main.bounds.width - marginLeftAndRight
                    }

                    item.frame = CGRect(x: 0, y: 0, width: width, height: rowHeight)
                    if isVariableRowHeight {
                        item.needSizeUpdate = true
                    }
                }
            }
        }
    }

    private func filterSpecialAttributes() {
        guard let collectionView = collectionView, collectionView.numberOfSections > 0 else { return }

        let contentOffset = collectionView.contentOffset
        var pinnableY = contentOffset.y + collectionView.contentInset.top
        var nonPinnableY = pinnableY
        resetAttributes(pinnableAttributes)

        if let section = gridLayoutInfo?.sections[SectionMetrics.globalSection] {
            pinnableY = applyTopPinning(toAttributes: section.pinnableAttribues, minY: pinnableY)
            finalizePinnedAttributes(section.pinnableAttribues, zIndex: SectionMetrics.pinnedHeaderZIndex)

            if !section.nonPinnableAttributes.isEmpty {
                resetAttributes(section.nonPinnableAttributes)
                nonPinnableY = applyBottomPinning(toAttributes: section.nonPinnableAttributes, maxY: nonPinnableY)
                finalizePinnedAttributes(section.nonPinnableAttributes, zIndex: SectionMetrics.pinnedHeaderZIndex)
            }

            if let backgroundAttribute = section.backgroundAttribute {
                let nonPinnableAttributesMaxY = section.nonPinnableAttributes.last?.frame.maxY ?? 0
                let pinnableAttributesMaxY = section.pinnableAttribues.last?.frame.maxY ?? 0
                let bottomY = max(nonPinnableAttributesMaxY, pinnableAttributesMaxY)
                backgroundAttribute.frame.origin.y = min(nonPinnableY, collectionView.bounds.origin.y)
                backgroundAttribute.frame.size.height = bottomY - backgroundAttribute.frame.origin.y
            }
        }
    }

    private func finalizePinnedAttributes(_ attributes: [CollectionViewGridLayoutAttributes], zIndex: Int) {
        for (index, attribute) in attributes.enumerated() {
            attribute.isPinnedHeader = attribute.frame.origin.y != attribute.unpinnedY
            attribute.zIndex = zIndex - (1 + index)
        }
    }

    private func finalLayoutAttributesForAttributes(_ attributes: CollectionViewGridLayoutAttributes) -> CollectionViewGridLayoutAttributes {
        attributes.frame = attributes.frame.offsetBy(dx: contentOffsetDelta.x, dy: contentOffsetDelta.y)
        return attributes
    }

    private func heightOfAttributes(_ attributes: [GridLayoutSupplementaryViewInfo]) -> CGFloat {
        guard !attributes.isEmpty else {
            return 0
        }

        var minY = CGFloat(Int.max)
        var maxY = CGFloat(Int.min)
        for attr in attributes {
            minY = CGFloat.minimum(minY, attr.frame.minY)
            maxY = CGFloat.maximum(maxY, attr.frame.maxY)
        }

        return maxY - minY
    }

    private func initialLayoutAttributesForAttributes(_ attributes: CollectionViewGridLayoutAttributes) -> CollectionViewGridLayoutAttributes {
        attributes.frame = attributes.frame.offsetBy(dx: -contentOffsetDelta.x, dy: -contentOffsetDelta.y)
        return attributes
    }

    func measureSupplementalItemOfKind(_ kind: String, at indexPath: IndexPath) -> CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }

        let collectionReusableView = collectionView.dataSource?.collectionView?(
            collectionView,
            viewForSupplementaryElementOfKind: kind,
            at: indexPath
        )
        let fittingSize = CGSize(width: gridLayoutInfo?.width ?? 0, height: SectionMetrics.measureHeight)
        let size = collectionReusableView?.preferredLayoutSizeFittingSize(fittingSize)
        collectionReusableView?.removeFromSuperview()
        return size ?? .zero
    }

    private func resetLayout() {
        if let gridLayoutInfo = gridLayoutInfo {
            gridLayoutInfo.invalidate()
        } else {
            gridLayoutInfo = GridLayoutInfo()
        }

        oldKindToDecorationAttributes = kindToDecorationAttributes
        kindToDecorationAttributes.removeAll()

        oldKindToSupplementaryViewAttributes = kindToSupplementaryViewAttributes
        kindToSupplementaryViewAttributes.removeAll()

        oldIndexPathToItemAttributes = indexPathToItemAttributes
        indexPathToItemAttributes.removeAll()
    }

    private func resetAttributes(_ attributes: [CollectionViewGridLayoutAttributes]) {
        attributes.forEach({
            $0.isPinnedHeader = false
            $0.frame.origin.y = $0.unpinnedY
        })
    }
}
