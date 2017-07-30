//
//  FriendListTableViewCell.swift
//  LocationTracking
//
//  Created by Nguyen Hai Dang on 6/17/17.
//  Copyright © 2017 Nguyen Hai Dang. All rights reserved.
//

import UIKit

protocol ContactTableViewCellDelegate {
    func requestLocation(contact: Contact)
    func shareLocation(contact: Contact)
}
class ContactTableViewCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var shareLocationButton: UIButton!
    @IBOutlet weak var requestLocationButton: UIButton!
    var contactObject: Contact?
    
    var delegate: ContactTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    //MARK: - Action
    @IBAction func tappedRequestLocation(_ sender: UIButton) {
        if contactObject != nil {
            delegate?.requestLocation(contact: contactObject!)
        }
    }
    
    @IBAction func tappedShareLocation(_ sender: UIButton) {
        if contactObject != nil {
            delegate?.shareLocation(contact: contactObject!)
        }
    }
    
    //MARK: - Setup Cell
    func setupCell(contact:Contact) {
        contactObject = contact
        userNameLabel.text = contact.email
        statusLabel.text = "lat:" + String(contact.latitude) + "long:" + String(contact.longitude)
        currentLocationLabel.text = String(contact.latitude)
        
        if contact.isShare == Int16(ShareStatus.kShared.rawValue) {
            //Shared location
            requestLocationButton.isHidden = true
            shareLocationButton.isHidden = true
            currentLocationLabel.isHidden = false
            currentLocationLabel.text = "lat:" + String(contact.latitude) + "long:" + String(contact.longitude)
        } else if contact.isShare == Int16(ShareStatus.kwaitingShared.rawValue) {
            //Shared location
            requestLocationButton.isHidden = true
            shareLocationButton.isHidden = true
            currentLocationLabel.isHidden = false
            currentLocationLabel.text = "waiting to share location"
        } else if contact.isShare == Int16(ShareStatus.kRequestShare.rawValue) {
            //Users request share location
            requestLocationButton.isHidden = true
            currentLocationLabel.isHidden = true
            shareLocationButton.isHidden = false
        } else if contact.isShare == Int16(ShareStatus.kNotYetShared.rawValue) {
            //Users request share location
            requestLocationButton.isHidden = false
            shareLocationButton.isHidden = true
            currentLocationLabel.isHidden = true
        }
    }
}
