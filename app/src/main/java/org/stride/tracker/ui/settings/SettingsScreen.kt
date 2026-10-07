package org.stride.tracker.ui.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

@Composable
fun SettingsScreen(viewModel: SettingsViewModel, modifier: Modifier = Modifier) {
    val stepGoal by viewModel.stepGoal.collectAsStateWithLifecycle()
    val distanceGoalKm by viewModel.distanceGoalKm.collectAsStateWithLifecycle()
    val weightKg by viewModel.weightKg.collectAsStateWithLifecycle()
    val heightCm by viewModel.heightCm.collectAsStateWithLifecycle()
    val strideLengthCm by viewModel.strideLengthCm.collectAsStateWithLifecycle()
    val useMetric by viewModel.useMetric.collectAsStateWithLifecycle()
    val themeMode by viewModel.themeMode.collectAsStateWithLifecycle()
    val dynamicColor by viewModel.dynamicColor.collectAsStateWithLifecycle()
    val healthAvailable by viewModel.healthAvailable.collectAsStateWithLifecycle()
    val permissionsGranted by viewModel.permissionsGranted.collectAsStateWithLifecycle()
    val syncMessage by viewModel.syncMessage.collectAsStateWithLifecycle()

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Text(
                text = "Settings",
                style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
            )
        }

        item {
            SettingsCard(title = "Goals") {
                var stepsText by remember { mutableStateOf(stepGoal.toString()) }
                LaunchedEffect(stepGoal) { stepsText = stepGoal.toString() }
                OutlinedTextField(
                    value = stepsText,
                    onValueChange = { stepsText = it },
                    label = { Text("Daily step goal") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                var distanceText by remember { mutableStateOf(distanceGoalKm.toString()) }
                LaunchedEffect(distanceGoalKm) { distanceText = distanceGoalKm.toString() }
                OutlinedTextField(
                    value = distanceText,
                    onValueChange = { distanceText = it },
                    label = { Text("Daily distance goal (km)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                FilledTonalButton(onClick = {
                    stepsText.toIntOrNull()?.let { viewModel.updateStepGoal(it) }
                    distanceText.toDoubleOrNull()?.let { viewModel.updateDistanceGoalKm(it) }
                }) {
                    Text("Save goals")
                }
            }
        }

        item {
            SettingsCard(title = "Body") {
                var weightText by remember { mutableStateOf(weightKg.toString()) }
                LaunchedEffect(weightKg) { weightText = weightKg.toString() }
                OutlinedTextField(
                    value = weightText,
                    onValueChange = { weightText = it },
                    label = { Text("Weight (kg)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                var heightText by remember { mutableStateOf(heightCm.toString()) }
                LaunchedEffect(heightCm) { heightText = heightCm.toString() }
                OutlinedTextField(
                    value = heightText,
                    onValueChange = { heightText = it },
                    label = { Text("Height (cm)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                var strideText by remember { mutableStateOf(strideLengthCm.toString()) }
                LaunchedEffect(strideLengthCm) { strideText = strideLengthCm.toString() }
                OutlinedTextField(
                    value = strideText,
                    onValueChange = { strideText = it },
                    label = { Text("Stride length (cm)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )

                FilledTonalButton(onClick = {
                    weightText.toDoubleOrNull()?.let { viewModel.updateWeightKg(it) }
                    heightText.toDoubleOrNull()?.let { viewModel.updateHeightCm(it) }
                    strideText.toDoubleOrNull()?.let { viewModel.updateStrideLengthCm(it) }
                }) {
                    Text("Save body metrics")
                }
            }
        }

        item {
            SettingsCard(title = "Preferences") {
                ListItem(
                    headlineContent = { Text("Metric units") },
                    supportingContent = { Text("Use kilometers instead of miles") },
                    trailingContent = {
                        Switch(
                            checked = useMetric,
                            onCheckedChange = viewModel::updateUseMetric,
                        )
                    },
                )

                Text(
                    text = "Theme",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(top = 4.dp),
                )
                val themeOptions = listOf(
                    "system" to "System",
                    "light" to "Light",
                    "dark" to "Dark",
                )
                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    themeOptions.forEachIndexed { index, (value, label) ->
                        SegmentedButton(
                            shape = SegmentedButtonDefaults.itemShape(
                                index = index,
                                count = themeOptions.size,
                            ),
                            onClick = { viewModel.updateThemeMode(value) },
                            selected = themeMode == value,
                        ) {
                            Text(label)
                        }
                    }
                }

                ListItem(
                    headlineContent = { Text("Dynamic color") },
                    supportingContent = { Text("Match colors to your wallpaper (Android 12+)") },
                    trailingContent = {
                        Switch(
                            checked = dynamicColor,
                            onCheckedChange = viewModel::updateDynamicColor,
                        )
                    },
                )
            }
        }

        item {
            SettingsCard(title = "Data") {
                ListItem(
                    headlineContent = { Text("Health Connect") },
                    supportingContent = {
                        Text(
                            if (healthAvailable) "Available on this device"
                            else "Not available on this device",
                        )
                    },
                    trailingContent = {
                        Text(
                            text = if (permissionsGranted) "Connected" else "Not connected",
                            style = MaterialTheme.typography.labelLarge,
                            color = if (permissionsGranted) {
                                MaterialTheme.colorScheme.primary
                            } else {
                                MaterialTheme.colorScheme.onSurfaceVariant
                            },
                        )
                    },
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    FilledTonalButton(onClick = viewModel::syncNow) {
                        Text("Sync now")
                    }
                    OutlinedButton(onClick = viewModel::backfill) {
                        Text("Backfill last year")
                    }
                }
                syncMessage?.let {
                    Text(
                        text = it,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        item {
            SettingsCard(title = "About") {
                Text(
                    text = "Stride 1.0.0",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold),
                )
                Text(
                    text = "Free and open source (GPL-3.0). All data stays on your device.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun SettingsCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    ElevatedCard(shape = RoundedCornerShape(28.dp)) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
            )
            content()
        }
    }
}
