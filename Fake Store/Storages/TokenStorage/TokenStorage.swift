//
//  TokenStorage.swift
//  Fake Store
//
//  Created by Антон Голубейков on 20.10.2022.
//

import Foundation

protocol TokenStorage {

     func getToken() throws -> TokenContainer
     func set(newToken: TokenContainer) throws
     func removeTokenFromContainer() throws

 }
