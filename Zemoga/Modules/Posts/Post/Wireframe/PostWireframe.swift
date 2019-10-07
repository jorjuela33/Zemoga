//
//  PostWireframe.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import Domain
import UIKit

protocol PostWireframeInterface {
    func toPostScreen(withPost post: Post)
}

struct PostWireframe {
    private let navigationController: NavigationController
    private let repositoryProvider: RepositoryProvider
    private let storyBoard: UIStoryboard

    // MARK: Initializers

     init(
        navigationController: NavigationController,
        repositoryProvider: RepositoryProvider,
        storyBoard: UIStoryboard = UIStoryboard(storyboardName: .main)
        ) {

        self.navigationController = navigationController
        self.repositoryProvider = repositoryProvider
        self.storyBoard = storyBoard
    }
}

extension PostWireframe: PostWireframeInterface {

    // MARK: PostWireframeInterface

    func toPostScreen(withPost post: Post) {
        let presenter = PostPresenter(
            post: post,
            postsRepository: repositoryProvider.makePostsRepository(),
            commentsRepository: repositoryProvider.makeCommentsRepository(),
            usersRepository: repositoryProvider.makeUsersRepository(),
            wireframe: self
        )
        let viewController: PostCollectionViewController = storyBoard.instantiateViewController()

        viewController.presenter = presenter
        navigationController.pushViewController(viewController, animated: true)
    }
}
