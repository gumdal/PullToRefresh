//
//  PullToRefreshView.m
//  Grant Paul (chpwn)
//
//  (based on EGORefreshTableHeaderView)
//
//  Created by Devin Doty on 10/14/09October14.
//  Copyright 2009 enormego. All rights reserved.
//
//
// The MIT License (MIT)
// Copyright © 2012 Sonny Parlin, http://sonnyparlin.com
//
// //  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "PullToRefreshView.h"
#import <AudioToolbox/AudioToolbox.h>

#define TEXT_COLOR	 [UIColor colorWithRed:(87.0/255.0) green:(108.0/255.0) blue:(137.0/255.0) alpha:1.0]
#define FLIP_ANIMATION_DURATION 0.18f


@interface PullToRefreshView (Private)

@property (nonatomic, assign) PullToRefreshViewState state;

@end

@implementation PullToRefreshView
@synthesize delegate, scrollView, startingContentInset;

- (void)showActivity:(BOOL)shouldShow animated:(BOOL)animated {
    if (shouldShow) [activityView startAnimating];
    else [activityView stopAnimating];
    
    [UIView animateWithDuration:(animated ? 0.1f : 0.0) animations:^{
        arrowImage.opacity = (shouldShow ? 0.0 : 1.0);
    }];
}

- (void)setImageFlipped:(BOOL)flipped {
    [UIView animateWithDuration:0.1f animations:^{
        arrowImage.transform = (flipped ? CATransform3DMakeRotation(M_PI * 2, 0.0f, 0.0f, 1.0f) : CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f));
    }];
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0.0f, 0.0f - scroll.bounds.size.height, scroll.bounds.size.width, scroll.bounds.size.height);
    NSLog(@"Frame at init = %@", NSStringFromCGRect(frame));
    
    if ((self = [super initWithFrame:frame])) {
        scrollView = scroll;
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
        self.startingContentInset = scrollView.contentInset;
        
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];
        
		lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 30.0f - [self heightOfViewsBelow], self.frame.size.width, 20.0f)];
		[self addSubview:lastUpdatedLabel];
        
		statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, frame.size.height - 48.0f - [self heightOfViewsBelow], self.frame.size.width, 20.0f)];
		[self addSubview:statusLabel];
        
		arrowImage = [[CALayer alloc] init];
		[self.layer addSublayer:arrowImage];
        
        activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self addSubview:activityView];
		
        self.enabled = YES;
//        [self performViewLayouts];
        [self setState:PullToRefreshViewStateNormal];
    }
    
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    [self performViewLayouts];
}

-(void)performViewLayouts
{
    CGRect frame = CGRectMake(0.0f, 0.0f - self.frame.size.height, self.frame.size.width, self.frame.size.height);
    NSLog(@"Frame at layoutSubviews = %@", NSStringFromCGRect(frame));
    NSLog(@"Scroll view content inset at layoutsubviews = %@", NSStringFromUIEdgeInsets(self.scrollView.contentInset));
    lastUpdatedLabel.frame = CGRectMake(0.0f, frame.size.height - 30.0f - [self heightOfViewsBelow], self.frame.size.width, 20.0f);
    lastUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    lastUpdatedLabel.font = [UIFont systemFontOfSize:12.0f];
    lastUpdatedLabel.textColor = TEXT_COLOR;
    lastUpdatedLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    lastUpdatedLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    lastUpdatedLabel.backgroundColor = [UIColor clearColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    lastUpdatedLabel.textAlignment = NSTextAlignmentCenter;
#else
    lastUpdatedLabel.textAlignment = UITextAlignmentCenter;
#endif
    
    statusLabel.frame = CGRectMake(0.0f, frame.size.height - 48.0f - [self heightOfViewsBelow], self.frame.size.width, 20.0f);
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    statusLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    statusLabel.textColor = TEXT_COLOR;
    statusLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    statusLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    statusLabel.backgroundColor = [UIColor clearColor];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    statusLabel.textAlignment = NSTextAlignmentCenter;
#else
    statusLabel.textAlignment = UITextAlignmentCenter;
#endif
    
    arrowImage.frame = CGRectMake(10.0f, frame.size.height - 60.0f - [self heightOfViewsBelow], 24.0f, 52.0f);
    arrowImage.contentsGravity = kCAGravityResizeAspect;
    arrowImage.contents = (id) [UIImage imageNamed:@"arrow"].CGImage;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        arrowImage.contentsScale = [[UIScreen mainScreen] scale];
    }
#endif
    
    activityView.frame = CGRectMake(10.0f, frame.size.height - 38.0f - [self heightOfViewsBelow], 20.0f, 20.0f);
}

#pragma mark -
#pragma mark Setters

- (void)setEnabled:(BOOL)enabled
{
	if (enabled == _enabled)
		return;
	
	_enabled = enabled;
	[UIView animateWithDuration:0.25
                     animations:
	 ^{
		 self.alpha = enabled ? 1 : 0;
	 }];
}

