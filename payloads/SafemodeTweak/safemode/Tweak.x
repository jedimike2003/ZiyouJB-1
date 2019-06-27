%hook SBLockScreenViewControllerBase
-(void)finishUIUnlockFromSource:(int)arg1 {
	%orig(arg1);
	UIAlertView *ac = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"It seems SpringBoard Has Crashed! Neither Substitute, Nor TweakInject Has Caused This Issue! We Reccomend You Delete Any Recently Installed Tweak That May Have Caused This Issue. Would You Like To Respring?" delegate:self cancelButtonTitle:@"Not Yet" otherButtonTitles:@"Respring", nil];
    [ac show];
}
%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        exit(0);
    }
}
%end

%hook SBDashBoardViewController
-(void)finishUIUnlockFromSource:(int)arg1 {
	%orig(arg1);
	UIAlertView *ac = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"It seems SpringBoard Has Crashed! Neither Substitute, Nor TweakInject Has Caused This Issue! We Reccomend You Delete Any Recently Installed Tweak That May Have Caused This Issue. Would You Like To Respring?" delegate:self cancelButtonTitle:@"Not Yet" otherButtonTitles:@"Respring", nil];
    [ac show];
}
%new
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        exit(0);
    }
}
%end