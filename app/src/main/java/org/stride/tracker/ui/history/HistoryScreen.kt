package org.stride.tracker.ui.history

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.stride.tracker.data.local.DailySummary
import org.stride.tracker.data.repo.FitnessRepository
import org.stride.tracker.ui.dashboard.formatDistance
import java.text.NumberFormat
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun HistoryScreen(viewModel: HistoryViewModel, modifier: Modifier = Modifier) {
    val days by viewModel.days.collectAsStateWithLifecycle()
    val weekTotals by viewModel.weekTotals.collectAsStateWithLifecycle()
    val monthTotals by viewModel.monthTotals.collectAsStateWithLifecycle()
    val yearTotals by viewModel.yearTotals.collectAsStateWithLifecycle()
    val useMetric by viewModel.useMetric.collectAsStateWithLifecycle()
    val isSyncing by viewModel.isSyncing.collectAsStateWithLifecycle()
    val message by viewModel.message.collectAsStateWithLifecycle()

    var selectedDay by remember { mutableStateOf<DailySummary?>(null) }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Text(
                text = "History",
                style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
            )
        }

        item {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                FilledTonalButton(onClick = viewModel::backfill, enabled = !isSyncing) {
                    Text(if (isSyncing) "Working…" else "Backfill last year")
                }
                message?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        item {
            TotalsRow(
                weekTotals = weekTotals,
                monthTotals = monthTotals,
                yearTotals = yearTotals,
                useMetric = useMetric,
            )
        }

        items(days.sortedByDescending { it.date }, key = { it.date }) { day ->
            DayRow(day = day, useMetric = useMetric, onClick = { selectedDay = day })
            HorizontalDivider()
        }
    }

    selectedDay?.let { day ->
        DayDetailDialog(day = day, useMetric = useMetric, onDismiss = { selectedDay = null })
    }
}

@Composable
private fun TotalsRow(
    weekTotals: FitnessRepository.PeriodTotals?,
    monthTotals: FitnessRepository.PeriodTotals?,
    yearTotals: FitnessRepository.PeriodTotals?,
    useMetric: Boolean,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        TotalsCard(
            label = "This week",
            totals = weekTotals,
            useMetric = useMetric,
            modifier = Modifier.weight(1f),
        )
        TotalsCard(
            label = "This month",
            totals = monthTotals,
            useMetric = useMetric,
            modifier = Modifier.weight(1f),
        )
        TotalsCard(
            label = "This year",
            totals = yearTotals,
            useMetric = useMetric,
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun TotalsCard(
    label: String,
    totals: FitnessRepository.PeriodTotals?,
    useMetric: Boolean,
    modifier: Modifier = Modifier,
) {
    ElevatedCard(shape = RoundedCornerShape(28.dp), modifier = modifier) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = totals?.let { NumberFormat.getInstance().format(it.steps) } ?: "—",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
            )
            Text(
                text = totals?.let { formatDistance(it.distanceMeters, useMetric) } ?: "",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun DayRow(day: DailySummary, useMetric: Boolean, onClick: () -> Unit) {
    ListItem(
        headlineContent = {
            Text(formatDayDate(day.date), style = MaterialTheme.typography.titleMedium)
        },
        supportingContent = {
            Text(
                text = "${NumberFormat.getInstance().format(day.steps)} steps • " +
                    "${formatDistance(day.distanceMeters, useMetric)} • " +
                    "${day.caloriesKcal.toInt()} kcal",
                style = MaterialTheme.typography.bodyMedium,
            )
        },
        trailingContent = {
            if (day.stepsEstimated || day.distanceEstimated || day.caloriesEstimated) {
                Surface(
                    color = MaterialTheme.colorScheme.tertiaryContainer,
                    shape = RoundedCornerShape(8.dp),
                ) {
                    Text(
                        text = "est.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onTertiaryContainer,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    )
                }
            }
        },
        modifier = Modifier.clickable(onClick = onClick),
    )
}

@Composable
private fun DayDetailDialog(day: DailySummary, useMetric: Boolean, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("Close") }
        },
        title = { Text(formatDayDate(day.date)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                DetailRow("Steps", NumberFormat.getInstance().format(day.steps))
                DetailRow("Distance", formatDistance(day.distanceMeters, useMetric))
                DetailRow("Calories", "${day.caloriesKcal.toInt()} kcal")
                DetailRow("Active minutes", "${day.activeMinutes} min")
                if (day.stepsEstimated || day.distanceEstimated || day.caloriesEstimated) {
                    Text(
                        text = "Some values are estimated.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        },
    )
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
        )
    }
}

private val dayFormatter = DateTimeFormatter.ofPattern("EEE, d MMM yyyy", Locale.getDefault())

private fun formatDayDate(date: String): String =
    runCatching { LocalDate.parse(date).format(dayFormatter) }.getOrDefault(date)
