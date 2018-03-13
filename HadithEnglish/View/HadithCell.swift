//
//  HadithCell.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 2.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

class HadithCell: UITableViewCell {

    
    @IBOutlet weak var HadithSubject: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateUI(hadithSubject:String?){
        HadithSubject.text = hadithSubject
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
