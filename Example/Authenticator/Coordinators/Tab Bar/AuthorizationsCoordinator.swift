//
//  AuthorizationCoordinator.swift
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
import SEAuthenticator

final class AuthorizationsCoordinator: Coordinator {
    let rootViewController = AuthorizationsViewController()

    private var passcodeCoordinator: PasscodeCoordinator?

    private var timer: Timer?
    private let dataSource = AuthorizationsDataSource()
    private var connections = ConnectionsCollector.activeConnections

    private var selectedViewModelIndex: Int?
    private var selectedCell: AuthorizationCollectionViewCell?

    private var authorizationFromPush: (connectionId: String, authorizationId: String)?

    func start() {
        rootViewController.dataSource = dataSource
        rootViewController.delegate = self

        setupPolling()
        updateDataSource(with: [])
    }

    func start(with connectionId: String, authorizationId: String) {
        start()
        authorizationFromPush = (connectionId, authorizationId)
    }

    func stop() {
        timer?.invalidate()
    }

    private func setupPolling() {
        getEncryptedAuthorizationsIfAvailable()

        timer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(getEncryptedAuthorizationsIfAvailable),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func getEncryptedAuthorizationsIfAvailable() {
        if connections.count > 0 {
            refresh()
        } else {
            updateDataSource(with: [])
        }
    }

     private func updateDataSource(with authorizations: [SEDecryptedAuthorizationData]) {
        if dataSource.update(with: authorizations) {
            rootViewController.reloadData()
            if authorizations.count > 1,
                let authorizationToScroll = authorizationFromPush,
                let viewModel = dataSource.viewModel(
                    by: authorizationToScroll.connectionId,
                    authorizationId: authorizationToScroll.authorizationId
                ),
                let index = dataSource.index(of: viewModel) {
                    rootViewController.scroll(to: index)
                    authorizationFromPush = nil
            }
        }
        rootViewController.updateViewsHiddenState()
    }

    private func confirmationData(for index: Int) -> SEConfirmAuthorizationData? {
        guard let viewModel = dataSource.viewModel(at: index),
            let connection = ConnectionsCollector.with(id: viewModel.connectionId),
            let url = connection.baseUrl else { return nil }

        return SEConfirmAuthorizationData(
            url: url,
            connectionGuid: connection.guid,
            accessToken: connection.accessToken,
            appLanguage: UserDefaultsHelper.applicationLanguage,
            authorizationId: viewModel.authorizationId,
            authorizationCode: viewModel.authorizationCode
        )
    }
}

// MARK: - Actions
private extension AuthorizationsCoordinator {
    @objc func refresh() {
        AuthorizationsInteractor.refresh(
            connections: Array(connections),
            success: { encryptedAuthorizations in
                DispatchQueue.global(qos: .background).async {
                    let decryptedAuthorizations = encryptedAuthorizations.compactMap { authorization in
                        return AuthorizationsPresenter.decryptedData(from: authorization)
                    }

                    DispatchQueue.main.async {
                        self.updateDataSource(with: decryptedAuthorizations)
                    }
                }
            },
            connectionNotFoundFailure: { connectionId in
                if let id = connectionId, let connection = ConnectionsCollector.with(id: id) {
                    ConnectionRepository.setInactive(connection)
                }
            }
        )
    }

    func presentPasscodeView() {
        passcodeCoordinator = PasscodeCoordinator(
            rootViewController: rootViewController,
            purpose: .enter,
            type: .authorize
        )
        passcodeCoordinator?.onCompleteClosure = { [weak self] in
            self?.selectedCell?.setProcessing(with: l10n(.processing))

            guard let index = self?.selectedViewModelIndex,
                let data = self?.confirmationData(for: index) else { return }

            AuthorizationsInteractor.confirm(data: data)
        }
        passcodeCoordinator?.start()
    }
}

// MARK: - AuthorizationsViewControllerDelegate
extension AuthorizationsCoordinator: AuthorizationsViewControllerDelegate {
    func denyPressed(at index: Int) {
        guard let data = confirmationData(for: index) else { return }

        AuthorizationsInteractor.deny(data: data)
    }

    func confirmPressed(at index: Int, cell: AuthorizationCollectionViewCell) {
        selectedViewModelIndex = index
        selectedCell = cell

        guard PasscodeManager.isBiometricsEnabled else { self.presentPasscodeView(); return }

        PasscodeManager.useBiometrics(
            type: .authorize,
            reasonString: "Confirm authorization",
            onSuccess: {
                cell.setProcessing(with: l10n(.processing))

                guard let data = self.confirmationData(for: index) else { return }

                AuthorizationsInteractor.confirm(data: data)
            },
            onFailure: { _ in
                self.presentPasscodeView()
            }
        )
    }

    func modalClosed() {
        setupPolling()
    }
}
