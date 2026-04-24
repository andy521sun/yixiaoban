import 'package:flutter/material.dart';

/// 医小伴APP主题配置
class ThemeConfig {
  // 主色调
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color accentColor = Color(0xFFFB8C00);

  // 中性色
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFF8F9FA);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color textPrimaryColor = Color(0xFF202124);
  static const Color textSecondaryColor = Color(0xFF5F6368);
  static const Color textHintColor = Color(0xFF9AA0A6);

  // 功能色
  static const Color successColor = Color(0xFF0F9D58);
  static const Color warningColor = Color(0xFFF4B400);
  static const Color errorColor = Color(0xFFDB4437);
  static const Color infoColor = Color(0xFF4285F4);

  // 字体配置
  static const String fontFamily = 'PingFang SC, Noto Sans SC, sans-serif';
  static const double fontSizeH1 = 24.0;
  static const double fontSizeH2 = 20.0;
  static const double fontSizeH3 = 18.0;
  static const double fontSizeBody1 = 16.0;
  static const double fontSizeBody2 = 14.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeButton = 16.0;

  // 间距配置 (基于8dp)
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // 圆角配置
  static const double borderRadiusNone = 0.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusFull = 999.0;

  // 阴影配置
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      offset: Offset(0, 3),
      blurRadius: 6,
    ),
  ];

  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.19),
      offset: Offset(0, 10),
      blurRadius: 20,
    ),
  ];

  static const List<BoxShadow> shadowLevel4 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.25),
      offset: Offset(0, 14),
      blurRadius: 28,
    ),
  ];

  // 明亮主题
  static ThemeData get lightTheme {
    return ThemeData(
      // 颜色配置
      primaryColor: primaryColor,
      primaryColorLight: primaryColor.withOpacity(0.8),
      primaryColorDark: primaryColor.withOpacity(0.9),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: borderColor,
      canvasColor: backgroundColor,
      
      // 文字主题
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeH1,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeH2,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeH3,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeBody1,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeBody2,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeCaption,
          fontWeight: FontWeight.normal,
          color: textHintColor,
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeButton,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
        labelStyle: TextStyle(
          fontSize: fontSizeBody2,
          color: textSecondaryColor,
        ),
        hintStyle: TextStyle(
          fontSize: fontSizeBody2,
          color: textHintColor,
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 48),
          padding: EdgeInsets.symmetric(horizontal: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeButton,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          minimumSize: Size(double.infinity, 48),
          padding: EdgeInsets.symmetric(horizontal: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: TextStyle(
            fontSize: fontSizeButton,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: Size(double.infinity, 48),
          padding: EdgeInsets.symmetric(horizontal: spacingM),
          textStyle: TextStyle(
            fontSize: fontSizeButton,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // 应用栏主题
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeH2,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        iconTheme: IconThemeData(
          color: textPrimaryColor,
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        selectedLabelStyle: TextStyle(fontSize: fontSizeCaption),
        unselectedLabelStyle: TextStyle(fontSize: fontSizeCaption),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      // 图标主题
      iconTheme: IconThemeData(
        color: textSecondaryColor,
        size: 24,
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      
      // 进度指示器主题
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderColor,
      ),
      
      // 弹窗主题
      dialogTheme: DialogTheme(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        titleTextStyle: TextStyle(
          fontSize: fontSizeH2,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        contentTextStyle: TextStyle(
          fontSize: fontSizeBody1,
          color: textSecondaryColor,
        ),
      ),
      
      // 浮动操作按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      
      // 标签主题
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withOpacity(0.1),
        secondarySelectedColor: primaryColor,
        labelStyle: TextStyle(
          fontSize: fontSizeCaption,
          color: textSecondaryColor,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: fontSizeCaption,
          color: Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: spacingS),
        shape: StadiumBorder(
          side: BorderSide(color: borderColor),
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return borderColor;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return borderColor.withOpacity(0.5);
        }),
      ),
      
      // 单选/复选框主题
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
      ),
      
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return textSecondaryColor;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),
    );
  }

  // 暗黑主题
  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      scaffoldBackgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      dividerColor: Color(0xFF333333),
      canvasColor: Color(0xFF121212),
      textTheme: lightTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
        fillColor: Color(0xFF1E1E1E),
      ),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }

  // 获取自定义颜色
  static Map<String, Color> get customColors {
    return {
      'success': successColor,
      'warning': warningColor,
      'error': errorColor,
      'info': infoColor,
      'secondary': secondaryColor,
      'accent': accentColor,
    };
  }

  // 获取间距
  static EdgeInsets get edgeInsetsAllS => EdgeInsets.all(spacingS);
  static EdgeInsets get edgeInsetsAllM => EdgeInsets.all(spacingM);
  static EdgeInsets get edgeInsetsAllL => EdgeInsets.all(spacingL);
  static EdgeInsets get edgeInsetsHorizontalM => EdgeInsets.symmetric(horizontal: spacingM);
  static EdgeInsets get edgeInsetsVerticalM => EdgeInsets.symmetric(vertical: spacingM);
  static EdgeInsets get edgeInsetsScreen => EdgeInsets.symmetric(
        horizontal: spacingM,
        vertical: spacingL,
      );
}