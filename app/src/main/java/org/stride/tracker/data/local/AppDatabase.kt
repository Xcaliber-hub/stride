package org.stride.tracker.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [DailySummary::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun dailySummaryDao(): DailySummaryDao
}
