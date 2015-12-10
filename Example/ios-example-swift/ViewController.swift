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
    var data = NSMutableData()
    
    @IBAction func generateKey(sender: AnyObject) {
        pem = BPKeyUtils.generatePem()
        pemText.text = pem
    }
    
    
    @IBAction func generateSin(sender: AnyObject) {
        sin = BPKeyUtils.generateSinFromPem(pem)
        sinText.text = sin
    }
    
    @IBAction func getToken(sender: AnyObject) {
        
        let pairingCode = pairingText.text as String!
        if(pairingCode.isEmpty) {
            tokenText.text = "Please get a pairing code from test.bitpay.com"
            return
        }

        data.setData(NSData())

        NSLog("pairingCode: \(pairingText.text)")
        
        let bp = BPBitPay(name: "BitPay", pem: pem)
        
        bp.host = "https://test.bitpay.com"
        
        do {
            let token = try bp.authorizeClient(pairingCode)
            self.token = token
            tokenText.text = token

        } catch _ {
            NSLog("api error")
            tokenText.text = "api error"
        }
    }
    
    
    @IBAction func testCreateInvoice(sender: AnyObject) {
        
        if(token.isEmpty || pem.isEmpty) {
            tokenText.text = "Please uses steps 2 and 4 before attempting to test the invoice"
            return
        }
        
        data.setData(NSData())
        
        let url = NSURL(string: "https://test.bitpay.com/invoices")
        let request = NSMutableURLRequest(URL: url!)

        
        let pubkey = BPKeyUtils.getPublicKeyFromPem(pem)
        NSLog("public key: \(pubkey)")
        NSLog("private key: \(BPKeyUtils.getPrivateKeyFromPem(pem))")
        
        let postString = "{\"currency\":\"USD\",\"price\":20,\"token\":\"\(token)\"}"
        
        let message = "https://test.bitpay.com/invoices\(postString)"
        
        let signedMessage = BPKeyUtils.sign(message, withPem: pem)

        let bodyData = (postString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        
        request.HTTPBody = bodyData
        request.addValue("2.0.0", forHTTPHeaderField: "x-accept-version")
        request.addValue(pubkey, forHTTPHeaderField: "x-identity")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(signedMessage, forHTTPHeaderField: "x-signature")
        request.HTTPMethod = "POST"
        
        let connection = NSURLConnection(request: request, delegate: self, startImmediately: true)
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
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        self.pairingText.delegate = self
    }

    func dismissKeyboard() {
        view.endEditing(true)
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
        let errorInParsing = "there was an error parsing"
        
        let obj: AnyObject?
        do {
            obj = try NSJSONSerialization.JSONObjectWithData(data,
                        options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            jsonError = error
            obj = nil
        }

        let dta = NSString(data: data, encoding: NSUTF8StringEncoding)
        print("response from server is: \(dta)")
        
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