//
//  RankingViewController.swift
//  Team1_QuizApp
//
//  Created by Vuong Vu Bac Son on 9/9/20.
//  Copyright © 2020 Vuong Vu Bac Son. All rights reserved.
//

import UIKit
import FirebaseDatabase

class RankingViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblLoading: UILabel!
    
    @IBOutlet weak var civicEducationView: UIView!
    @IBOutlet weak var geographyView: UIView!
    @IBOutlet weak var historyView: UIView!
    
    @IBOutlet weak var lblGeography: UILabel!
    @IBOutlet weak var lblCivicEducation: UILabel!
    @IBOutlet weak var lblHistory: UILabel!
    
    var refreshControl = UIRefreshControl()
    
    var ref: DatabaseReference!
    var timer = Timer()
    var listRanking: [UserRank] = []
    var listRankingForView: [UserRank] = [UserRank(key: "Default", score: 0, time: 0, username: "Default")]
    var category = "Civic Education"
    var loadingTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.tag = TabbarItemTag.fourthViewConroller.rawValue
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        ref = Database.database().reference()
        
        let civicEducationGesture = UITapGestureRecognizer(target: self, action:  #selector(self.civicEducationClicked))
        self.civicEducationView.addGestureRecognizer(civicEducationGesture)
        
        let geographyGesture = UITapGestureRecognizer(target: self, action:  #selector(self.geographyClicked))
        self.geographyView.addGestureRecognizer(geographyGesture)
        
        let historyGesture = UITapGestureRecognizer(target: self, action:  #selector(self.historyClicked))
        self.historyView.addGestureRecognizer(historyGesture)

        tableView.register(RankViewCell.nib(), forCellReuseIdentifier: RankViewCell.identifier)

        tableView.delegate = self
        tableView.dataSource = self
        
        setupViewBorder(view: civicEducationView)
        setupViewBorder(view: geographyView)
        setupViewBorder(view: historyView)
        
        civicEducationView.backgroundColor = .blue
        lblCivicEducation.textColor = .white
        
        initTableView()
        
        tableView.reloadData()
    }
    
    func initTableView() {
        loading.isHidden = false
        loading.startAnimating()
        lblLoading.isHidden = false
        
        setStateForView(state: true)

        DispatchQueue.main.async {
            self.getListUser(category: self.category)
        }
        
        checkWhenDataIsReady()
        
    }
    
    @objc func refresh(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.getListUser(category: self.category)
        }

        refreshControl.endRefreshing()
    }
    
    func setupViewBorder(view: UIView) {
        view.layer.cornerRadius = 15
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.darkGray.cgColor
        view.clipsToBounds = true
    }
    
    @objc func civicEducationClicked(sender : UITapGestureRecognizer) {
        reInitLoading()
        
        civicEducationView.backgroundColor = .blue
        lblCivicEducation.textColor = .white
        
        geographyView.backgroundColor = .white
        lblGeography.textColor = .black
        
        historyView.backgroundColor = .white
        lblHistory.textColor = .black
        
        self.category = "Civic Education"
        
        initTableView()

    }
    
    @objc func geographyClicked(sender : UITapGestureRecognizer) {
        reInitLoading()
        
        geographyView.backgroundColor = .purple
        lblGeography.textColor = .white
        
        historyView.backgroundColor = .white
        lblHistory.textColor = .black
        
        civicEducationView.backgroundColor = .white
        lblCivicEducation.textColor = .black

        
        self.category = "Geography"
        
        initTableView()
    }
    
    @objc func historyClicked(sender : UITapGestureRecognizer) {
        reInitLoading()
        
        historyView.backgroundColor = .red
        lblHistory.textColor = .white
        
        civicEducationView.backgroundColor = .white
        lblCivicEducation.textColor = .black
        
        geographyView.backgroundColor = .white
        lblGeography.textColor = .black
        
        self.category = "History"
        
        initTableView()
    }
    
    func reInitLoading() {
        lblLoading.text = "Wait for a moment..."
        loadingTime = 0
    }
    
    func setStateForView(state: Bool) {
        tableView.isHidden = state
    }
    
    func checkWhenDataIsReady() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(RankingViewController.setupData)), userInfo: nil, repeats: true)
    }
    @objc func setupData() {
        loadingTime += 1
        
        if loadingTime == 3 {
            lblLoading.text = "No data to show."
            loading.isHidden = true
            loading.stopAnimating()
        }
        
        if listRanking.count != 0 {
            loading.isHidden = true
            loading.stopAnimating()
            lblLoading.isHidden = true
            setStateForView(state: false)
            
            self.listRanking = self.listRanking.sorted{
                a1, a2 in
                return (a1.score, a2.time) > (a2.score, a1.time)
            }
            
            listRankingForView.removeAll()
            listRankingForView = listRanking
            
            tableView.reloadData()
            
            timer.invalidate()
        }
    }
    
    func getListUser(category: String){
        ref.child("PlayHistory").observeSingleEvent(of: .value, with: {
            snapshot in
            for category in snapshot.children {
                let q = UserRank(key: (category as AnyObject).key)
                self.getDataRank(user: q.key, category: self.category)
            }
        })
    }
    
    func getDataRank(user: String, category: String){
        listRanking.removeAll()
        self.ref.child("PlayHistory").child(user).child(category).queryOrdered(byChild: "score").queryLimited(toLast: 1).observe(.value) { snapshot in
            for case let child as DataSnapshot in snapshot.children {
                guard let dict = child.value as? [String: Any] else {
                    return
                }
                
                let score = dict["score"] as! Int
                let time = dict["time"] as! Int
                let username = dict["username"] as! String
                
                let q = UserRank(key: user, score: score, time: time, username: username)
                self.listRanking.append(q)
            }
        }
    }
}

extension RankingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listRankingForView.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RankViewCell.identifier, for: indexPath) as! RankViewCell
        
        var imageName = ""
        if indexPath.row == 0 {
            imageName = "1stplace"
        } else if indexPath.row == 1 {
            imageName = "2ndplace"
        } else if indexPath.row == 2 {
            imageName = "3rdplace"
        } else {
            imageName = "unranked"
        }
        
        cell.configure(imageName: imageName, score: listRankingForView[indexPath.row].score, time: listRankingForView[indexPath.row].time, username: listRankingForView[indexPath.row].username)
        
        return cell
    }
}
