package com.prank.max

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val overlayPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        updateUi()
        if (Settings.canDrawOverlays(this)) {
            startPrank()
        } else {
            Toast.makeText(
                this,
                "Без разрешения пранк не сработает",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        findViewById<Button>(R.id.btnRequestPermission).setOnClickListener {
            requestOverlayPermission()
        }
        findViewById<Button>(R.id.btnStartPrank).setOnClickListener {
            if (Settings.canDrawOverlays(this)) {
                startPrank()
            } else {
                requestOverlayPermission()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        updateUi()
    }

    private fun updateUi() {
        val granted = Settings.canDrawOverlays(this)
        val status = findViewById<TextView>(R.id.txtStatus)
        status.text = if (granted) {
            "✅ Разрешение получено"
        } else {
            "⚠️ Разрешение на вспл. окна не выдано"
        }
        findViewById<Button>(R.id.btnStartPrank).isEnabled = granted
    }

    private fun requestOverlayPermission() {
        if (Settings.canDrawOverlays(this)) {
            updateUi()
            return
        }
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        overlayPermissionLauncher.launch(intent)
    }

    private fun startPrank() {
        val intent = Intent(this, FakeInstallOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        // Уводим пользователя на домашний экран, чтобы окно "висело" поверх
        val home = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(home)
    }
}
