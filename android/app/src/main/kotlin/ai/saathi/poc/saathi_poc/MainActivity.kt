package ai.saathi.poc.saathi_poc

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioRecordingConfiguration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Diagnostics bridge for the PoC. Exposes only what the app-switch experiment needs:
 * runtime permissions, the opt-in microphone foreground service, and Android's own view of
 * our microphone (AudioRecordingCallback), which is what tells us whether Android silenced
 * the mic after we left the foreground.
 */
class MainActivity : FlutterActivity() {
    private val permissionRequestCode = 4201
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var events: EventChannel.EventSink? = null
    private var recordingCallback: AudioManager.AudioRecordingCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val audioManager: AudioManager
        get() = getSystemService(AUDIO_SERVICE) as AudioManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "saathi_poc/android").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> requestVoicePermissions(result)
                "startVoiceService" -> result.success(startVoiceService())
                "stopVoiceService" -> {
                    stopService(Intent(this, VoiceSessionService::class.java))
                    result.success(true)
                }
                "deviceInfo" -> result.success(deviceInfo())
                "audioSnapshot" -> result.success(audioSnapshot())
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "saathi_poc/android_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    events = sink
                    registerRecordingCallback()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterRecordingCallback()
                    events = null
                }
            },
        )
    }

    override fun onPause() {
        super.onPause()
        emit(mapOf("type" to "activity", "event" to "onPause"))
    }

    override fun onStop() {
        super.onStop()
        emit(mapOf("type" to "activity", "event" to "onStop"))
    }

    override fun onResume() {
        super.onResume()
        emit(mapOf("type" to "activity", "event" to "onResume"))
    }

    override fun onDestroy() {
        unregisterRecordingCallback()
        super.onDestroy()
    }

    private fun emit(event: Map<String, Any?>) {
        mainHandler.post { events?.success(event) }
    }

    // ---------------------------------------------------------------- permissions

    private fun requestVoicePermissions(result: MethodChannel.Result) {
        val wanted = mutableListOf(Manifest.permission.RECORD_AUDIO)
        if (Build.VERSION.SDK_INT >= 33) wanted += Manifest.permission.POST_NOTIFICATIONS
        val missing = wanted.filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isEmpty()) {
            result.success(permissionState())
            return
        }
        if (pendingPermissionResult != null) {
            result.error("busy", "A permission request is already in progress", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(missing.toTypedArray(), permissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        pendingPermissionResult?.success(permissionState())
        pendingPermissionResult = null
    }

    private fun permissionState(): Map<String, Boolean> = mapOf(
        "microphone" to (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED),
        "notifications" to (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED),
    )

    // ---------------------------------------------------------------- foreground service

    /** Must be called while the activity is visible: Android 11+ only grants mic access to a
     *  foreground service that was started from the foreground ("while-in-use" rule). */
    private fun startVoiceService(): Map<String, Any?> = try {
        val intent = Intent(this, VoiceSessionService::class.java)
        if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
        mapOf("started" to true)
    } catch (e: Exception) {
        mapOf("started" to false, "error" to "${e.javaClass.simpleName}: ${e.message}")
    }

    // ---------------------------------------------------------------- audio diagnostics

    private fun registerRecordingCallback() {
        if (recordingCallback != null) return
        val callback = object : AudioManager.AudioRecordingCallback() {
            override fun onRecordingConfigChanged(configs: MutableList<AudioRecordingConfiguration>) {
                emit(mapOf("type" to "recording", "configs" to configs.map(::describe)))
            }
        }
        audioManager.registerAudioRecordingCallback(callback, mainHandler)
        recordingCallback = callback
    }

    private fun unregisterRecordingCallback() {
        recordingCallback?.let { audioManager.unregisterAudioRecordingCallback(it) }
        recordingCallback = null
    }

    private fun describe(config: AudioRecordingConfiguration): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>("sessionId" to config.clientAudioSessionId)
        if (Build.VERSION.SDK_INT >= 29) {
            // true = Android is feeding us silence (e.g. app backgrounded without a mic FGS)
            out["silenced"] = config.isClientSilenced
            out["source"] = config.clientAudioSource
        }
        return out
    }

    private fun audioSnapshot(): Map<String, Any?> = mapOf(
        "mode" to audioManager.mode, // 3 = MODE_IN_COMMUNICATION
        "micMuted" to audioManager.isMicrophoneMute,
        "musicActive" to audioManager.isMusicActive,
        "recordings" to audioManager.activeRecordingConfigurations.map(::describe),
    )

    private fun deviceInfo(): Map<String, Any?> = mapOf(
        "sdkInt" to Build.VERSION.SDK_INT,
        "release" to Build.VERSION.RELEASE,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "webView" to if (Build.VERSION.SDK_INT >= 26) {
            WebView.getCurrentWebViewPackage()?.let { "${it.packageName} ${it.versionName}" }
        } else {
            null
        },
    )
}
