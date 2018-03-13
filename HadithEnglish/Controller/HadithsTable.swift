//
//  HadithsTable.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 3.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

class HadithsTable: UITableViewController,UIActionSheetDelegate {
    

    @IBOutlet var hadithTableDetail: UITableView!
    
    var selectedHadith:Hadith!
    var subjectIndex:Int!
    
    let userData = UserDefaults.standard

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = selectedHadith?.name.trim()
        hadithTableDetail.delegate = self
        hadithTableDetail.dataSource = self
        
        hadithTableDetail.rowHeight = UITableViewAutomaticDimension
        hadithTableDetail.estimatedRowHeight = 300
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "", style: .plain, target: nil, action: nil)

    }
    
    override func tableView(_ hadithTableDetail: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row: \(indexPath.row)")
        
        let indexPath = hadithTableDetail.indexPathForSelectedRow
        let selectedCell = tableView.cellForRow(at: indexPath!) as! hadithDetailCell
        let hadithId = selectedCell.hadithId.text
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Share", style: .default , handler:{ (UIAlertAction)in
            print("User click share button")
        }))
        
        var FavoritesIndexData = self.userData.stringArray(forKey: "FavoriteIndex") ?? [String]()
        
        let indexOfFavorite = FavoritesIndexData.index(of: hadithId!)
        
        if(indexOfFavorite == nil) {
            alert.addAction(UIAlertAction(title: "Add Favorites", style: .destructive , handler:{ (UIAlertAction)in

                FavoritesIndexData.append(hadithId!);
                
                self.userData.set(FavoritesIndexData,forKey:"FavoriteIndex")
            }))
        }else {
            alert.addAction(UIAlertAction(title: "Remove Favorite", style: .destructive , handler:{ (UIAlertAction)in
                
                if let index = FavoritesIndexData.index(of:hadithId!) {
                    FavoritesIndexData.remove(at: index)
                }
                
                self.userData.set(FavoritesIndexData,forKey:"FavoriteIndex")
            }))
        }

        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    

    override func tableView(_ hadithTableDetail: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return selectedHadith!.hadiths.count
    }
    
    override func tableView(_ hadithTableDetail: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ hadithTableDetail: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "HadithDetailCell", for: indexPath) as? hadithDetailCell {
            
            if indexPath.row % 2 == 0 {
                cell.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.1)
            }else{
                cell.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.2)
            }
            
            let hadithSubject = selectedHadith!.hadiths[indexPath.row].hadith.trim()
            let hadithId = String(describing:selectedHadith!.hadiths[indexPath.row].id)
            
            cell.updateDescUI(hadithDescFr: hadithSubject, hadithIdFr: hadithId);
            cell.layoutMargins = UIEdgeInsets.zero
            return cell
        }else {
            return UITableViewCell()
        }
    }
 


}
