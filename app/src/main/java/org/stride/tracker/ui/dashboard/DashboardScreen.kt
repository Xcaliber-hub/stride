package org.stride.tracker.ui.dashboard

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.stride.tracker.data.local.DailySummary
import java.text.NumberFormat
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel,
    onRequestPermissions: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val today by viewModel.today.collectAsStateWithLifecycle()
    val last7 by viewModel.last7.collectAsStateWithLifecycle()
    val stepGoal by viewModel.stepGoal.collectAsStateWithLifecycle()
    val useMetric by viewModel.useMetric.collectAsStateWithLifecycle()
    val isSyncing by viewModel.isSyncing.collectAsStateWithLifecycle()
    val message by viewModel.message.collectAsStateWithLifecycle()
    val healthAvailable by viewModel.healthAvailable.collectAsStateWithLifecycle()
    val permissionsGranted by viewModel.permissionsGranted.collectAsStateWithLifecycle()

    PullToRefreshBox(
        isRefreshing = isSyncing,
        onRefresh = viewModel::refresh,
        modifier = modifier.fillMaxSize(),
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            item { Header() }

            item {
                StepsRing(
                    steps = today?.steps ?: 0L,
                    goal = stepGoal,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            item { StatCards(today = today, useMetric = useMetric) }

            item { WeekChart(days = last7) }

            if (!healthAvailable || !permissionsGranted) {
                item { HealthPromptCard(onRequestPermissions = onRequestPermissions) }
            }

            item {
                SyncRow(
                    isSyncing = isSyncing,
                    message = message,
                    onSync = viewModel::refresh,
                )
            }
        }
    }
}

@Composable
private fun Header() {
    val hour = LocalTime.now().hour
    val greeting = when (hour) {
        in 0..11 -> "Good morning"
        in 12..17 -> "Good afternoon"
        else -> "Good evening"
    }
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            text = greeting,
            style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
        )
        Text(
            text = formatDateHeader(),
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun StepsRing(steps: Long, goal: Int, modifier: Modifier = Modifier) {
    val target = if (goal > 0) (steps.toFloat() / goal).coerceIn(0f, 1f) else 0f
    val animated by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 80f),
        label = "stepsRing",
    )
    val trackColor = MaterialTheme.colorScheme.surfaceVariant
    val progressColor = MaterialTheme.colorScheme.primary

    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.size(220.dp)) {
            Canvas(Modifier.fillMaxSize()) {
                val strokePx = 28.dp.toPx()
                val inset = strokePx / 2f
                val arcTopLeft = Offset(inset, inset)
                val arcSize = Size(size.width - strokePx, size.height - strokePx)
                drawArc(
                    color = trackColor,
                    startAngle = 0f,
                    sweepAngle = 360f,
                    useCenter = false,
                    topLeft = arcTopLeft,
                    size = arcSize,
                    style = Stroke(width = strokePx, cap = StrokeCap.Butt),
                )
                drawArc(
                    color = progressColor,
                    startAngle = -90f,
                    sweepAngle = 360f * animated,
                    useCenter = false,
                    topLeft = arcTopLeft,
                    size = arcSize,
                    style = Stroke(width = strokePx, cap = StrokeCap.Round),
                )
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = NumberFormat.getInstance().format(steps),
                    style = MaterialTheme.typography.displayLarge.copy(fontWeight = FontWeight.Bold),
                )
                Text(
                    text = "/ ${NumberFormat.getInstance().format(goal)} steps",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun StatCards(today: DailySummary?, useMetric: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        StatCard(
            icon = Icons.Filled.Route,
            label = "Distance",
            value = today?.let { formatDistance(it.distanceMeters, useMetric) } ?: "—",
            modifier = Modifier.weight(1f),
        )
        StatCard(
            icon = Icons.Filled.LocalFireDepartment,
            label = "Calories",
            value = today?.let { "${it.caloriesKcal.toInt()} kcal" } ?: "—",
            modifier = Modifier.weight(1f),
        )
        StatCard(
            icon = Icons.Filled.Timer,
            label = "Active",
            value = today?.let { "${it.activeMinutes} min" } ?: "—",
            modifier = Modifier.weight(1f),
        )
    }
}

@Composable
private fun StatCard(icon: ImageVector, label: String, value: String, modifier: Modifier = Modifier) {
    ElevatedCard(
        modifier = modifier,
        shape = RoundedCornerShape(28.dp),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(icon, contentDescription = label, tint = MaterialTheme.colorScheme.primary)
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
            )
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun WeekChart(days: List<DailySummary>) {
    val sorted = days.sortedBy { it.date }
    val maxSteps = sorted.maxOfOrNull { it.steps } ?: 0L
    // The most recent entry in the 7-day window is treated as "today".
    val todayDate = sorted.maxByOrNull { it.date }?.date

    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Last 7 days",
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
        )
        ElevatedCard(shape = RoundedCornerShape(28.dp)) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (sorted.isEmpty()) {
                    Text(
                        text = "No data yet — sync to get started.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                } else {
                    sorted.forEach { day ->
                        DayBar(
                            label = dayLabel(day.date),
                            value = day.steps,
                            maxValue = maxSteps,
                            isToday = day.date == todayDate,
                            modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun DayBar(
    label: String,
    value: Long,
    maxValue: Long,
    isToday: Boolean,
    modifier: Modifier = Modifier,
) {
    val target = if (maxValue > 0) value.toFloat() / maxValue else 0f
    val animated by animateFloatAsState(
        targetValue = target,
        animationSpec = spring(dampingRatio = 0.6f, stiffness = 120f),
        label = "dayBar",
    )
    val barColor = if (isToday) MaterialTheme.colorScheme.tertiary else MaterialTheme.colorScheme.primary

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            modifier = Modifier
                .height(120.dp)
                .fillMaxWidth(),
            contentAlignment = Alignment.BottomCenter,
        ) {
            Canvas(
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .fillMaxHeight(animated.coerceAtLeast(0.02f)),
            ) {
                drawRoundRect(
                    color = barColor,
                    cornerRadius = CornerRadius(x = size.width / 2f, y = size.width / 2f),
                )
            }
        }
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun HealthPromptCard(onRequestPermissions: () -> Unit) {
    OutlinedCard(shape = RoundedCornerShape(28.dp)) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = "Connect Health Connect",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
            )
            Text(
                text = "Stride reads your steps, distance and calories from Health Connect. " +
                    "Grant permission to keep your dashboard up to date.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            FilledTonalButton(onClick = onRequestPermissions) {
                Text("Grant permissions")
            }
        }
    }
}

@Composable
private fun SyncRow(isSyncing: Boolean, message: String?, onSync: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        FilledTonalButton(onClick = onSync, enabled = !isSyncing) {
            Icon(Icons.Filled.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text(if (isSyncing) "Syncing…" else "Sync now")
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

private fun dayLabel(date: String): String = runCatching {
    LocalDate.parse(date).dayOfWeek.getDisplayName(TextStyle.NARROW, Locale.getDefault())
}.getOrDefault("")

fun formatDateHeader(): String =
    LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, d MMMM", Locale.getDefault()))

fun formatDistance(meters: Double, useMetric: Boolean): String =
    if (useMetric) {
        String.format(Locale.US, "%.2f km", meters / 1000.0)
    } else {
        String.format(Locale.US, "%.2f mi", meters / 1609.344)
    }
