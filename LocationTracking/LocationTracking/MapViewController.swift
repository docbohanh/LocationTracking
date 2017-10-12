//
//  MapViewController.swift
//  LocationTracking
//
//  Created by Nguyen Hai Dang on 6/8/17.
//  Copyright © 2017 Nguyen Hai Dang. All rights reserved.
//

import UIKit
import AVFoundation 
import GoogleMaps
import GooglePlaces
import GoogleMobileAds

class MapViewController: OriginalViewController, GMSMapViewDelegate, CLLocationManagerDelegate, GADInterstitialDelegate, GADBannerViewDelegate {

    @IBOutlet weak var addNewLocationNameTextView: UITextView!
    @IBOutlet weak var allowUpdateLocationSwitch: UISwitch!
    @IBOutlet weak var bannerView: GADBannerView!
    var interstitial: GADInterstitial!
    var locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 12.0
    var currentContact: Contact?
    var marker: GMSMarker?

    // An array to hold the list of likely places.
    var likelyPlaces: [GMSPlace] = []
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addLeftBarItem(imageName: "ic_menu",title: "")
        self.addRightBarItem(imageName: "icon_add_user",title: "")
        self.initMapView()
        //Init Ads
        self.initAdsView()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        
        self.getCurrentLocation()
        if currentContact == nil {
            self.addTitleNavigation(title: "Location Tracking")
        } else {
            self.addTitleNavigation(title: (currentContact?.email)!)
        }
        //Real time contact location
        self.referentCurrentContact()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        app_delegate.firebaseObject.removeObServerContact()
    }
    
    func updateLocationAddress(address: String) {
        let titleLabel = self.navigationItem.titleView as! UILabel
        titleLabel.text = address
        titleLabel.font = UIFont.systemFont(ofSize: 14)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Init View
    //Init MapView
    func initMapView() {
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized {
            // Already Authorized
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    // User granted
                } else {
                    return
                    // User Rejected
                }
            })
        }
        let camera = GMSCameraPosition.camera(withLatitude:0.0,
                                              longitude:0.0,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height - bannerView.frame.size.height), camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        view.bringSubview(toFront: allowUpdateLocationSwitch)
        view.bringSubview(toFront: addNewLocationNameTextView)
    }
    
    //Init Location
    func getCurrentLocation() {
        locationManager.delegate = self
        placesClient = GMSPlacesClient.shared()
        locationManager.requestWhenInUseAuthorization()
        if #available(iOS 9.0, *) {
            locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let latitude  = locationManager.location != nil ? locationManager.location!.coordinate.latitude : 0
        let longitude = locationManager.location != nil ? locationManager.location!.coordinate.longitude : 0

        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: zoomLevel)
        mapView.camera = camera
        if allowUpdateLocationSwitch.isOn {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
    }
    
    //Init Banner View
    func initAdsView() {
        bannerView.adUnitID = kBannerAdUnitId;
        bannerView.rootViewController = self;
        bannerView.delegate = self
        bannerView.adSize = kGADAdSizeSmartBannerPortrait
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        bannerView.load(request)
        self.interstitial = createAndLoadInterstitial()
    }
    
    // MARK: - Update Location
    //Update when contact changed location
    func referentCurrentContact() {
        app_delegate.firebaseObject.referentToContact(onCompletionHandler: {_ in
            let visibleViewController: UIViewController = Common.getVisibleViewController(UIApplication.shared.keyWindow?.rootViewController)!
            if visibleViewController.isKind(of:KYDrawerController.self) {
                let drawerController = visibleViewController as! KYDrawerController
                if drawerController.drawerState == .closed {
                    //MapViewController
                    let mapNavigationViewController = drawerController.mainViewController as! UINavigationController
                    if let mapViewController = mapNavigationViewController.viewControllers.last {
                        if mapViewController is MapViewController {
                            let mapVC = mapViewController as! MapViewController
                            mapVC.updateMarker()
                        }
                    }
                }
            }
        })
    }

    // MARK: - Init Interstitial
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: kInterstitialAdUnitID)
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return GADInterstitial() //interstitial
    }
    
    func showInterstitialAds() {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("[Admob] Ad wasn't ready!")
        }
    }
    
    func updateMarker() {
        if (currentContact != nil) {
            mapView.clear()
            let position = CLLocationCoordinate2DMake((currentContact?.latitude)!,(currentContact?.longitude)!)
            marker = GMSMarker(position: position)
            marker?.title = currentContact?.email
            marker?.map = mapView
            let newCamera = GMSCameraPosition.camera(withLatitude: (currentContact?.latitude)!, longitude: (currentContact?.longitude)!, zoom: self.mapView.camera.zoom)
            mapView.camera = newCamera
            Common.convertToAddress(latitude: (currentContact?.latitude)!, longitude: (currentContact?.longitude)!, onCompletionHandler: {address in
                self.updateLocationAddress(address: address)
            })
        }
    }
    
// MARK: - GMSMapViewDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Get current location
        let lastLocation = locations.last!
        if currentLocation.coordinate.latitude != lastLocation.coordinate.latitude || currentLocation.coordinate.longitude != lastLocation.coordinate.longitude {
            //Update current location
            currentLocation = locations.last!
            
            //Update location
            guard let profile = app_delegate.profile else { return }
            app_delegate.firebaseObject.updateLocation(id:profile.id!, lat: currentLocation.coordinate.latitude, long:currentLocation.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
    }
    
    func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
//        addNewLocationNameTextView.isHidden = false
    }
    
    //MARK: - Banner Admob Delegate
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    //MARK: - Interstitial Delegate
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
        
        // [Admob] Init Interstal ads
        interstitial = createAndLoadInterstitial()
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        print("interstitialDidDismissScreen")
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
    
    //MARK: - Action
    override func tappedLeftBarButton(sender: UIButton) {
        //Show Menu friends list
        if let drawerController = self.parent?.parent as? KYDrawerController {
            drawerController.setDrawerState(.opened, animated: true)
        }
    }
    
    override func tappedRightBarButton(sender: UIButton) {
        //Add new contact
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        let addContactViewController = main_storyboard.instantiateViewController(withIdentifier: "AddContactViewController") as! AddContactViewController
        self.navigationController?.pushViewController(addContactViewController, animated: true)
    }
    
    @IBAction func tappedAllowUpdateLocation(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
            view.makeToast("Shared your location to friends", duration: 2, position: .center)
        } else {
            locationManager.stopUpdatingLocation()
            view.makeToast("Stoped sharing your location to friends", duration: 2, position: .center)
        }
    }
}
