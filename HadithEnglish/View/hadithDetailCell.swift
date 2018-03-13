//
//  hadithDetailCell.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 3.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

class hadithDetailCell: UITableViewCell {

    
    @IBOutlet weak var hadithDesc: UILabel!
    @IBOutlet weak var hadithId: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateDescUI(hadithDescFr:String,hadithIdFr:String!){
        hadithDesc.text = hadithDescFr
        hadithId.text = hadithIdFr
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
