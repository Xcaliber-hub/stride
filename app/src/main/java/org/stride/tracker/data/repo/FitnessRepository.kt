package org.stride.tracker.data.repo

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.stride.tracker.data.health.HealthConnectManager
import org.stride.tracker.data.local.DailySummary
import org.stride.tracker.data.local.DailySummaryDao
import org.stride.tracker.data.prefs.UserPrefs
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class FitnessRepository(
    private val dao: DailySummaryDao,
    private val prefs: UserPrefs,
    private val healthConnect: HealthConnectManager,
) {

    fun today(): LocalDate = LocalDate.now(ZoneId.systemDefault())

    private fun key(d: LocalDate) = d.format(DateTimeFormatter.ISO_LOCAL_DATE)

    fun todaySummary(): Flow<DailySummary?> = dao.getDay(key(today()))

    fun rangeSummaries(start: LocalDate, end: LocalDate): Flow<List<DailySummary>> =
        dao.getRange(key(start), key(end))

    data class PeriodTotals(
        val steps: Long,
        val distanceMeters: Double,
        val caloriesKcal: Double,
        val activeMinutes: Int,
        val daysTracked: Int,
    )

    fun totals(start: LocalDate, end: LocalDate): Flow<PeriodTotals> =
        rangeSummaries(start, end).map { days ->
            PeriodTotals(
                steps = days.sumOf { it.steps },
                distanceMeters = days.sumOf { it.distanceMeters },
                caloriesKcal = days.sumOf { it.caloriesKcal },
                activeMinutes = days.sumOf { it.activeMinutes },
                daysTracked = days.count { it.steps > 0 },
            )
        }

    sealed interface SyncResult {
        data object Success : SyncResult
        data class Skipped(val reason: String) : SyncResult
        data class Failed(val error: Throwable) : SyncResult
    }

    suspend fun syncRange(start: LocalDate, end: LocalDate): SyncResult {
        if (!healthConnect.isAvailable()) {
            return SyncResult.Skipped("Health Connect is not available on this device")
        }
        if (!healthConnect.hasAllPermissions()) {
            return SyncResult.Skipped("Health Connect permissions not granted")
        }
        return try {
            val prefsSnapshot = prefs.snapshot()
            for (aggregate in healthConnect.readDailyAggregates(start, end)) {
                val steps = aggregate.steps ?: 0L

                val distanceMeters: Double
                val distanceEstimated: Boolean
                if (aggregate.distanceMeters != null) {
                    distanceMeters = aggregate.distanceMeters
                    distanceEstimated = false
                } else {
                    distanceMeters = steps * prefsSnapshot.strideLengthCm / 100.0
                    distanceEstimated = true
                }

                val caloriesKcal: Double
                val caloriesEstimated: Boolean
                if (aggregate.caloriesKcal != null) {
                    caloriesKcal = aggregate.caloriesKcal
                    caloriesEstimated = false
                } else {
                    caloriesKcal = steps * 0.045 * (prefsSnapshot.weightKg / 70.0)
                    caloriesEstimated = true
                }

                dao.upsert(
                    DailySummary(
                        date = key(aggregate.date),
                        steps = steps,
                        distanceMeters = distanceMeters,
                        caloriesKcal = caloriesKcal,
                        activeMinutes = (steps / 120).toInt(),
                        distanceEstimated = distanceEstimated,
                        caloriesEstimated = caloriesEstimated,
                    ),
                )
            }
            SyncResult.Success
        } catch (e: Exception) {
            SyncResult.Failed(e)
        }
    }

    suspend fun syncRecent(): SyncResult = syncRange(today().minusDays(2), today())

    suspend fun backfillYear(): SyncResult = syncRange(today().minusDays(364), today())
}
