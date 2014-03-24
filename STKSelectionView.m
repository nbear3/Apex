#import "STKSelectionView.h"
#import "STKConstants.h"
#import "STKSelectionViewCell.h"
#import "STKSelectionHeaderView.h"
#import "STKSelectionTitleTextField.h"
#import <SpringBoard/SpringBoard.h>

#define kCellReuseIdentifier @"STKSelectionViewCell"
#define kHeaderReuseIdentifier @"OMEMGEE!"

@implementation STKSelectionView
{
    UIView *_contentView;
    UICollectionView *_collectionView;
    SBFolderBackgroundView *_backgroundView;
    SBIcon *_selectedIcon;
    SBIcon *_centralIcon;
    SBIconView *_selectedIconView;
    STKSelectionTitleTextField *_searchTextField;

    NSArray *_recommendedApps;
    NSArray *_allApps;
    NSArray *_searchResults;
    BOOL _hasRecommendations;
    BOOL _isSearching;
}

- (instancetype)initWithFrame:(CGRect)frame selectedIcon:(SBIcon *)selectedIcon centralIcon:(SBIcon *)centralIcon
{   
    if ((self = [super initWithFrame:frame])) {
        _selectedIcon = [selectedIcon retain];
        _centralIcon = [centralIcon retain];

        _contentView = [[UIView alloc] initWithFrame:self.bounds];

        UICollectionViewFlowLayout *flowLayout = [[[UICollectionViewFlowLayout alloc] init] autorelease];
        flowLayout.itemSize = [CLASS(SBIconView) defaultIconSize];

        _collectionView = [[[UICollectionView alloc] initWithFrame:_contentView.bounds collectionViewLayout:flowLayout] autorelease];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.layer.cornerRadius = 35.f; // the default corner radius for folders, apparently.
        _collectionView.layer.masksToBounds = YES;
        _collectionView.allowsSelection = YES;
        _collectionView.scrollIndicatorInsets = (UIEdgeInsets){25.f, 0.f, 25.f, 0.f};
        _collectionView.backgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
        _collectionView.bounces = YES;
        _collectionView.alwaysBounceVertical = YES;
        [_collectionView registerClass:[STKSelectionViewCell class] forCellWithReuseIdentifier:kCellReuseIdentifier];
        [_collectionView registerClass:[STKSelectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kHeaderReuseIdentifier];

        _backgroundView = [[CLASS(SBFolderBackgroundView) alloc] initWithFrame:_contentView.frame];
        _backgroundView.center = _collectionView.center;

        [_contentView addSubview:_backgroundView];
        [_contentView addSubview:_collectionView];
        [self addSubview:_contentView];
        [self _setupTextField];
    }
    return self;
}

- (void)dealloc
{
    [_searchResults release];
    [_recommendedApps release];
    [_allApps release];
    [_selectedIcon release];
    [_centralIcon release];
    [_contentView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    _contentView.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
    _collectionView.frame = _backgroundView.frame = _contentView.bounds;
}

- (UIView *)contentView
{
    return _contentView;
}

- (void)setIconsForSelection:(NSArray *)icons
{
    _iconsForSelection = [icons copy];
    [self _processIcons:icons];
    [_collectionView reloadData];
}

- (void)flashScrollIndicators
{
    [_collectionView flashScrollIndicators];
}

- (void)_processIcons:(NSArray *)icons
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    icons = [icons sortedArrayUsingDescriptors:@[sortDescriptor]];

    NSMutableArray *iconsSimilarToSelectedIcon = [NSMutableArray array];
    NSMutableArray *allIcons = [NSMutableArray array];
    NSSet *centralIconGenres = [NSSet setWithArray:[_centralIcon folderTitleOptions]];
    for (SBIcon *icon in icons) {
        if (icon == _centralIcon) continue;

        NSSet *iconGenres = [NSSet setWithArray:[icon folderTitleOptions]];
        if ([centralIconGenres intersectsSet:iconGenres]) {
            // icons with similar title options are to be grouped together
            [iconsSimilarToSelectedIcon addObject:icon];
        }
        [allIcons addObject:icon];
    }

    _hasRecommendations = (iconsSimilarToSelectedIcon.count > 0);
    _recommendedApps = [iconsSimilarToSelectedIcon retain];
    _allApps = [allIcons retain];
}

- (NSArray *)_iconsForSection:(NSInteger)section
{
    if (section == 0) {
        if (_isSearching) return _searchResults;
        if (_hasRecommendations) return _recommendedApps;
        return _allApps;
    }
    if (section == 1) {
        return _allApps;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return ((!_hasRecommendations || _isSearching) ? 1 : 2);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self _iconsForSection:section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    STKSelectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    SBIcon *icon = [self _iconsForSection:indexPath.section][indexPath.item];
    cell.iconView.icon = icon;
    if (cell.iconView.icon == _selectedIcon) {
        [cell.iconView showApexOverlayOfType:STKOverlayTypeEditing];
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    else {
        if ([indexPath compare:[[collectionView indexPathsForSelectedItems] firstObject]] == NSOrderedSame) {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        [cell.iconView removeApexOverlay];
    }
    cell.tapHandler = ^(STKSelectionViewCell *tappedCell) {
        [self _selectedCell:[[tappedCell retain] autorelease]];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return (CGSize){0, 30.f};
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return (UIEdgeInsets){10, 20, 25, 20};
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    STKSelectionHeaderView *view = (STKSelectionHeaderView *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader 
                                                                                                withReuseIdentifier:kHeaderReuseIdentifier
                                                                                                       forIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (_isSearching) {
            view.headerTitle = @"Search Results";
        }
        else if (_hasRecommendations) {
            view.headerTitle = @"Recommendations";
        }
        else {
            view.headerTitle = @"All";
        }
    }
    else {
        view.headerTitle = @"All";
    }
    return view;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)_selectedCell:(STKSelectionViewCell *)cell
{
    NSIndexPath *previousIndexPath = [[_collectionView indexPathsForSelectedItems] firstObject];
    STKSelectionViewCell *previousSelection = (STKSelectionViewCell *)[_collectionView cellForItemAtIndexPath:previousIndexPath];
    [previousSelection.iconView removeApexOverlay];
    [_collectionView deselectItemAtIndexPath:previousIndexPath animated:NO];

    if (_selectedIcon == cell.iconView.icon) {
        _selectedIcon = nil;
        return;
    }
    _selectedIcon = cell.iconView.icon;
    
    NSIndexPath *currentIndexPath = [_collectionView indexPathForCell:cell];
    STKSelectionViewCell *currentSelection = (STKSelectionViewCell *)[_collectionView cellForItemAtIndexPath:currentIndexPath];
    [currentSelection.iconView showApexOverlayOfType:STKOverlayTypeEditing];
    [_collectionView selectItemAtIndexPath:currentIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)_setupTextField
{
    _searchTextField = [[[STKSelectionTitleTextField alloc] initWithFrame:(CGRect){{15.f, 46.f}, {290.f, 40}}] autorelease];
    _searchTextField.delegate = self;
    _searchTextField.attributedPlaceholder = [self _attributedPlaceholderForTextField];
    [_searchTextField addTarget:self action:@selector(_searchTextChanged) forControlEvents:UIControlEventEditingChanged];
    [self addSubview:_searchTextField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.textAlignment = NSTextAlignmentLeft;
    textField.textColor = [UIColor whiteColor];
    textField.attributedPlaceholder = nil;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.textAlignment = NSTextAlignmentCenter;
    textField.textColor = [UIColor whiteColor];
    _searchTextField.attributedPlaceholder = [self _attributedPlaceholderForTextField];
}

- (void)_searchTextChanged
{
    [_searchResults release];
    _searchResults = nil;
    if (_searchTextField.text.length == 0) {
        _isSearching = NO;
        [_collectionView reloadData];
        return;
    }
    _isSearching = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray *searchResults = [NSMutableArray new];
        for (SBIcon *icon in _allApps) {
            if ([[icon displayName] rangeOfString:_searchTextField.text options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)].location != NSNotFound) {
                [searchResults addObject:icon];
            }
        }
        _searchResults = searchResults;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_collectionView reloadData];
        });
    });
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    _isSearching = NO;
    [_searchResults release];
    _searchResults = nil;
    [_collectionView reloadData];
    return YES;
}

- (NSAttributedString *)_attributedPlaceholderForTextField
{
    return [[[NSAttributedString alloc] initWithString:@"Select Sub-App"
                                            attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:24.f],
                                                         NSForegroundColorAttributeName: [UIColor colorWithWhite:1.f alpha:0.5f]}] autorelease];
}

@end