- (void)refreshLastUpdatedDate {
    NSDate *date = [NSDate date];
    
	if ([delegate respondsToSelector:@selector(pullToRefreshViewLastUpdated:)])
		date = [delegate pullToRefreshViewLastUpdated:self];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    lastUpdatedLabel.text = [NSString stringWithFormat:@"Last Updated: %@", [formatter stringFromDate:date]];
}

- (BOOL)setState:(PullToRefreshViewState)state_
{
    BOOL stateConsumed = NO;
    state = [self clearCurrentViewStatesForState:state];
    state = (state | state_);
    if ((state_ & PullToRefreshViewStateReady) != 0)
    {
        stateConsumed = YES;
        statusLabel.text = @"Release to refresh...";
        [self showActivity:NO animated:NO];
        [self setImageFlipped:YES];
        scrollView.contentInset = self.startingContentInset;
    }
    else if ((PullToRefreshViewStateNormal & state_) !=0)
    {
        stateConsumed = YES;
        statusLabel.text = @"Pull down to refresh...";
        [self showActivity:NO animated:NO];
        [self setImageFlipped:NO];
        [self refreshLastUpdatedDate];
        scrollView.contentInset = self.startingContentInset;
    }
    else if ((PullToRefreshViewStateLoading & state_) != 0)
    {
        stateConsumed = YES;
        statusLabel.text = @"Loading...";
        [self showActivity:YES animated:YES];
        [self setImageFlipped:NO];
        scrollView.contentInset = UIEdgeInsetsMake([self topInsetToShowView], 0.0f, 0.0f, 0.0f);
    }
    return stateConsumed;
}

-(PullToRefreshViewState)clearCurrentViewStatesForState:(PullToRefreshViewState)inState
{
    return (inState & ~PullToRefreshViewStateNormal & ~PullToRefreshViewStateLoading & ~PullToRefreshViewStateReady);
}

#pragma mark -
#pragma mark UIScrollView

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"] && self.isEnabled) {
        if (scrollView.isDragging) {
            if ((state & PullToRefreshViewStateReady)!=0) {
                if (scrollView.contentOffset.y > -1*[self offsetCheckToTriggerPullToRefresh] && scrollView.contentOffset.y < 0.0f) {
                    [self setState:PullToRefreshViewStateNormal];
                }
            } else if ((state & PullToRefreshViewStateNormal) !=0) {
                if (scrollView.contentOffset.y < -1*[self offsetCheckToTriggerPullToRefresh]) {
                    [self playSound:@"psst1" withExt:@"wav"];
                    [self setState:PullToRefreshViewStateReady];
                }
            } else if ((state & PullToRefreshViewStateLoading)!=0) {
                if (scrollView.contentOffset.y >= 0) {
                    scrollView.contentInset = self.startingContentInset;
                } else {
                    scrollView.contentInset = UIEdgeInsetsMake(MIN(-scrollView.contentOffset.y, [self topInsetToShowView]), 0, 0, 0);
                }
            }
        } else {
            if ((state & PullToRefreshViewStateReady) !=0 ) {
                [UIView animateWithDuration:0.2f animations:^{
                    [self setState:PullToRefreshViewStateLoading];
                }];
                
                if ([delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)]) {
                    [delegate pullToRefreshViewShouldRefresh:self];
                }
            }
        }
        self.frame = CGRectMake(scrollView.contentOffset.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
//        NSLog(@"Pull to refresh frame = %@", NSStringFromCGRect(self.frame));
//        NSLog(@"Content inset of scroll view = %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
    }
}

- (void)finishedLoading {
    if ((state & PullToRefreshViewStateLoading) !=0 ) {
        [self playSound:@"pop" withExt:@"wav"];
        [UIView animateWithDuration:0.3f animations:^{
            [self setState:PullToRefreshViewStateNormal];
        }];
    }
}

-(void) playSound:(NSString *)fName withExt:(NSString *) ext
{
    SystemSoundID completeSound;
    NSURL *audioPath = [[NSBundle mainBundle] URLForResource:fName withExtension:ext];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)audioPath, &completeSound);
    AudioServicesPlaySystemSound (completeSound);
}

#pragma mark - View config
-(CGFloat)heightOfView
{
//    return 0.0;
    return 60.0f;
}

-(CGFloat)topInsetToShowView
{
    return [self heightOfView] + [self heightOfViewsBelow];
}

-(CGFloat)offsetCheckToTriggerPullToRefresh
{
    return [self topInsetToShowView] + 5.0;
}

-(CGFloat)heightOfViewsBelow
{
    return 0.0; // Top most view return nothing, the height of views below should be declared by subclasses themselves, as they know their own height!
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[scrollView removeObserver:self forKeyPath:@"contentOffset"];
	scrollView = nil;
}

@end
