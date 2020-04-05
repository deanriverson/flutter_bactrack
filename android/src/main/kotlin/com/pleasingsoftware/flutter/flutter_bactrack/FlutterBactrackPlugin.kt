@file:Suppress("unused")

package com.pleasingsoftware.flutter.flutter_bactrack

import BACtrackAPI.API.BACtrackAPI
import BACtrackAPI.API.BACtrackAPI.BACtrackDevice
import BACtrackAPI.API.BACtrackAPICallbacks
import BACtrackAPI.Constants.BACTrackDeviceType
import BACtrackAPI.Constants.BACtrackUnit
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar


private const val tag = "FlutterBactrackPlugin"
private const val CHANNEL_ID = "com.pleasingsoftware.flutter/bactrack_plugin"

// Methods coming in from Dart. MUST BE kept in sync with strings in flutter_bactrack.dart.
private const val initMethod = "init"
private const val connectToNearestBreathalyzerMethod = "connectToNearestBreathalyzer"
private const val connectToNearestBreathalyzerWithTimeoutMethod = "connectToNearestBreathalyzerWithTimeout"
private const val disconnectMethod = "disconnect"
private const val startScanMethod = "startScan"
private const val stopScanMethod = "stopScan"
private const val connectToDeviceMethod = "connectToDevice"
private const val startCountdownMethod = "startCountdown"
private const val getBreathalyzerBatteryVoltageMethod = "getBreathalyzerBatteryVoltage"
private const val getUseCountMethod = "getUseCount"
private const val getSerialNumberMethod = "getSerialNumber"
private const val getFirmwareVersionMethod = "getFirmwareVersion"

// Methods going back to Dart. MUST BE kept in sync with BACtrackState enum in flutter_bactrack.dart.
private const val apiKeyDeclinedMethod = "apiKeyDeclined"
private const val apiKeyAuthorizedMethod = "apiKeyAuthorized"
private const val didConnectMethod = "didConnect"
private const val connectedMethod = "connected"
private const val disconnectedMethod = "disconnected"
private const val connectionTimeoutMethod = "connectionTimeout"
private const val foundBreathalyzerMethod = "foundBreathalyzer"
private const val countDownMethod = "countDown"
private const val startBlowingMethod = "startBlowing"
private const val keepBlowingMethod = "keepBlowing"
private const val analyzingMethod = "analyzing"
private const val resultsMethod = "results"
private const val firmwareVersionMethod = "firmwareVersion"
private const val serialNumberMethod = "serialNumber"
private const val unitsMethod = "units"
private const val useCountMethod = "useCount"
private const val batteryVoltageMethod = "batteryVoltage"
private const val batteryLevelMethod = "batteryLevel"
private const val errorMethod = "error"

