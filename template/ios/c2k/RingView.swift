//
//  RingView.swift
//  C2k
//
//  Created by Jeff Kingyens on 7/20/16.
//  Copyright © 2016 Jeff Kingyens. All rights reserved.
//

import UIKit
import QuartzCore

// this defines a ring + a count inside the ring
@IBDesignable class RingView: UIView {
    
    // hold a reference to the shape layer
    var ringLayer: CAShapeLayer = CAShapeLayer()
    
    // the fraction of ring to be filled
    @IBInspectable var progress : Double = 0.5 {
        didSet {
            computeAnimation()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        // initialize the superview
        super.init(coder: aDecoder)
        
        sharedInit()
        
    }
    
    override init(frame: CGRect) {
        
        // initialize with the frame
        super.init(frame: frame)
        
        sharedInit()
        
    }
    
    // if tint color changed then redraw
    override func tintColorDidChange() {
        
        ringLayer.strokeColor = tintColor.cgColor
        setNeedsDisplay()
        
    }
    
    // shared initializer for creating a path
    func sharedInit() {
        
        // setup the ring layer and add as sublayer
        ringLayer.strokeColor = tintColor.cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineCap = kCALineCapRound
        ringLayer.position = CGPoint(x: 0, y: 0)
        
        // add this sublayer into the rendering stack
        layer.addSublayer(ringLayer)
        
    }
    
    // based on the difference between the old and the new progress, compute animation
    func computeAnimation() {
        
        // compute the initial + end conditions for the animation
        
        // center of the ring
        let centerX = self.bounds.width/2
        let centerY = self.bounds.height/2
        
        // spacing to the view frame
        let minimal = min(centerX, centerY)
        
        // thickness is a percentage of the screen width
        let thickness = minimal * 0.2
        ringLayer.lineWidth = CGFloat(thickness)
        
        // the radius should be the minimum of the 2 - the width of the stroke
        let radius = minimal - CGFloat(thickness/2)
        
        // build a path that represents the progress over the fixed background circle
        let newPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: CGFloat(Float.pi*3.0)/2.0, endAngle: CGFloat(Float.pi*3.0)/2.0 + CGFloat(Float.pi)*CGFloat(2.0)*CGFloat(progress), clockwise: true)
        
        // if the path already exists, animate the transistion
        if (ringLayer.path != nil) {
            
            // attach an animation to this path so we can watch it change from old state to new state
            let ringAnim = CABasicAnimation(keyPath: "path")
            ringAnim.fromValue = ringLayer.path
            ringAnim.toValue = newPath.cgPath
            ringAnim.duration = 0.15
            
            // initiate the animation
            ringLayer.add(ringAnim, forKey: "path")
            
        }
        
        // always set the new path
        ringLayer.path = newPath.cgPath
        
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    // draw a progress circle
    override func draw(_ rect: CGRect) {
        
        // center of the ring
        let centerX = self.bounds.width/2
        let centerY = self.bounds.height/2
        
        // spacing to the view frame
        let minimal = min(centerX, centerY)
        
        // thickness is a percentage of the screen width
        let thickness = minimal * 0.2
        
        // the radius should be the minimum of the 2 - the width of the stroke
        let radius = minimal - CGFloat(thickness/2)
        
        // paint the dark circle
        let path = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), radius: radius, startAngle: CGFloat(Float.pi*3.0)/2.0, endAngle: CGFloat(Float.pi*3.0)/2.0 + CGFloat(Float.pi * 2.0), clockwise: true)
        path.lineWidth = CGFloat(thickness)
        var sat, hue, bright, alpha : CGFloat
        alpha = CGFloat(0.0)
        hue = CGFloat(0.0)
        sat = CGFloat(0.0)
        bright = CGFloat(0.0)
        tintColor.getHue(&hue, saturation: &sat, brightness: &bright, alpha: &alpha)
        bright = max (bright - CGFloat(0.6), CGFloat(0.0))
        let darkerColor = UIColor(hue: hue, saturation: sat, brightness: bright, alpha: alpha)
        darkerColor.setStroke()
        path.stroke()
        
    }
    
}
