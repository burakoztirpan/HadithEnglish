//
//  FavoriteCell.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 4.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

class FavoriteCell: UITableViewCell {
    
    
    @IBOutlet weak var favoriteDesc: UILabel!
    @IBOutlet weak var hadithId: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateFavoriteDescUI(favorite:String,favoriteId:String){
        favoriteDesc.text = favorite
        hadithId.text = favoriteId
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
