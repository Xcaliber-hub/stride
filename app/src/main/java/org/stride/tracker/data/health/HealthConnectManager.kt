package org.stride.tracker.data.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.aggregate.AggregateRequest
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.LocalDate
import java.time.ZoneId

class HealthConnectManager(private val context: Context) {

    val permissions: Set<String> = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
    )

    fun sdkStatus(): Int = HealthConnectClient.getSdkStatus(context)

    fun isAvailable(): Boolean = sdkStatus() == HealthConnectClient.SDK_AVAILABLE

    suspend fun hasAllPermissions(): Boolean = try {
        HealthConnectClient.getOrCreate(context)
            .permissionController
            .getGrantedPermissions()
            .containsAll(permissions)
    } catch (e: Exception) {
        false
    }

    data class DayAggregate(
        val date: LocalDate,
        val steps: Long?,
        val distanceMeters: Double?,
        val caloriesKcal: Double?,
        val activeMinutes: Int? = null,
    )

    suspend fun readDailyAggregates(start: LocalDate, end: LocalDate): List<DayAggregate> {
        val client = HealthConnectClient.getOrCreate(context)
        val zone = ZoneId.systemDefault()
        val days = generateSequence(start) { it.plusDays(1) }.takeWhile { !it.isAfter(end) }
        return days.map { date ->
            try {
                val filter = TimeRangeFilter.between(
                    date.atStartOfDay(zone).toInstant(),
                    date.plusDays(1).atStartOfDay(zone).toInstant(),
                )
                val result = client.aggregate(
                    AggregateRequest(
                        metrics = setOf(
                            StepsRecord.COUNT_TOTAL,
                            DistanceRecord.DISTANCE_TOTAL,
                            TotalCaloriesBurnedRecord.ENERGY_TOTAL,
                        ),
                        timeRangeFilter = filter,
                    ),
                )
                DayAggregate(
                    date = date,
                    steps = result[StepsRecord.COUNT_TOTAL],
                    distanceMeters = result[DistanceRecord.DISTANCE_TOTAL]?.inMeters,
                    caloriesKcal = result[TotalCaloriesBurnedRecord.ENERGY_TOTAL]?.inKilocalories,
                    // Health Connect exposes no all-day active-minutes aggregate;
                    // the repository estimates active minutes from steps.
                    activeMinutes = null,
                )
            } catch (e: Exception) {
                DayAggregate(date, null, null, null, null)
            }
        }.toList()
    }
}
