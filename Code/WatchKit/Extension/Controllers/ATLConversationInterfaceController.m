    //
//  ATLWatchConversationViewController.m
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "ATLConversationInterfaceController.h"
#import <LayerKit/LayerKit.h>
#import "ATLMessageRow.h"
#import "ATLMessagingUtilities.h"
#import "ATLConversationDataSource.h"
#import "ATLConstants.h"

#import "ATLIncomingRow.h"
#import "ATLOutgoingRow.h"
#import "ATLMessagingUtilities.h"

@interface ATLConversationInterfaceController () <LYRProgressDelegate, LYRQueryControllerDelegate>

@property (nonatomic) ATLConversationDataSource *conversationDataSource;
@property (nonatomic, readwrite) LYRClient *layerClient;
@property (nonatomic, readwrite) LYRConversation *conversation;

@end

@implementation ATLConversationInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    
    self.layerClient = [context objectForKey:ATLLayerClientKey];
    self.conversation = [context objectForKey:ATLLayerConversationKey];
    self.conversationDataSource = [self dataSourceForConversation];
}

- (void)willActivate
{
    [super willActivate];
    NSUInteger lastIndex = [self.messageTable numberOfRows] - 1;
    [self.messageTable scrollToRowAtIndex:lastIndex];
}

- (ATLConversationDataSource *)dataSourceForConversation
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRMessage class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"conversation" predicateOperator:LYRPredicateOperatorIsEqualTo value:self.conversation];
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"position" ascending:YES]];
    
    ATLConversationDataSource *conversationDatasource = [ATLConversationDataSource dataSourceWithLayerClient:self.layerClient query:query];
    conversationDatasource.paginationIncrement = 50;
    conversationDatasource .queryController.delegate = self;
    conversationDatasource.numberOfSectionsBeforeFirstMessage = 0;
    
    NSError *error;
    if (![conversationDatasource executeWithError:&error] ){
        NSLog(@"Failed fetching messages with error %@", error);
    }
    return conversationDatasource ;
}

- (void)configureConversationController
{
    self.conversationDataSource = [self dataSourceForConversation];
    NSUInteger messageCount = [self.conversationDataSource.queryController numberOfObjectsInSection:0];
    [self calculateRowsForMessageCount:messageCount];
    NSUInteger rowCount = self.messageTable.numberOfRows;
    for (NSUInteger i = 0; i < rowCount - 1; i++) {
        [self configureRowAtIndex:i];
    }
}

- (void)calculateRowsForMessageCount:(NSUInteger)messageCount
{
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:messageCount];
    for (NSUInteger i = 0; i < messageCount; i++) {
        LYRMessage *message = [self.conversationDataSource messageAtCollectionViewSection:i];
        if ([message.sender.userID isEqualToString:self.layerClient.authenticatedUserID]) {
            [rows addObject:@"outgoingRow"];
        } else {
            [rows addObject:@"incomingRow"];
        }
    }
    
    [rows addObject:@"ReplyController"];
    [self.messageTable setRowTypes:rows];
}

- (void)configureRowAtIndex:(NSUInteger)index
{
    LYRMessage *message = [self.conversationDataSource messageAtCollectionViewSection:index];
    ATLMessageRow *row = [self.messageTable rowControllerAtIndex:index];
    [row updateWithMessage:message];
    
    if ([self.conversationDataSource shouldDisplayDateLabelForSection:index]) {
        NSAttributedString *dateString =  [self attributedStringForMessageDate:message];
        [row.dateLabel setAttributedText:dateString];
    } else {
        [row.dateLabelGroup setHidden:YES];
    }
    
    if ([self.conversationDataSource shouldDisplaySenderLabelForSection:index]) {
        id<ATLParticipant> sender = [self participantForIdentifier:message.sender.userID];
        [row.senderNameLabel setText:sender.fullName];
    } else {
        [row.senderNameGroup setHidden:YES];
    }
    
    if ([self.conversationDataSource shouldDisplayReadReceiptForSection:index]) {
        NSAttributedString *recipientStatusString = [self attributedStringForRecipientStatusOfMessage:message];
        [row.recipientStatusLabel setAttributedText:recipientStatusString];
    } else {
        [row.footerGroup setHidden:YES];
    }
}

#pragma mark - Message Sending

- (IBAction)replyButtonTapped:(id)sender
{
    [self presentTextInputControllerWithSuggestions:@[@"Test"] allowedInputMode:WKTextInputModeAllowAnimatedEmoji completion:^(NSArray *results) {
        NSString *messageText = results[0];
        if (messageText) {
            ATLMediaAttachment *mediaAttachment = [ATLMediaAttachment mediaAttachmentWithText:messageText];
            NSOrderedSet *messages = [self defaultMessagesForMediaAttachments:@[mediaAttachment]];
            for (LYRMessage *message in messages) {
                [self sendMessage:message];
            }
        }
    }];
}

