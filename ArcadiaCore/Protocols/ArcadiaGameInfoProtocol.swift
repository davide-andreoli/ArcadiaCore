//
//  iRetroGameInfoProtocol.swift
//  iRetroCore
//
//  Created by Davide Andreoli on 14/05/24.
//

import Foundation

public protocol ArcadiaGameInfoProtocol {
    var path: UnsafePointer<CChar>! { get set }
    var data: UnsafeRawPointer! { get set }
    var size: Int { get set }
    var meta: UnsafePointer<CChar>! { get set }
    
    init(path: UnsafePointer<CChar>!, data: UnsafeRawPointer!, size: Int, meta: UnsafePointer<CChar>!)
}
