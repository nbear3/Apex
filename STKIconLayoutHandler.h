#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STKConstants.h"

typedef NS_OPTIONS(NSUInteger, STKPositionMask) {
    STKPositionRegular        = 0,
    STKPositionTouchingTop    = 1 << 0,
    STKPositionTouchingBottom = 1 << 1,
    STKPositionTouchingLeft   = 1 << 2,
    STKPositionTouchingRight  = 1 << 3,
    STKPositionDock           = 1 << 4
};

typedef struct {
    NSUInteger xPos;
    NSUInteger yPos;
    NSUInteger index;
} STKIconCoordinates;

#define STKPositionMasksEqual(_a, _b) ( ((a & STKPositionRegular) == (b & STKPositionRegular)) && \
									    ((a & STKPositionTouchingTop) == (b & STKPositionTouchingTop)) && ((a & STKPositionTouchingBottom) == (b & STKPositionTouchingBottom)) && \
									    ((a & STKPositionTouchingLeft) == (b & STKPositionTouchingLeft)) && ((a & STKPositionTouchingRight) == (b & STKPositionTouchingRight)) && \
									    ((a & STKPositionDock) == (b & STKPositionDock)) )

#define STKCoordinatesAreValid(_coords) (_coords.xPos != NSNotFound && _coords.yPos != NSNotFound && _coords.index != NSNotFound)

@class STKIconLayout, SBIcon;
@interface STKIconLayoutHandler : NSObject

// Set the exact position by OR'ing the different values in the enum
// It will just explode in your face if you try to pull crap.
// I mean it.
+ (STKIconLayout *)layoutForIcons:(NSArray *)icons aroundIconAtPosition:(STKPositionMask)position;

+ (BOOL)layout:(STKIconLayout *)layout requiresRelayoutForPosition:(STKPositionMask)position suggestedLayout:(__autoreleasing STKIconLayout **)outLayout;

// Returns an STKIconLayout object whose properties contain SBIcons to be faded out when the new icons are coming in
// This, is plain magic.
+ (STKIconLayout *)layoutForIconsToDisplaceAroundIcon:(SBIcon *)icon usingLayout:(STKIconLayout *)layout;
+ (STKIconCoordinates)coordinatesForIcon:(SBIcon *)icon withOrientation:(UIInterfaceOrientation)orientation;

// Returns a layout containing four id<NSObject> to indicate where the icons would go.
+ (STKIconLayout *)emptyLayoutForIconAtPosition:(STKPositionMask)position;

// Returns a STKIconLayout instance with objects to indicate where there are empty spaces in `layout`
+ (STKIconLayout *)layoutForPlaceHoldersInLayout:(STKIconLayout *)layout withPosition:(STKPositionMask)position;

@end
