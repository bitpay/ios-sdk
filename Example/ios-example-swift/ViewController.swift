//
//  ViewController.swift
//  ios-example-swift
//
//  Created by chrisk on 4/15/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

import UIKit

class ViewController: UIViewController,  NSURLConnectionDelegate, UITextFieldDelegate {

    @IBOutlet weak var pairingText: UITextField!
    @IBOutlet weak var pemText: UITextView!
    @IBOutlet weak var sinText: UITextField!
    @IBOutlet weak var tokenText: UITextField!
    @IBOutlet weak var invoiceText: UITextView!
    
    var pem = ""
    var key = ""
    var sin = ""
    var token = ""
    var invoice = ""
    var data = NSMutableData.new()
    
    @IBAction func generateKey(sender: AnyObject) {
        pem = BPKeyUtils.generatePem()
        pemText.text = pem
    }
    
    
    @IBAction func generateSin(sender: AnyObject) {
        sin = BPKeyUtils.generateSinFromPem(pem)
        sinText.text = sin
    }
    
    @IBAction func getToken(sender: AnyObject) {
        
        if(pairingText.text.isEmpty) {
            tokenText.text = "Please get a pairing code from test.bitpay.com"
            return
        }

        data.setData(NSData())

        NSLog("pairingCode: \(pairingText.text)")
        
        let bp = BPBitPay(name: "BitPay", pem: pem)
        
        bp.host = "https://test.bitpay.com"
        
        var apiError: NSError?
        var pairingCode = pairingText.text as String
        let token = bp.authorizeClient(pairingCode, error: &apiError)
        
        if token == nil {
            if let error = apiError {
                NSLog("api error")
                tokenText.text = "api error"
            }
        } else {
            self.token = token
            tokenText.text = token
        }
    
    }
    
    
    @IBAction func testCreateInvoice(sender: AnyObject) {
        
        if(token.isEmpty || pem.isEmpty) {
            tokenText.text = "Please uses steps 2 and 4 before attempting to test the invoice"
            return
        }
        
        data.setData(NSData())
        
        var url = NSURL(string: "https://test.bitpay.com/invoices")
        var request = NSMutableURLRequest(URL: url!)

        
        var pubkey = BPKeyUtils.getPublicKeyFromPem(pem)
        NSLog("public key: \(pubkey)")
        NSLog("private key: \(BPKeyUtils.getPrivateKeyFromPem(pem))")
        
        var postString = "{\"currency\":\"USD\",\"price\":20,\"token\":\"\(token)\"}"
        
        var message = "https://test.bitpay.com/invoices\(postString)"
        
        var signedMessage = BPKeyUtils.sign(message, withPem: pem)

        var bodyData = (postString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        
        request.HTTPBody = bodyData
        request.addValue("2.0.0", forHTTPHeaderField: "x-accept-version")
        request.addValue(pubkey, forHTTPHeaderField: "x-identity")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(signedMessage, forHTTPHeaderField: "x-signature")
        request.HTTPMethod = "POST"
        
        var connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
        connection?.start()
        
    }
    
//UITextFieldDelegate Methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
//end

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pairingText.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
//NSURLConnection Delegate Methods
    func connection(connection: NSURLConnection,
        didReceiveData data: NSData!) {
            self.data.appendData(data)
    }
    
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {

        var jsonError: NSError?
        var errorInParsing = "there was an error parsing"
        
        let obj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments,
            error: &jsonError)

        var dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        println("response from server is: \(dta)")
        
        if(jsonError != nil) {
            NSLog(errorInParsing)
            invoiceText.text = errorInParsing
            return
        }
        
        if let root = obj as? NSDictionary {
            if let data = root["data"] as? NSArray {
                if let tokenDictionary = data[0] as? NSDictionary {
                    if let token = tokenDictionary["token"] as? NSString {
                        self.token = token as String
                        tokenText.text = self.token
                    }
                }
            } else {
                //this must be the invoice creation call
                invoiceText.text = root.description as String
            }
            
        }
        
    }
    
    func connection(connection: NSURLConnection, didFinishWithError error: NSErrorPointer) {
        invoiceText.text = "There was an error from the api."
    }

    

}