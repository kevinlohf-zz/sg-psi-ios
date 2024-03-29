//
//  MapPresenterTests.swift
//  PSIMapTests
//
//  Created by Kevin Lo on 29/10/2019.
//  Copyright © 2019 Zuhlke Engineering HK Limited. All rights reserved.
//

import Cuckoo
import XCTest
@testable import PSIMap

class MapPresenterTests: XCTestCase {

    let subject: MapPresenterProtocol = MapPresenter()

    let viewMock = MockMapViewProtocol()

    private var mockAPIResponse: PSIAPIResponse {
        let bundle = Bundle(for: type(of: self))
        guard
            let dataURL = bundle.url(forResource: "psi-api-response", withExtension: "json"),
            let data = try? Data(contentsOf: dataURL),
            let response = try? PSIAPIResponse.make(jsonData: data)
            else
        {
            return PSIAPIResponse(regionMetadata: [], items: [])
        }
        return response
    }

    override func setUp() {
        subject.view = viewMock

        stub(viewMock) { view in
            when(view).showPSIIndex(with: any()).thenDoNothing()
            when(view).showRefreshTime(any()).thenDoNothing()
            when(view).showAirQualitySummary(
                airQuality: any(),
                outdoorActivityAdvise: any()
            ).thenDoNothing()
            when(view).showError().thenDoNothing()
            when(view).startLoading().thenDoNothing()
            when(view).stopLoading().thenDoNothing()
        }
    }

    override func tearDown() {
        clearInvocations(viewMock)
        clearStubs(viewMock)
    }

}

// MARK: - Test - presentData(with response: PSIAPIResponse)

extension MapPresenterTests {

    func test_presentData_withValidResponse_shouldInvokeView() {
        // Act
        subject.presentData(with: mockAPIResponse)

        // Assert
        let matcher = ParameterMatcher <[MapPSIIndexItem]> { param in
            // Simply check whether the item of east exists
            // Referring to TestData/psi-api-response.json
            return param.contains { item -> Bool in
                return item.latitude == 1.35735 &&
                    item.longitude == 103.94 &&
                    item.name == "east" &&
                    item.psiTwentyFourHourly == 55 &&
                    item.pm25Hourly == 16
            }
        }
        verify(viewMock).showPSIIndex(with: matcher)
    }

    func test_presentData_withValidResponse_shouldExcludeZeroCoordinates() {
        // Act
        subject.presentData(with: mockAPIResponse)

        // Assert
        let matcher = ParameterMatcher <[MapPSIIndexItem]> { param in
            // Referring to TestData/psi-api-response.json
            return !param.contains { item -> Bool in
                return item.latitude == 0 && item.longitude == 0
            }
        }
        verify(viewMock).showPSIIndex(with: matcher)
    }

    func test_presentData_withNationalReading_shouldShowAirQuality() {
        // Act
        subject.presentData(with: mockAPIResponse)

        // Assert
        // Referring to TestData/psi-api-response.json
        verify(viewMock).showAirQualitySummary(airQuality: equal(to: .moderate), outdoorActivityAdvise: any())
    }

    func test_presentData_withNationalReading_shouldShowOutdoorActivityAdvise() {
        // Act
        subject.presentData(with: mockAPIResponse)

        // Assert
        // Referring to TestData/psi-api-response.json
        verify(viewMock).showAirQualitySummary(airQuality: any(), outdoorActivityAdvise: equal(to: .normal))
    }

    func test_presentData_withLastUpdateTime_shouldShowUpdateTime() {
        // Act
        subject.presentData(with: mockAPIResponse)

        // Assert
        // Record in the API is "2019-10-27T23:08:52+08:00"
        // Referring to TestData/psi-api-response.json
        verify(viewMock).showRefreshTime("Oct 27, 2019 at 11:08 PM")
    }

}

// MARK: - Test - presentError()

extension MapPresenterTests {

    func test_presentError_shouldInvokeShowError() {
        // Act
        subject.presentError()

        // Assert
        verify(viewMock).showError()
    }

}

// MARK: - Test - presentLoadingState(isLoading: Bool)

extension MapPresenterTests {

    func test_presentLoadingStateWithLoading_shouldInvokeStartLoading() {
        // Act
        subject.presentLoadingState(isLoading: true)

        // Assert
        verify(viewMock).startLoading()
    }

    func test_presentLoadingStateWithNotLoading_shouldInvokeStopLoading() {
        // Act
        subject.presentLoadingState(isLoading: false)

        // Assert
        verify(viewMock).stopLoading()
    }

}
