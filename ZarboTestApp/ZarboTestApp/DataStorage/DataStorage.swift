//
//  DataStorage.swift
//  Demo App
//
//  Created by Dmitry on 19.09.2024.
//

import Foundation

final class DataStorage  {
    private let SKU_KEY = "sku"
}

extension DataStorage: IDataStorage {
    
    func getSKU() -> String? {
        UserDefaults.standard.string(forKey: SKU_KEY)
    }
    
    func setSKU(_ value: String) {
        UserDefaults.standard.setValue(value, forKey: SKU_KEY)
        UserDefaults.standard.synchronize()
    }
}
