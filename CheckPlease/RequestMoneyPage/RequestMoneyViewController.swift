//
//  RequestMoneyViewController.swift
//  CheckPlease
//
//  Created by Tony Cioara on 9/5/18.
//  Copyright © 2018 Tony Cioara. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class RequestMoneyViewController: UIViewController {
 //        TODO: Add search by name and email
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        
    }
    
    init(items: [ReceiptItem], delegate: RequestMoneyDelegate) {
        
        self.receiptItems = items
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //    MARK: - Private
    
    private var delegate: RequestMoneyDelegate!
//  Change this to users once connected to the backend.
    
    private let users = DataSource.users
    private var filteredUsers = [User]()
    
    private var receiptItems: [ReceiptItem]
    private var selectedPath: IndexPath?
    
    private let searchController : UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
//        searchController.searchBar.keyboardType = .numberPad
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Name, e-mail, phone"
        searchController.definesPresentationContext = true
        searchController.searchBar.returnKeyType = .send
        return searchController
    }()
    
    private let tableView = UITableView()
    private let requestTableViewCellId = "requestTableViewCellId"
    private let requestPhoneNumberCellId = "requestPhoneNumberCellId"
    
    private func addSubviews() {
        [tableView].forEach { (view) in
            self.view.addSubview(view)
        }
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.right.bottom.equalToSuperview()
        }
    }
    
    private func setUpViews() {
        self.title = "Request"
        self.view.backgroundColor = AppColors.white
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        addSubviews()
        setConstraints()
        setUpTableView()
    }
    
    private func setUpTableView() {
        tableView.register(RequestTableViewCell.self, forCellReuseIdentifier: requestTableViewCellId)
        tableView.register(RequestPhoneNumberTableViewCell.self, forCellReuseIdentifier: requestPhoneNumberCellId)
        tableView.separatorStyle = .none
        
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func displayAlert(user: User?, phoneNumber: String?) {
        var message = "Items: "
        var title = ""
        for index in 0..<receiptItems.count {
            let item = receiptItems[index]
            if index == receiptItems.count - 1 {
                message.append(item.name)
            } else {
                message.append("\(item.name), ")
            }
            
        }
        if let user = user {
            title = "Request \(user.firstName) \(user.lastName)"
        } else if let phoneNumber = phoneNumber {
            title = "Request \(phoneNumber)"
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (action) in
            //            TODO: Perform networking request here
            self.delegate.confirmButtonPressed()
            self.searchController.isActive = false
            self.navigationController?.popViewController(animated: true)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            if let path = self.selectedPath {
                self.tableView.deselectRow(at: path, animated: true)
            }
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        if searchController.isActive {
            searchController.present(alertController, animated: true, completion: nil)
        } else {
            self.present(alertController, animated: true, completion: nil)
        }
//        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
    
}

extension RequestMoneyViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltering() {
            if isPhoneNumber() && filteredUsers.count == 0 {
                return 1
            }
            return filteredUsers.count
        }
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isFiltering() && isPhoneNumber() && filteredUsers.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: requestPhoneNumberCellId, for: indexPath) as! RequestPhoneNumberTableViewCell
            if let phoneNumber = self.searchController.searchBar.text {
                cell.setUp(phoneNumber: phoneNumber)
            }
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: requestTableViewCellId, for: indexPath) as! RequestTableViewCell
        if isFiltering() {
            cell.setUp(user: filteredUsers[indexPath.row])
        } else {
            cell.setUp(user: users[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedPath = indexPath
        
        if isFiltering() && filteredUsers.count == 0 {
            if isPhoneNumber() {
                if var phoneNumber = searchController.searchBar.text {
                    phoneNumber.formatPhoneNumber()
                    self.displayAlert(user: nil, phoneNumber: phoneNumber)
                }
            }
        } else {
            var selectedUser: User
            if isFiltering() {
                selectedUser = filteredUsers[indexPath.row]
            } else {
                selectedUser = users[indexPath.row]
            }
            displayAlert(user: selectedUser, phoneNumber: nil)
            
        }
        
//        searchController.isActive = false
        
        
    }
}

extension RequestMoneyViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {return}
        filterContentWhenSearching(searchText: text)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if isPhoneNumber() {
            if var phoneNumber = searchBar.text {
                phoneNumber.formatPhoneNumber()
                self.displayAlert(user: nil, phoneNumber: phoneNumber)
            }
        }
        
        searchBar.resignFirstResponder()
    }
    
    //    MARK: - Private
    
    private func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    private func filterContentWhenSearching(searchText: String, scope: String = "All") {
        filteredUsers = users.filter({ (user) -> Bool in
            if user.firstName.contains(searchText) ||
                    user.lastName.contains(searchText) ||
                    user.email.contains(searchText) ||
                    user.phoneNumber.contains(searchText) {
                return true
            }
            return false
        })
        
        tableView.reloadData()
    }
    
    private func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    private func isPhoneNumber() -> Bool {
        if let _ = Int(searchController.searchBar.text!) {
            return true
        }
        return false
    }
    
}
