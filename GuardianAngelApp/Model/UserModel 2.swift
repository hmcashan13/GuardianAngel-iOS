//
//  User.swift
//  InstagramFirebase
//
//  Created by Brian Voong on 4/11/17.
//  Copyright © 2017 Lets Build That App. All rights reserved.
//

import Foundation

struct User {
    
    let id: String
    let name: String
    let email: String
    let profileImageUrl: String?
    
    init(id: String, dictionary: [String: Any]) {
        self.id = id
        self.name = dictionary["name"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"]  as? String ?? ""
    }
}
