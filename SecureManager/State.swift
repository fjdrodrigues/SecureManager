//
//  State.swift
//  SecureManager
//
//  Created by Fabio on 07/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

enum State {
    case online
    case offline
}
extension State: CustomStringConvertible {
    var description: String {
        switch self {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        }
    }
}
