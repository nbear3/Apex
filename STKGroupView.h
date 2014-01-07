#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STKConstants.h"

typedef NS_ENUM(NSInteger, STKActivationMode) {
	STKActivationModeSwipeUp,
	STKActivationModeSwipeDown,
	STKActivationModeSwipeUpAndDown,
	STKActivationModeDoubleTap
};

@protocol STKGroupViewDelegate;
@class SBIconView, STKGroup;
@interface STKGroupView : UIView <UIGestureRecognizerDelegate>

- (instancetype)initWithGroup:(STKGroup *)group;

- (void)open;
- (void)close;

@property (nonatomic, retain) STKGroup *group;
@property (nonatomic, readonly) BOOL isOpen;
@property (nonatomic, assign) STKActivationMode activationMode;
@property (nonatomic, assign) id<STKGroupViewDelegate> delegate;

@end

@protocol STKGroupViewDelegate

@required 
- (BOOL)groupViewShouldOpen:(STKGroupView *)groupView;

@optional
- (void)groupViewWillOpen:(STKGroupView *)groupView;
- (void)groupViewDidOpen:(STKGroupView *)groupView;
- (void)groupViewWillClose:(STKGroupView *)groupView;
- (void)groupViewDidClose:(STKGroupView *)groupView;
@end