- (NSOrderedSet *)defaultMessagesForMediaAttachments:(NSArray *)mediaAttachments
{
    NSMutableOrderedSet *messages = [NSMutableOrderedSet new];
    for (ATLMediaAttachment *attachment in mediaAttachments){
        NSArray *messageParts = ATLMessagePartsWithMediaAttachment(attachment);
        NSString *pushText;
        if ([attachment.mediaMIMEType isEqualToString:ATLMIMETypeTextPlain]) {
            pushText = attachment.textRepresentation;
        } else {
            NSString *senderName = [[self participantForIdentifier:self.layerClient.authenticatedUserID] fullName];
            pushText = [NSString stringWithFormat:@"%@ %@", senderName, ATLDefaultPushAlertText];
        }
        LYRMessage *message = ATLMessageForParts(self.layerClient, messageParts, pushText, ATLPushNotificationSoundName);
        if (message) {
            [messages addObject:message];
        }
    }
    return messages;
}

- (void)sendMessage:(LYRMessage *)message
{
    NSError *error;
    BOOL success = [self.conversation sendMessage:message error:&error];
    if (success) {
        [self notifyDelegateOfMessageSend:message];
    } else {
        [self notifyDelegateOfMessageSendFailure:message error:error];
    }
}
#pragma mark - Delegate

- (void)notifyDelegateOfMessageSend:(LYRMessage *)message
{
    if ([self.delegate respondsToSelector:@selector(conversationInterfaceController:didSendMessage:)]) {
        [self.delegate conversationInterfaceController:self didSendMessage:message];
    }
}

- (void)notifyDelegateOfMessageSendFailure:(LYRMessage *)message error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(conversationInterfaceController:didFailSendingMessage:error:)]) {
        [self.delegate conversationInterfaceController:self didFailSendingMessage:message error:error];
    }
}

- (void)notifyDelegateOfMessageSelection:(LYRMessage *)message
{
    if ([self.delegate respondsToSelector:@selector(conversationInterfaceController:didSelectMessage:)]) {
        [self.delegate conversationInterfaceController:self didSelectMessage:message];
    }
}

#pragma mark - Data Source 

- (id<ATLParticipant>)participantForIdentifier:(NSString *)identifier
{
    if ([self.dataSource respondsToSelector:@selector(conversationInterfaceController:participantForIdentifier:)]) {
        return [self.dataSource conversationInterfaceController:self participantForIdentifier:identifier];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"ATLConversationInterfaceControllerDelegate must return a participant for an identifier" userInfo:nil];
    }
    return nil;
}

- (NSAttributedString *)attributedStringForMessageDate:(LYRMessage *)message
{
    NSAttributedString *dateString;
    if ([self.dataSource respondsToSelector:@selector(conversationInterfaceController:attributedStringForDisplayOfDate:)]) {
        NSDate *date = message.receivedAt ?: [NSDate date];
        dateString = [self.dataSource conversationInterfaceController:self attributedStringForDisplayOfDate:date];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"ATLConversationInterfaceControllerDataSource must return an attributed string for Date" userInfo:nil];
    }
    NSAssert([dateString isKindOfClass:[NSAttributedString class]], @"Date string must be an attributed string");
    return dateString;
}

- (NSAttributedString *)attributedStringForRecipientStatusOfMessage:(LYRMessage *)message
{
    NSAttributedString *recipientStatusString;
    if ([self.dataSource respondsToSelector:@selector(conversationInterfaceController:attributedStringForDisplayOfRecipientStatus:)]) {
        recipientStatusString = [self.dataSource conversationInterfaceController:self attributedStringForDisplayOfRecipientStatus:message.recipientStatusByUserID];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"ATLConversationInterfaceControllerDataSource must return an attributed string for recipient status" userInfo:nil];
    }
    NSAssert([recipientStatusString isKindOfClass:[NSAttributedString class]], @"Recipient String must be an attributed string");
    return recipientStatusString;
}

- (void)progressDidChange:(LYRProgress *)progress
{
    NSLog(@"progress");
}

#pragma mark - Query Controller Delegate

- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case LYRQueryControllerChangeTypeInsert:
            [self insertMessage:object atIndex:newIndexPath.row];
            break;
        case LYRQueryControllerChangeTypeUpdate:
            [self configureRowAtIndex:indexPath.row];
            break;
        case LYRQueryControllerChangeTypeMove:
            [self.messageTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]];
            [self.messageTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndexPath.row] withRowType:@"conversationRow"];
            [self configureRowAtIndex:newIndexPath.row];
            break;
        case LYRQueryControllerChangeTypeDelete:
            [self.messageTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]];
            break;
        default:
            break;
    }
}

- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
{
    NSUInteger lastIndex = [self.messageTable numberOfRows] - 1;
    [self.messageTable scrollToRowAtIndex:lastIndex];
}

#pragma mark - Change Configuration

- (void)insertMessage:(LYRMessage *)message atIndex:(NSUInteger)index
{
    if ([message.sender.userID isEqualToString:self.layerClient.authenticatedUserID]) {
        [self.messageTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withRowType:@"outgoingRow"];
    } else {
        [self.messageTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withRowType:@"incomingRow"];
    }
    [self configureRowAtIndex:index];
    if (index > 0) {
        [self configureRowAtIndex:index- 1];
    }
}

@end



