//
//  ACRChoiceSetViewDataSource.mm
//  ACRChoiceSetViewDataSource
//
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "ACRChoiceSetViewDataSource.h"
#import "ACOBundle.h"
#import "ACRInputLabelView.h"
#import "ACRInputTableView.h"
#import "UtiliOS.h"
#import <Foundation/Foundation.h>

using namespace AdaptiveCards;

NSString *checkedCheckboxReuseID = @"checked-checkbox";
NSString *uncheckedCheckboxReuseID = @"unchecked-checkbox";
NSString *checkedRadioButtonReuseID = @"checked-radiobutton";
NSString *uncheckedRadioButtonReuseID = @"unchecked-radiobutton";

const CGFloat padding = 8.0f;
const CGFloat minimumRowHeight = 44.0;

@implementation ACRChoiceSetCell {
    CGSize _imageSize;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImage *iconImage = nil;
        if ([reuseIdentifier isEqualToString:@"checked-checkbox"]) {
            iconImage = [UIImage systemImageNamed:@"checkmark.square"];
        } else if ([reuseIdentifier isEqualToString:@"checked-radiobutton"]) {
            iconImage = [UIImage systemImageNamed:@"record.circle"];
        } else if ([reuseIdentifier isEqualToString:@"unchecked-checkbox"]) {
            iconImage = [UIImage systemImageNamed:@"square"];
        } else if ([reuseIdentifier isEqualToString:@"unchecked-radiobutton"]) {
            iconImage = [UIImage systemImageNamed:@"circle"];
        }

        if (iconImage) {
            self.imageView.image = iconImage;
        }
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.adjustsFontSizeToFitWidth = NO;
        self.backgroundColor = UIColor.clearColor;
        _imageSize = iconImage.size;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.imageView.image) {
        self.imageView.frame = CGRectMake(0, 0, _imageSize.width, _imageSize.height);
        self.imageView.center = CGPointMake(_imageSize.width / 2, self.bounds.size.height / 2);
        self.textLabel.frame = CGRectMake(_imageSize.width + padding, 0, self.bounds.size.width - _imageSize.width - padding, self.bounds.size.height);
    }
}

@end

@implementation ACRChoiceSetViewDataSource {
    std::shared_ptr<ChoiceSetInput> _choiceSetDataSource;
    NSMutableDictionary *_userSelections;
    // used for radio button; keep tracking of the current choice
    NSIndexPath *_currentSelectedIndexPath;
    NSMutableSet *_defaultValuesSet;
    NSArray *_defaultValuesArray;
    BOOL _shouldWrap;
    std::shared_ptr<HostConfig> _config;
    CGSize _contentSize;
    NSString *_accessibilityString;
    NSMutableArray<CompletionHandler> *_completionHandlers;
}

