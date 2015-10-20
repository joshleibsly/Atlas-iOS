//
//  ATLConversationDataSource.m
//  Atlas
//
//  Created by Kevin Coleman on 2/4/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
#import "ATLConversationDataSource.h"

@interface ATLConversationDataSource ()

@property (nonatomic) LYRClient *layerClient;
@property (nonatomic, readwrite) LYRQueryController *queryController;
@property (nonatomic, readwrite) BOOL expandingPaginationWindow;

@end

@implementation ATLConversationDataSource

+ (instancetype)dataSourceWithLayerClient:(LYRClient *)layerClient query:(LYRQuery *)query
{
    return [[self alloc] initWithLayerClient:layerClient query:query];
}

- (id)initWithLayerClient:(LYRClient *)layerClient query:(LYRQuery *)query
{
    self = [super init];
    if (self) {
        _layerClient = layerClient;
    
        NSError *error = nil;
        _queryController = [layerClient queryControllerWithQuery:query error:&error];
        if (!_queryController) {
            NSLog(@"LayerKit failed to create a query controller with error: %@", error);
            return nil;
        }
        _queryController.updatableProperties = [NSSet setWithObjects:@"parts.transferStatus", @"recipientStatusByUserID", @"sentAt", nil];
        
        self.paginationIncrement = 30;
        _dateDisplayTimeInterval = 60*60
        _numberOfSectionsBeforeFirstMessage = 1;
        
        BOOL success = [_queryController execute:&error];
        if (!success) NSLog(@"LayerKit failed to execute query with error: %@", error);
    }
    return self;
}

- (BOOL)executeWithError:(NSError **)error {
    return [self.queryController execute:error];
}

- (void)setPaginationIncrement:(NSUInteger)paginationIncrement {
    _paginationIncrement = paginationIncrement;
    
    NSUInteger numberOfMessagesAvailable = [self.layerClient countForQuery:self.queryController.query error:nil];
    NSUInteger numberOfMessagesToDisplay = MIN(numberOfMessagesAvailable, paginationIncrement);
    self.queryController.paginationWindow = -numberOfMessagesToDisplay;
}

#pragma mark - UI Configuration

