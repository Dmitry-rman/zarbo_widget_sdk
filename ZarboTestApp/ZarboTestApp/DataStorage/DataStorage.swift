//
//  DataStorage.swift
//  Demo App
//
//  Created by Dmitry on 19.09.2024.
//

import Foundation

struct DataStorage  {
    
    enum DataKey: String {
        case SKU_KEY = "sku"
        case USDZ_URL_KEY = "usdzUrl"
        case PACKET_URL_KEY = "packetUrl"
    }
    
    private func setValue<T>(_ value: T, key: DataKey) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    private func getValue(forKey key: DataKey) -> Any? {
        UserDefaults.standard.value(forKey: key.rawValue)
    }
}

extension DataStorage: IDataStorage {
    
    var usdzUrl: String? {
        get { getValue(forKey: .USDZ_URL_KEY) as? String }
        set { setValue(newValue, key: .USDZ_URL_KEY) }
    }
    
    var packetUrl: String? {
        get { getValue(forKey: .PACKET_URL_KEY) as? String }
        set { setValue(newValue, key: .PACKET_URL_KEY) }
    }
    
    var sku: String? {
        get { getValue(forKey: .SKU_KEY) as? String }
        set { setValue(newValue, key: .SKU_KEY) }
    }
}
