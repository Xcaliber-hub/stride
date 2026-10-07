package org.stride.tracker.ui.history

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

class HistoryViewModel(app: Application) : AndroidViewModel(app) {

    private val container = (app as StrideApp).appContainer
    private val repository: FitnessRepository get() = container.repository

    val days: StateFlow<List<DailySummary>> = repository
        .rangeSummaries(repository.today().minusDays(364), repository.today())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val weekTotals: StateFlow<FitnessRepository.PeriodTotals?> = repository
        .totals(repository.today().minusDays(6), repository.today())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val monthTotals: StateFlow<FitnessRepository.PeriodTotals?> = repository
        .totals(repository.today().minusDays(29), repository.today())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val yearTotals: StateFlow<FitnessRepository.PeriodTotals?> = repository
        .totals(repository.today().minusDays(364), repository.today())
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    val useMetric: StateFlow<Boolean> = container.prefs.useMetric
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), true)

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message.asStateFlow()

    fun refresh() {
        viewModelScope.launch {
            _isSyncing.value = true
            _message.value = when (val result = repository.syncRecent()) {
                is FitnessRepository.SyncResult.Success -> "Synced just now"
                is FitnessRepository.SyncResult.Skipped -> result.reason
                is FitnessRepository.SyncResult.Failed -> "Sync failed"
            }
            _isSyncing.value = false
            delay(4_000)
            _message.value = null
        }
    }

    fun backfill() {
        viewModelScope.launch {
            _isSyncing.value = true
            _message.value = when (val result = repository.backfillYear()) {
                is FitnessRepository.SyncResult.Success -> "Backfill complete"
                is FitnessRepository.SyncResult.Skipped -> result.reason
                is FitnessRepository.SyncResult.Failed -> "Backfill failed"
            }
            _isSyncing.value = false
            delay(4_000)
            _message.value = null
        }
    }

    fun clearMessage() {
        _message.value = null
    }
}
