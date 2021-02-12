//
//  LocationManager.m
//  Unity-iPhone
//
//  Created by phongnt on 10/11/17.
//

#import "LocationManager.h"
#import <UIKit/UIKit.h>
#import "Connection.h"


@interface LocationManager ()

@end

@implementation LocationManager

+ (id)sharedManager {
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    
    return sharedMyModel;
}

#pragma mark - CLLocationManager

-(void)showAlertWithTitle:(NSString *)title
               andMessage:(NSString *)message
         inViewController:(UIViewController *)viewController
  withButtonFunctionality:(void (^)(void))buttonHandler
{
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* alertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
        if (buttonHandler)
            buttonHandler();
    }];
    [alertController addAction: alertAction];
    [viewController presentViewController:alertController animated:YES completion:nil];
}


- (void)checkLocationAccess {
    
    
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    switch (status) {
            
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");  // alert dialog for all request
            
            [self showAlertWithTitle:@"Error"
                          andMessage:@"Please Open Settings and allow to use Location Servies"
                    inViewController:self
             withButtonFunctionality:^{
                NSLog(@"kCLAuied");
                
                // Open Settings
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:[NSDictionary dictionary] completionHandler:nil];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
                return;
            }];
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"kCLAuthorizationStatusRestricted");
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"kCLAuthorizationStatusNotDetermined"); // request
            [_locationManager requestAlwaysAuthorization];
            [_locationManager requestWhenInUseAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"kCLAuthorizationStatusAuthorizedAlways"); // allowed
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [_locationManager requestAlwaysAuthorization];
            NSLog(@"kCLAuthorizationStatusAuthorizedWhenInUse"); // alert dialog for always request next time
            break;
    }
    [self showAlertWithTitle:@"Error"
                  andMessage:@"Please Open setting s"
            inViewController:self
     withButtonFunctionality:^{
        NSLog(@"kCLAuied");
        
        // Open Settings
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:[NSDictionary dictionary] completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
        return;
    }];
    
}
#pragma mark - CLLocationManager

- (void)startMonitoringLocation {
    NSLog(@"startMonitoringLocation");
    if (!_locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.activityType = CLActivityTypeFitness;
    _locationManager.distanceFilter = 0;
    [_locationManager requestAlwaysAuthorization];
    
    [_locationManager startMonitoringSignificantLocationChanges];
    [_locationManager startMonitoringVisits];
    
    _locationManager.pausesLocationUpdatesAutomatically = NO; //this is important
    _locationManager.allowsBackgroundLocationUpdates = YES;
    [_locationManager startUpdatingLocation];
    
}

- (void)stopMonitoringLocation {
    if (!_locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    [_locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManager Delegate


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSDate *now = [NSDate date];
    NSTimeInterval interval = self.lastTimestamp ? [now timeIntervalSinceDate:self.lastTimestamp] : 0;
    
    if (!self.lastTimestamp || interval >= 60)
    {
        currentLocation = [locations objectAtIndex:0];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
        
        [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
         {
            if (!(error))
            {
               
                
                isGrantedNotificationAccess = true;
                UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
                UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound;
                [center requestAuthorizationWithOptions:options completionHandler:
                 ^(BOOL granted, NSError * _Nullable error){
                    isGrantedNotificationAccess = granted;
                }
                 ];
                
                NSDate *today = [NSDate date];
                NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSString *dateString = [dateFormat stringFromDate:today];
                NSLog(@"date: %@", dateString);
               
                self.lastTimestamp = now;
                NSLog(@"Sending current location to web service.");
                
                NSLog(@"\nCurrent Location Detected\n");
                NSLog(@"%f",self->currentLocation.coordinate.latitude);
                NSLog(@"%f",self->currentLocation.coordinate.longitude);
                
                NSString *latitude = [NSString stringWithFormat:@"%f",self->currentLocation.coordinate.latitude] ;
                NSString *longitude = [NSString stringWithFormat:@"%f",self->currentLocation.coordinate.longitude] ;
             
                if (isGrantedNotificationAccess)
                {
                    NSLog(@"dsdsdsds.");
                    UNUserNotificationCenter *center=[UNUserNotificationCenter currentNotificationCenter];
                    UNMutableNotificationContent * mucontent = [[UNMutableNotificationContent alloc]init];
                    mucontent.title=@"Bexcell";
                    mucontent.subtitle=@"Location update";
                    mucontent.sound=[UNNotificationSound defaultSound];
                    
                    UNTimeIntervalNotificationTrigger *trigger=[UNTimeIntervalNotificationTrigger triggerWithTimeInterval:3 repeats:NO];
                    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:@"UYLocalNotification" content:mucontent trigger:trigger];
                    [center addNotificationRequest:request withCompletionHandler:nil];
                    
                }
              
            }
            else
            {
                NSLog(@"Geocode failed with error %@", error);
                NSLog(@"\nCurrent Location Not Detected\n");
                
                
            }
            
        }];
    }
}
- (void)postRequestWithURL:(NSString *)url
                parameters:(NSDictionary *)dictionary
         completionHandler:(void (^) (NSURLResponse *response, id responseObject))completionHandler
{
    
    AFHTTPSessionManager *sessionManager = [Connection sessionManager];
    //    AFHTTPSessionManager *sessionManager = [AFHTTPSessionManager manager];
    [sessionManager setRequestSerializer: [AFJSONRequestSerializer serializer]];
    [[sessionManager requestSerializer] setAuthorizationHeaderFieldWithUsername:AuthorizationHeaderFieldUsername
                                                                       password:AuthorizationHeaderFieldPassword];
    [[sessionManager requestSerializer] setValue:AcceptLanguageHTTPHeaderValue
                              forHTTPHeaderField:AcceptLanguageHTTPHeaderKey];
    [sessionManager POST:url
              parameters:dictionary
                 headers:nil
                progress:nil
                 success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            completionHandler(task.response, responseObject);
        });
    }
                 failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"\%@ API Error: %@\n", url, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }];
}



@end
