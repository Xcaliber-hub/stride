package org.stride.tracker.data.di

import android.content.Context
import androidx.room.Room
import org.stride.tracker.data.health.HealthConnectManager
import org.stride.tracker.data.local.AppDatabase
import org.stride.tracker.data.local.DailySummaryDao
import org.stride.tracker.data.prefs.UserPrefs
import org.stride.tracker.data.repo.FitnessRepository

class AppContainer(context: Context) {
    private val database: AppDatabase = Room.databaseBuilder(
        context.applicationContext,
        AppDatabase::class.java,
        "stride.db",
    ).build()

    val dailySummaryDao: DailySummaryDao = database.dailySummaryDao()
    val userPrefs: UserPrefs = UserPrefs(context.applicationContext)
    val healthConnectManager: HealthConnectManager = HealthConnectManager(context.applicationContext)
    val repository: FitnessRepository = FitnessRepository(
        dao = dailySummaryDao,
        prefs = userPrefs,
        healthConnect = healthConnectManager,
    )
}
