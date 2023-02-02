//
//  ManagementTokenResponse.swift
//  dunlao
//
//  Created by PhilipHayes on 11/10/2022.
//ManagementTokenResponse.

import Foundation

struct ManagementTokenResponse: Codable {
    var status: Status
    var token: String
    var dateCreated: String
    var expiryDate: String
}
