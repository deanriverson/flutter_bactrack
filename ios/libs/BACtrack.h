//
//  Public-SDK
//
//  Copyright (c) 2018 KHN Solutions LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


/*******************************************************************************************/
/************************************ Global Values ****************************************/
/*******************************************************************************************/

typedef NS_ENUM(NSInteger, BACtrackDeviceType) {
    BACtrackDeviceType_Mobile = 0,
    BACtrackDeviceType_Vio,
    BACtrackDeviceType_Unknown
};

#define MOBILE__ERROR_TIME_OUT                   0x01
#define MOBILE__ERROR_BLOW_ERROR                 0x02
#define MOBILE__ERROR_OUT_OF_TEMPERATURE         0x03
#define MOBILE__ERROR_LOW_BATTERY                0x04
#define MOBILE__ERROR_CALIBRATION_FAIL           0x05
#define MOBILE__ERROR_NOT_CALIBRATED             0x06
#define MOBILE__ERROR_COM_ERROR                  0x07
#define MOBILE__ERROR_INFLOW_ERROR               0x08
#define MOBILE__ERROR_SOLENOID_ERROR             0x09
#define ERROR_SENSOR                             0x0a
#define ERROR_BAC_UPPER_LIMIT                    0x0b


/*******************************************************************************************/
/************** Callbacks received from the BACtrack Device Delegate ***********************/
/*******************************************************************************************/
@class Breathalyzer;
@protocol BacTrackAPIDelegate <NSObject>

/** API Key declined for some reason (firmware update required, etc). */
-(void)BacTrackAPIKeyDeclined:(NSString *)errorMessage;

@optional

/** API Key valid, you can now connect to a breathlyzer. */
-(void)BacTrackAPIKeyAuthorized;

/**
 * Connection Callbacks
 */

/** Successfully connected to BACtrack and found services and characteristics. */
-(void)BacTrackConnected __attribute__((deprecated));
-(void)BacTrackConnected:(BACtrackDeviceType)device;

/** Disconnected from BACTrack. */
-(void)BacTrackDisconnected;

/**
 * Taking a BAC test Callbacks
 */

/** Counting down to reading, estimated seconds left, error = TRUE if BAC sensor rejects request. */
-(void)BacTrackCountdown:(NSNumber*)seconds executionFailure:(BOOL)error;

/** Tell the user to start blowing. */
-(void)BacTrackStart;

/** Tell the user to keep blowing. */
-(void)BacTrackBlow;

/** BACtrack is analyzing the result.*/
-(void)BacTrackAnalyzing;

/** Result of the blow. */
-(void)BacTrackResults:(CGFloat)bac;

/**
 * Error Callbacks
 */

/** Error with device. e.g. "Not Connected", "Bluetooth Unsupported", etc. */
-(void)BacTrackError:(NSError*)error;

/** Attempting to connect to BACtrack timed out. */
-(void)BacTrackConnectTimeout;

/** Asks for connection timeout when connecting to nearest breathalyzer. */
-(NSTimeInterval)BacTrackGetTimeout;

/**
 * Accessory Callbacks
 */

/** Found a breathalyzer. Call comes in for every breathalyzer found during scan. */
-(void)BacTrackFoundBreathalyzer:(Breathalyzer*)breathalyzer;

/** Reports the hardware serial number. GoodAngel. */
-(void)BacTrackSerial:(NSString *)serial_hex;

/** Reports battery level.  0 is low (needs to be charged). 1 is medium, 2 is high. **/
-(void)BacTrackBatteryLevel:(NSNumber *)number;


@end


/*************************************************************************************************/
/****************************** Command calls to BACtrack Device *********************************/
/*************************************************************************************************/
@interface BacTrackAPI : NSObject

/** Callback delegate. Must be set. */
@property (strong, nonatomic) id<BacTrackAPIDelegate> delegate;

/** Initialize class with this method. Requires API Key. */
-(id)initWithDelegate:(id<BacTrackAPIDelegate>)delegate AndAPIKey:(NSString*)api_key;

/** NORMAL use case for connecting to a breathalyzer. */
-(void)connectToNearestBreathalyzer;


/** ALTERNATE use case for connecting to a breathalyzer.
 *  Use startScan and stopScan to get breathalyzer.
 *  Use CBPeripheral peripheral and NSString uuid to
 *  distinguish between multiple breathalyzers. */
-(void)connectBreathalyzer:(Breathalyzer*)breathalyzer withTimeout:(NSTimeInterval)timeout;

/** Scan for BACtrack breathalyzers. */
-(void)startScan;

/** Stop scanning for BACtrack breathalyzers. */
-(void)stopScan;

/** Disconnect from BACtrack breathalyzer. */
-(void)disconnect;

/** Start BACtrack Countdown to take a breathalyzer test, returns YES if test started succesfully,
 *  NO if errors. */
-(BOOL)startCountdown;

/** Initiate callback (BacTrackBatteryLevel) with the current 
  * battery level. */
-(void)getBreathalyzerBatteryLevel;


@end

/*************************************************************************************************/
/****************************** Breathalyzer properties *********************************/
/*************************************************************************************************/

@interface Breathalyzer : NSObject

@property (strong, nonatomic) NSString * uuid;
@property (strong, nonatomic) CBPeripheral * peripheral;
@property (strong, nonatomic) NSNumber * rssi;
@property (nonatomic) BACtrackDeviceType type;

@end
