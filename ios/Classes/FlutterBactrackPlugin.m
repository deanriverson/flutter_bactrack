#import "FlutterBactrackPlugin.h"
#if __has_include(<flutter_bactrack/flutter_bactrack-Swift.h>)
#import <flutter_bactrack/flutter_bactrack-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_bactrack-Swift.h"
#endif

#import "BACtrack.h"

@implementation FlutterBactrackPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterBactrackPlugin registerWithRegistrar:registrar];
}
@end
