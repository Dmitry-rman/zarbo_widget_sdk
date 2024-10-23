//
//  DaItaStorage.swift
//  Demo App
//
//  Created by Dmitry on 19.09.2024.
//

import Foundation

protocol IDataStorage {
    var sku: String? { get set }
    var usdzUrl: String? { get set }
    var packetUrl: String? { get set }
}
