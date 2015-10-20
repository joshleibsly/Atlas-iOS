//
//  ATLConversationRow.h
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface ATLConversationRow : NSObject

/**
 @abstract The title label for the conversation.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;

/**
 @abstract The last message label for the conversation.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *lastMessageLabel;

/**
 @abstractT The date label for the conversation.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@end
