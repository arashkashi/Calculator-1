//
//  NetworkService.swift
//  Calculator
//
//  Created by Arash Kashi on 16.08.21.
//  Copyright © 2021 Andrea Vultaggio. All rights reserved.
//

import Foundation
import Combine
import SwiftUI



class NetworkService {
    
    enum DownloadError: Error {
        case dataNotValid
    }
    
    enum Result<T> {
        case success(T)
        case fail(Error)
    }
    
    static var shared: NetworkService = NetworkService()
    fileprivate init() {}
    
    private var timeout: TimeInterval = 5000
    
    // TODO: Rethink the accumulation if subscriptions
    // it is not right to have bag in a singlton, means memory leak.
    // solution to use a ordered list such as stack instead of set
    var bag = Set<AnyCancellable>()
    
    lazy var session: URLSession = {
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = self.timeout
        config.httpShouldSetCookies = true
        
        return URLSession(configuration: config)
    }()
    
    func downloadImage(from url: URL, comp: @escaping (Result<Image>) -> ()) {
        getData(from: url) { data, response, error in
            guard  error == nil else {
                DispatchQueue.main.async() {
                    comp(Result.fail(error!))
                }
                return
            }
            
            guard let data = data, let validUIImage = UIImage(data: data) else {
                DispatchQueue.main.async() {
                    comp(Result.fail(DownloadError.dataNotValid))
                }
                return
            }
            
            DispatchQueue.main.async() {
                // TODO: should set the caching mechanism here.
                comp(.success(Image(uiImage: validUIImage)))
            }
        }
    }
    
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        self.session.dataTask(with: url, completionHandler: completion).resume()
    }
    
    // TODO: Impagination is UX friendly when lists are long.
    func sendRequest<T: Codable>(with urlReq: URLRequest
                                 , model: T.Type
                                 , comp: @escaping (Result<T>) -> ()) {
        
        self.session.dataTaskPublisher(for: urlReq)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    
                    throw URLError(.badServerResponse)
                }
                #if DEBUG
                let jsonObject = try JSONSerialization.jsonObject(with: element.data)
                let prettyData = try JSONSerialization.data(withJSONObject: jsonObject,
                                options: .prettyPrinted)
                print(String(data: prettyData, encoding: .utf8) ?? "unknown")
                #endif
                return element.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    comp(Result.fail(error))
                case .finished:
                    // TODO find a way to remove from the bag of cancalable
                    // instead of set use a Queue (ordered collection)
                    break
                }
            } receiveValue: { value in
                comp(Result.success(value))
            }
            .store(in: &bag)
        
        print(bag.count)
    }
}

extension URLRequest {
    static func bitcoinRequest() -> URLRequest {
        let url = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
        return URLRequest(url: url)
    }
}


struct BPIData: Codable {
    var code: String
    var rate_float: Double
}
struct BitcoinResponse: Codable {
    var disclaimer: String
    var chartName: String
    var bpi: Dictionary<String, BPIData>
}



