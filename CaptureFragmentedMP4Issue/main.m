//
//  main.m
//  CaptureFragmentedMP4Issue
//
//  Created by Sean Daly on 6/21/18.
//  Copyright © 2018 Sean Daly. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

BOOL shouldKeepRunning = YES;

@interface CaptureFragmentedMovie : NSObject<AVCaptureFileOutputRecordingDelegate>
@property AVCaptureSession* captureSession;
@property AVCaptureMovieFileOutput* movieOutput;
-(void) CaptureIssue;
@end

@implementation CaptureFragmentedMovie

-(id)init
{
    self = [super init];
    _captureSession = [[AVCaptureSession alloc] init];
    _movieOutput = [[AVCaptureMovieFileOutput alloc] init ];
    return self;
}

-(void) CaptureIssue
{
    NSString* filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"CaptureFragmentedMP4Issue"];
    filePath = [filePath stringByAppendingPathExtension:@"mp4"];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if(error)
        {
            NSLog(@"Error removing file %@ %@", filePath, error);
            return;
        }
    }

    int64_t secondsToCapture = 20;
    int64_t secondsToFragment = 0;
    if(secondsToCapture - 2 < 2)
    {
        secondsToFragment = 2; // min fragment time that works
    }
    else
    {
        secondsToFragment = secondsToCapture - 2;
    }
    _movieOutput.maxRecordedDuration = CMTimeMake(secondsToCapture, 1); // 4 second capture
    _movieOutput.movieFragmentInterval = CMTimeMake(secondsToFragment, 1); // 2 second fragment writting
    
    NSError* error;
    [_captureSession addInput:[AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:&error]];
    [_captureSession addInput:[AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error]];
    [_captureSession addOutput:_movieOutput];
    [self->_captureSession startRunning];
    [self->_movieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath] recordingDelegate:self];
}
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error)
    {
        if([error.domain isEqualToString:@"AVFoundationErrorDomain"] && error.code == -11806)
        {
            NSLog(@"Recording Stopped");
        }
        else if([error.domain isEqualToString:@"AVFoundationErrorDomain"] && [error.localizedFailureReason isEqualToString:@"The recording reached the maximum allowable length."])
        {
            NSLog(@"%@", error.localizedFailureReason);
        }
        else
        {
            NSLog(@"error: %@", error);
        }
    }
    if([_captureSession isRunning])
    {
        [_movieOutput stopRecording];
        [_captureSession stopRunning];
    }
    shouldKeepRunning = NO;
}

@end

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        //dispatch_queue_t sessionQueue = dispatch_queue_create("captureSessionQueue", DISPATCH_QUEUE_SERIAL);
        //dispatch_async(sessionQueue, ^
        //{
            CaptureFragmentedMovie* captureFragmentedMovie = [[CaptureFragmentedMovie alloc] init];
            [captureFragmentedMovie CaptureIssue];
        //});
        
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        while (shouldKeepRunning && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    }
    return 0;
}
