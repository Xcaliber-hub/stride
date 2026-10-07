package org.stride.tracker.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import org.stride.tracker.data.di.AppContainer
import org.stride.tracker.ui.navigation.StrideNav
import org.stride.tracker.ui.navigation.StrideRoutes
import org.stride.tracker.ui.theme.StrideTheme

class MainActivity : ComponentActivity() {

    private lateinit var container: AppContainer

    // Hoisted so the permission callback (outside of composition) can change it.
    private val startDestinationState = mutableStateOf<String?>(null)

    private val permissionLauncher = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract(),
    ) { granted ->
        if (granted.containsAll(container.healthConnect.permissions)) {
            lifecycleScope.launch { container.repository.backfillYear() }
            startDestinationState.value = StrideRoutes.DASHBOARD
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        container = (application as StrideApp).appContainer
        enableEdgeToEdge()
        setContent {
            val themeMode by container.prefs.themeMode.collectAsStateWithLifecycle(initialValue = "system")
            val dynamicColor by container.prefs.dynamicColor.collectAsStateWithLifecycle(initialValue = true)
            val darkTheme = when (themeMode) {
                "light" -> false
                "dark" -> true
                else -> isSystemInDarkTheme()
            }
            LaunchedEffect(Unit) {
                startDestinationState.value =
                    if (container.healthConnect.hasAllPermissions()) StrideRoutes.DASHBOARD
                    else StrideRoutes.ONBOARDING
            }
            StrideTheme(darkTheme = darkTheme, dynamicColor = dynamicColor) {
                val startDestination = startDestinationState.value
                if (startDestination != null) {
                    // NavHost only reads startDestination on first composition, so recreate the
                    // whole nav graph when it changes (e.g. after the permission grant).
                    key(startDestination) {
                        val navController = rememberNavController()
                        StrideNav(
                            navController = navController,
                            startDestination = startDestination,
                            onRequestHealthPermissions = {
                                permissionLauncher.launch(container.healthConnect.permissions)
                            },
                        )
                    }
                } else {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
            }
        }
    }
}
