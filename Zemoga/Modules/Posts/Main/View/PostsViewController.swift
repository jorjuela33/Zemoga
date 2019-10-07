//
//  PostsViewController.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import RxCocoa
import RxSwift
import UIKit

class PostsViewController: ViewController {
    private let disposeBag = DisposeBag()

    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var deleteButton: UIButton!

    private var refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)
    private lazy var loadingIndicator: LoadingIndicator = {
        return LoadingIndicator.show(in: self.view, loadingMessage: "Deleting Post...")
    }()

    var presenter: PostsPresenter?
    var swipeStateMachine: SwipeToEditStateMachine!

    override func viewDidLoad() {
        super.viewDidLoad()
        swipeStateMachine = SwipeToEditStateMachine(collectionView: collectionView)
        bindPresenter()
        configure()
    }

    // MARK: Private methods

    private func bindPresenter() {
        let delete = deleteButton.rx.tap.asDriver()
        let itemSelected = collectionView.rx.itemSelected.asDriver()
        let refresh = refreshBarButtonItem.rx.tap.asDriver()
        let input = PostsPresenter.Input(delete: delete, itemSelected: itemSelected, refresh: refresh)
        let output = presenter?.transform(input)

        collectionView.dataSource = output?.datasource
        output?.datasource.delegate = self
        output?.datasource.registerReusableViewsWithCollectionView(collectionView)

        output?.error.drive(rx.message).disposed(by: disposeBag)
        output?.state.drive(loadingIndicator.rx.state).disposed(by: disposeBag)
    }

    private func configure() {
        navigationItem.rightBarButtonItem = refreshBarButtonItem
        collectionView.contentInset.bottom = deleteButton.frame.height
    }
}

extension PostsViewController: CollectionViewDelegate {}
