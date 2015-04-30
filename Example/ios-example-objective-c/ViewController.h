//
//  ViewController.h
//  ios-sdk-example
//
//  Created by Christopher Kleeschulte on 4/10/15.
//  Copyright (c) 2015 Christopher Kleeschulte. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "keyutils.h"
#import "client.h"

@interface ViewController : UIViewController <UITextFieldDelegate>

- (IBAction)generateKeys:(id)sender;
- (IBAction)generateSin:(id)sender;
- (IBAction)getToken:(id)sender;
- (IBAction)testCreatInvoice:(id)sender;

@property (weak, nonatomic) IBOutlet UITextView *invoiceText;
@property (weak, nonatomic) IBOutlet UITextField *pairText;
@property (weak, nonatomic) IBOutlet UITextView *keyText;
@property (weak, nonatomic) IBOutlet UITextField *sinText;
@property (weak, nonatomic) IBOutlet UITextField *tokenText;


@end