- (instancetype)initWithInputChoiceSet:(std::shared_ptr<AdaptiveCards::ChoiceSetInput> const &)choiceSet WithHostConfig:(std::shared_ptr<AdaptiveCards::HostConfig> const &)hostConfig
{
    self = [super init];
    if (self) {
        self.id = [[NSString alloc] initWithCString:choiceSet->GetId().c_str()
                                           encoding:NSUTF8StringEncoding];
        _isMultiChoicesAllowed = choiceSet->GetIsMultiSelect();
        _choiceSetDataSource = choiceSet;
        _shouldWrap = choiceSet->GetWrap();
        _userSelections = [[NSMutableDictionary alloc] init];
        _currentSelectedIndexPath = nil;
        _config = hostConfig;
        _parentStyle = ACRContainerStyle::ACRNone;
        self.isRequired = choiceSet->GetIsRequired();
        
        NSString *defaultValues = [NSString stringWithCString:_choiceSetDataSource->GetValue().c_str()
                                                     encoding:NSUTF8StringEncoding];
        _defaultValuesArray = [defaultValues componentsSeparatedByCharactersInSet:
                                                 [NSCharacterSet characterSetWithCharactersInString:@","]];

        if (_isMultiChoicesAllowed || [_defaultValuesArray count] == 1) {
            _defaultValuesSet = [NSMutableSet setWithArray:_defaultValuesArray];
        }

        NSUInteger index = 0;
        for (const auto &choice : _choiceSetDataSource->GetChoices()) {
            NSString *keyForDefaultValue = [NSString stringWithCString:choice->GetValue().c_str()
                                                              encoding:NSUTF8StringEncoding];

            if ([_defaultValuesSet containsObject:keyForDefaultValue]) {
                _userSelections[[NSNumber numberWithInteger:index]] = [NSNumber numberWithBool:YES];
            }
            ++index;
        }
        
        self.hasValidationProperties = self.isRequired;
        _completionHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

// ChoiceSetView is a parent view that leads to child view that handles input selection
// so the size is always 1 when there are more than one choices
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (_choiceSetDataSource->GetChoices().size());
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPathInternal:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    if (_userSelections[[NSNumber numberWithInteger:indexPath.row]] == [NSNumber numberWithBool:YES]) {
        if (_isMultiChoicesAllowed) {
            cell = [tableView dequeueReusableCellWithIdentifier:checkedCheckboxReuseID];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:checkedRadioButtonReuseID];
        }
        cell.accessibilityTraits |= UIAccessibilityTraitSelected;
    } else {
        if (_isMultiChoicesAllowed) {
            cell = [tableView dequeueReusableCellWithIdentifier:uncheckedCheckboxReuseID];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:uncheckedRadioButtonReuseID];
        }
        cell.accessibilityTraits &= ~UIAccessibilityTraitSelected;
    }

    NSString *title = [NSString stringWithCString:_choiceSetDataSource->GetChoices()[indexPath.row]->GetTitle().c_str()
                                         encoding:NSUTF8StringEncoding];
    cell.textLabel.text = title;
    cell.textLabel.numberOfLines = _choiceSetDataSource->GetWrap() ? 0 : 1;
    cell.textLabel.textColor = getForegroundUIColorFromAdaptiveAttribute(_config, _parentStyle);
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)configureCellForAccsessibility:(UITableViewCell *)cell tableView:(UITableView *)tableView
{
    NSString *accessibilityLabel = ([tableView isKindOfClass:[ACRInputTableView class]]) ? ((ACRInputTableView *)tableView).adaptiveAccessibilityLabel : tableView.accessibilityLabel;
    _accessibilityString = accessibilityLabel ? accessibilityLabel : @"";
    cell.accessibilityTraits = cell.accessibilityTraits;
    
    // If required field voice over should call it out as required.
    if (isRequired)
    {
        cell.accessibilityLabel = [NSString stringWithFormat:@"%@ %@, %@, %@", _accessibilityString, @"(Required)", cell.textLabel.text, _isMultiChoicesAllowed ? @"check box" : @"radio button"];
        cell.accessibilityLabel = [cell.accessibilityLabel stringByReplacingOccurrencesOfString:@"*" withString:@""];
    }
    else
    {
        cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@", _accessibilityString, cell.textLabel.text, _isMultiChoicesAllowed ? @"check box" : @"radio button"];
    }
    
    cell.accessibilityHint = NSLocalizedString(@"double tap to select", nil);

    NSString *elementId = [NSString stringWithCString:_choiceSetDataSource->GetId().c_str()
                                             encoding:NSUTF8StringEncoding];
    cell.textLabel.accessibilityIdentifier = [NSString stringWithFormat:@"%@, %@", elementId, cell.textLabel.text];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPathInternal:indexPath];
    [self configureCellForAccsessibility:cell tableView:tableView];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // update the current selection
    if ([_userSelections count] &&
        [_userSelections objectForKey:[NSNumber numberWithInteger:indexPath.row]] &&
        [[_userSelections objectForKey:[NSNumber numberWithInteger:indexPath.row]] boolValue] == YES) {
        _currentSelectedIndexPath = indexPath;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *indexPathsToUpdate = [NSMutableArray arrayWithObject:indexPath];
    if (!_isMultiChoicesAllowed) {
        if (_currentSelectedIndexPath && _currentSelectedIndexPath != indexPath) {
            // deselect currently selected index path
            [indexPathsToUpdate addObject:_currentSelectedIndexPath];
            [self tableView:tableView didDeselectRowAtIndexPath:_currentSelectedIndexPath];
        }
        _userSelections[[NSNumber numberWithInteger:indexPath.row]] = [NSNumber numberWithBool:YES];

    } else {
        if ([_userSelections[[NSNumber numberWithInteger:indexPath.row]] boolValue]) {
            _userSelections[[NSNumber numberWithInteger:indexPath.row]] = [NSNumber numberWithBool:NO];
        } else {
            _userSelections[[NSNumber numberWithInteger:indexPath.row]] = [NSNumber numberWithBool:YES];
        }
    }
    [self notifyDelegates];
    [tableView reloadData];
    _currentSelectedIndexPath = indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // uncheck selection if multi choice is not allowed
    if (!_isMultiChoicesAllowed) {
        _userSelections[[NSNumber numberWithInteger:indexPath.row]] = [NSNumber numberWithBool:NO];
        _currentSelectedIndexPath = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPathInternal:indexPath];
    NSString *textString = nil;

    if (!_shouldWrap) {
        textString = @"A";
    } else {
        textString = cell.textLabel.text;
    }

    if (_contentSize.width == 0 && tableView.contentSize.width && tableView.frame.size.height) {
        _contentSize = tableView.contentSize;
        [tableView invalidateIntrinsicContentSize];
    }

    CGSize labelStringSize =
        [textString boundingRectWithSize:CGSizeMake(tableView.contentSize.width - [self getNonInputWidth:cell], CGFLOAT_MAX)
                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                              attributes:@{NSFontAttributeName : cell.textLabel.font}
                                 context:nil]
            .size;
    
    CGFloat rowHeight = labelStringSize.height + _spacing;
    
    return (rowHeight < minimumRowHeight) ? minimumRowHeight : rowHeight;
}

