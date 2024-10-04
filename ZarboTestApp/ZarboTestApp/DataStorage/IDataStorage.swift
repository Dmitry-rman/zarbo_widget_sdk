//
//  DaItaStorage.swift
//  Demo App
//
//  Created by Dmitry on 19.09.2024.
//

import Foundation

protocol IDataStorage {
    func getSKU() -> String?
    func setSKU(_ value: String)
}
