//
//  RingViewController.swift
//  c2k
//
//  Created by Jeff Kingyens on 5/14/17.
//
//


import UIKit

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
    
    func refreshRing() {
        
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
                    
                    self.ringView?.isHidden = false
                    let counter = try JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                    self.progressText?.text = String(describing: counter["value"] as! NSNumber) + " / " + String(describing: (counter["max"] as! NSNumber))
                    self.titleText?.text = (counter["title"] as! String)
                    self.ringView?.progress = (counter["value"] as! Double) / (counter["max"] as! Double)
                    let r = (counter["color"] as AnyObject)["r"] as! Float
                    let g = (counter["color"] as AnyObject)["g"] as! Float
                    let b = (counter["color"] as AnyObject)["b"] as! Float
                    self.ringView?.tintColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
                    self.ringView?.setNeedsDisplay()

                
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

