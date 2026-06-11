package com.shipnow.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android side of the `shipnow/wallet` channel.
 *
 * Apple Wallet is iOS-only, so we always return `false` / `null` here.
 * The Flutter [WalletService] falls back to its in-app pkpass builder
 * (writes the .pkpass file to the cache dir and opens it with the
 * system PDF viewer) so the user can still share or inspect the file.
 */
class MainActivity : FlutterActivity() {
    private val walletChannel = "shipnow/wallet"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, walletChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(false)
                    "isPassInstalled" -> result.success(false)
                    "addPass" -> {
                        // On Android we open the .pkpass with the system
                        // viewer (most devices won't have a handler, but
                        // it lets the user share it via email etc).
                        val b64 = call.argument<String>("pkpassBase64")
                        val serial = call.argument<String>("serial") ?: "pass"
                        if (b64 == null) {
                            result.error("bad_args", "Missing pkpassBase64", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val bytes = android.util.Base64.decode(b64, android.util.Base64.DEFAULT)
                            val dir = cacheDir
                            val file = java.io.File(dir, "$serial.pkpass")
                            file.writeBytes(bytes)
                            val uri: Uri = androidx.core.content.FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.apple.pkpass")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, "Add to Wallet"))
                            result.success(false)  // not actually added; user has to follow the share flow
                        } catch (e: Exception) {
                            result.error("share_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
