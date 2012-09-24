//
//  CreateTagViewController.m
//  Drift
//
//  Created by Mikael Hultgren on 2012-09-23.
//  Copyright (c) 2012 Artsoftheinsane. All rights reserved.
//

#import "CreateTagViewController.h"
#import "Tag.h"
#import "NSManagedObject+ActiveRecord.h"
#import "UIViewController+KNSemiModal.h"

@interface CreateTagViewController ()

@end

@implementation CreateTagViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)createTag:(id)sender {
    NSString *value = [self.tagTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (value.length != 0) {
        NSArray *tags = [Tag where:@{ @"name" : value }];
        if (tags.count == 0) {
            Tag *tag = [Tag create];
            tag.name = value;

            [[CoreDataManager instance] saveContext];

            // Here's how to call dismiss button on the parent ViewController
            // be careful with view hierarchy
            UIViewController * parent = [self.view containingViewController];
            if ([parent respondsToSelector:@selector(dismissSemiModalView)]) {
                [parent dismissSemiModalView];
            }
        }
    }
}

@end
