//
//  ATLConversationListInterfaceController
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import "ATLAvatarItem.h"

@class ATLConversationListInterfaceController;

///---------------------------------------
/// @name Delegate
///---------------------------------------


@protocol ATLConversationListInterfaceControllerDelegate <NSObject>

/**
 @abstract Informs the delegate that an `LYRConversation` was selected from the conversation list.
 @param conversationListInterfaceController The `LYRconversationListInterfaceController` in which the selection occurred.
 @param conversation The `LYRConversation` object that was selected.
 */
- (void)conversationListInterfaceController:(ATLConversationListInterfaceController *)conversationListInterfaceController didSelectConversation:(LYRConversation *)conversation;

@end

///---------------------------------------
/// @name Data Source
///---------------------------------------

@protocol ATLConversationListInterfaceControllerDataSource <NSObject>

/**
 @abstract Asks the data source for a title string to display for a given conversation.
 @param conversationListInterfaceController The `LYRconversationListInterfaceController` in which the string will appear.
 @param conversation The `LYRConversation` object.
 @return The string to be displayed as the title for a given conversation in the conversation list.
 */
- (NSString *)conversationListInterfaceController:(ATLConversationListInterfaceController *)conversationListInterfaceController titleForConversation:(LYRConversation *)conversation;

@optional

/**
 @abstract Asks the delegate for an avatar item representing a conversation.
 @param conversationListInterfaceController The `LYRconversationListInterfaceController` in which the item's data will appear.
 @param conversation The `LYRConversation` object.
 @return An object conforming to the `ATLAvatarItem` protocol.
 @discussion The data provided by the object conforming to the `ATLAvatarItem` protocol will be displayed in an `LYRAvatarImageView`.
 */
- (id<ATLAvatarItem>)conversationListInterfaceController:(ATLConversationListInterfaceController *)conversationListInterfaceController avatarItemForConversation:(LYRConversation *)conversation;

/**
 @abstract Asks the data source for the string to display as the conversation's last sent message.
 @param conversationListInterfaceController The `LYRconversationListInterfaceController` in which the title string will appear.
 @params conversation The conversation for which the last message text should be returned.
 @return A string representing the content of the last message.  If `nil` is returned the controller will fall back to default behavior.
 @discussion This is used when the application uses custom `MIMEType`s and wants to customize how they are displayed.
 */
- (NSString *)conversationListInterfaceController:(ATLConversationListInterfaceController *)conversationListInterfaceController lastMessageTextForConversation:(LYRConversation *)conversation;

/**
 @abstract Asks the data source to configure the query used to fetch content for the controller if necessary.
 @discussion The `LYRconversationListInterfaceController` uses the following default query:
 
 LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
 query.predicate = [LYRPredicate predicateWithProperty:@"participants" predicateOperator:LYRPredicateOperatorIsIn value:self.layerClient.authenticatedUserID];
 query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastMessage.receivedAt" ascending:NO]];
 
 Applications that require advanced query configuration can do so by implementing this data source method.
 
 @param viewController The `ATLConversationViewController` requesting the configuration.
 @param defaultQuery An `LYRQuery` object with the default configuration for the controller.
 @return An `LYRQuery` object with any additional configuration.
 @raises `NSInvalidArgumentException` if an `LYRQuery` object is not returned.
 */
- (LYRQuery *)conversationListInterfaceController:(ATLConversationListInterfaceController *)viewController willLoadWithQuery:(LYRQuery *)defaultQuery;

@end

@interface ATLConversationListInterfaceController : WKInterfaceController

/**
 @abstract The `LYRClient` object used to query for messaging content to be displayed in the controller.
 @discussion The `LYRClient` object must be passed into the `context` dictionary as a value for the `ATLLayerClientKey` key when presenting the controller.
 */
@property (nonatomic) LYRClient *layerClient;

/**
 @abstract The `ATLConversationListInterfaceControllerDelegate` class informs the receiver to specific events that occurred within the controller.
 */
@property (nonatomic, weak) id<ATLConversationListInterfaceControllerDelegate>delegate;

/**
 @abstract The `ATLConversationListInterfaceControllerDataSource` class presents an interface allowing for the display of information pertaining to specific conversations in the controller
 */
@property (nonatomic, weak) id<ATLConversationListInterfaceControllerDataSource>dataSource;

/**
 @abstract The `WKInterfaceTable` in which conversations are displayed.
 @discussion Applications can customize the table via the `Interface.storyboard` file.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceTable *conversationTable;

/**
 @abstract Configures the receiver and its content for display.
 @discussion Subclasses must call this method in `awakeWithContext:` after any aditional setup has been perfromed.
 */
- (void)configureConversationListController;

@end
