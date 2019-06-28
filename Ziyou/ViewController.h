//
//  ViewController.h
//  Slice
//
//  Created by Tanay Findley on 5/7/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SVProgressHUD.h>

@interface ViewController : UIViewController

@property (readonly) ViewController *sharedController;
+ (ViewController*)sharedController;

@property (strong, nonatomic) IBOutlet UIView *backGroundView;
@property (strong, nonatomic) IBOutlet UILabel *sliceLabel;
@property (strong, nonatomic) IBOutlet UIImageView *paintBrush;
@property (strong, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIImageView *settings_buttun_bg;
@property (weak, nonatomic) IBOutlet UIButton *buttontext;
@property (weak, nonatomic) IBOutlet UIImageView *jailbreakButtonBackground;
@property (weak, nonatomic) IBOutlet UIView *credits_view;
@property (strong, nonatomic) IBOutlet UISwitch *restoreFSSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *loadTweakSwitch;


//-------UI STUFF--------//

//SWITCH FUNCTIONS
- (IBAction)Restore_FS_Switch_Action:(UISwitch *)sender;

//THE EXPLOIT BUTTONS outlet
@property (weak, nonatomic) IBOutlet UIButton *VS_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *MS1_OUTLET;
@property (weak, nonatomic) IBOutlet UIButton *MS2_Outlet;

//the exploit buttons action

- (IBAction)MS1_ACTION:(UIButton *)sender;
- (IBAction)MS2_ACTION:(UIButton *)sender;
- (IBAction)VS_ACTION:(UIButton *)sender;

//THE PACKAGE MANAGER BUTTONS outlet
@property (weak, nonatomic) IBOutlet UIButton *Cydia_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *Zebra_Outlet;
@property (weak, nonatomic) IBOutlet UIButton *Sileo_Outlet;

//the package manager buttons action
- (IBAction)Cydia_Button:(UIButton *)sender;
- (IBAction)Zebra_Button:(UIButton *)sender;
- (IBAction)Sileo_Button:(UIButton *)sender;


@end

static inline void showAlertWithCancel(NSString *title, NSString *message, Boolean wait, Boolean destructive, NSString *cancel) {
    dispatch_semaphore_t semaphore;
    if (wait)
        semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ViewController *controller = [ViewController sharedController];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *OK = [UIAlertAction actionWithTitle:@"Okay" style:destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (wait)
                dispatch_semaphore_signal(semaphore);
        }];
        [alertController addAction:OK];
        [alertController setPreferredAction:OK];
        if (cancel) {
            UIAlertAction *abort = [UIAlertAction actionWithTitle:cancel style:destructive ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (wait)
                    dispatch_semaphore_signal(semaphore);
            }];
            [alertController addAction:abort];
            [alertController setPreferredAction:abort];
        }
        [controller presentViewController:alertController animated:YES completion:nil];
    });
    if (wait)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


static inline void showAlert(NSString *title, NSString *message, Boolean wait, Boolean destructive) {
    [SVProgressHUD dismiss];//have to include it
    showAlertWithCancel(title, message, wait, destructive, nil);
}


