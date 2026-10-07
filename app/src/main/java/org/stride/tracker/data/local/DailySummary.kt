package org.stride.tracker.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "daily_summaries")
data class DailySummary(
    @PrimaryKey val date: String, // yyyy-MM-dd
    val steps: Long = 0L,
    val distanceMeters: Double = 0.0,
    val caloriesKcal: Double = 0.0,
    val activeMinutes: Int = 0,
    val stepsEstimated: Boolean = false,
    val distanceEstimated: Boolean = false,
    val caloriesEstimated: Boolean = false,
)
