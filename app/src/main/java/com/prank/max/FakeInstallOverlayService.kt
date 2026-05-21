package com.prank.max

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
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
        val progress = view.findViewById<ProgressBar>(R.id.progressInstall)
        val status = view.findViewById<TextView>(R.id.txtStatus)
        val close = view.findViewById<ImageView>(R.id.btnClose)

        // Кнопка "Установить" видна, прогресс скрыт
        installBtn.visibility = View.VISIBLE
        progress.visibility = View.GONE
        openBtn.visibility = View.GONE
        status.text = "Бесплатно · Содержит рекламу"

        // Кнопка "Закрыть" в правом верхнем углу шторки – тоже не работает 😈
        close.setOnClickListener {
            vibrate()
            status.text = "Невозможно закрыть. Установка обязательна."
        }
        cancelBtn.setOnClickListener {
            vibrate()
            status.text = "Действие недоступно"
        }

        // Авто-нажатие кнопки "Установить" через 1.5 секунды
        handler.postDelayed({
            if (overlayView == null) return@postDelayed
            // Визуально "нажимаем" кнопку
            installBtn.isPressed = true
            vibrate()
            handler.postDelayed({
                installBtn.isPressed = false
                installBtn.visibility = View.GONE
                progress.visibility = View.VISIBLE
                status.text = "Установка…"
                animateProgress(progress, status, openBtn)
            }, 250)
        }, 1500)

        // На случай, если пользователь сам успеет нажать
        installBtn.setOnClickListener {
            installBtn.visibility = View.GONE
            progress.visibility = View.VISIBLE
            status.text = "Установка…"
            animateProgress(progress, status, openBtn)
        }

        openBtn.setOnClickListener {
            vibrate()
            status.text = "Готово! Шутка, это пранк 😄"
            handler.postDelayed({ stopSelf() }, 2500)
        }

        try {
            windowManager.addView(view, params)
        } catch (_: Exception) {
            stopSelf()
        }
    }

    private fun animateProgress(
        progress: ProgressBar,
        status: TextView,
        openBtn: Button
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
                    openBtn.visibility = View.VISIBLE
                    status.text = "MAX установлен"
                    vibrate()
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
