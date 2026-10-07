package org.stride.tracker.ui.dashboard

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
import org.stride.tracker.data.local.DailySummary
import org.stride.tracker.data.repo.FitnessRepository
import org.stride.tracker.ui.StrideApp

class DashboardViewModel(app: Application) : AndroidViewModel(app) {

    private val container = (app as StrideApp).appContainer
    private val repository: FitnessRepository get() = container.repository

    val today: StateFlow<DailySummary?> = repository.todaySummary()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val last7: StateFlow<List<DailySummary>> = repository
        .rangeSummaries(repository.today().minusDays(6), repository.today())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val stepGoal: StateFlow<Int> = container.prefs.stepGoal
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 10_000)

    val useMetric: StateFlow<Boolean> = container.prefs.useMetric
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message.asStateFlow()

    // Health Connect state drives the permission prompt card on the dashboard.
    private val _healthAvailable = MutableStateFlow(container.healthConnect.isAvailable())
    val healthAvailable: StateFlow<Boolean> = _healthAvailable.asStateFlow()

    private val _permissionsGranted = MutableStateFlow(false)
    val permissionsGranted: StateFlow<Boolean> = _permissionsGranted.asStateFlow()

    init {
        refreshHealthStatus()
    }

    fun refreshHealthStatus() {
        viewModelScope.launch {
            _healthAvailable.value = container.healthConnect.isAvailable()
            _permissionsGranted.value = container.healthConnect.hasAllPermissions()
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _isSyncing.value = true
            _message.value = when (val result = repository.syncRecent()) {
                is FitnessRepository.SyncResult.Success -> "Synced just now"
                is FitnessRepository.SyncResult.Skipped -> result.reason
                is FitnessRepository.SyncResult.Failed -> "Sync failed"
            }
            _isSyncing.value = false
            refreshHealthStatus()
            delay(4_000)
            _message.value = null
        }
    }

    fun clearMessage() {
        _message.value = null
    }
}
