//
//  ViewController.swift
//  AcceptBitcoin
//
//  Created by chrisk on 12/11/15.
//  Copyright © 2015 bitpay. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var errorText: UITextView!
    /*
    Directions for getting a valid token from BitPay without using any crypto functions whatsoever
    Step 1: Log in to either https://test.bitpay.com -or- https://bitpay.com depending on whether you would like to be on testnet or livenet
    Step 2: Click "Payment Tools" and then "Manage API Tokens"
    Step 3: Click "Add New Token", uncheck "Require Authentication" and then click "Add Token"
    Step 4: copy the token from the bitpay website into the constant "token" below. Security notice: This token can be hard-coded in your apps because the only permissions it has (if you followed steps 1-4 above) is that invoices can be created. Refunds and other information gathering is not permitted.
    */
    let token = "put a valid token here!"
    let DEBUG = true //test bitpay using bitcoin testnet or real money bitpay using live bitcoins?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func testCreateInvoice(sender: AnyObject) {
        
        let url = DEBUG ? NSURL(string: "https://test.bitpay.com/invoices") :
        NSURL(string: "https://bitpay.com/invoices")
        
        let request = NSMutableURLRequest(URL: url!)
        
        //please see https://bitpay.com/docs/create-invoice for more info
        let postString = "{\"currency\":\"USD\",\"price\":1.00,\"token\":\"\(token)\"}"
        
        let bodyData = (postString as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        
        request.HTTPBody = bodyData
        request.addValue("2.0.0", forHTTPHeaderField: "x-accept-version")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.HTTPMethod = "POST"
        
        processResults(request){(res, error) -> Void in
            if error != nil {
                if let err = error {
                    print(err)
                    self.errorText.text = err
                }
            } else {
                var jsonError: NSError?
                let errorInParsing = "there was an error parsing"
        
                let obj: AnyObject?
                let data = res.dataUsingEncoding(NSUTF8StringEncoding)
                do {
                    obj = try NSJSONSerialization.JSONObjectWithData(data!,
                        options: NSJSONReadingOptions.AllowFragments)
                } catch let error as NSError {
                    //this is probably the BitPay API not working correctly
                    jsonError = error
                    obj = nil
                }
        
                print("response from server is: \(res)")
        
                if(jsonError != nil) {
                    NSLog(errorInParsing)
                    return
                }
        
                if let root = obj as? NSDictionary {
                    if let invoice = root["data"] {
                        if let paymentUrls = invoice["paymentUrls"] as? NSDictionary {
                            if let bip72String = paymentUrls["BIP72"] {
                                /* This should bring up Copay or whatever can handle the URL Scheme of bitcoin:? the last installed app that registered the custom URL scheme as 'bitcoin' will respond to openURL. This is most likely a bitcoin wallet. Could be Copay, Mycelium, whatever. Be sure to specify in Info.plist the key 'LSApplicationQueriesSchemes' with an array value of 'bitcoin'. This is NEW for iOS 9. See this app's Info.plist for exactly what that looks like. The JSON response to create the invoice includes 'paymentUrls' that bitcoin wallets will respond to and use. BIP21 (bitcoin improvement proposal) and BIP72 are the most common. Most recent bitcoin wallets will handle those formats very nicely. Since Apple started letting bitcoin apps back in the app store semi-recently, most of the iOS bitcoin wallets should be covered. Once the payment is made and the user taps 'return to <appname>' you should query the BIP73 invoice url to confirm that the invoice is confirmed */
                                let bip72 = NSURL(string: bip72String as! String)
                                if UIApplication.sharedApplication().canOpenURL(bip72!) {
                                    UIApplication.sharedApplication().openURL(bip72!)
                                }
                            } else
                            {
                                print("The \"BIP72b\" key from invoice is nil.")
                            }
                        } else {
                            print("The \"paymentUrls\" key from invoice is nil.")
                        }
                    } else {
                        print("The invoice does not have a data key.")
                    }
                }

            }
        }
    }
    
    
    func processResults(request: NSURLRequest!, callback:(String, String?) -> Void) {
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error != nil {
                callback("", error!.localizedDescription)
            } else {
                let result = NSString(data: data!, encoding:
                    NSASCIIStringEncoding)!
                callback(result as String, nil)
            }
        }
        task.resume()
        
    }

}

