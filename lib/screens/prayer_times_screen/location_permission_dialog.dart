// lib/widgets/location_permission_dialog.dart
import 'package:flutter/material.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kPrimaryLight;

class LocationPermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback onSecondaryButtonPressed;
  final IconData icon;

  const LocationPermissionDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText = 'إلغاء',
    required this.onPrimaryButtonPressed,
    required this.onSecondaryButtonPressed,
    this.icon = Icons.location_on,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono en círculo con gradiente
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Título
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Mensaje
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón secundario
              OutlinedButton(
                onPressed: onSecondaryButtonPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  secondaryButtonText,
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón primario
              ElevatedButton(
                onPressed: onPrimaryButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 2,
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Función de ayuda para mostrar el diálogo
Future<bool> showLocationPermissionDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String primaryButtonText,
  String secondaryButtonText = 'إلغاء',
  IconData icon = Icons.location_on,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: LocationPermissionDialog(
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        icon: icon,
        onPrimaryButtonPressed: () {
          Navigator.of(context).pop(true);
        },
        onSecondaryButtonPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
    ),
  );
  
  return result ?? false;
}

// Diálogos predefinidos para diferentes escenarios de permisos de ubicación

// 1. Diálogo para solicitar activar el servicio de ubicación
Future<bool> showLocationServiceDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'تفعيل خدمة الموقع',
    message: 'تحتاج مواقيت الصلاة إلى تفعيل خدمة الموقع للحصول على أوقات دقيقة للصلاة في موقعك الحالي. هل ترغب في فتح إعدادات الموقع?',
    primaryButtonText: 'فتح الإعدادات',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.location_on,
  );
}

// 2. Diálogo para explicar por qué necesitamos permisos de ubicación
Future<bool> showLocationPermissionRationaleDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'إذن الوصول للموقع',
    message: 'يحتاج التطبيق إلى إذن الوصول لموقعك للحصول على مواقيت الصلاة الدقيقة في منطقتك. لن يتم مشاركة موقعك مع أي طرف ثالث.',
    primaryButtonText: 'السماح',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.info_outline,
  );
}

// 3. Diálogo para abrir la configuración de la aplicación
Future<bool> showOpenAppSettingsDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'تغيير إعدادات التطبيق',
    message: 'تم رفض إذن الوصول للموقع بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل إذن الموقع يدوياً.',
    primaryButtonText: 'فتح الإعدادات',
    secondaryButtonText: 'ليس الآن',
    icon: Icons.settings,
  );
}

// 4. Diálogo para usar ubicación por defecto
Future<bool> showDefaultLocationDialog(BuildContext context) {
  return showLocationPermissionDialog(
    context: context,
    title: 'استخدام الموقع الافتراضي',
    message: 'سيتم استخدام موقع افتراضي (مكة المكرمة) لحساب مواقيت الصلاة. هل تريد المحاولة مرة أخرى للحصول على موقعك الحالي؟',
    primaryButtonText: 'محاولة مرة أخرى',
    secondaryButtonText: 'استخدام الافتراضي',
    icon: Icons.location_city,
  );
}