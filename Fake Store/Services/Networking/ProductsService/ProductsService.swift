//
//  ProductsService.swift
//  Fake Store
//
//  Created by Антон Голубейков on 30.10.2022.
//

import Foundation

struct ProductsService {

    var dataTask: BaseNetworkTask<EmptyModel, [ProductsResponseModel]> { BaseNetworkTask<EmptyModel, [ProductsResponseModel]> (
        method: .get,
        path: "products"
    )
    }

    func loadProducts(_ onResponseWasReceived: @escaping (_ result: Result<[ProductsResponseModel], Error>) -> Void) {
        dataTask.performRequest(onResponseWasReceived)
    }

}
