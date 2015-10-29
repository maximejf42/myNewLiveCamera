//
//  ViewController.m
//  myNewLiveCamera
//
//  Created by Robert Zimmelman on 10/27/15.
//  Copyright © 2015 Robert Zimmelman. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>



@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;
@property (weak, nonatomic) IBOutlet UIView *myVideoView;

@end

@implementation ViewController
AVCaptureSession *session;
AVCaptureStillImageOutput *stillimageoutput;




- (IBAction)takePicture:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    if (stillimageoutput.connections.count == 0) {
        NSLog(@"NO Connections!");
        return;
    }
    for (AVCaptureConnection *connection in stillimageoutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            NSLog(@"connection %@ port %@",connection,port);
            if (
                [[port mediaType] isEqual:AVMediaTypeVideo]) {
                NSLog(@"Making connection");
                videoConnection = connection;
                NSLog(@"video connection %@",videoConnection);
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    [stillimageoutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer != NULL){
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            
            [self.myImageView setImage:image];
            
//            CIImage *myCImage = [CIImage imageWithData:imageData];
            CIContext *myFaceDetectorContext = [CIContext contextWithOptions:nil];                    // 1
            //    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh, CIDetectorMinFeatureSize: @0.01 };      // 2
            NSDictionary *myFaceDetectorOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"CIDetectorAccuracy", @"CIDetectorAccuracyHigh", @"CIDetectorMinFeatureSize", @"0.01",  nil];
            CIDetector *myFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                            context:myFaceDetectorContext
                                                            options:myFaceDetectorOptions];                    // 3
//            NSDictionary *opts = [NSDictionary alloc] initWithDictionary: @{ CIDetectorImageOrientation :
//                              [[myCIImage properties] valueForKey:kCGImagePropertyOrientation] }; // 4
            
            
            NSArray *myFaceFeatures = [myFaceDetector featuresInImage:image.CIImage options:myFaceDetectorOptions];        // 5
            for (CIFaceFeature *f in myFaceFeatures)
            {
                //        NSLog(@"f = %@",f);
                NSLog(@"bounds = %@",NSStringFromCGRect(f.bounds));
                if (f.hasLeftEyePosition){
                    NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
                }
                if (f.leftEyeClosed)
                {
                    NSLog(@"Left Eye is Closed");
                }
                
                if (f.hasRightEyePosition){
                    NSLog(@"Right eye %g %g", f.rightEyePosition.x, f.rightEyePosition.y);
                }
                if (f.rightEyeClosed)
                {
                    NSLog(@"Right Eye is Closed");
                }
                
                if (f.hasMouthPosition)
                {
                    NSLog(@"Mouth %g %g", f.mouthPosition.x, f.mouthPosition.y);
                }
                if (f.hasSmile)
                {
                    NSLog(@"SMILING");
                }
                if (f.hasFaceAngle)
                {
                    NSLog(@"Has a Face Angle");
                    NSLog(@"Face Angle is: %f",f.faceAngle);
                }
                
            }
            
            
            // end of face detector part
            
            
            // begin rectangle detector part
            CIDetector *myRectangleDetector = [CIDetector detectorOfType:CIDetectorTypeRectangle
                                                                 context:myFaceDetectorContext
                                                                 options:myFaceDetectorOptions];
            
            NSArray *myRectangleFeatures = [myRectangleDetector featuresInImage:image.CIImage options:myFaceDetectorOptions];
            NSLog(@"%lu  Rectangles Detected", (unsigned long) myRectangleFeatures.count);
            if (myRectangleFeatures.count == 0) {
                NSLog(@"No Rectangles Detected!");
            }
            for (CIRectangleFeature *rf in myRectangleFeatures)
            {
                NSLog(@"Top Location = %f %f %f %f",rf.topLeft.x, rf.topLeft.y, rf.topRight.x, rf.topRight.y);
                NSLog(@"Bottom Location = %f %f %f %f",rf.bottomLeft.x, rf.bottomLeft.y, rf.bottomRight.x, rf.bottomRight.y);
            }
            

            
            
            
            
        }
    }];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) viewWillAppear:(BOOL)animated{
    session = [[AVCaptureSession alloc]init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    NSError *error;
//    AVCaptureDevice *inputDevice = [self frontCamera];
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([session canAddInput:deviceInput]) {
        [session addInput:deviceInput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view]layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.myVideoView.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    stillimageoutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillimageoutput setOutputSettings:outputSettings];
    [session addOutput:stillimageoutput];
    [session startRunning];
}


- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}



@end
