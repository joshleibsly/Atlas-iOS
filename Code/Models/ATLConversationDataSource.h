//
//  ATLConversationQueryDataSource.h
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

#import <UIKit/UIKit.h> 
#import <LayerKit/LayerKit.h>

extern NSInteger const ATLNumberOfSectionsBeforeFirstMessageSection;

/**
 @abstract The `ATLConversationDataSource` manages an `LYRQueryController` object whose data is displayed in an
 `ATLConversationViewController`. The `ATLConversationDataSource` also provides convenience methods for the translation 
 of index objects between an `LYRQueryController` and an `ATLConversationViewController`.
 @discussion The `ATLConversationViewController` reserves the section at index 0 for a "Loading Messages" indicator if
 one is needed during pagination. The index translation methods provided by the `ATLConversationDataSource` account for
 this offset.
 */
@interface ATLConversationDataSource : NSObject

///---------------------------------------
/// @name Initializing a Data Source
///---------------------------------------

/**
 @abstract Creates and returns an `ATLConversationDataSource` object.
 @param layerClient An `LYRClient` object used to initialize the `queryController` property.
 @param query An `LYRQuery` object used as the query for the `queryController` property.
 @return An `ATLConversationDataSource` object.
 */
+ (instancetype)dataSourceWithLayerClient:(LYRClient *)layerClient query:(LYRQuery *)query;

/**
 @abstract The `LYRQueryController` object managing data displayed in the `ATLConversationViewController`.
 @discussion The `queryController` is hydrated with messages belonging to the `LYRConversation` object supplied in the designated initializer.
 */
@property (nonatomic, readonly) LYRQueryController *queryController;

/**
 @abstract Excutes the query supplied in the initializer and prepares the query controller for use. 
 @discussion The `ATLConversationDataSource` provides an explict execute method so that configuration may be performed prior to executing the query. 
 @error A pointer to an `NSError` object that will describe any failure that occured.
 @return A boolean value that indicates whether or not the query was successful.
 */
- (BOOL)executeWithError:(NSError **)error;

///---------------------------------------
/// @name Conversation UI Configuration
///---------------------------------------

/**
 @abstract The time interval that must elapse for a date to be displayed in the conversation UI.
 @discussion If the time elapsed between two messages is greater than the `dateDisplayTimeInterval`, a date will be displayed.
 @defualt `3600`
 */
@property (nonatomic) NSTimeInterval dateDisplayTimeInterval;

/**
 @abstract Determines whether or not a date label should be displayed in a given section.
 */
- (BOOL)shouldDisplayDateLabelForSection:(NSUInteger)section;

/**
 @abstract Determines whether or not a sender label should be displayed in a given section.
 */
- (BOOL)shouldDisplaySenderLabelForSection:(NSUInteger)section;

/**
 @abstract Determines whether or not a read receipt label should be displayed in a given section.
 */
- (BOOL)shouldDisplayReadReceiptForSection:(NSUInteger)section;

/**
 @abstract Determines whether or not messages should be clustered for a given section.
 */
- (BOOL)shouldClusterMessageAtSection:(NSUInteger)section;

/**
 @abstract Determines whether or not an avatar item should be displayed in a given section.
 */
- (BOOL)shouldDisplayAvatarItemAtIndexPath:(NSIndexPath *)indexPath;

///---------------------------------------
/// @name Pagination
///---------------------------------------

/**
 @abstract The number of sections intended to be used prior to the first message.
 @discussion Value is used to offset query controller calculations so that a `Loading Messages` spinner may be displayed during pagination.
 @default `1`
 */
@property (nonatomic) NSUInteger numberOfSectionsBeforeFirstMessage;

/**
 @abstract The pagination increment to be used when paginating messages.
 @default `30`
 */
@property (nonatomic) NSUInteger paginationIncrement;;

/**
 @abstract Asks the receiver if its `queryController` has more messages to display than are currently displayed on screen.
 @return `YES` if there are more messages to display.
 */
- (BOOL)moreMessagesAvailable;

/**
 @abstract Expands the pagination window of the `queryController` by the `paginationWindow` property if
 more messages are available for display.
 */
- (void)expandPaginationWindow;

/**
 @abstract Returns `YES` if the data source is currently in the process of expanding its pagination window.
 */
@property (nonatomic, readonly, getter=isExpandingPaginationWindow) BOOL expandingPaginationWindow;

///---------------------------------------
/// @name Index Translation Methods
///---------------------------------------

/**
 @abstract Converts an `ATLConversationViewController` index path into an `LYRQueryController` index path.
 */
- (NSIndexPath *)queryControllerIndexPathForCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath;

/**
 @abstract Converts an `LYRQueryController` index path into an `ATLConversationViewController` index path.
 */
- (NSIndexPath *)collectionViewIndexPathForQueryControllerIndexPath:(NSIndexPath *)collectionViewIndexPath;

/**
 @abstract Converts an `LYRQueryController` row into an `ATLConversationViewController` section.
 @discussion The `ATLConversationViewController` displays one `LYRMessage` object for each section.
 */
- (NSInteger)collectionViewSectionForQueryControllerRow:(NSInteger)queryControllerRow;

/**
 @abstract Fetches the `LYRMessage` object corresponding to an `ATLConversationViewController` index path.
 */
- (LYRMessage *)messageAtCollectionViewIndexPath:(NSIndexPath *)collectionViewIndexPath;

/**
 @abstract Fetches the `LYRMessage` object corresponding to an `ATLConversationViewController` section.
 */
- (LYRMessage *)messageAtCollectionViewSection:(NSInteger)collectionViewSection;

@end
