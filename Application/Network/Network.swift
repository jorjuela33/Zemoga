//
//  Network.swift
//  Application
//
//  Created by Jorge Orjuela on 10/4/19.
//

import Domain

typealias RetrieveCallback<T> = (Result<T, Error>) -> Void
typealias SaveCallback<T> = (Result<T, Error>) -> Void
typealias VoidCallback = (Result<Void, Error>) -> Void

protocol Network {
    func cancelConnectionRequest(withRegistration registration: ConnectionRequestRegistration)
    func header(forKey key: String) -> String?
    func deletePost(withID postID: Int64, withCallback callback: @escaping VoidCallback) -> ConnectionRequestRegistration
    func retrieveComments(
        forPostWithID postID: Int64,
        withCallback callback: @escaping RetrieveCallback<[CommentEntity]>
    ) -> ConnectionRequestRegistration
    
    func retrievePosts(withCallback callback: @escaping RetrieveCallback<[PostEntity]>) -> ConnectionRequestRegistration
    func retrieveUser(withID userID: Int64, withCallback callback: @escaping RetrieveCallback<UserEntity>) -> ConnectionRequestRegistration
    func setHeader(_ value: String, forKey key: String)
}

final class NetworkManager: Network {
    private let connection: Connection
    private let connectionTree = ConnectionTree()
    private static let queue = DispatchQueue(label: "com.network.queue")

    // MARK: Initializers

    init(connection: Connection) {
        self.connection = connection
    }

    // MARK: Network

    /// cancels the request associated to the registration
    func cancelConnectionRequest(withRegistration registration: ConnectionRequestRegistration) {
        let connectionRequest = connectionTree.removeConnectionRequest(withRegistration: registration)
        connectionRequest?.cancel()
    }

    /// delete the post associated to the given id
    func deletePost(withID postID: Int64, withCallback callback: @escaping VoidCallback) -> ConnectionRequestRegistration {
        let connectionRequest = connection.delete("posts/\(postID)")
            .responseJSON { result, error in
                guard let error = error else {
                    callback(.success(()))
                    return
                }

                callback(.failure(error))
            }
            .validate()

        enqueueConnectionRequest(connectionRequest)
        return connectionRequest.identifier
    }

    /// return the value associated to the given header
    func header(forKey key: String) -> String? {
        return connection.header(forKey: key)
    }

    /// retrieves all the comments
    /// for the given post id
    func retrieveComments(
        forPostWithID postID: Int64,
        withCallback callback: @escaping RetrieveCallback<[CommentEntity]>
    ) -> ConnectionRequestRegistration {

        let connectionRequest = connection.get("posts/\(postID)/comments")
            .response({ (comments: [CommentEntity]?, error) in
                if let error = error {
                    callback(.failure(error))
                } else if let comments = comments {
                    callback(.success(comments))
                }
            })
            .validate()

        enqueueConnectionRequest(connectionRequest)
        return connectionRequest.identifier
    }

    /// retrieves all the posts
    func retrievePosts(withCallback callback: @escaping RetrieveCallback<[PostEntity]>) -> ConnectionRequestRegistration {
        let connectionRequest = connection.get("posts")
            .response({ (posts: [PostEntity]?, error) in
                if let error = error {
                    callback(.failure(error))
                } else if let posts = posts {
                    callback(.success(posts))
                }
            })
            .validate()

        enqueueConnectionRequest(connectionRequest)
        return connectionRequest.identifier
    }

    /// retrieves the user associated
    /// to the given user id
    func retrieveUser(withID userID: Int64, withCallback callback: @escaping RetrieveCallback<UserEntity>) -> ConnectionRequestRegistration {
        let connectionRequest = connection.get("users/\(userID)")
            .response({ (user: UserEntity?, error) in
                if let error = error {
                    callback(.failure(error))
                } else if let user = user {
                    callback(.success(user))
                }
            })
            .validate()

        enqueueConnectionRequest(connectionRequest)
        return connectionRequest.identifier
    }

    /// sets the header for all the requests
    func setHeader(_ value: String, forKey key: String) {
        connection.setHeader(value, forKey: key)
    }

    // MARK: Private methods

    private func enqueueConnectionRequest(_ connectionRequest: ConnectionRequest) {
        connectionRequest.completionCallback = { [weak self] in
            self?.cancelConnectionRequest(withRegistration: connectionRequest.identifier)
        }

        NetworkManager.queue.async {
            self.connectionTree.addConnectionRequest(connectionRequest)
        }
    }
}
