//
//  CreateTagViewController.h
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-23.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreateTagViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UITextField *tagTextField;

- (IBAction)createTag:(id)sender;

@end
