package org.stride.tracker.data.local

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow

@Dao
interface DailySummaryDao {
    @Upsert
    suspend fun upsert(summary: DailySummary)

    @Query("SELECT * FROM daily_summaries WHERE date BETWEEN :start AND :end ORDER BY date DESC")
    fun getRange(start: String, end: String): Flow<List<DailySummary>>

    @Query("SELECT * FROM daily_summaries WHERE date = :date")
    fun getDay(date: String): Flow<DailySummary?>
}
