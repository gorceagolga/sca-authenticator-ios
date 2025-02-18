//
//  AuthorizationsHeaderCollectionViewCell
//  This file is part of the Salt Edge Authenticator distribution
//  (https://github.com/saltedge/sca-authenticator-ios)
//  Copyright © 2019 Salt Edge Inc.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 3 or later.
//
//  This program is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
//  General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//  For the additional permissions granted for Salt Edge Authenticator
//  under Section 7 of the GNU General Public License see THIRD_PARTY_NOTICES.md
//

import UIKit

private struct Layout {
    static let connectionImageViewSize: CGSize = CGSize(width: 24.0, height: 24.0)
    static let connectionImageViewOffset: CGFloat = 16.0
    static let nameLabelOffset: CGFloat = 8.0
    static let progressViewWidthOffset: CGFloat = -22.0
    static let timeLeftLabelOffset: CGFloat = -8.0
    static let timeLeftLabelHeight: CGFloat = 28.0
}

final class AuthorizationHeaderCollectionViewCell: UICollectionViewCell {
    private let connectionImageView = UIImageView()
    private let connectionNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = .auth_darkGray
        return label
    }()
    private let timeLeftLabel = TimeLeftLabel()
    private let progressView = CountdownProgressView()

    private var timer: Timer!
    private var secondsLeft: Int = 0
    private var lifetime: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white
        setupShadowAndCornerRadius()
        setTimer()
        layout()
    }

    deinit {
        timer.invalidate()
    }

    func configure(_ item: AuthorizationViewModel, at indexPath: IndexPath) {
        secondsLeft = diffInSecondsFromNow(for: item.authorizationExpiresAt)
        lifetime = item.lifetime

        connectionImageView.contentMode = .scaleAspectFit
        connectionImageView.image = #imageLiteral(resourceName: "bankPlaceholderCyanSmall")

        if let connection = ConnectionsCollector.with(id: item.connectionId) {
            setImage(from: connection.logoUrl)
            connectionNameLabel.text = connection.name
        }
        updateCountdown(secondsLeft)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers
private extension AuthorizationHeaderCollectionViewCell {
    func setupShadowAndCornerRadius() {
        contentView.layer.cornerRadius = 21.0
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4.0
    }

    func setImage(from imageUrl: URL?) {
        guard let url = imageUrl else { return }

        ConnectionImageHelper.setAnimatedCachedImage(from: url, for: connectionImageView)
    }

    func setTimer() {
        if timer != nil { timer.invalidate() }
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(countDownTime), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
    }

    func updateCountdown(_ timeLeft: Int) {
        setTimer()
        progressView.update(secondsLeft: timeLeft, lifetime: lifetime)
        timeLeftLabel.update(secondsLeft: timeLeft)
    }

    @objc private func countDownTime() {
        secondsLeft -= 1
        if secondsLeft <= 0 {
            timer.invalidate()
        } else {
            updateCountdown(secondsLeft)
        }
    }
}

// MARK: - Layout
extension AuthorizationHeaderCollectionViewCell: Layoutable {
    func layout() {
        contentView.addSubviews(connectionImageView, connectionNameLabel, progressView, timeLeftLabel)

        connectionImageView.left(to: contentView, offset: Layout.connectionImageViewOffset)
        connectionImageView.centerY(to: contentView)
        connectionImageView.size(Layout.connectionImageViewSize)

        connectionNameLabel.leftToRight(of: connectionImageView, offset: Layout.nameLabelOffset)
        connectionNameLabel.centerY(to: connectionImageView)

        progressView.height(3.0)
        progressView.bottom(to: contentView)
        progressView.width(to: contentView, offset: Layout.progressViewWidthOffset)
        progressView.centerX(to: contentView)

        timeLeftLabel.right(to: contentView, offset: Layout.timeLeftLabelOffset)
        timeLeftLabel.centerY(to: connectionImageView)
        timeLeftLabel.height(Layout.timeLeftLabelHeight)
    }
}

private extension AuthorizationHeaderCollectionViewCell {
    func diffInSecondsFromNow(for date: Date) -> Int {
        let currentDate = Date()
        let diffDateComponents = Calendar.current.dateComponents([.minute, .second], from: currentDate, to: date)

        guard let minutes = diffDateComponents.minute, let seconds = diffDateComponents.second else { return 0 }

        return 60 * minutes + seconds
    }
}
