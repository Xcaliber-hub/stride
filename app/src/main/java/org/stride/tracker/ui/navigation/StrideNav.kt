package org.stride.tracker.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import org.stride.tracker.ui.dashboard.DashboardScreen
import org.stride.tracker.ui.dashboard.DashboardViewModel
import org.stride.tracker.ui.history.HistoryScreen
import org.stride.tracker.ui.history.HistoryViewModel
import org.stride.tracker.ui.onboarding.OnboardingScreen
import org.stride.tracker.ui.settings.SettingsScreen
import org.stride.tracker.ui.settings.SettingsViewModel

object StrideRoutes {
    const val ONBOARDING = "onboarding"
    const val DASHBOARD = "dashboard"
    const val HISTORY = "history"
    const val SETTINGS = "settings"
}

private data class BottomTab(
    val route: String,
    val label: String,
    val icon: ImageVector,
)

private val bottomTabs = listOf(
    BottomTab(StrideRoutes.DASHBOARD, "Today", Icons.Filled.DirectionsWalk),
    BottomTab(StrideRoutes.HISTORY, "History", Icons.Filled.History),
    BottomTab(StrideRoutes.SETTINGS, "Settings", Icons.Filled.Settings),
)

@Composable
fun StrideNav(
    navController: NavHostController,
    startDestination: String,
    onRequestHealthPermissions: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val tabRoutes = bottomTabs.map { it.route }
    val showBottomBar = currentRoute in tabRoutes

    Scaffold(
        modifier = modifier,
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomTabs.forEach { tab ->
                        NavigationBarItem(
                            selected = currentRoute == tab.route,
                            onClick = {
                                navController.navigate(tab.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(tab.icon, contentDescription = tab.label) },
                            label = { Text(tab.label) },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(StrideRoutes.ONBOARDING) {
                OnboardingScreen(
                    onConnect = onRequestHealthPermissions,
                    onSkip = {
                        navController.navigate(StrideRoutes.DASHBOARD) {
                            popUpTo(StrideRoutes.ONBOARDING) { inclusive = true }
                        }
                    },
                )
            }
            composable(StrideRoutes.DASHBOARD) {
                val dashboardViewModel: DashboardViewModel = viewModel()
                DashboardScreen(
                    viewModel = dashboardViewModel,
                    onRequestPermissions = onRequestHealthPermissions,
                )
            }
            composable(StrideRoutes.HISTORY) {
                val historyViewModel: HistoryViewModel = viewModel()
                HistoryScreen(viewModel = historyViewModel)
            }
            composable(StrideRoutes.SETTINGS) {
                val settingsViewModel: SettingsViewModel = viewModel()
                SettingsScreen(viewModel = settingsViewModel)
            }
        }
    }
}
