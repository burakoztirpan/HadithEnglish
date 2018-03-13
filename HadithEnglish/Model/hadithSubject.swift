//
//  HadithList.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 2.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import Foundation

struct simpleHadith: Decodable {
    var hadith: String
    var id: Int
}

struct Hadith : Decodable {
    var name: String
    var hadiths: [simpleHadith]
}


class hadithSubject {
    private var _hadithName: String!
    private var _hadithList : [String] = []
    private var _hadithCollect: [Hadith]?
    
  
    
    var hadithName:String {
        return _hadithName
    }
    
    var hadithList:[String] {
        return _hadithList
    }
    
    var hadithCollect:[Hadith] {
        return _hadithCollect!
    }
    
}
