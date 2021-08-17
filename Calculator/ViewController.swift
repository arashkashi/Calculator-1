//
//  ViewController.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 17/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import UIKit
import DeviceKit
import Combine

class ViewController: UIViewController {
    
    //MARK: Outlets
    
    @IBOutlet weak var sequence: UILabel!
    @IBOutlet weak var cornerView: UIView!
    @IBOutlet weak var display: UILabel!
    
    
    @IBOutlet weak var plusButton: UIButton!
    
    //MARK: Variables
    
    private var brain = CalculatorBrain()
    private var userIsInTheMiddleOfTyping = false
    
    var iPhoneModel: Device {
        get {
            return Device.current
        }
    }
    
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            let tmp = String(newValue).removeAfterPointIfZero()
            display.text = tmp.setMaxLength(of: 8)
        }
    }
 
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    //MARK: UIVIew Delegate
    
    override func viewDidLoad() {
        
        // round the corners of the calculator on iPhone X
        if iPhoneModel == .iPhoneX || iPhoneModel == .simulator(.iPhoneX){
            cornerView.layer.cornerRadius = 35
            cornerView.layer.masksToBounds = true
        }
        
        NotificationCenter.default.publisher(for: .AsyncOperationStarted).sink { _ in
            self.view.displayAnimatedActivityIndicatorView()
        }.store(in: &bag)
        
        NotificationCenter.default.publisher(for: .AsyncOperationEnded).sink { _ in
            self.view.hideAnimatedActivityIndicatorView()
        }.store(in: &bag)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.plusButton.addGestureRecognizer(longPressRecognizer)
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            self.plusButton.isHidden = true
        }
    }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if event?.subtype == .motionShake {
            self.plusButton.isHidden = false
        }
    }
    
    var bag = Set<AnyCancellable>()
    
    //MARK: IBAction(s)
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            
            if digit == "." && (textCurrentlyInDisplay.range(of: ".") != nil) {
                return
            } else {
                let tmp = textCurrentlyInDisplay + digit
                display.text = tmp.setMaxLength(of: 8)
            }
            
        } else {
            if digit == "." {
                display.text = "0."
            } else {
                display.text = digit
            }
            userIsInTheMiddleOfTyping = true
        }
        
        sequence.text = brain.description
    }
    
    
    
    @IBAction func performOperation(_ sender: UIButton) {
        
        if userIsInTheMiddleOfTyping {
            brain.setOperand(displayValue)
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol) { [weak self] in
                if let result = self?.brain.result {
                    self?.displayValue = result
                }
                
                self?.sequence.text = self?.brain.description
            }
        }
    }
}



extension Notification.Name {
    static var AsyncOperationStarted = Notification.Name("async.operation.started")
    static var AsyncOperationEnded = Notification.Name("async.operation.ended")
}





