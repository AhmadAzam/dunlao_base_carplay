//
//  InformationContentResponse.swift
//  dunlao
//
//  Created by PhilipHayes on 13/10/2022.
//

import Foundation

struct InformationContentResponse: Codable{
    let status: Status
    let content: String
    let isHTML: Bool
}
