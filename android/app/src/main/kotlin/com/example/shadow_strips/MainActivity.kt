package com.example.shadow_strips

import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

class MainActivity: FlutterActivity() {
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Tell OS we are drawing edge-to-edge
            WindowCompat.setDecorFitsSystemWindows(window, false)
            
            val controller = WindowInsetsControllerCompat(window, window.decorView)
            
            // 1. Keep Top Status Bar Visible
            controller.show(WindowInsetsCompat.Type.statusBars())
            
            // 2. Hide Bottom Navigation Bar
            controller.hide(WindowInsetsCompat.Type.navigationBars())
            
            // 3. FORCE 3-Second Auto-Hide Spring (Transient)
            controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }
}
