package org.stride.tracker.data.work

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import org.stride.tracker.data.repo.FitnessRepository
import org.stride.tracker.ui.StrideApp
import java.util.concurrent.TimeUnit

class DailySyncWorker(appContext: Context, params: WorkerParameters) :
    CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result = try {
        when (val sync = (applicationContext as StrideApp).appContainer.repository.syncRecent()) {
            is FitnessRepository.SyncResult.Success -> Result.success()
            is FitnessRepository.SyncResult.Skipped -> Result.success()
            is FitnessRepository.SyncResult.Failed -> Result.retry()
        }
    } catch (e: Exception) {
        Result.retry()
    }

    companion object {
        private const val UNIQUE_WORK_NAME = "stride_daily_sync"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<DailySyncWorker>(6, TimeUnit.HOURS)
                .setConstraints(
                    Constraints.Builder()
                        .setRequiresBatteryNotLow(true)
                        .build(),
                )
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
        }
    }
}
