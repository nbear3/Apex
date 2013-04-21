#import "STKConstants.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBIconListView.h>
#import <SpringBoard/SBRootFolder.h>

#import <objc/runtime.h>


NSString * const STKTweakName = @"Stacks";
NSString * const STKEditingStateChangedNotification = @"STKEditingStateChanged";
NSString * const STKHomescreenWillScrollNotification = @"STKHomescreenWillScrollNotification";

inline double STKScaleNumber(double numToScale, double prevMin, double prevMax, double newMin, double newMax)
{
    double oldRange = (prevMax - prevMin);
    double newRange = (newMax - newMin);
    return (((numToScale - prevMin) * newRange) / oldRange) + newMin;
}

inline double STKAlphaFromDistance(double distance)
{
    // Subtract from 1 to invert the scale
    // Greater the distance, lower the alpha
    double alpha = (STKScaleNumber(distance, 0.0, 85.0, 1.0, 0.0));
    if (alpha < 0.0) {
        alpha = 0.0;
    }
    return alpha;
}

SBIconListView * STKListViewForIcon(SBIcon *icon)
{
    SBIconController *controller = [objc_getClass("SBIconController") sharedInstance];
    
    SBRootFolder *rootFolder = [controller valueForKeyPath:@"rootFolder"];
    NSIndexPath *indexPath = [rootFolder indexPathForIcon:icon];
    
    SBIconListView *listView = nil;
    [controller getListView:&listView folder:NULL relativePath:NULL forIndexPath:indexPath createIfNecessary:YES];

    return listView;
}

NSUInteger STKInfoForSpecifier(uint typeSpecifier)
{
    size_t size = sizeof(int);
    int results;
    int mib[2] = {CTL_HW, typeSpecifier};
    sysctl(mib, 2, &results, &size, NULL, 0);
    return (NSUInteger) results;
}


NSUInteger STKGetCPUFrequency(void)
{
    return STKInfoForSpecifier(HW_CPU_FREQ);
}
