//
//  PostsPresenter.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/5/19.
//

import Domain
import RxCocoa
import RxSwift

class PostsPresenter {
    private let datasource: SegmentedDatasource
    private let disposeBag = DisposeBag()
    private let postsRepository: PostsRepository
    private let wireframe: PostsWireframeInterface? 

    struct Input {
        let delete: Driver<Void>
        let itemSelected: Driver<IndexPath>
        let refresh: Driver<Void>
    }

    struct Output {
        let datasource: SegmentedDatasource
        let error: Driver<Message>
        let state: Driver<ActivityState>
    }

    // MARK: Initializers

    init(postsRepository: PostsRepository, wireframe: PostsWireframeInterface) {
        self.datasource = SegmentedDatasource(datasources: [])
        self.postsRepository = postsRepository
        self.wireframe = wireframe
    }

    // MARK: Instance methods

    func transform(_ input: Input) -> Output {
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let postsDatasource = PostsDatasource(postsRepository: postsRepository, filteringBy: .notFavorites)
        let deleteCallback: ((PostDisplayItem) -> Void) = { [weak self] post in
            guard let `self` = self else { return }

            self.postsRepository.deletePost(withID: post.post.id)
                .trackActivity(activityIndicator)
                .trackError(errorTracker)
                .subscribe()
                .disposed(by: self.disposeBag)
        }

        postsDatasource.deleteCallback = deleteCallback
        postsDatasource.noContent = NoContent(title: "No posts.", message: "You don't have any posts.", image: #imageLiteral(resourceName: "imgNoResults"))
        postsDatasource.title = "All"

        let favoritePostsDatasource = PostsDatasource(postsRepository: postsRepository, filteringBy: .favorites)
        favoritePostsDatasource.deleteCallback = deleteCallback
        favoritePostsDatasource.noContent = NoContent(title: "No favorite posts.", message: "You haven't selected any favorite post yet.", image: #imageLiteral(resourceName: "imgNoResults"))
        favoritePostsDatasource.title = "Favorites"

        datasource.addDatasource(postsDatasource)
        datasource.addDatasource(favoritePostsDatasource)
        datasource.setNeedsLoadContent()

        input.delete
            .flatMapLatest { _  in
                return self.postsRepository.deleteAllPosts()
                    .asObservable()
                    .asDriverOnErrorJustComplete()
            }
            .drive()
            .disposed(by: disposeBag)

        input.itemSelected
            .drive(onNext: { [weak self] indexPath in
                guard let post: PostDisplayItem = self?.datasource.item(at: indexPath) else { return }

                self?.wireframe?.toPostScreen(withPost: post.post)
            })
            .disposed(by: disposeBag)

        input.refresh
            .drive(onNext: { [weak self] in
                self?.datasource.setNeedsLoadContent()
            })
            .disposed(by: disposeBag)

        return Output(datasource: datasource, error: errorTracker.map(ErrorBuilder.create), state: activityIndicator.asDriver())
    }
}
