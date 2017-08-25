//
//  ContactViewController.swift
//  LocationTracking
//
//  Created by Nguyen Hai Dang on 6/15/17.
//  Copyright © 2017 Nguyen Hai Dang. All rights reserved.
//

import UIKit

class ContactViewController : OriginalViewController,UITableViewDelegate,UITableViewDataSource,ContactTableViewCellDelegate {

    @IBOutlet weak var segmented: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    var contactArray = [Contact]()
    var currentIndex = kContactListIndex
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addTitleNavigation(title: "Contacts")
        self.initView()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        self.refreshContactData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Init Object
    func initView() {
        self.addLeftBarItem(imageName: "ic_logout", title: "")
        self.addRightBarItem(imageName: "refresh", title: "")
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
    }
    
    //MARK: - Data
    
    func refreshContactData() {
        switch segmented.selectedSegmentIndex {
        case kContactListIndex:
            contactArray.removeAll()
            contactArray += DatabaseManager.getContactSharedLocation(contetxt: nil)
            tableView.reloadData()
            break
        default:
            contactArray.removeAll()
            contactArray += DatabaseManager.getRequestToMeContact(contetxt: nil)
            tableView.reloadData()
            break
        }
    }
    //MARK: - Action
    @IBAction func tappedChangeSegmentedIndex(_ sender: UISegmentedControl) {
        //Only reload when current index != selected index
        if currentIndex != sender.selectedSegmentIndex {
            currentIndex = sender.selectedSegmentIndex
            self.refreshContactData()
        }
    }
    
    override func tappedLeftBarButton(sender: UIButton) {
        let result = app_delegate.firebaseObject.signOut()
        if result {
            //Sign out is success
            if let drawerController = self.parent?.parent as? KYDrawerController {
                drawerController .dismiss(animated: true, completion: nil)
            }
        } else {
            //Sign out is failure
        }
    }
    
    //Refresh contact from server
    override func tappedRightBarButton(sender: UIButton) {
        self.showHUD()
        let profile = DatabaseManager.getProfile()
        app_delegate.firebaseObject.refreshData(email: (profile?.email)!, completionHandler: {isSuccess in
            self.hideHUD()
            self.refreshContactData()
        })
    }
    
    //MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.showHUD()
            let contact = contactArray[indexPath.row]
            app_delegate.firebaseObject.deleteContact(contactId: contact.id!, atUserId: (app_delegate.profile?.id)!, onCompletionHandler: {_ in
                tableView.beginUpdates()
                self.contactArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .none);
                tableView.endUpdates()
                self.hideHUD()
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell") as! ContactTableViewCell
        cell.setupCell(contact: contactArray[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Show Map View
        if let drawerController = self.parent?.parent as? KYDrawerController {
            drawerController.setDrawerState(.closed, animated: true)
            let mapNavigationViewController = drawerController.mainViewController as! UINavigationController
            let mapViewController = mapNavigationViewController.viewControllers.last as! MapViewController
            mapViewController.currentContact = contactArray[indexPath.row]
            //Add observer when changed contact
            mapViewController.updateMarker()
        }
    }
    
    //MARK: - ContactTableViewCell Delegate
    func requestLocation(contact: Contact) {
        self .showHUD()
        app_delegate.firebaseObject.requestLocation(toContact: contact, onCompletetionHandler: {_ in
            DatabaseManager.updateContact(id: contact.id!, latitude: contact.latitude, longitude: contact.longitude, isShare: ShareStatus.kwaitingShared.rawValue, onCompletion: {_ in
                self.hideHUD()
                self.tableView.reloadData()
            })
        })
    }
    
    func shareLocation(contact: Contact) {
        self .showHUD()
        app_delegate.firebaseObject.shareLocation(toContact: contact, onCompletetionHandler: {_ in
            DatabaseManager.updateContact(id: contact.id!, latitude: contact.latitude, longitude: contact.longitude, isShare: ShareStatus.kShared.rawValue, onCompletion: {_ in
                self.tableView.reloadData()
                self.segmented.selectedSegmentIndex = kContactListIndex
                self.hideHUD()
            })
        })
    }
}
