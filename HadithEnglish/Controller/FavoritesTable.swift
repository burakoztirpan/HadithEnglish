//
//  HadithsTable.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 3.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

class FavoritesTable: UITableViewController,UIActionSheetDelegate {
    

    @IBOutlet var favoriteTableDetail: UITableView!    
    let userData = UserDefaults.standard
    var favoriteList = [simpleHadith]()
    var hadithJson = [Hadith]()
    
    func loadTable () {
        favoriteList = []
        let FavoritesIndexData = self.userData.stringArray(forKey: "FavoriteIndex") ?? [String]()
        
        hadithJson.forEach { hadith in
            hadith.hadiths.forEach { hadithM in
                
                let hadithId = String(describing:hadithM.id)
                let indexOfFavorite = FavoritesIndexData.index(of: hadithId)
                
                if indexOfFavorite != nil {
                    favoriteList.append(hadithM)
                }
                
            }
        }
        
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadTable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Favorites"
        
        func loadJson(filename fileName: String) -> [Hadith]? {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let jsonData = try decoder.decode([Hadith].self, from: data)
                    return jsonData
                } catch {
                    print("error:\(error)")
                }
            }
            return nil
        }
        
        self.hadithJson = loadJson(filename:"newHadithJson")!

        favoriteTableDetail.rowHeight = UITableViewAutomaticDimension
        favoriteTableDetail.estimatedRowHeight = 300

        
    }
    
    
    override func tableView(_ favoriteTableDetail: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return favoriteList.count
    }
    
    override func tableView(_ favoriteTableDetail: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ favoriteTableDetail: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as? FavoriteCell {
            
            if indexPath.row % 2 == 0 {
                cell.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.1)
            }else{
                cell.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.2)
            }
            
            let hadithSubject = favoriteList[indexPath.row].hadith.trim()
            let hadithId = String(describing:favoriteList[indexPath.row].id)
            
            cell.updateFavoriteDescUI(favorite: hadithSubject,favoriteId: hadithId);
            cell.layoutMargins = UIEdgeInsets.zero
            return cell
            
            
            
        }else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ favoriteTableDetail: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row: \(indexPath.row)")
        
        let indexPath = favoriteTableDetail.indexPathForSelectedRow
        let selectedCell = tableView.cellForRow(at: indexPath!) as! FavoriteCell
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
                self.loadTable()
            }))
        }
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
        
    }
    
}

