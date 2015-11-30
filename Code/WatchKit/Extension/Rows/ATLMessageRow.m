//
//  ATLMessageRow.m
//  Layer Messenger
//
//  Created by Kevin Coleman on 5/29/15.
//  Copyright (c) 2015 Layer. All rights reserved.
//

#import "ATLMessageRow.h"
#import "ATLMessagingUtilities.h"
#import "ATLIncomingRow.h"
#import "ATLOutgoingRow.h"
#import "ATLConstants.h"

@interface ATLMessageRow () <LYRProgressDelegate>

@property (nonatomic) LYRMessage *message;

@end

@implementation ATLMessageRow

- (void)updateWithMessage:(LYRMessage *)message
{
    [self configureRowColor];
    
    self.message = message;
    
    LYRMessagePart *messagePart = message.parts[0];
    if ([messagePart.MIMEType isEqualToString:ATLMIMETypeTextPlain] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/paymentRequest"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/creditCardConfirmation"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/uberRequest"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/uberRequestDetail"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/uberRequestComplete"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/flowProducts"]) {
        [self configureBubbleViewForTextContent];
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImageJPEG]) {
        [self configureBubbleViewForImageContent];
    }else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImagePNG]) {
        [self configureBubbleViewForImageContent];
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeImageGIF]){
        [self configureBubbleViewForGIFContent];
    } else if ([messagePart.MIMEType isEqualToString:ATLMIMETypeLocation]) {
        [self configureBubbleViewForLocationContent];
    }
}

- (void)configureRowColor
{
    if ([self isKindOfClass:[ATLIncomingRow class]]) {
        [self.labelGroup setBackgroundColor:ATLBlueColor()];
    } else {
        [self.labelGroup setBackgroundColor:ATLLightGrayColor()];
    }
}

- (void)configureBubbleViewForTextContent
{
    LYRMessagePart *messagePart = self.message.parts[0];
    if ([messagePart.MIMEType isEqualToString:@"gobutler/paymentRequest"] ||
        [messagePart.MIMEType isEqualToString:@"gobutler/creditCardConfirmation"]) {
        [self.label setText:NSLocalizedString(@"Please see the iPhone app for your payment details.", nil)];
    } else if ([messagePart.MIMEType isEqualToString:@"gobutler/uberRequest"] ||
               [messagePart.MIMEType isEqualToString:@"gobutler/uberRequestDetail"] ||
               [messagePart.MIMEType isEqualToString:@"gobutler/uberRequestComplete"]) {
        [self.label setText:NSLocalizedString(@"Please see the iPhone app for your Uber request details.", nil)];
    } else if ([messagePart.MIMEType isEqualToString:@"gobutler/flowProducts"]) {
        [self.label setText:NSLocalizedString(@"Please see the iPhone app for your gift suggestions.", nil)];
    } else {
        [self.label setText:[[NSString alloc] initWithData:messagePart.data encoding:NSUTF8StringEncoding]];
    }
    
    [self.mapGroup setHidden:YES];
    [self.imageGroup setHidden:YES];
}

- (void)configureBubbleViewForImageContent
{
    if (self.message.parts.count > 1) {
        LYRMessagePart *previewPart = self.message.parts[1];
        switch (previewPart.transferStatus) {
            case LYRContentTransferComplete:
                [self displayImageForMessagePart:previewPart];
                break;
                
            case LYRContentTransferAwaitingUpload:
                [self displayImageForMessagePart:previewPart];
                break;
                
            case LYRContentTransferUploading:
                [self displayImageForMessagePart:previewPart];
                break;
                
            case LYRContentTransferReadyForDownload:
                [self downloadMessagePart:previewPart];
                break;
                
            case LYRContentTransferDownloading:
                [self downloadMessagePart:previewPart];
                break;
                
            default:
                break;
        }
    }
    
    [self.mapGroup setHidden:YES];
    [self.labelGroup setHidden:YES];
}

- (void)configureBubbleViewForGIFContent
{
    [self.label setText:@"GIF's NOT YET SUPPORTED"];
    
    [self.imageGroup setHidden:YES];
    [self.mapGroup setHidden:YES];
}

- (void)configureBubbleViewForLocationContent
{
    LYRMessagePart *messagePart = self.message.parts[0];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:messagePart.data
                                                               options:NSJSONReadingAllowFragments
                                                                 error:nil];
    double lat = [dictionary[ATLLocationLatitudeKey] doubleValue];
    double lon = [dictionary[ATLLocationLongitudeKey] doubleValue];
    
    CLLocationCoordinate2D coodintate = CLLocationCoordinate2DMake(lat, lon);
    MKCoordinateRegion region =  MKCoordinateRegionMake(coodintate, MKCoordinateSpanMake(0.005, 0.005));
    [self.map setRegion:region];
    [self.map addAnnotation:coodintate withPinColor:WKInterfaceMapPinColorRed];
    
    [self.labelGroup setHidden:YES];
    [self.imageGroup setHidden:YES];
}

#pragma mark - Image Handling

- (void)displayImageForMessagePart:(LYRMessagePart *)part
{
    CGRect screenRect = [[WKInterfaceDevice currentDevice] screenBounds];
    LYRMessagePart *dimensionPart = self.message.parts[2];
    
    CGSize size = ATLImageSizeForJSONData(dimensionPart.data);
    CGFloat width = size.width;
    CGFloat height = size.height;
    
    CGFloat ratio;
    if (width > height) {
        ratio = height / width;
        [self.image setWidth:screenRect.size.width];
        [self.image setHeight:screenRect.size.width * ratio];
    } else {
        ratio = width /  height;
        [self.image setWidth:screenRect.size.height *ratio];
        [self.image setHeight:screenRect.size.height];
    }
    
    [self.image setImageData:part.data];
}

- (void)downloadMessagePart:(LYRMessagePart *)part
{
    NSError *error;
    LYRProgress *progress = [part downloadContent:&error];
    if (progress) {
        progress.delegate = self;
    } else {
        NSLog(@"Failed downloading message part with error: %@", error);
    }
}

#pragma mark - LYRProgress Delegate

- (void)progressDidChange:(LYRProgress *)progress
{
    if (progress.fractionCompleted == 1.0) {
        LYRMessagePart *part = self.message.parts[1];
        [self displayImageForMessagePart:part];
    }
}

@end
