//
//  PullToRefreshSearchBarView.m
//  Snakes
//
//  Created by Raj Pawan Gumdal on 01/07/13.
//  Copyright (c) 2013 Jagli. All rights reserved.
//

#import "PullToRefreshSearchBarView.h"
@interface PullToRefreshSearchBarView()
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) UIEdgeInsets originalEdgeInsets;
@end

@implementation PullToRefreshSearchBarView
@synthesize searchBar;
@synthesize originalEdgeInsets;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithScrollView:(UIScrollView *)scrollView searchBar:(UISearchBar*)inSearchBar
{
    self = [super initWithScrollView:scrollView];
    if (self)
    {
        self.originalEdgeInsets = self.startingContentInset;
        self.searchBar = inSearchBar;
        [self addSubview:self.searchBar];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    CGRect frame = CGRectMake(0.0f, 0.0f - self.bounds.size.height, self.bounds.size.width, self.bounds.size.height);
    self.searchBar.frame = CGRectMake(0.0, frame.size.height - self.searchBar.frame.size.height, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - View config
-(CGFloat)heightOfViewsBelow
{
    return [self.searchBar frame].size.height; // This value To be used by super
}

#pragma mark - Overridden
#define OFFSET_PULL_FACTOR 3
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"] && self.isEnabled)
    {
        if (self.scrollView.isDragging && ((state & PullToRefreshViewStateNormal) !=0))
        {
//            NSLog(@"Scroll view content offset y = %f", self.scrollView.contentOffset.y);
//            NSLog(@"Height negative of searc bar = %f", -1*[self searchBar].frame.size.height);
            if (self.scrollView.contentOffset.y < -1*[self searchBar].frame.size.height)
            {
//                NSLog(@"Maximized");
                self.startingContentInset = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0.0f, 0.0f, 0.0f);
            }
            else if (self.scrollView.contentOffset.y >= -1*[self searchBar].frame.size.height + OFFSET_PULL_FACTOR)
            {
//                NSLog(@"Minimized");
                self.startingContentInset = self.originalEdgeInsets;
                [UIView animateWithDuration:0.2f animations:^{
                self.scrollView.contentInset = self.startingContentInset;
                }];
            }
        }
        else if ((state & PullToRefreshViewStateNormal) !=0)
        {
            [UIView animateWithDuration:0.2f animations:^{
                self.scrollView.contentInset = self.startingContentInset;
            }];
        }
    }
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
