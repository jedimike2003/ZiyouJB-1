//
//  ViewController.m
//  Ziyou
//
//  Created by Tanay Findley on 5/7/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
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
#include "machswap.h"




@interface ViewController ()
@end

@implementation ViewController

ViewController *sharedController = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    
    
    
    
    initSettingsIfNotExist();
    
    
    NSLog(@"Starting the jailbreak...");
    sharedController = self;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];

    gradient.frame = self.backGroundView.bounds;
    gradient.colors = @[(id)[[UIColor colorWithRed:0.26 green:0.81 blue:0.64 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:0.09 green:0.35 blue:0.62 alpha:1.0] CGColor]];
    
    [self.backGroundView.layer insertSublayer:gradient atIndex:0];
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/.jailbroken_ziyou"])
    {
        [[self buttontext] setEnabled:false];
    }
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

- (void)updateStatus:(NSString*)statusNum {
    
    runOnMainQueueWithoutDeadlocking(^{
        [UIView transitionWithView:self.buttontext duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.buttontext setTitle:statusNum forState:UIControlStateNormal];
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
bool setNonceBool = false;
int exploitType = 0;


//0 = Cydia
//1 = Zebra

int packagerType = 0;


void wannaSliceOfMe() {
    //Run The Exploit
    
    
    runOnMainQueueWithoutDeadlocking(^{
        logSlice("Jailbreaking");});
    
    //INIT. EXPLOIT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] TFP0
    //[*] ROOT
    //[*] UNSANDBOX
    //[*] OFFSETS
    
    
    //0 = MachSwap
    //1 = MachSwap2
    //2 = Voucher_Swap
    //3 = SockPuppet
    
    runExploit(getExploitType()); //Change this depending on what device you have...
    

    
    
    getOffsets();
    offs_init();
    
    //MID-POINT. HERE WE ACHIEVE THE FOLLOWING:
    //[*] INIT KEXECUTE
    //[*] REMOUNT //
    //[*] REQUIRED FILES TO FINISH ARE EXTRACTED
    //[*] REMAP
    
    init_kexecute();
    
    remountFS(restore_fs);
    
    createWorkingDir();
    saveOffs();
    setHSP4();
    initInstall(getPackagerType());
    
    term_kexecute();
    
    finish(loadTweaks);
    
    
    
    
    
    
    
    
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
        restore_fs = true;
        saveCustomSetting(@"RestoreFS", 1);
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
}







@end