/** FlutterBactrackPlugin */
class FlutterBactrackPlugin : FlutterPlugin, PluginRegistry.RequestPermissionsResultListener, ActivityAware {
    companion object {
        private var plugin: FlutterBactrackPlugin? = null

        // The static registerWith function is optional and equivalent to onAttachedToEngine. It
        // supports the old pre-Flutter-1.12 Android projects. You are encouraged to continue
        // supporting plugin registration via this function while apps migrate to use the new
        // Android APIs post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
        //
        // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
        // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be
        // called depending on the user's project. onAttachedToEngine or registerWith must both
        // be defined in the same class.
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            Log.i(tag, "BACtrack plugin registering through old interface!")
            plugin = FlutterBactrackPlugin()
            plugin?.initChannel(registrar.messenger(), registrar.context(), registrar.activity())
        }
    }

    private val pluginPermissionCode = 10100101
    private val mainLooper = Handler(Looper.getMainLooper())

    private lateinit var channel: MethodChannel
    private lateinit var pluginContext: Context

    private var api: BACtrackAPI? = null
    private var pluginActivityBinding: ActivityPluginBinding? = null
    private var pluginActivity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.v(tag, "BACtrack plugin attached to engine")
        initChannel(flutterPluginBinding.binaryMessenger, flutterPluginBinding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Nothing to do yet
        Log.v(tag, "BACtrack plugin detached to engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.v(tag, "BACtrack plugin attached to activity")
        handleAttachment(binding)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.v(tag, "BACtrack plugin reattached to activity for config changes")
        handleAttachment(binding)
    }

    override fun onDetachedFromActivity() {
        Log.v(tag, "BACtrack plugin detached from activity")
        handleDetachment()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.v(tag, "BACtrack plugin detached from activity for config changes")
        handleDetachment()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>?,
        grantResults: IntArray?
    ): Boolean {
        Log.i(tag, "BACtrack plugin onRequestPermissionsResult: code $requestCode, permissions: ${permissions?.joinToString() ?: "null"}, grantResults: ${grantResults?.joinToString() ?: "null"}")
        return when (requestCode) {
            pluginPermissionCode -> handlePermissionResult(grantResults)
            else -> false
        }
    }

    private fun handleAttachment(binding: ActivityPluginBinding) {
        if (pluginActivityBinding == null) {
            pluginActivityBinding = binding
            pluginActivity = pluginActivityBinding!!.activity
            binding.addRequestPermissionsResultListener(this)
        }
    }

    private fun handleDetachment() {
        if (pluginActivityBinding == null)
            return

        pluginActivityBinding?.removeRequestPermissionsResultListener(this)
        pluginActivity = null
        pluginActivityBinding = null
    }

    /**
     * This may be called in one of two ways depending on whether the plugin is being initialized using
     * the old Flutter plugin code (i.e. via the static registerWith method above) or the new plugin
     * code (i.e. via the onAttachedToEngine method above).  When initializing with the old method, we
     * must save a reference to our Activity since this will be the only way to get it.  When initializing
     * with the new method, the activity ref is saved during the handleAttachment method.
     */
    private fun initChannel(messenger: BinaryMessenger, ctx: Context, activity: Activity? = null) {
        pluginContext = ctx
        pluginActivity = activity

        channel = MethodChannel(messenger, CHANNEL_ID)

        channel.setMethodCallHandler { call: MethodCall, result: Result ->
            Log.i(tag, "BACtrack plugin received method call '${call.method}' with args '${call.arguments}'")
            when (call.method) {
                initMethod -> handleInit(call.arguments.toString(), result)
                connectToNearestBreathalyzerMethod -> handleConnectToNearest(result)
                connectToNearestBreathalyzerWithTimeoutMethod -> handleConnectToNearestWithTimeout(result)
                disconnectMethod -> handleDisconnect(result)
                startScanMethod -> result.notImplemented()
                stopScanMethod -> result.notImplemented()
                startCountdownMethod -> handleCountdown(result)
                getBreathalyzerBatteryVoltageMethod -> handleGetBatteryVoltage(result)
                getUseCountMethod -> handleGetUseCount(result)
                getSerialNumberMethod -> handleGetSerialNumber(result)
                getFirmwareVersionMethod -> handleGetFirmwareVersion(result)
                else -> result.notImplemented()
            }
        }
    }

    private var apiInitializer: ((Boolean) -> Unit) = { _ -> Unit }

    private fun createApiInitializer(apiKey: String, result: Result): (Boolean) -> Unit {
        return { permissionGranted ->
            if (permissionGranted) {
                Log.i(tag, "Creating BACtrack API object with API key: '$apiKey'")
                api = BACtrackAPI(pluginContext, mCallbacks, apiKey)
                result.success(true)
            } else {
                result.error("Permission Error", "Bluetooth permissions not granted", null)
            }
        }
    }

    private fun handleInit(apiKey: String, result: Result) {
        if (api != null) {
            // Already init'd
            result.success(null)
            return
        }

        apiInitializer = createApiInitializer(apiKey, result)

        // TODO make sure we have a permission result before we do anything else
        if (checkPermissions()) {
            apiInitializer(true)
        }
    }

    private fun handleConnectToNearest(result: Result) {
        api?.connectToNearestBreathalyzer()
        result.success(null)
    }

    private fun handleConnectToNearestWithTimeout(result: Result) {
        api?.connectToNearestBreathalyzerWithTimeout()
        result.success(null)
    }

    private fun handleDisconnect(result: Result) {
        api?.disconnect()
        result.success(null)
    }

    private fun handleCountdown(result: Result) {
        result.success(api?.startCountdown())
    }

    private fun handleGetBatteryVoltage(result: Result) {
        result.success(api?.breathalyzerBatteryVoltage)
    }

    private fun handleGetUseCount(result: Result) {
        result.success(api?.useCount)
    }

    private fun handleGetSerialNumber(result: Result) {
        result.success(api?.serialNumber)
    }

    private fun handleGetFirmwareVersion(result: Result) {
        result.success(api?.firmwareVersion)
    }

    private val mCallbacks: BACtrackAPICallbacks = object : BACtrackAPICallbacks {
        override fun BACtrackAPIKeyDeclined(errorMessage: String) {
            invokeChannelMethodOnMainThread(apiKeyDeclinedMethod, errorMessage)
        }

        override fun BACtrackAPIKeyAuthorized() {
            invokeChannelMethodOnMainThread(apiKeyAuthorizedMethod, null)
        }

        override fun BACtrackConnected(bacTrackDeviceType: BACTrackDeviceType) {
            invokeChannelMethodOnMainThread(connectedMethod, bacTrackDeviceType.name)
        }

        override fun BACtrackDidConnect(message: String) {
            invokeChannelMethodOnMainThread(didConnectMethod, message)
        }

        override fun BACtrackDisconnected() {
            invokeChannelMethodOnMainThread(disconnectedMethod, null)
        }

        override fun BACtrackConnectionTimeout() {
            invokeChannelMethodOnMainThread(connectionTimeoutMethod, null)
        }

        override fun BACtrackUnits(unit: BACtrackUnit) {
            invokeChannelMethodOnMainThread(unitsMethod, unit.name)
        }

        override fun BACtrackFoundBreathalyzer(bacTrackDevice: BACtrackDevice) {
            // TODO - add devices to a map as they're found so we can connect to them later
            invokeChannelMethodOnMainThread(
                foundBreathalyzerMethod,
                "${bacTrackDevice.type.name}@${bacTrackDevice.device.address}"
            )
        }

        override fun BACtrackCountdown(currentCountdownCount: Int) {
            invokeChannelMethodOnMainThread(countDownMethod, currentCountdownCount.toString())
        }

        override fun BACtrackStart() {
            invokeChannelMethodOnMainThread(startBlowingMethod, null)
        }

        override fun BACtrackBlow() {
            invokeChannelMethodOnMainThread(keepBlowingMethod, null)
        }

        override fun BACtrackAnalyzing() {
            invokeChannelMethodOnMainThread(analyzingMethod, null)
        }

        override fun BACtrackResults(measuredBac: Float) {
            invokeChannelMethodOnMainThread(resultsMethod, measuredBac.toString())
        }

        override fun BACtrackFirmwareVersion(version: String) {
            invokeChannelMethodOnMainThread(firmwareVersionMethod, version)
        }

        override fun BACtrackSerial(serialHex: String) {
            invokeChannelMethodOnMainThread(serialNumberMethod, serialHex)
        }

        override fun BACtrackUseCount(useCount: Int) {
            invokeChannelMethodOnMainThread(useCountMethod, useCount.toString())
        }

        override fun BACtrackBatteryVoltage(voltage: Float) {
            invokeChannelMethodOnMainThread(batteryVoltageMethod, voltage.toString())
        }

        override fun BACtrackBatteryLevel(level: Int) {
            invokeChannelMethodOnMainThread(batteryLevelMethod, level.toString())
        }

        override fun BACtrackError(errorCode: Int) {
            invokeChannelMethodOnMainThread(errorMethod, errorCode.toString())
        }
    }

    private fun invokeChannelMethodOnMainThread(method: String, argument: String?) {
        Log.v(tag, "BACtrack callback $method: $argument")
        mainLooper.post { channel.invokeMethod(method, argument) }
    }

    private fun checkPermissions(): Boolean {
        if (pluginActivity == null) {
            return false
        }

        if (
            isPermissionGranted(pluginActivity!!, Manifest.permission.BLUETOOTH) &&
            isPermissionGranted(pluginActivity!!, Manifest.permission.BLUETOOTH_ADMIN) &&
            isPermissionGranted(pluginActivity!!, Manifest.permission.ACCESS_FINE_LOCATION) &&
            isPermissionGranted(pluginActivity!!, Manifest.permission.ACCESS_NETWORK_STATE)
        ) {
            Log.i(tag, "BACtrack plugin checkPermissions(): permissions have already been granted")
            return true
        }

        Log.i(tag, "BACtrack plugin checkPermissions(): requesting permissions")

        val perms = arrayOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_NETWORK_STATE
        )

        pluginActivity!!.requestPermissions(perms, pluginPermissionCode)
        return false
    }

    private fun isPermissionGranted(activity: Activity, permStr: String) =
        ContextCompat.checkSelfPermission(activity, permStr) == PackageManager.PERMISSION_GRANTED

    private fun handlePermissionResult(grantResults: IntArray?): Boolean {
        Log.i(tag, "BACtrack plugin: handlePermissionResult: grantResults: ${grantResults?.joinToString() ?: "null"}")

        val permissionGranted = grantResults?.isNotEmpty() == true &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        Log.i(tag, "BACtrack plugin permissions granted? $permissionGranted")
        apiInitializer(permissionGranted)

        // we handled the request code
        return true
    }
}
