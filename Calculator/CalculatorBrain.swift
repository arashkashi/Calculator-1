//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Andrea Vultaggio on 17/10/2017.
//  Copyright © 2017 Andrea Vultaggio. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    //MARK: Variables
    
    private var accumulator: Double?
    private var pendingBinaryOperation: PendingBinaryOperation?
    private var resultIsPending = false
    
    var description = ""
    var result: Double? { get { return accumulator } }
    
    //MARK: Enumerations
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double)
        case binaryOperation((Double, Double) -> Double)
        case bitcoinOperation(Double)
        case result
    }
    
    private var operations: Dictionary<String, Operation> = [
        "＋" : .binaryOperation({ $0 + $1 }),
        "﹣" : .binaryOperation({ $0 - $1 }),
        "×" : .binaryOperation({ $0 * $1 }),
        "÷" : .binaryOperation({ $0 / $1 }),
        "₿" : .bitcoinOperation(0),
        "cos" : .unaryOperation({ cos($0) }),
        "sin" : .unaryOperation({ sin($0) }),
        "AC": .constant(0),
        "=" : .result
    ]
    
    //MARK: Embedded struct
    
    private struct PendingBinaryOperation {
        let function: (Double, Double) -> Double
        let firstOperand: Double
        
        func perform(with secondOperand: Double) -> Double {
            return function(firstOperand, secondOperand)
        }
    }
    
    //MARK: Functions
    
    private func performPendingBinaryOperation() {
        if pendingBinaryOperation != nil && accumulator != nil {
            accumulator = pendingBinaryOperation?.perform(with: accumulator!)
            pendingBinaryOperation = nil
            resultIsPending = false
        }
    }
    
    func getBitcoinValue(input: Double, comp: @escaping (Double) -> Void) {
        // TODO: for now just increase by two
    }
    
    func performOperation(_ symbol: String, comp: @escaping () -> ()) {
        if let operation = operations[symbol] {
            switch operation {
            case .bitcoinOperation(_):
                // TODO: Make the calcular keypad disabled
                NotificationCenter.default.post(name: .AsyncOperationStarted, object: nil)
                NetworkService.shared.sendRequest(with: URLRequest.bitcoinRequest()
                                                  , model: BitcoinResponse.self) { [weak self] result in
                    NotificationCenter.default.post(name: .AsyncOperationEnded, object: nil)
                    
                    switch result {
                    case .fail(let error):
                        // TODO: Handle grafefully
                        print(error.localizedDescription)
                        break
                    case .success(let result):
                        self?.accumulator = result.bpi["USD"]?.rate_float ?? 666.6
                    }
                    comp()
                }
                break
            case .constant(let value):
                accumulator = value
                description = ""
            case .unaryOperation(let function):
                if accumulator != nil {
                    let value = String(describing: accumulator!).removeAfterPointIfZero()
                    description = symbol + "(" + value.setMaxLength(of: 5) + ")" + "="
                    accumulator = function(accumulator!)
                }
            case .binaryOperation(let function):
                performPendingBinaryOperation()
                
                if accumulator != nil {
                    if description.last == "=" {
                        description = String(describing: accumulator!).removeAfterPointIfZero().setMaxLength(of: 5) + symbol
                    } else {
                        description += symbol
                    }
                    
                    pendingBinaryOperation = PendingBinaryOperation(function: function, firstOperand: accumulator!)
                    resultIsPending = true
                    accumulator = nil
                }
            case .result:
                performPendingBinaryOperation()
                
                if !resultIsPending {
                    description += "="
                }
            }
            
            switch operation {
            case .bitcoinOperation(_):
                break
            default:
                comp()
            }
        }
    }
    
    func setOperand(_ operand: Double?) {
        accumulator = operand ?? 0.0
        if !resultIsPending {
            description = String(describing: operand!).removeAfterPointIfZero().setMaxLength(of: 5)
        } else {
            description += String(describing: operand!).removeAfterPointIfZero().setMaxLength(of: 5)
        }
    }
}
