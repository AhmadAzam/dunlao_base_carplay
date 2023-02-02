//
//  BlogPost.swift
//  dunlao
//
//  Created by PhilipHayes on 20/09/2022.
//

import Foundation
struct BlogPost: Decodable {
    enum Category: String, Decodable {
        case swift, combine, debugging, xcode
    }

    let title: String
    let url: URL
    let category: Category
    let views: Int
}
