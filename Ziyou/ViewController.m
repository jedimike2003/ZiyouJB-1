//
//  ViewController.m
//  Slice
//
//  Created by Tanay Findley on 5/7/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//

//THIS PROJECT IS IN VERY EARLY STAGES OF DEVELOPMENT!

#import <time.h>
#import "ViewController.h"
#import "utils.h"
#include "ImportantHolders.h"
#include "offsets.h"
#include "remap_tfp_set_hsp.h"
#include "kernel_slide.h"
#include "kernel_exec.h"
#include <mach/host_priv.h>
#include <mach/mach_error.h>
#include <mach/mach_host.h>
#include <mach/mach_port.h>
#include <mach/mach_time.h>
#include <mach/task.h>
#include <mach/thread_act.h>
#include "reboot.h"
#include "SVProgressHUD.h"
#include "machswap.h"




@interface ViewController ()
@end

@implementation ViewController

ViewController *sharedController = nil;


- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    
    
    
    initSettingsIfNotExist();
    if (shouldLoadTweaks())
    {
        [_loadTweakSwitch setOn:true];
    } else {
        [_loadTweakSwitch setOn:false];
    }
    
    //0 = Cydia
    //1 = Zebra
    if (getPackagerType() == 0)
    {
        [_Cydia_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getPackagerType() == 1)
    {
        [_Zebra_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getPackagerType() == 2)
    {
        [_Sileo_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    //0 = MS
    //1 = MS2
    //2 = VS
    if (getExploitType() == 0)
    {
        [_MS1_OUTLET sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 1)
    {
        [_MS2_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    } else if (getExploitType() == 2)
    {
        [_VS_Outlet sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    if (shouldRestoreFS())
    {
        [_restoreFSSwitch setOn:true];
    } else {
        [_restoreFSSwitch setOn:false];
    }
    
    NSLog(@"Starting the jailbreak...");
    sharedController = self;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];

    gradient.frame = self.backGroundView.bounds;
    gradient.colors = @[(id)[[UIColor colorWithRed:0.26 green:0.81 blue:0.64 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.09 green:0.35 blue:0.62 alpha:1.0] CGColor]];
    
    [self.backGroundView.layer insertSublayer:gradient atIndex:0];
}

+ (ViewController *)sharedController {
    return sharedController;
}


- (IBAction)sliceTwitterHandle:(id)sender
{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/sliceteam1"] options:@{} completionHandler:nil];

}

    


/***
 Thanks Conor
 **/
void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat {
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat ? HUGE_VALF : 0;
    
    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)runAnimateGradientOnView:(UIView*)view {
    [UIView animateWithDuration:HUGE_VAL animations:^{
        
    }];
}

- (void)finishOnView:(UIView*)view {
    
    [UIView animateWithDuration:0.5f animations:^{
        [[self sliceLabel] setAlpha:0.0f];
    }];
    
    [UIView animateWithDuration:2.5f animations:^{
        [[self paintBrush] setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
    }];
}

///////////////////////----JELBREK TIEM----////////////////////////////

void logSlice(const char *sliceOfText) {
    //Simple Log Function
    NSString *stringToLog = [NSString stringWithUTF8String:sliceOfText];
    NSLog(@"%@", stringToLog);
}

- (void)updateStatus:(int)statusNum {
    
    runOnMainQueueWithoutDeadlocking(^{
        [UIView transitionWithView:self.buttontext duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbreaking (%d/5)", statusNum] forState:UIControlStateNormal];
        } completion:nil];
    });
    
    
}

- (void)kek {
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbroken"] forState:UIControlStateNormal];
    });
}


//Wen eta bootloop?

bool restore_fs = false;
bool loadTweaks = true;

int exploitType = 0;


//0 = Cydia
//1 = Zebra

int packagerType = 0;

void wannaSliceOfMe() {
    //Run The Exploit
    
    
    runOnMainQueueWithoutDeadlocking(^{
        [sharedController updateStatus:1];
        logSlice("Jailbreaking (1/5)");
        [SVProgressHUD showWithStatus:@"Starting Jailbreak"];
        [sharedController runSpinAnimationOnView:[sharedController paintBrush] duration:1.0f rotations:1.0f repeat:HUGE_VALF];
    });
    
    //INIT. EXPLOIT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] TFP0
    //[*] ROOT
    //[*] UNSANDBOX
    //[*] OFFSETS
    
    [SVProgressHUD showWithStatus:@"Starting Exploit"];
    
    
    //0 = MachSwap
    //1 = MachSwap2
    //2 = Voucher_Swap
    
    runExploit(getExploitType()); //Change this depending on what device you have...
    

    
    
    getOffsets();
    [SVProgressHUD showWithStatus:@"Got Offsets"];
    offs_init();
    
    //MID-POINT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] INIT KEXECUTE
    //[*] REMOUNT //
    //[*] REQUIRED FILES TO FINISH ARE EXTRACTED
    //[*] REMAP
    
    runOnMainQueueWithoutDeadlocking(^{
        [sharedController updateStatus:2];
    });
    
    init_kexecute();
    remountFS(restore_fs);
    createWorkingDir();
    runOnMainQueueWithoutDeadlocking(^{
        [sharedController updateStatus:3];
    });
    [SVProgressHUD showWithStatus:@"Installing Bootstrap"];
    saveOffs();
    setHSP4();
    initInstall(getPackagerType());
    [SVProgressHUD showWithStatus:@"Installed Bootstrap"];

    runOnMainQueueWithoutDeadlocking(^{
        [sharedController updateStatus:4];
    });

    runOnMainQueueWithoutDeadlocking(^{
        [sharedController updateStatus:5];
    });
    
    [SVProgressHUD showWithStatus:@"Finishing up"];
    finish(loadTweaks);
    [SVProgressHUD showSuccessWithStatus:@"Jailbreak Succeeded!"];
    
    
    runOnMainQueueWithoutDeadlocking(^{
        [sharedController finishOnView:[sharedController paintBrush]];
        
        [sharedController kek];
        
    });
    
    
    
    
    
    
}

///////////////////////----BOOTON----////////////////////////////






- (IBAction)Credits:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Credits" message:@"Main Developers\n-\n @BrandonPlank6, @Chr0nicT\n Special Thanks\n @Pwn20wnd" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *THANKS = [UIAlertAction actionWithTitle:@"Thanks!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        [alertController dismissViewControllerAnimated:true completion:nil];
    }];
    [alertController addAction:THANKS];
    [alertController setPreferredAction:THANKS];
    [self presentViewController:alertController animated:false completion:nil];
    
}





- (IBAction)jailbreak:(id)sender {
    
    //HERE
    if (shouldRestoreFS())
    {
        
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"WARNING" message:@"You have selected that you would like to restore your RootFS. This is your LAST chance to back out. Would you like to continue?" preferredStyle:UIAlertControllerStyleAlert];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
            exit(0);
        }]];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action){
            return;
        }]];
        
        [self presentViewController:ac animated:true completion:nil];
        
        restore_fs = true;
    } else {
        restore_fs = false;
    }
    
    if (shouldLoadTweaks())
    {
        loadTweaks = true;
    } else {
        loadTweaks = false;
    }
    
    //Disable The Button
    [sender setEnabled:false];
    
    //Disable and fade out the settings button
    [[self settingsButton] setEnabled:false];
    [UIView animateWithDuration:1.0f animations:^{
        [[self settingsButton] setAlpha:0.0f];
    }];
    
    //Run the exploit in a void.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
       wannaSliceOfMe();
    });
    
    
    runOnMainQueueWithoutDeadlocking(^{
        [self.buttontext setTitle:[NSString stringWithFormat:@"Jailbroken"] forState:UIControlStateNormal];
    });
    

}


