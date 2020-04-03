import Flutter
import UIKit

public class SwiftFlutterBactrackPlugin: NSObject, FlutterPlugin {
  private static let CHANNEL_ID = "com.pleasingsoftware.flutter/bactrack_plugin"
  private static let initMethod = "init"
  private static let connectToNearestBreathalyzerMethod = "connectToNearestBreathalyzer"
  private static let connectToNearestBreathalyzerWithTimeoutMethod = "connectToNearestBreathalyzerWithTimeout"
  private static let disconnectMethod = "disconnect"
  private static let startScanMethod = "startScan"
  private static let stopScanMethod = "stopScan"
  private static let connectToDeviceMethod = "connectToDevice"
  private static let startCountdownMethod = "startCountdown"
  private static let getBreathalyzerBatteryVoltageMethod = "getBreathalyzerBatteryVoltage"
  private static let getUseCountMethod = "getUseCount"
  private static let getSerialNumberMethod = "getSerialNumber"
  private static let getFirmwareVersionMethod = "getFirmwareVersion"
  
  private var api: BacTrackAPI? = nil
  private let channel: FlutterMethodChannel
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: CHANNEL_ID, binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterBactrackPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("FlutterBactrackPlugin: Got method %@ with args %@", call.method, String(describing: call.arguments))
    
    switch call.method {
    case SwiftFlutterBactrackPlugin.initMethod:
      handleInit(argsAsString(call.arguments), result)
    case SwiftFlutterBactrackPlugin.connectToNearestBreathalyzerMethod:
      handleConnectToNearest(result)
    case SwiftFlutterBactrackPlugin.connectToNearestBreathalyzerWithTimeoutMethod:
      handleConnectToNearestWithTimeout(result)
    case SwiftFlutterBactrackPlugin.disconnectMethod:
      handleDisconnect(result)
    case SwiftFlutterBactrackPlugin.startCountdownMethod:
      handleCountdown(result)
    case SwiftFlutterBactrackPlugin.getBreathalyzerBatteryVoltageMethod:
      handleGetBatteryVoltage(result)
    default:
      result(FlutterError(code: "UNSUPPORTED",
                          message: "Method call '\(call.method)' is not supported on iOS",
        details: nil))
    }
  }
  
  private func handleInit(_ apiKey: String, _ result: @escaping FlutterResult) {
    api = BacTrackAPI(delegate: ApiCallbacks(channel: channel), andAPIKey: apiKey)
    result(nil)
  }

  private func handleConnectToNearest(_ result: @escaping FlutterResult) {
    NSLog("Got connectToNearest")
    api?.connectToNearestBreathalyzer()
    result(nil)
  }
  
  private func handleConnectToNearestWithTimeout(_ result: @escaping FlutterResult) {
    NSLog("Got connectToNearest")
    api?.connectToNearestBreathalyzer()
    result(nil)
  }
  
  private func handleDisconnect(_ result: FlutterResult) {
      api?.disconnect()
      result(nil)
  }

  private func handleCountdown(_ result: FlutterResult) {
      result(api?.startCountdown())
  }

  private func handleGetBatteryVoltage(_ result: FlutterResult) {
    api?.getBreathalyzerBatteryLevel()
    result(nil)
  }

  private func argsAsString(_ args: Any?) -> String { args as? String ?? "" }
  
  class ApiCallbacks : NSObject, BacTrackAPIDelegate {
    private static let apiKeyDeclinedMethod = "apiKeyDeclined"
    private static let apiKeyAuthorizedMethod = "apiKeyAuthorized"
    private static let didConnectMethod = "didConnect"
    private static let connectedMethod = "connected"
    private static let disconnectedMethod = "disconnected"
    private static let connectionTimeoutMethod = "connectionTimeout"
    private static let foundBreathalyzerMethod = "foundBreathalyzer"
    private static let countDownMethod = "countDown"
    private static let startBlowingMethod = "startBlowing"
    private static let keepBlowingMethod = "keepBlowing"
    private static let analyzingMethod = "analyzing"
    private static let resultsMethod = "results"
    private static let firmwareVersionMethod = "firmwareVersion"
    private static let serialNumberMethod = "serialNumber"
    private static let unitsMethod = "units"
    private static let useCountMethod = "useCount"
    private static let batteryVoltageMethod = "batteryVoltage"
    private static let batteryLevelMethod = "batteryLevel"
    private static let errorMethod = "error"
    
    private let channel: FlutterMethodChannel
    
    init(channel: FlutterMethodChannel) {
      self.channel = channel
      super.init()
    }
    
    func bacTrackAPIKeyAuthorized() {
      channel.invokeMethod(ApiCallbacks.apiKeyAuthorizedMethod, arguments: nil)
    }
    
    func bacTrackAPIKeyDeclined(_ errorMessage: String!) {
      channel.invokeMethod(ApiCallbacks.apiKeyDeclinedMethod, arguments: errorMessage)
    }
    
    func bacTrackError(_ error: Error!) {
      channel.invokeMethod(ApiCallbacks.errorMethod, arguments: error.localizedDescription)
    }
    
    func bacTrackConnected(_ device: BACtrackDeviceType) {
      channel.invokeMethod(ApiCallbacks.connectedMethod, arguments: deviceTypeToString(device))
    }
    
    func bacTrackConnectTimeout() {
      channel.invokeMethod(ApiCallbacks.connectionTimeoutMethod, arguments: nil)
    }
    
    func bacTrackDisconnected() {
      channel.invokeMethod(ApiCallbacks.disconnectedMethod, arguments: nil)
    }
    
    func bacTrackFound(_ breathalyzer: Breathalyzer!) {
      channel.invokeMethod(ApiCallbacks.foundBreathalyzerMethod, arguments: deviceTypeToString(breathalyzer.type))
    }
    
    func bacTrackCountdown(_ seconds: NSNumber!, executionFailure error: Bool) {
      channel.invokeMethod(ApiCallbacks.countDownMethod, arguments: seconds.stringValue)
    }
    
    func bacTrackStart() {
      channel.invokeMethod(ApiCallbacks.startBlowingMethod, arguments: nil)
    }
    
    func bacTrackBlow() {
      channel.invokeMethod(ApiCallbacks.keepBlowingMethod, arguments: nil)
    }
    
    func bacTrackAnalyzing() {
      channel.invokeMethod(ApiCallbacks.analyzingMethod, arguments: nil)
    }
    
    func bacTrackResults(_ bac: CGFloat) {
      channel.invokeMethod(ApiCallbacks.resultsMethod, arguments: "\(bac)")
    }
    
    func bacTrackSerial(_ serial_hex: String!) {
      channel.invokeMethod(ApiCallbacks.serialNumberMethod, arguments: serial_hex)
    }
    
    func bacTrackBatteryLevel(_ number: NSNumber!) {
      channel.invokeMethod(ApiCallbacks.batteryLevelMethod, arguments: number.stringValue)
    }
    
    private func deviceTypeToString(_ device: BACtrackDeviceType) -> String {
      switch device {
      case .mobile:
        return "BACtrack Mobile"
      case .vio:
        return "BACtrack Vio"
      default:
        return "Unknown BACtrack Device"
      }
    }
  }
}
