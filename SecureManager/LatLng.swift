//
//  LatLng.swift
//  SecureManager
//
//  Created by Fabio on 07/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import Foundation

struct LatLng: CustomStringConvertible {
    //MARK: Properties
    var latitude: Double
    var longitude: Double
    
    //MARK: Initialization
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public var description: String { return "Latitude: \(latitude), Longitude: \(longitude)" }
}
