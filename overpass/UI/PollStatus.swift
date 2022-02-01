//
//  PollStatus.swift
//  overpass
//
//  Created by Geoffrey Matrangola on 1/29/22.
//

import Foundation

class PollStatus {
    var type: String = ""
    var id: String = ""
    
    init(_ id: String, _ type: String) {
        self.id = id
        self.type = type
    }
}
