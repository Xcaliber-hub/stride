package org.stride.tracker.ui

import android.app.Application
import org.stride.tracker.data.di.AppContainer
import org.stride.tracker.data.work.DailySyncWorker

class StrideApp : Application() {
    lateinit var appContainer: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        appContainer = AppContainer(this)
        DailySyncWorker.schedule(this)
    }
}
