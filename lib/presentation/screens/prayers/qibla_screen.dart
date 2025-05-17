// lib/presentation/screens/prayers/qibla_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/interfaces/qibla_service.dart';
import '../../blocs/prayers/prayer_times_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<double>? _qiblaSubscription;
  double _direction = 0.0;
  bool _compassAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCompassAvailability();
    _initQiblaDirection();
  }

  @override
  void dispose() {
    _qiblaSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkCompassAvailability() async {
    // في التطبيق الحقيقي، يجب استخدام خدمة QiblaService لفحص توفر البوصلة
    // هنا نفترض أنها متوفرة للتبسيط
    setState(() {
      _compassAvailable = true;
      _isLoading = false;
    });
  }

  Future<void> _initQiblaDirection() async {
    final provider = Provider.of<PrayerTimesProvider>(context, listen: false);
    
    if (!provider.hasLocation) {
      // تعيين موقع افتراضي مؤقت (مكة المكرمة)
      provider.setLocation(
        latitude: 21.422510,
        longitude: 39.826168,
      );
    }
    
    // تحميل اتجاه القبلة
    if (provider.qiblaDirection == null) {
      await provider.loadQiblaDirection();
    }
    
    // في التطبيق الحقيقي، يمكننا استخدام QiblaService للحصول على تدفق بيانات البوصلة
    // هنا، سنقوم بمحاكاة تغيير الاتجاه لأغراض التوضيح
    
    // تمثيل عملية الاستماع للبوصلة
    // في التطبيق الحقيقي، يجب استخدام خدمة QiblaService
    // _qiblaSubscription = qiblaService.getCompassStream().listen((direction) {
    //   setState(() {
    //     _direction = direction;
    //   });
    // });
    
    // محاكاة وجود بوصلة باستخدام مؤقت
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _direction = (_direction + 1) % 360;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'اتجاه القبلة'),
      body: Consumer<PrayerTimesProvider>(
        builder: (context, provider, child) {
          if (_isLoading || provider.isLoading) {
            return const Center(child: LoadingWidget());
          }
          
          if (!provider.hasLocation) {
            return _buildLocationRequest(context, provider);
          }
          
          if (!_compassAvailable) {
            return _buildCompassNotAvailable(context);
          }
          
          if (provider.qiblaDirection == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لم يتم تحميل اتجاه القبلة'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadQiblaDirection(),
                    child: const Text('تحميل اتجاه القبلة'),
                  ),
                ],
              ),
            );
          }
          
          return _buildQiblaCompass(context, provider);
        },
      ),
    );
  }
  
  Widget _buildLocationRequest(BuildContext context, PrayerTimesProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'يرجى السماح بالوصول إلى الموقع لتحديد اتجاه القبلة',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // تعيين موقع افتراضي مؤقت (مكة المكرمة)
                provider.setLocation(
                  latitude: 21.422510,
                  longitude: 39.826168,
                );
                provider.loadQiblaDirection();
              },
              icon: const Icon(Icons.location_on),
              label: const Text('استخدام موقع افتراضي'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompassNotAvailable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.compass_calibration_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'البوصلة غير متوفرة في هذا الجهاز',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى التأكد من أن جهازك يحتوي على مستشعر البوصلة وأنه مفعل',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass(BuildContext context, PrayerTimesProvider provider) {
    final qiblaDirection = provider.qiblaDirection!;
    final actualDirection = (qiblaDirection - _direction) % 360;
    
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // الدائرة الخارجية والشمال
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.background,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // إشارات الاتجاهات (شمال، جنوب، شرق، غرب)
                      ...List.generate(4, (index) {
                        final angle = index * 90.0;
                        final label = _getDirectionLabel(angle);
                        return Positioned(
                          top: 150 + 120 * math.sin(math.pi * 2 * angle / 360) - 15,
                          left: 150 + 120 * math.cos(math.pi * 2 * angle / 360) - 15,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      
                      // درجات البوصلة
                      ...List.generate(24, (index) {
                        if (index % 3 == 0) return const SizedBox.shrink();
                        final angle = index * 15.0;
                        return Transform.rotate(
                          angle: math.pi * 2 * angle / 360,
                          child: Align(
                            alignment: const Alignment(0, -0.9),
                            child: Container(
                              height: 10,
                              width: 2,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                
                // عقرب القبلة
                Transform.rotate(
                  angle: math.pi * 2 * actualDirection / 360,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // الظل
                      Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // البوصلة الداخلية
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      
                      // صورة الكعبة (يمكن استبدالها بصورة أفضل)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      // مؤشر القبلة
                      Align(
                        alignment: const Alignment(0, -0.7),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      // خط القبلة
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 4,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // معلومات القبلة
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'اتجاه القبلة: ${qiblaDirection.toStringAsFixed(1)}°',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'قم بتوجيه الهاتف بحيث يشير المؤشر إلى القبلة',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'لضبط البوصلة، قم بتحريك هاتفك بشكل دائري على شكل رقم 8',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getDirectionLabel(double angle) {
    if (angle == 0) return 'E';
    if (angle == 90) return 'N';
    if (angle == 180) return 'W';
    if (angle == 270) return 'S';
    return '';
  }
}