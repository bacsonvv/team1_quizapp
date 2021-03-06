//
//  HomeViewController.swift
//  Team1_QuizApp
//
//  Created by Nguyen Thi Huong on 9/3/20.
//  Copyright © 2020 Vuong Vu Bac Son. All rights reserved.
//
import UIKit
import FirebaseCore
import FirebaseDatabase
import GoogleSignIn

class CategoryViewController: UIViewController {
    
    @IBOutlet weak var categoryTableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var lblLoading: UILabel!
    
    var refreshControl = UIRefreshControl()

    var timer = Timer()
    let cellID = "CategoryTableViewCell"
    var listCollection = ["Default", "Default", "Default"]
    var ref = Database.database().reference()
    var spreadSheetId = "1urSOD9SR3lSD7WE1SF0CqKRa7c1INR9I-iMqQgwsKvM"
    var user = ""
    var id = ""
    var timeLimit = 0
    var numberOfQuestions = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.tag = TabbarItemTag.secondViewConroller.rawValue
        
        refreshControl.attributedTitle = NSAttributedString(string: "Reload data")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        categoryTableView.addSubview(refreshControl)
        
        id = UserDefaults.standard.string(forKey: "idUser") ?? "Undefined"
        user = UserDefaults.standard.string(forKey: "username") ?? "Undefined"
        timeLimit = UserDefaults.standard.integer(forKey: "timeLimit")
        numberOfQuestions = UserDefaults.standard.integer(forKey: "numberOfQuestions")

        categoryTableView.delegate = self
        categoryTableView.dataSource = self
        
        setStateForView(state: true)
        
        loading.isHidden = false
        lblLoading.isHidden = false
        loading.startAnimating()
        
        DispatchQueue.main.async {
            self.GetListCategory()
        }
        
        checkWhenDataIsReady()
        
        categoryTableView.reloadData()
        
        initComponent()
    }
    
    func checkWhenDataIsReady() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(CategoryViewController.setupData)), userInfo: nil, repeats: true)
    }
    
    @objc func setupData() {
        if listCollection.count != 0 {
            loading.isHidden = true
            lblLoading.isHidden = true
            loading.stopAnimating()
            
            setStateForView(state: false)
            
            timer.invalidate()
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        DispatchQueue.main.async {
            self.GetListCategory()
        }
        
        refreshControl.endRefreshing()
    }
    
    func setStateForView(state: Bool) {
        categoryTableView.isHidden = state
    }
    
    fileprivate func initComponent() {
        categoryTableView.register(UINib(nibName: "CategoryTableViewCell", bundle: nil), forCellReuseIdentifier: cellID)
    }
    
    func showDialog() {
        let alert = UIAlertController(title: "No category selected ", message: "Please pick any item to continue", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
        }
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    func GetListCategory(){
        self.listCollection.removeAll()
        ref.child(spreadSheetId).observe(.value, with: {
            snapshot in
            for category in snapshot.children {
                self.listCollection.append((category as AnyObject).key)
            }
            self.categoryTableView.reloadData()
        })
    }
}


extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listCollection.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = categoryTableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! CategoryTableViewCell
        cell.lblCategory.text = listCollection[indexPath.row]
        cell.nameCategory = listCollection[indexPath.row]
        
        if cell.lblCategory.text == "Geography" {
            cell.lblTime.textColor = .white
            cell.lblNumberOfQuestion.textColor = .white
        }

        cell.imageCategory.image = UIImage(named: listCollection[indexPath.row])
        cell.lblTime.text = "Time: \(timeLimit)"
        cell.lblNumberOfQuestion.text = "Questions: \(numberOfQuestions)"
        cell.delegate  = self

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190
    }
}

extension CategoryViewController : CategoryDelegate {
    func didTapButton(with: String, nameCat: String) {
        if with == "see" {
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "listQVC") as! ListQuestionViewController
            vc.category = nameCat
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "gameVC") as! GameViewController
            vc.category = nameCat
            vc.username = self.user
            vc.userId = self.id
            self.navigationController?.pushViewController(vc, animated: false)
        }
    }
}
