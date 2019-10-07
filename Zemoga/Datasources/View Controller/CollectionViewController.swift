//
//  CollectionViewController.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import UIKit

class CollectionViewController: UICollectionViewController {
    var swipeStateMachine: SwipeToEditStateMachine!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        swipeStateMachine = SwipeToEditStateMachine(collectionView: self.collectionView)
        collectionView.addObserver(self, forKeyPath: "dataSource", options: [.initial, .new], context: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let datasource = collectionView.dataSource as? DataSource {
            datasource.registerReusableViewsWithCollectionView(collectionView)
            datasource.setNeedsLoadContent()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        swipeStateMachine.viewDidDissapear(animated: false)
    }

    // MARK: Observer methods

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
        ) {

        guard keyPath == "dataSource" else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard
            /// collectionView
            let collectionView = object as? UICollectionView,

            /// datasource
            let datasource = collectionView.dataSource as? DataSource, datasource.delegate == nil else {
                return
        }

        datasource.delegate = self
    }
}

extension CollectionViewController: CollectionViewDelegate {}
