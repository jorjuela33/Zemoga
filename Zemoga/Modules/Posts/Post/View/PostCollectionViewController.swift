//
//  PostCollectionViewController.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import RxCocoa
import RxSwift
import UIKit

class PostCollectionViewController: CollectionViewController {
    private let disposeBag = DisposeBag()
    private var favoriteBarButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: nil)

    var presenter: PostPresenter?

    override func viewDidLoad() {
        super.viewDidLoad()
        bindPresenter()
        configure()
    }

    // MARK: Private methods

    private func bindPresenter() {
        let favorite = favoriteBarButtonItem.rx.tap.asDriver()
        let refreshControl = UIRefreshControl()
        let pullDownToRefresh = refreshControl.rx.controlEvent(.valueChanged).asDriver()
        let input = PostPresenter.Input(favorite: favorite, pullDownToRefresh: pullDownToRefresh)
        let output = presenter?.transform(input)

        collectionView.dataSource = output?.datasource
        collectionView.refreshControl = refreshControl

        output?.datasource.defaultMetrics.rowSize = CGSize(width: UIScreen.main.bounds.width, height: SectionMetrics.variableRowHeight)
        output?.datasource.defaultMetrics.separatorInsets = .zero
        output?.error.drive(rx.message).disposed(by: disposeBag)
        output?.favoriteImage
            .drive(onNext: { [weak self] image in
                self?.favoriteBarButtonItem.image = image
            })
            .disposed(by: disposeBag)

        let supplementaryViewMetrics = output?.datasource.newHeader(
            forKey: "globalHeader",
            supplementaryViewClass: PostReusableView.self
        )

        supplementaryViewMetrics?.configurationCallback = { reusableView, _, _ in
            guard let postReusableView = reusableView as? PostReusableView else { return }

            output?.postInfo
                .drive(onNext: postReusableView.configure)
                .disposed(by: postReusableView.rx.reuseBag)
        }
    }

    private func configure() {
        navigationItem.rightBarButtonItem = favoriteBarButtonItem
    }
}
