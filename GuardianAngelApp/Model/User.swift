//
//  UserModel.swift
//  GuardianAngelApp
//
//  Created by Hudson Mcashan on 5/4/19.
//  Copyright © 2019 Guardian Angel. All rights reserved.
//

import Foundation

struct LocalUser {
    let id: String
    let name: String
    let email: String
    let profileImage: String?
    
    init(id: String, name: String, email: String, profileImage: String?) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImage = profileImage
    }
}
