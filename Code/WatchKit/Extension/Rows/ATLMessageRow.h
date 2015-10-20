//
//  ATLMessageRow.h
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h> 
#import <LayerKit/LayerKit.h>

@interface ATLMessageRow : NSObject

///----------------
/// Message Content
///----------------

/**
 @abstract The `WKInterfaceLabel` used to display an `LYRMessage` object's text content.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *label;

/**
 @abstract The `WKInterfaceImage` used to display an `LYRMessage` object's image content.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceImage *image;

/**
 @abstract The `WKInterfaceMap` used to display an `LYRMessage` object's location content.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;

///----------------
/// Message Header
///----------------

/**
 @abstract The `WKInterfaceLabel` used to display the date label for a message.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

/**
 @abstract The `WKInterfaceLabel` used to display the sender's name of a message.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *senderNameLabel;

///----------------
/// Message Footer
///----------------

/**
 @abstract The `WKInterfaceLabel` used to display a recipient status for a message.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *recipientStatusLabel;

///-----------
/// Row Groups
///-----------

/**
 @abstract The `WKInterfaceLabel` used to display the row's `label`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *labelGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `image`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *imageGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `map`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *mapGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `dateLabel`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *dateLabelGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `senderNameLabel`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *senderNameGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `header`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *headerGroup;

/**
 @abstract The `WKInterfaceLabel` used to display the row's `footer`.
 */
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *footerGroup;

///-------------------
/// Displaying Content
///-------------------

/**
 @abstract Updated the row with an `LYRMessage` whose content will be displayed in the receiver.
 */
- (void)updateWithMessage:(LYRMessage *)message;

@end
