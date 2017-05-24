//
//  RingViewController.swift
//  c2k
//
//  Created by Jeff Kingyens on 5/14/17.
//
//


import UIKit
import Foundation
import SystemConfiguration

func isInternetAvailable() -> Bool
{
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }
    
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    return (isReachable && !needsConnection)
}

class RingViewController: UIViewController {
    
    @IBOutlet var ringView : RingView?
    @IBOutlet var progressText : UILabel?
    @IBOutlet var titleText : UILabel?
    @IBOutlet var errorBox : UILabel?
    @IBOutlet var refresh : UITapGestureRecognizer?
    
    var userAct : NSUserActivity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshRing()
        
    }
    
    @IBAction func refreshFromUI(sender:UITapGestureRecognizer){
        refreshRing()
    }
    
    func paintFromPreferences() {
     
        let defaults = UserDefaults.standard
        
        let value = defaults.object(forKey: "value")
        let max = defaults.object(forKey: "max")
        let title = defaults.object(forKey: "title")
        let r = defaults.object(forKey: "red") as! Float
        let g = defaults.object(forKey: "green") as! Float
        let b = defaults.object(forKey: "blue") as! Float
        
        self.ringView?.isHidden = false
        self.progressText?.text = String(describing: value as! NSNumber) + " / " + String(describing: (max as! NSNumber))
        self.titleText?.text = (title as! String)
        self.ringView?.progress = (value as! Double) / (max as! Double)
        self.ringView?.tintColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        self.ringView?.setNeedsDisplay()
        
    }
    
    func refreshRing() {
        
        if (!isInternetAvailable()) {
            let defaults = UserDefaults.standard
            if ((defaults.object(forKey: "timestamp")) != nil) {
                paintFromPreferences()
            } else {
                self.errorBox?.text = "Connection\nError"
                self.errorBox?.isHidden = false
            }
            return
        }
        
        let loginString = String(format: "%@:%@", Config.username, Config.password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        var request = URLRequest(url: URL(string: "http://\(Config.host):\(Config.port)/counter")!)
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        errorBox?.isHidden = true
        ringView?.isHidden = true
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {

                guard let data = data, error == nil else {
                    self.errorBox?.text = "Connection\nError"
                    self.errorBox?.isHidden = false
                    return
                }

                do {
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        
                        if httpStatus.statusCode ==  401 {
                            self.errorBox?.text = "Authentication\nError"
                            self.errorBox?.isHidden = false
                        }
                        return
                    }

                    let counter = try JSONSerialization.jsonObject(with: data, options: []) as AnyObject

                    let defaults = UserDefaults.standard
                    defaults.set(counter["value"] as! NSNumber, forKey: "value")
                    defaults.set(counter["max"] as! NSNumber, forKey: "max")
                    defaults.set(counter["title"] as! String, forKey: "title")
                    let r = (counter["color"] as AnyObject)["r"] as! Float
                    let g = (counter["color"] as AnyObject)["g"] as! Float
                    let b = (counter["color"] as AnyObject)["b"] as! Float
                    defaults.set(r, forKey: "red")
                    defaults.set(g, forKey: "green")
                    defaults.set(b, forKey: "blue")
                    defaults.set(Date(), forKey: "timestamp")
                    
                    self.paintFromPreferences()
                
                } catch {
                    
                }
                
            }
            
        }
        task.resume()
        
    }
    
    // handle device-level rotations
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        self.ringView?.computeAnimation()
        
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            
            self.ringView?.computeAnimation()
            
        }) { (UIViewControllerTransitionCoordinatorContext) in
            
            self.ringView?.computeAnimation()
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.ringView?.computeAnimation()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

