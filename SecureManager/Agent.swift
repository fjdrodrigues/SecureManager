//
//  Agent.swift
//  SecureManager
//
//  Created by Fabio on 07/10/2018.
//  Copyright © 2018 Fabio. All rights reserved.
//

import UIKit


struct Agent {
    
    //MARK: Properties
    
    var name: String
    var email: String
    var latLng: LatLng?
    var state: State?
    var lastUpdate: String
    var evidenceCollected: Int
    var evidence: [UIImageView]?
    
    //MARK: Initialization
    
    init(name: String, email: String, latLng: LatLng?, state: State?, lastUpdate: String, evidenceCollected: Int, evidence: [UIImageView]?) {
        self.name = name
        self.email = email
        if (latLng != nil) {
            self.latLng = latLng!
        }
        if (state != nil) {
            self.state = state!
        }
        self.lastUpdate = lastUpdate
        self.evidenceCollected = evidenceCollected
        if (evidence != nil) {
            self.evidence = evidence!
        }
        
    }
    
    mutating func setName(name: String) {
        self.name = name
    }
    mutating func setEmail(email: String) {
        self.email = email
    }
    mutating func setlatLng(latLng: LatLng) {
        self.latLng = latLng
    }
    mutating func setState(state: State) {
        self.state = state
    }
    mutating func setLastUpdate(lastUpdate: String) {
        self.lastUpdate = lastUpdate
    }
    mutating func setEvidenceCollected(evidenceCollected: Int) {
        self.evidenceCollected = evidenceCollected
    }
    mutating func setEvidence(evidence: [UIImageView]) {
        self.evidence = evidence
    }
    
}
