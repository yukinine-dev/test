package com.prank.max

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

class FakeInstallOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startInForeground()
        showOverlay()
    }

    private fun startInForeground() {
        val channelId = "max_prank_channel"
        val nm = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "MAX",
                NotificationManager.IMPORTANCE_MIN
            )
            nm.createNotificationChannel(channel)
        }
        val notif: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("MAX")
            .setContentText("Подготовка к установке…")
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .build()
        startForeground(1, notif)
    }

    private fun showOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.CENTER

        val view = LayoutInflater.from(this)
            .inflate(R.layout.overlay_fake_install, null, false)
        overlayView = view

        val installBtn = view.findViewById<Button>(R.id.btnInstall)
        val openBtn = view.findViewById<Button>(R.id.btnOpen)
        val cancelBtn = view.findViewById<Button>(R.id.btnCancel)
        val progressArea = view.findViewById<View>(R.id.installProgressArea)
        val progress = view.findViewById<ProgressBar>(R.id.progressInstall)
        val status = view.findViewById<TextView>(R.id.txtStatus)
        val back = view.findViewById<ImageView>(R.id.btnBack)
        val settings = view.findViewById<ImageView>(R.id.btnSettings)
        val permissions = view.findViewById<View>(R.id.cardPermissions)
        val permissionScrim = view.findViewById<View>(R.id.permissionScrim)
        val allowShortcutBtn = view.findViewById<Button>(R.id.btnAllowShortcut)
        val denyShortcutBtn = view.findViewById<Button>(R.id.btnDenyShortcut)

        // Initial state
        installBtn.visibility = View.VISIBLE
        cancelBtn.visibility = View.VISIBLE
        openBtn.visibility = View.GONE
        progressArea.visibility = View.GONE
        permissionScrim.visibility = View.GONE
        status.text = "Установка…"

        // Inert top-bar and permissions card
        back.setOnClickListener { vibrate() }
        settings.setOnClickListener { vibrate() }
        permissions.setOnClickListener { vibrate() }
        cancelBtn.setOnClickListener { vibrate() }
        denyShortcutBtn.setOnClickListener { vibrate() }

        val startInstall = {
            installBtn.visibility = View.GONE
            cancelBtn.visibility = View.GONE
            progressArea.visibility = View.VISIBLE
            status.text = "Установка…"
            animateProgress(progress, status) {
                openBtn.visibility = View.VISIBLE
                showShortcutPermission(permissionScrim, allowShortcutBtn)
            }
        }

        // Авто-нажатие "Установить" через 1.5 секунды
        handler.postDelayed({
            if (overlayView == null) return@postDelayed
            installBtn.isPressed = true
            vibrate()
            handler.postDelayed({
                installBtn.isPressed = false
                startInstall()
            }, 250)
        }, 1500)

        installBtn.setOnClickListener { startInstall() }

        openBtn.setOnClickListener {
            vibrate()
            status.text = "Это пранк 😄"
            handler.postDelayed({ stopSelf() }, 2000)
        }

        try {
            windowManager.addView(view, params)
        } catch (_: Exception) {
            stopSelf()
        }
    }

    private fun showShortcutPermission(scrim: View, allowBtn: Button) {
        scrim.visibility = View.VISIBLE

        val doAllow = {
            pinMaxShortcut()
            scrim.visibility = View.GONE
        }

        allowBtn.setOnClickListener { doAllow() }

        // Авто-нажатие "Разрешить" через 1.2 с
        handler.postDelayed({
            if (overlayView == null) return@postDelayed
            allowBtn.isPressed = true
            vibrate()
            handler.postDelayed({
                allowBtn.isPressed = false
                doAllow()
            }, 250)
        }, 1200)
    }

    private fun pinMaxShortcut() {
        if (!ShortcutManagerCompat.isRequestPinShortcutSupported(this)) return

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            putExtra("from_max_shortcut", true)
        }

        val info = ShortcutInfoCompat.Builder(this, "max_pinned_shortcut")
            .setShortLabel("MAX")
            .setLongLabel("MAX")
            .setIcon(IconCompat.createWithResource(this, R.drawable.ic_max_logo))
            .setIntent(launchIntent)
            .build()

        val callbackIntent = ShortcutManagerCompat.createShortcutResultIntent(this, info)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        val successCallback = PendingIntent.getBroadcast(this, 0, callbackIntent, flags)

        try {
            ShortcutManagerCompat.requestPinShortcut(this, info, successCallback.intentSender)
        } catch (_: Exception) {
        }
    }

    private fun animateProgress(
        progress: ProgressBar,
        status: TextView,
        onDone: () -> Unit
    ) {
        progress.max = 100
        progress.progress = 0
        val step = 2
        val interval = 80L
        val runnable = object : Runnable {
            override fun run() {
                val next = progress.progress + step
                progress.progress = next
                status.text = when {
                    next < 30 -> "Загрузка… ${next}%"
                    next < 70 -> "Установка… ${next}%"
                    next < 100 -> "Завершение… ${next}%"
                    else -> "Установлено"
                }
                if (next >= 100) {
                    progress.visibility = View.GONE
                    status.text = "MAX установлен"
                    vibrate()
                    onDone()
                } else {
                    handler.postDelayed(this, interval)
                }
            }
        }
        handler.post(runnable)
    }

    private fun vibrate() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.vibrate(VibrationEffect.createOneShot(40, 120))
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createOneShot(40, 120))
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(40)
                }
            }
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {
            }
        }
        overlayView = null
        super.onDestroy()
    }
}
