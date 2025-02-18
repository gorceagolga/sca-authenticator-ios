//
//  AuthorizationRouterSpec.swift
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

import Quick
import Nimble
@testable import SEAuthenticator

class AuthorizationRouterSpec: BaseSpec {
    override func spec() {
        let baseUrl = URL(string: "base.com")!
        let baseUrlPath = "api/authenticator/v1/authorizations"

        describe("AuthorizationsRouter") {
            context("when it's .list") {
                it("should create a valid url request") {
                    let signature = SignatureHelper.signedPayload(
                        method: .get,
                        urlString: baseUrl.appendingPathComponent(baseUrlPath).absoluteString,
                        guid: "tag",
                        params: nil
                    )

                    let headers = Headers.signedRequestHeaders(
                        token: "token",
                        signature: signature,
                        appLanguage: "en"
                    )

                    let expectedRequest = URLRequestBuilder.buildUrlRequest(
                        with: baseUrl.appendingPathComponent(baseUrlPath),
                        method: HTTPMethod.get.rawValue,
                        headers: headers,
                        encoding: .url
                    )

                    let expectedData = SEBaseAuthorizationData(
                        url: baseUrl,
                        connectionGuid: "tag",
                        accessToken: "token",
                        appLanguage: "en"
                    )
                
                    let request = SEAuthorizationRouter.list(expectedData).asURLRequest()

                    expect(request).to(equal(expectedRequest))
                }
            }

            context("when it's .getAuthorization") {
                it("should create a valid url request") {
                    let data = SEAuthorizationData(
                        url: baseUrl,
                        connectionGuid: "123guid",
                        accessToken: "accessToken",
                        appLanguage: "en",
                        authorizationId: "1"
                    )

                    let signature = SignatureHelper.signedPayload(
                        method: .get,
                        urlString: baseUrl.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)").absoluteString,
                        guid: "123guid",
                        params: nil
                    )

                    let headers = Headers.signedRequestHeaders(
                        token: "accessToken",
                        signature: signature,
                        appLanguage: "en"
                    )

                    let expectedRequest = URLRequestBuilder.buildUrlRequest(
                        with: baseUrl.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)"),
                        method: HTTPMethod.get.rawValue,
                        headers: headers,
                        encoding: .url
                    )

                    let request = SEAuthorizationRouter.getAuthorization(data).asURLRequest()

                    expect(request).to(equal(expectedRequest))
                }
            }

            context("when it's .confirm") {
                it("should create a valid url request") {
                    let data = SEConfirmAuthorizationData(
                        url: baseUrl,
                        connectionGuid: "123guid",
                        accessToken: "accessToken",
                        appLanguage: "en",
                        authorizationId: "1",
                        authorizationCode: "code"
                    )

                    let params = RequestParametersBuilder.confirmAuthorization(true, authorizationCode: data.authorizationCode)

                    let signature = SignatureHelper.signedPayload(
                        method: .put,
                        urlString: data.url.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)").absoluteString,
                        guid: data.connectionGuid,
                        params: params
                    )

                    let headers = Headers.signedRequestHeaders(
                        token: data.accessToken,
                        signature: signature,
                        appLanguage: "en"
                    )

                    let expectedRequest = URLRequestBuilder.buildUrlRequest(
                        with: baseUrl.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)"),
                        method: HTTPMethod.put.rawValue,
                        headers: headers,
                        params: params,
                        encoding: .json
                    )

                    let request = SEAuthorizationRouter.confirm(data).asURLRequest()

                    expect(request).to(equal(expectedRequest))
                }
            }

            context("when it's .deny") {
                it("should create a valid url request") {
                    let data = SEConfirmAuthorizationData(
                        url: baseUrl,
                        connectionGuid: "123guid",
                        accessToken: "accessToken",
                        appLanguage: "en",
                        authorizationId: "1",
                        authorizationCode: "code"
                    )
                    
                    let params = RequestParametersBuilder.confirmAuthorization(false, authorizationCode: data.authorizationCode)
                    
                    let signature = SignatureHelper.signedPayload(
                        method: .put,
                        urlString: data.url.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)").absoluteString,
                        guid: data.connectionGuid,
                        params: params
                    )
                    
                    let headers = Headers.signedRequestHeaders(
                        token: data.accessToken,
                        signature: signature,
                        appLanguage: "en"
                    )

                    let expectedRequest = URLRequestBuilder.buildUrlRequest(
                        with: baseUrl.appendingPathComponent("\(baseUrlPath)/\(data.authorizationId)"),
                        method: HTTPMethod.put.rawValue,
                        headers: headers,
                        params: params,
                        encoding: .json
                    )
                    
                    let request = SEAuthorizationRouter.deny(data).asURLRequest()
                    
                    expect(request).to(equal(expectedRequest))
                }
            }
        }
    }
}