///////////////////////----UI STUFF----////////////////////////////
- (IBAction)MS1_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 0);
    
    //color var
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    //button color
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = white;
    self.MS2_Outlet.backgroundColor = purple;
    
    //button label color
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:black forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    
}

- (IBAction)MS2_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 1);
    
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.VS_Outlet.backgroundColor = purple;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = white;
    
    //button label color
    [self.VS_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:black forState:UIControlStateNormal];
}

- (IBAction)VS_ACTION:(UIButton *)sender {
    
    saveCustomSetting(@"ExploitType", 2);
    
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.VS_Outlet.backgroundColor = white;
    self.MS1_OUTLET.backgroundColor = purple;
    self.MS2_Outlet.backgroundColor = purple;
    
    //button label color
    [self.VS_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.MS1_OUTLET setTitleColor:white forState:UIControlStateNormal];
    [self.MS2_Outlet setTitleColor:white forState:UIControlStateNormal];
    
}

- (IBAction)Cydia_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 0);
    
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    
    self.Cydia_Outlet.backgroundColor = white;
    self.Zebra_Outlet.backgroundColor = purple;
    self.Sileo_Outlet.backgroundColor = purple;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:white forState:UIControlStateNormal];
    
}

- (IBAction)Zebra_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 1);
    
    //color var
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    //button color
    self.Cydia_Outlet.backgroundColor = purple;
    self.Zebra_Outlet.backgroundColor = white;
    self.Sileo_Outlet.backgroundColor = purple;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:black forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:white forState:UIControlStateNormal];
}

- (IBAction)Sileo_Button:(UIButton *)sender {
    
    saveCustomSetting(@"PackagerType", 2);
    
    UIColor *purple = [UIColor colorWithRed:0.48 green:0.44 blue:0.83 alpha:1.0];
    UIColor *white = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];;
    UIColor *black = [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.0];;
    
    self.Cydia_Outlet.backgroundColor = purple;
    self.Zebra_Outlet.backgroundColor = purple;
    self.Sileo_Outlet.backgroundColor = white;
    
    //button label color
    [self.Cydia_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Zebra_Outlet setTitleColor:white forState:UIControlStateNormal];
    [self.Sileo_Outlet setTitleColor:black forState:UIControlStateNormal];
}
- (IBAction)Restore_FS_Switch_Action:(UISwitch *)sender {
    if ([sender isOn])
    {
        saveCustomSetting(@"RestoreFS", 0);
    } else {
        saveCustomSetting(@"RestoreFS", 1);
    }
}

- (IBAction)loadTweaksPushed:(id)sender {
    if ([sender isOn])
    {
        saveCustomSetting(@"LoadTweaks", 0);
    } else {
        saveCustomSetting(@"LoadTweaks", 1);
    }
    
}


- (IBAction)dismissSwipe:(UISwipeGestureRecognizer *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)dismissButton:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}




@end
