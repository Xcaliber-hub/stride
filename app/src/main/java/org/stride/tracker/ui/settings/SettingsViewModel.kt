package org.stride.tracker.ui.settings

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.stride.tracker.data.repo.FitnessRepository
import org.stride.tracker.ui.StrideApp

class SettingsViewModel(app: Application) : AndroidViewModel(app) {

    private val container = (app as StrideApp).appContainer
    private val prefs get() = container.prefs

    val stepGoal: StateFlow<Int> = prefs.stepGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 10_000)
    val distanceGoalKm: StateFlow<Double> = prefs.distanceGoalKm
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 8.0)
    val weightKg: StateFlow<Double> = prefs.weightKg
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 70.0)
    val heightCm: StateFlow<Double> = prefs.heightCm
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 170.0)
    val strideLengthCm: StateFlow<Double> = prefs.strideLengthCm
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 75.0)
    val useMetric: StateFlow<Boolean> = prefs.useMetric
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)
    val themeMode: StateFlow<String> = prefs.themeMode
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), "system")
    val dynamicColor: StateFlow<Boolean> = prefs.dynamicColor
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    private val _healthAvailable = MutableStateFlow(false)
    val healthAvailable: StateFlow<Boolean> = _healthAvailable.asStateFlow()

    private val _permissionsGranted = MutableStateFlow(false)
    val permissionsGranted: StateFlow<Boolean> = _permissionsGranted.asStateFlow()

    private val _syncMessage = MutableStateFlow<String?>(null)
    val syncMessage: StateFlow<String?> = _syncMessage.asStateFlow()

    init {
        refreshHealthStatus()
    }

    fun updateStepGoal(value: Int) = viewModelScope.launch { prefs.updateStepGoal(value) }
    fun updateDistanceGoalKm(value: Double) = viewModelScope.launch { prefs.updateDistanceGoalKm(value) }
    fun updateWeightKg(value: Double) = viewModelScope.launch { prefs.updateWeightKg(value) }
    fun updateHeightCm(value: Double) = viewModelScope.launch { prefs.updateHeightCm(value) }
    fun updateStrideLengthCm(value: Double) = viewModelScope.launch { prefs.updateStrideLengthCm(value) }
    fun updateUseMetric(value: Boolean) = viewModelScope.launch { prefs.updateUseMetric(value) }
    fun updateThemeMode(value: String) = viewModelScope.launch { prefs.updateThemeMode(value) }
    fun updateDynamicColor(value: Boolean) = viewModelScope.launch { prefs.updateDynamicColor(value) }

    fun refreshHealthStatus() {
        viewModelScope.launch {
            _healthAvailable.value = container.healthConnect.isAvailable()
            _permissionsGranted.value = container.healthConnect.hasAllPermissions()
        }
    }

    fun syncNow() {
        viewModelScope.launch {
            _syncMessage.value = when (val result = container.repository.syncRecent()) {
                is FitnessRepository.SyncResult.Success -> "Synced just now"
                is FitnessRepository.SyncResult.Skipped -> result.reason
                is FitnessRepository.SyncResult.Failed -> "Sync failed"
            }
            delay(4_000)
            _syncMessage.value = null
        }
    }

    fun backfill() {
        viewModelScope.launch {
            _syncMessage.value = when (val result = container.repository.backfillYear()) {
                is FitnessRepository.SyncResult.Success -> "Backfill complete"
                is FitnessRepository.SyncResult.Skipped -> result.reason
                is FitnessRepository.SyncResult.Failed -> "Backfill failed"
            }
            delay(4_000)
            _syncMessage.value = null
        }
    }

    fun clearSyncMessage() {
        _syncMessage.value = null
    }
}
