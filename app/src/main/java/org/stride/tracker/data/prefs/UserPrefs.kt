package org.stride.tracker.data.prefs

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.userPrefsDataStore by preferencesDataStore(name = "user_prefs")

class UserPrefs(private val context: Context) {

    private object Keys {
        val STEP_GOAL = intPreferencesKey("step_goal")
        val DISTANCE_GOAL_KM = doublePreferencesKey("distance_goal_km")
        val WEIGHT_KG = doublePreferencesKey("weight_kg")
        val HEIGHT_CM = doublePreferencesKey("height_cm")
        val STRIDE_LENGTH_CM = doublePreferencesKey("stride_length_cm")
        val USE_METRIC = booleanPreferencesKey("use_metric")
        val THEME_MODE = stringPreferencesKey("theme_mode")
        val DYNAMIC_COLOR = booleanPreferencesKey("dynamic_color")
    }

    data class Snapshot(
        val stepGoal: Int,
        val distanceGoalKm: Double,
        val weightKg: Double,
        val heightCm: Double,
        val strideLengthCm: Double,
        val useMetric: Boolean,
        val themeMode: String,
        val dynamicColor: Boolean,
    )

    val stepGoal: Flow<Int> = context.userPrefsDataStore.data.map { it[Keys.STEP_GOAL] ?: 10000 }
    val distanceGoalKm: Flow<Double> = context.userPrefsDataStore.data.map { it[Keys.DISTANCE_GOAL_KM] ?: 8.0 }
    val weightKg: Flow<Double> = context.userPrefsDataStore.data.map { it[Keys.WEIGHT_KG] ?: 70.0 }
    val heightCm: Flow<Double> = context.userPrefsDataStore.data.map { it[Keys.HEIGHT_CM] ?: 170.0 }
    val strideLengthCm: Flow<Double> = context.userPrefsDataStore.data.map { it[Keys.STRIDE_LENGTH_CM] ?: 75.0 }
    val useMetric: Flow<Boolean> = context.userPrefsDataStore.data.map { it[Keys.USE_METRIC] ?: true }
    val themeMode: Flow<String> = context.userPrefsDataStore.data.map { it[Keys.THEME_MODE] ?: "system" }
    val dynamicColor: Flow<Boolean> = context.userPrefsDataStore.data.map { it[Keys.DYNAMIC_COLOR] ?: true }

    suspend fun updateStepGoal(value: Int) = edit { it[Keys.STEP_GOAL] = value }
    suspend fun updateDistanceGoalKm(value: Double) = edit { it[Keys.DISTANCE_GOAL_KM] = value }
    suspend fun updateWeightKg(value: Double) = edit { it[Keys.WEIGHT_KG] = value }
    suspend fun updateHeightCm(value: Double) = edit { it[Keys.HEIGHT_CM] = value }
    suspend fun updateStrideLengthCm(value: Double) = edit { it[Keys.STRIDE_LENGTH_CM] = value }
    suspend fun updateUseMetric(value: Boolean) = edit { it[Keys.USE_METRIC] = value }
    suspend fun updateThemeMode(value: String) = edit { it[Keys.THEME_MODE] = value }
    suspend fun updateDynamicColor(value: Boolean) = edit { it[Keys.DYNAMIC_COLOR] = value }

    suspend fun snapshot(): Snapshot = Snapshot(
        stepGoal = stepGoal.first(),
        distanceGoalKm = distanceGoalKm.first(),
        weightKg = weightKg.first(),
        heightCm = heightCm.first(),
        strideLengthCm = strideLengthCm.first(),
        useMetric = useMetric.first(),
        themeMode = themeMode.first(),
        dynamicColor = dynamicColor.first(),
    )

    private suspend fun edit(transform: suspend (androidx.datastore.preferences.core.MutablePreferences) -> Unit) {
        context.userPrefsDataStore.edit(transform)
    }
}
