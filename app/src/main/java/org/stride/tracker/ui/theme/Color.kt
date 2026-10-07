package org.stride.tracker.ui.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.graphics.Color

// Fallback (non-dynamic) Material 3 palettes seeded from a fitness green.
// Used only when the user disables dynamic color or runs below Android 12.

val StrideLightColors = lightColorScheme(
    primary = Color(0xFF2F6B33),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFB2F0B6),
    onPrimaryContainer = Color(0xFF002105),
    secondary = Color(0xFF4E6547),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFD1E8D0),
    onSecondaryContainer = Color(0xFF0C1F0D),
    tertiary = Color(0xFF3A656E),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFBEEAF6),
    onTertiaryContainer = Color(0xFF001F26),
    error = Color(0xFFBA1A1A),
    onError = Color(0xFFFFFFFF),
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    background = Color(0xFFF7FBF1),
    onBackground = Color(0xFF191C17),
    surface = Color(0xFFF7FBF1),
    onSurface = Color(0xFF191C17),
    surfaceVariant = Color(0xFFDFE4D7),
    onSurfaceVariant = Color(0xFF43483E),
    outline = Color(0xFF73796C),
)

val StrideDarkColors = darkColorScheme(
    primary = Color(0xFF97D98A),
    onPrimary = Color(0xFF0B390F),
    primaryContainer = Color(0xFF1B5220),
    onPrimaryContainer = Color(0xFFB2F0B6),
    secondary = Color(0xFFB5CCA6),
    onSecondary = Color(0xFF243518),
    secondaryContainer = Color(0xFF3A4C2F),
    onSecondaryContainer = Color(0xFFD1E8D0),
    tertiary = Color(0xFFA2CEDA),
    onTertiary = Color(0xFF01363F),
    tertiaryContainer = Color(0xFF1F4D56),
    onTertiaryContainer = Color(0xFFBEEAF6),
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    background = Color(0xFF11140F),
    onBackground = Color(0xFFE1E4D9),
    surface = Color(0xFF11140F),
    onSurface = Color(0xFFE1E4D9),
    surfaceVariant = Color(0xFF43483E),
    onSurfaceVariant = Color(0xFFC3C8BB),
    outline = Color(0xFF8D9387),
)
