//
//  ATLWatchConversationListViewController.m
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "ATLConversationListInterfaceController.h"
#import "ATLConversationRow.h"
#import "ATLMessagingUtilities.h"
#import "ATLConstants.h"
#import <LayerKit/LayerKit.h>

static NSDateFormatter *ATLDateFormatter()
{
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
    }
    return dateFormatter;
}

@interface ATLConversationListInterfaceController () <LYRQueryControllerDelegate>

@property (nonatomic) LYRQueryController *queryController;

@end

@implementation ATLConversationListInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    // Extract Layer Client from context
    self.layerClient = [context objectForKey:ATLLayerClientKey];
    
    // Setup Query Controller
    NSError *error;
    self.queryController = [self queryControllerForConversationList];
    BOOL success = [self.queryController execute:&error];
    if (!success) {
        NSLog(@"Failed to execute query with error %@", error);
    }
    
    // Set default title
    [self setTitle:@"Messages"];
}

- (LYRQueryController *)queryControllerForConversationList
{
    LYRQuery *query = ATLConversationListDefaultQueryForAuthenticatedUserID(self.layerClient.authenticatedUserID);
    query.limit = 10;
    if ([self.dataSource respondsToSelector:@selector(conversationListInterfaceController:willLoadWithQuery:)]) {
        query = [self.dataSource conversationListInterfaceController:self willLoadWithQuery:query];
    }
    LYRQueryController *queryController = [self.layerClient queryControllerWithQuery:query error:nil];
    queryController.delegate = self;
    return queryController;
}

- (void)configureConversationListController
{
    NSUInteger conversationCount = [self.queryController numberOfObjectsInSection:0];
    [self.conversationTable setNumberOfRows:conversationCount withRowType:@"conversationRow"];
    for (NSInteger i = 0; i < conversationCount; i++) {
        [self configureRowAtIndex:i];
    }
}

- (void)configureRowAtIndex:(NSUInteger)index
{
    ATLConversationRow *row = [self.conversationTable rowControllerAtIndex:index];
    LYRConversation *conversation = [self.queryController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [row.titleLabel setText:[self titleForConversation:conversation]];
   
    NSString *lastMessage = ATLLastMessageTextForMessage(conversation.lastMessage);
    [row.lastMessageLabel setText:lastMessage];
    [row.dateLabel setText:[ATLDateFormatter() stringFromDate:conversation.lastMessage.receivedAt]];
}

#pragma mark - Table Selection

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    LYRConversation *conversation = [self.queryController objectAtIndexPath:[NSIndexPath indexPathForRow:rowIndex inSection:0]];
    [self.delegate conversationListInterfaceController:self didSelectConversation:conversation];
}

#pragma mark - Data Source

- (NSString *)titleForConversation:(LYRConversation *)conversation
{
    if ([self.dataSource respondsToSelector:@selector(conversationListInterfaceController:titleForConversation:)]) {
        return [self.dataSource conversationListInterfaceController:self titleForConversation:conversation];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"ATLConversationListInterfaceControllerDataSource must return a title for the conversation" userInfo:nil];
    }
    return nil;
}

#pragma mark - Query Controller Delegate

- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case LYRQueryControllerChangeTypeInsert:
            [self.conversationTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.row] withRowType:@"conversationRow"];
            [self configureRowAtIndex:newIndexPath.row];
            break;
        case LYRQueryControllerChangeTypeUpdate:
            [self configureRowAtIndex:indexPath.row];
            break;
        case LYRQueryControllerChangeTypeMove:
            [self.conversationTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]];
            [self.conversationTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.row] withRowType:@"conversationRow"];
            [self configureRowAtIndex:newIndexPath.row];
            break;
        case LYRQueryControllerChangeTypeDelete:
            [self.conversationTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]];
            break;
        default:
            break;
    }
}

@end



