//
//  BasicDataSource.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

protocol CollectionViewConfigurableCell {
    associatedtype E

    func configure(for element: E)
}

extension Loading {

    // MARK: Instance methods

    func update<T: Equatable>(_ items: [T]) {
        items.isEmpty ? updateWithNoContent() : updateWithContent()
    }
}

class BasicDataSource<E: Equatable, Cell: UICollectionViewCell>: DataSource where Cell.E == E, Cell: CollectionViewConfigurableCell {
    private(set) var items: [E] = []

    // MARK: Initializers

    override init() {
        super.init()
        errorContent = NoContent(
            title: "Fetching Issue.",
            message: "There was an issue with fetching the data.",
            image: #imageLiteral(resourceName: "imgFetchingError"),
            actionTitle: "RETRY NOW",
            actionCallback: { [weak self] in
                self?.setNeedsLoadContent()
            }
        )
    }

    // MARK: Instance methods

    /// Set the items with optional animation.
    func setItems(_ items: [E], animated: Bool = false) {
        guard items != self.items else { return }

        guard animated else {
            self.items = items
            updateLoadingState()
            notifyDidReloadData()
            return
        }

        let newItemSet = NSOrderedSet(array: items)
        let oldItemSet = NSOrderedSet(array: self.items)

        let deletedItems = NSMutableOrderedSet(array: self.items)
        deletedItems.minus(newItemSet)

        let newItems = NSMutableOrderedSet(array: items)
        newItems.minus(oldItemSet)

        let movedItems = NSMutableOrderedSet(array: items)
        movedItems.intersect(oldItemSet)

        var deletedIndexPaths: [IndexPath] = []
        for deletedItem in deletedItems {
            let indexPath = IndexPath(item: oldItemSet.index(of: deletedItem), section: 0)
            deletedIndexPaths.append(indexPath)
        }

        var insertedIndexPaths: [IndexPath] = []
        for newItem in newItems {
            let indexPath = IndexPath(item: newItemSet.index(of: newItem), section: 0)
            insertedIndexPaths.append(indexPath)
        }

        var fromMovedIndexPaths: [IndexPath] = []
        var toMovedIndexPaths: [IndexPath] = []
        for movedItem in movedItems {
            fromMovedIndexPaths.append(IndexPath(item: oldItemSet.index(of: movedItem), section: 0))
            toMovedIndexPaths.append(IndexPath(item: newItemSet.index(of: movedItem), section: 0))
        }

        self.items = items
        updateLoadingState()

        if !deletedIndexPaths.isEmpty {
            notifyItemsRemoved(at: deletedIndexPaths)
        }

        if !insertedIndexPaths.isEmpty {
            notifyItemsInserted(at: insertedIndexPaths)
        }

        for index in 0..<fromMovedIndexPaths.count {
            var fromIndexPath: IndexPath?
            var toIndexPath: IndexPath?

            if index < fromMovedIndexPaths.count {
                fromIndexPath = fromMovedIndexPaths[index]
            }

            if index < toMovedIndexPaths.count {
                toIndexPath = toMovedIndexPaths[index]
            }

            if
                /// from indexPath
                let fromIndexPath = fromIndexPath,

                /// to indexPath
                let toIndexPath = toIndexPath {

                notifyItemMoved(from: fromIndexPath, to: toIndexPath)
            }
        }
    }

    // MARK: Overriden methods

    override func indexPaths<T>(for item: T) -> [IndexPath] {
        guard let item = item as? E else {
            return []
        }

        var indexPaths: [IndexPath] = []
        for (index, obj) in items.enumerated() {
            if item == obj {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
        }

        return indexPaths
    }

    override func item<T>(at indexPath: IndexPath) -> T? {
        guard indexPath.row < items.count else {
            return nil
        }

        return items[indexPath.row] as? T
    }

    override func loadContent() {

    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: Cell.self),
            for: indexPath
            ) as? Cell else {
                return UICollectionViewCell()
        }

        let element = items[indexPath.row]
        cell.configure(for: element)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.row != destinationIndexPath.row || sourceIndexPath.row < items.count else { return }

        let toIndex = destinationIndexPath.row >= items.count ? destinationIndexPath.row - 1 : destinationIndexPath.row
        let movingObject = items[sourceIndexPath.row]
        items.remove(at: sourceIndexPath.row)
        items.insert(movingObject, at: toIndex)
        notifyItemMoved(from: sourceIndexPath, to: destinationIndexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return obscuredByPlaceholder() ? 0 : items.count
    }

    override func collectionView(_ collectionView: UICollectionView, sizeFittingSize size: CGSize, forItemAt indexPath: IndexPath) -> CGSize {
        let cell = self.collectionView(collectionView, cellForItemAt: indexPath) as? CollectionViewCell
        let fittinSize = cell?.preferredLayoutSizeFittingSize(size)
        cell?.removeFromSuperview()
        return fittinSize ?? .zero
    }

    override func shouldDisplayPlaceholder() -> Bool {
        if !items.isEmpty {
            return false
        }

        return super.shouldDisplayPlaceholder()
    }

    override func removeItem(at indexPath: IndexPath) {
        let removedIndexes = IndexSet(integer: indexPath.row)
        removeItems(at: removedIndexes)
    }

    override func resetContent() {
        super.resetContent()
        items = []
    }

    // MARK: Private methods

    private func removeItems(at indexSet: IndexSet) {
        let count = items.count - indexSet.count
        guard count > 0 else { return }

        var batchUpdates: BacthUpdateCallback = {}
        var newItems: [E] = []
        for (index, item) in items.enumerated() {
            let previousBatchUpdate = batchUpdates
            if indexSet.contains(index) {
                batchUpdates = {
                    previousBatchUpdate()
                    self.notifyItemsRemoved(at: [IndexPath(row: index, section: 0)])
                }
            } else {
                let newIndex = newItems.count
                newItems.append(item)
                batchUpdates = {
                    previousBatchUpdate()
                    self.notifyItemMoved(from: IndexPath(row: index, section: 0), to: IndexPath(row: newIndex, section: 0))
                }
            }
        }

        items = newItems
        notifyBatchUpdate({ [weak self] in
            batchUpdates()
            self?.updateLoadingState()
        })
    }

    private func updateLoadingState() {
        let loadingState = self.loadingState
        let numberOfItems = items.count
        if numberOfItems > 0 {
            self.loadingState = .contentLoaded
        } else if numberOfItems == 0 && loadingState == .contentLoaded {
            self.loadingState = .noContent
        }
    }
}