- (BOOL)shouldDisplayDateLabelForSection:(NSUInteger)section
{
    if (section < self.numberOfSectionsBeforeFirstMessage) return NO;
    if (section == self.numberOfSectionsBeforeFirstMessage) return YES;
    
    LYRMessage *message = [self messageAtCollectionViewSection:section];
    LYRMessage *previousMessage = [self messageAtCollectionViewSection:section - 1];
    if (!previousMessage.sentAt) return NO;
    
    NSDate *date = message.sentAt ?: [NSDate date];
    NSTimeInterval interval = [date timeIntervalSinceDate:previousMessage.sentAt];
    if (interval > self.dateDisplayTimeInterval) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldDisplaySenderLabelForSection:(NSUInteger)section
{
    LYRConversation *conversation = self.queryController.query.predicate.value;
    if (conversation.participants.count <= 2) {
        return NO;
    }
    
    LYRMessage *message = [self messageAtCollectionViewSection:section];
    if ([message.sender.userID isEqualToString:self.layerClient.authenticatedUserID]) return NO;
    
    if (section > self.numberOfSectionsBeforeFirstMessage) {
        LYRMessage *previousMessage = [self messageAtCollectionViewSection:section - 1];
        if ([previousMessage.sender.userID isEqualToString:message.sender.userID]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)shouldDisplayReadReceiptForSection:(NSUInteger)section
{
    // Only show read receipt if last message was sent by currently authenticated user
    NSInteger lastQueryControllerRow = [self.queryController numberOfObjectsInSection:0] - 1;
    NSInteger lastSection = [self collectionViewSectionForQueryControllerRow:lastQueryControllerRow];
    if (section != lastSection) return NO;
    
    LYRMessage *message = [self messageAtCollectionViewSection:section];
    if (![message.sender.userID isEqualToString:self.layerClient.authenticatedUserID]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldClusterMessageAtSection:(NSUInteger)section
{
    if (section == [self.queryController numberOfObjectsInSection:0]) {
        return NO;
    }
    LYRMessage *message = [self messageAtCollectionViewSection:section];
    LYRMessage *nextMessage = [self messageAtCollectionViewSection:section + 1];
    if (!nextMessage.receivedAt) {
        return NO;
    }
    NSDate *date = message.receivedAt ?: [NSDate date];
    NSTimeInterval interval = [nextMessage.receivedAt timeIntervalSinceDate:date];
    return (interval < 60);
}

- (BOOL)shouldDisplayAvatarItemAtIndexPath:(NSIndexPath *)indexPath
{
    LYRMessage *message = [self messageAtCollectionViewIndexPath:indexPath];
    if ([message.sender.userID isEqualToString:self.layerClient.authenticatedUserID]) {
        return NO;
    }
    
    NSInteger lastQueryControllerRow = [self.queryController numberOfObjectsInSection:0] - 1;
    NSInteger lastSection = [self collectionViewSectionForQueryControllerRow:lastQueryControllerRow];
    if (indexPath.section < lastSection) {
        LYRMessage *nextMessage = [self messageAtCollectionViewSection:indexPath.section + 1];
        // If the next message is sent by the same user, no
        if ([nextMessage.sender.userID isEqualToString:message.sender.userID]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Pagination

- (BOOL)moreMessagesAvailable {
    return self.queryController.totalNumberOfObjects > ABS(self.queryController.count);
}

- (void)expandPaginationWindow
{
    self.expandingPaginationWindow = YES;
    if (!self.queryController) {
        self.expandingPaginationWindow = NO;
        return;
    }
    
    BOOL moreMessagesAvailable = [self moreMessagesAvailable];
    if (!moreMessagesAvailable) {
        self.expandingPaginationWindow = NO;
        return;
    }
    
    NSUInteger numberOfMessagesToDisplay = MIN(-self.queryController.paginationWindow + self.paginationIncrement, self.queryController.totalNumberOfObjects);
    self.queryController.paginationWindow = -numberOfMessagesToDisplay;
    self.expandingPaginationWindow = NO;
}

#pragma mark - Index Translation Methods

- (NSIndexPath *)queryControllerIndexPathForCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath
{
    return [self queryControllerIndexPathForCollectionViewSection:collectionViewIndexPath.section];
}

- (NSIndexPath *)queryControllerIndexPathForCollectionViewSection:(NSInteger)collectionViewSection
{
    NSInteger queryControllerRow = [self queryControllerRowForCollectionViewSection:collectionViewSection];
    NSIndexPath *queryControllerIndexPath = [NSIndexPath indexPathForRow:queryControllerRow inSection:0];
    return queryControllerIndexPath;
}

- (NSInteger)queryControllerRowForCollectionViewSection:(NSInteger)collectionViewSection
{
    return collectionViewSection - self.numberOfSectionsBeforeFirstMessage;
}

- (NSIndexPath *)collectionViewIndexPathForQueryControllerIndexPath:(NSIndexPath *)queryControllerIndexPath
{
    return [self collectionViewIndexPathForQueryControllerRow:queryControllerIndexPath.row];
}

- (NSIndexPath *)collectionViewIndexPathForQueryControllerRow:(NSInteger)queryControllerRow
{
    NSInteger collectionViewSection = [self collectionViewSectionForQueryControllerRow:queryControllerRow];
    NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForRow:0 inSection:collectionViewSection];
    return collectionViewIndexPath;
}

- (NSInteger)collectionViewSectionForQueryControllerRow:(NSInteger)queryControllerRow
{
    return queryControllerRow + self.numberOfSectionsBeforeFirstMessage;
}

- (LYRMessage *)messageAtCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath
{
    NSIndexPath *queryControllerIndexPath = [self queryControllerIndexPathForCollectionViewIndexPath:collectionViewIndexPath];
    LYRMessage *message = [self.queryController objectAtIndexPath:queryControllerIndexPath];
    return message;
}

- (LYRMessage *)messageAtCollectionViewSection:(NSInteger)collectionViewSection
{
    NSIndexPath *queryControllerIndexPath = [self queryControllerIndexPathForCollectionViewSection:collectionViewSection];
    LYRMessage *message = [self.queryController objectAtIndexPath:queryControllerIndexPath];
    return message;
}

@end
