//
//  ViewController.swift
//  HadithEnglish
//
//  Created by Burak Öztırpan on 2.03.2018.
//  Copyright © 2018 Burak Öztırpan. All rights reserved.
//

import UIKit

extension String
{
    func trim() -> String
    {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    

    
    var hadithList = [Hadith]()
    @IBOutlet weak var hadithTableView: UITableView!
    
    func tableView(_ hadithTableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hadithList.count
    }
    
    func tableView(_ hadithTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if let cell = hadithTableView.dequeueReusableCell(withIdentifier: "HadithCell", for: indexPath) as? HadithCell {
            
            let hadithSubject = hadithList[indexPath.row].name.trim()
            cell.updateUI(hadithSubject: hadithSubject);
            cell.layoutMargins = UIEdgeInsets.zero
            return cell
        }else {
            return UITableViewCell()
        }
        
    }
    
    
    
     func tableView(hadithTableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegue(withIdentifier: "showHadiths", sender: self)
     }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? HadithsTable {
            destination.selectedHadith = hadithList[(hadithTableView.indexPathForSelectedRow?.row)!]
            destination.subjectIndex = hadithTableView.indexPathForSelectedRow?.row
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hadithTableView.layoutMargins = UIEdgeInsets.zero
        hadithTableView.separatorInset = UIEdgeInsets.zero
        
        hadithTableView.delegate = self
        hadithTableView.dataSource = self
        
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
        
        let hadithJson = loadJson(filename:"newHadithJson")
        
        hadithJson?.forEach { hadith in
            hadithList.append(hadith)
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }


}

