//
//  PostReusableView.swift
//  Zemoga
//
//  Created by Jorge Orjuela on 10/6/19.
//

import UIKit

struct PostInfo {
    let body: String
    let email: String
    let name: String
    let phone: String
    let website: String
}

class PostReusableView: UICollectionReusableView {
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.textColor = UIColor.gray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.text = "Email:"
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.text = "Name:"
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var phoneLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.text = "Phone:"
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14.0, weight: .bold)
        label.text = "Description"
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var userInfoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 14.0, weight: .bold)
        label.text = "User"
        label.textColor = UIColor.black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var websiteLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: 12.0)
        label.text = "Website:"
        label.textColor = UIColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    // MARK: Instance methods

    func configure(for postInfo: PostInfo) {
        descriptionLabel.text = postInfo.body
        emailLabel.text = "Email: \(postInfo.email)"
        nameLabel.text = "Name: \(postInfo.name)"
        phoneLabel.text = "Phone: \(postInfo.phone)"
        websiteLabel.text = "Website: \(postInfo.website)"
    }

    // MARK: Private methods

    private func commonInit() {
        addSubview(descriptionLabel)
        addSubview(emailLabel)
        addSubview(nameLabel)
        addSubview(phoneLabel)
        addSubview(titleLabel)
        addSubview(userInfoLabel)
        addSubview(websiteLabel)

        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            bottomAnchor.constraint(equalTo: websiteLabel.bottomAnchor, constant: 12),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            emailLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            phoneLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 5),
            phoneLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            rightAnchor.constraint(equalTo: descriptionLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: emailLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: phoneLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: userInfoLabel.rightAnchor, constant: 15),
            rightAnchor.constraint(equalTo: websiteLabel.rightAnchor, constant: 15),
            titleLabel.heightAnchor.constraint(equalToConstant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            userInfoLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20),
            userInfoLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            websiteLabel.topAnchor.constraint(equalTo: phoneLabel.bottomAnchor, constant: 5),
            websiteLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
        ])
    }
}
