#import "STKPreferences.h"
#import "STKConstants.h"
#import "STKStackManager.h"

#import <SpringBoard/SpringBoard.h>
#import <objc/runtime.h>

#define kLastEraseDateKey @"LastEraseDate"

@interface STKPreferences ()
{
    NSDictionary *_currentPrefs;
    NSArray      *_layouts;
    NSArray      *_iconsInStacks;
    NSSet        *_iconsWithStacks;
}

- (void)_refreshGroupedIcons;

@end

@implementation STKPreferences

+ (NSString *)layoutsDirectory
{
    return [NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%@/Layouts", kSTKTweakName];
}

+ (instancetype)sharedPreferences
{
    static id sharedInstance;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];

        [[NSFileManager defaultManager] createDirectoryAtPath:[self layoutsDirectory] withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions : @511} error:NULL];
        [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions : @511} ofItemAtPath:[self layoutsDirectory] error:NULL]; // Make sure the permissions are correct anyway

        [sharedInstance reloadPreferences];
    });

    return sharedInstance;
}

- (void)reloadPreferences
{
    [_currentPrefs release];

    _currentPrefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
    if (!_currentPrefs) {
        _currentPrefs = [[NSDictionary alloc] init];
        [_currentPrefs writeToFile:kPrefPath atomically:YES];
    }

    [_layouts release];
    _layouts = nil;
    
    [_iconsInStacks release];
    _iconsInStacks = nil;

    [_iconsWithStacks release];
    _iconsWithStacks = nil;
}

- (NSSet *)identifiersForIconsWithStack
{
    static NSString * const fileType = @".layout";
    if (!_iconsWithStacks) {
        if (!_layouts) {
            _layouts = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self class] layoutsDirectory] error:nil] retain];
        }

        NSMutableSet *identifiersSet = [[[NSMutableSet alloc] initWithCapacity:_layouts.count] autorelease];

        for (NSString *layout in _layouts) {
            if ([layout hasSuffix:fileType]) {
                [identifiersSet addObject:[layout substringToIndex:(layout.length - fileType.length)]];
            }
        }

        _iconsWithStacks = [[NSSet alloc] initWithSet:identifiersSet];
    }
    return _iconsWithStacks;
}

- (NSArray *)stackIconsForIcon:(SBIcon *)icon
{
    SBIconModel *model = [(SBIconController *)[objc_getClass("SBIconController") sharedInstance] model];

    NSDictionary *attributes = [NSDictionary dictionaryWithContentsOfFile:[self layoutPathForIcon:icon]];
    
    if (!attributes) {
        return nil;
    }

    NSMutableArray *stackIcons = [NSMutableArray arrayWithCapacity:(((NSArray *)attributes[STKStackManagerStackIconsKey]).count)];
    for (NSString *identifier in attributes[STKStackManagerStackIconsKey]) {
        // Get the SBIcon instances for the identifiers
        SBIcon *icon = [model expectedIconForDisplayIdentifier:identifier];
        if (icon) {
            [stackIcons addObject:[model expectedIconForDisplayIdentifier:identifier]];
        }
    }
    return stackIcons;
}


- (NSString *)layoutPathForIconID:(NSString *)iconID
{
    return [NSString stringWithFormat:@"%@/%@.layout", [[self class] layoutsDirectory], iconID];
}

- (NSString *)layoutPathForIcon:(SBIcon *)icon
{
    return [self layoutPathForIconID:icon.leafIdentifier];
}

- (BOOL)iconHasStack:(SBIcon *)icon
{
    return (icon == nil ? NO : [[self identifiersForIconsWithStack] containsObject:icon.leafIdentifier]);
}

- (BOOL)iconIsInStack:(SBIcon *)icon
{
    if (!_iconsInStacks) {
        [self _refreshGroupedIcons];
    }

    return [_iconsInStacks containsObject:icon.leafIdentifier];
}

- (BOOL)removeLayoutForIcon:(SBIcon *)icon
{
    return [self removeLayoutForIconID:icon.leafIdentifier];
}

- (BOOL)removeLayoutForIconID:(NSString *)iconID
{
    NSError *err = nil;
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:[self layoutPathForIconID:iconID] error:&err];
    if (err) {
        NSLog(@"%@ An error occurred when trying to remove layout for %@. Error %i, %@", kSTKTweakName, iconID, err.code, err);
    }

    [self reloadPreferences];
    
    return ret;
}

- (void)_refreshGroupedIcons
{
    [_iconsInStacks release];

    NSMutableArray *groupedIcons = [NSMutableArray array];
    NSSet *identifiers = [self identifiersForIconsWithStack];
    for (NSString *identifier in identifiers) {
        SBIcon *centralIcon = [[(SBIconController *)[objc_getClass("SBIconController") sharedInstance] model] expectedIconForDisplayIdentifier:identifier];
        [groupedIcons addObjectsFromArray:[(NSArray *)[self stackIconsForIcon:centralIcon] valueForKeyPath:@"leafIdentifier"]];
    }

    _iconsInStacks = [groupedIcons copy];
}

@end