- (void)addObserverWithCompletion:(CompletionHandler)completion {
    [_completionHandlers addObject:completion];
}

- (void)notifyDelegates {
    for(CompletionHandler completion in _completionHandlers) {
        completion();
    }
}

- (BOOL)validate:(NSError * __autoreleasing *)error
{
    if (self.isRequired) {
        if (_isMultiChoicesAllowed) {
            for (id key in _userSelections) {
                if ([_userSelections[key] boolValue]) {
                    return YES;
                }
            }
            return NO;
        }
        return _userSelections.count > 0 ? YES : NO;
    }

    return YES;
}

- (void)getDefaultInput:(NSMutableDictionary *)dictionary
{
    dictionary[self.id] = [_defaultValuesArray componentsJoinedByString:@","];
}

- (void)getInput:(NSMutableDictionary *)dictionary
{
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [_userSelections keyEnumerator];
    NSNumber *key;
    while (key = [enumerator nextObject]) {
        if ([_userSelections[key] boolValue] == YES) {
            [values addObject:
                        [NSString stringWithCString:_choiceSetDataSource->GetChoices()[[key integerValue]]->GetValue().c_str()
                                           encoding:NSUTF8StringEncoding]];
        }
    }
    dictionary[self.id] = [values componentsJoinedByString:@","];
}

- (void)setFocus:(BOOL)shouldBecomeFirstResponder view:(UIView *)view
{
    if (shouldBecomeFirstResponder) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, view);
        [ACRInputLabelView commonSetFocus:shouldBecomeFirstResponder view:view];
    }
}

- (void)resetInput {
    [_userSelections removeAllObjects];
    NSUInteger index = 0;
    for (const auto &choice : _choiceSetDataSource->GetChoices()) {
        NSString *keyForDefaultValue = [NSString stringWithCString:choice->GetValue().c_str()
                                                          encoding:NSUTF8StringEncoding];

        if ([_defaultValuesSet containsObject:keyForDefaultValue]) {
            _userSelections[[NSNumber numberWithInteger:index]] = [NSNumber numberWithBool:YES];
        }
        ++index;
    }
    [_tableView reloadData];
}

- (NSString *)getTitlesOfChoices
{
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [_userSelections keyEnumerator];
    NSNumber *key;
    while (key = [enumerator nextObject]) {
        if ([_userSelections[key] boolValue] == YES) {
            [values addObject:
                        [NSString stringWithCString:_choiceSetDataSource->GetChoices()[[key integerValue]]->GetTitle().c_str()
                                           encoding:NSUTF8StringEncoding]];
        }
    }
    if ([values count] == 0) {
        return nil;
    }
    return [values componentsJoinedByString:@", "];
}

- (float)getNonInputWidth:(UITableViewCell *)cell
{
    return padding * 2 + cell.imageView.image.size.width;
}

@synthesize isRequired;
@synthesize hasValidationProperties;
@synthesize hasVisibilityChanged;

@end
