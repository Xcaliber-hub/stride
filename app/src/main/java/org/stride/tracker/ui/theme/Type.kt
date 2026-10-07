package org.stride.tracker.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// Default Material 3 type scale with bolder, tighter display/headline styles
// for an expressive editorial feel.
val StrideTypography = Typography(
    displayLarge = Typography().displayLarge.copy(
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp,
    ),
    displayMedium = Typography().displayMedium.copy(
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp,
    ),
    displaySmall = Typography().displaySmall.copy(
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp,
    ),
    headlineLarge = Typography().headlineLarge.copy(
        fontWeight = FontWeight.Bold,
        letterSpacing = 0.sp,
    ),
    headlineMedium = Typography().headlineMedium.copy(
        fontWeight = FontWeight.SemiBold,
        letterSpacing = 0.sp,
    ),
)
