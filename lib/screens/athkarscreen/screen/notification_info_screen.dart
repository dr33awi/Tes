// lib/screens/athkarscreen/notification_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:test_athkar_app/screens/hijri_date_time_header/hijri_date_time_header.dart'
    show kPrimary, kSurface;

class NotificationInfoScreen extends StatelessWidget {
  const NotificationInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'معلومات عن الإشعارات',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: kPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  _buildInfoCard(
                    context,
                    icon: Icons.info_outline,
                    title: 'دليل الإشعارات',
                    color: kPrimary,
                    content: 'هذا الدليل يساعدك على فهم كيفية عمل إشعارات الأذكار وإعدادها بشكل صحيح على جهازك.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.info_outline,
                    title: 'حول إشعارات الأذكار',
                    color: kPrimary,
                    content: 'يقوم التطبيق بإرسال إشعارات تذكيرية في الأوقات المحددة لمساعدتك على المداومة على قراءة الأذكار في أوقاتها المناسبة.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.timer,
                    title: 'أوقات الإشعارات',
                    color: kPrimary,
                    content: 'يعتمد التطبيق على أوقات افتراضية لكل نوع من الأذكار، ويمكنك تعديل هذه الأوقات بما يناسبك من خلال شاشة إعدادات الإشعارات.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.notification_important,
                    title: 'تفعيل الإشعارات',
                    color: kPrimary,
                    content: 'لضمان وصول الإشعارات إليك، يرجى التأكد من السماح للتطبيق بإرسال الإشعارات من خلال إعدادات جهازك. بعض أجهزة الأندرويد قد تحتاج أيضاً إلى السماح للتطبيق بالعمل في الخلفية.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.battery_alert,
                    title: 'توفير البطارية',
                    subtitle: '(خاص بأجهزة أندرويد)',
                    color: kPrimary,
                    content: 'قد تقوم بعض أجهزة أندرويد بإيقاف التطبيقات تلقائياً في الخلفية لتوفير البطارية، مما قد يؤثر على وصول الإشعارات. يمكنك إضافة تطبيق الأذكار إلى قائمة الاستثناءات من خلال إعدادات "توفير البطارية" أو "تحسين البطارية" في جهازك.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.warning_amber,
                    title: 'المنطقة الزمنية',
                    color: kPrimary,
                    content: 'يعتمد التطبيق على المنطقة الزمنية للجهاز. إذا كنت تسافر أو تغير المنطقة الزمنية، قد تحتاج إلى إعادة ضبط أوقات الإشعارات بما يناسب المنطقة الزمنية الجديدة.',
                  ),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.update,
                    title: 'تحديث التطبيق',
                    color: kPrimary,
                    content: 'تأكد من أنك تستخدم أحدث إصدار من التطبيق للاستفادة من التحسينات المستمرة في نظام الإشعارات.',
                  ),
                  
                  _buildTroubleshootingTips(context),
                  
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء بطاقة المعلومات
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required String content,
  }) {
    Color color2 = Color(0xFF2D6852);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shadowColor: color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color2,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: const [0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان البطاقة
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 14),
                
                // محتوى البطاقة
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    content,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.6,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // بناء قسم حلول المشكلات
  Widget _buildTroubleshootingTips(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      elevation: 8,
      shadowColor: kPrimary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimary,
              Color(0xFF2D6852),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: const [0.3, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'حلول لمشاكل الإشعارات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // حلول المشاكل
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildTroubleshootingTip(
                      number: '1',
                      title: 'الإشعارات لا تصل',
                      content: 'تأكد من تفعيل الإشعارات للتطبيق من إعدادات جهازك، ومن عدم تفعيل وضع "عدم الإزعاج".',
                    ),
                    
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    
                    _buildTroubleshootingTip(
                      number: '2',
                      title: 'مشكلة في التوقيت',
                      content: 'قم بإعادة ضبط أوقات الإشعارات من شاشة إعدادات الإشعارات.',
                    ),
                    
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    
                    _buildTroubleshootingTip(
                      number: '3',
                      title: 'الإشعارات تتوقف بعد فترة',
                      content: 'أجهزة الأندرويد تميل إلى إيقاف التطبيقات في الخلفية لتوفير البطارية. قم بإضافة التطبيق إلى قائمة الاستثناءات من إعدادات "توفير البطارية" أو "تحسين البطارية" في جهازك.',
                    ),
                    
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    
                    _buildTroubleshootingTip(
                      number: '4',
                      title: 'إعادة تشغيل التطبيق',
                      content: 'في حال استمرار المشكلة، حاول إعادة تشغيل التطبيق أو إعادة تشغيل الجهاز.',
                    ),
                    
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    
                    _buildTroubleshootingTip(
                      number: '5',
                      title: 'إعادة تثبيت التطبيق',
                      content: 'إذا استمرت المشكلة، قم بإلغاء تثبيت التطبيق ثم إعادة تثبيته. لاحظ أن هذا سيؤدي إلى فقدان إعدادات الإشعارات الحالية.',
                    ),
                    
                    Divider(color: Colors.white.withOpacity(0.1), height: 24),
                    
                    _buildTroubleshootingTip(
                      number: '6',
                      title: 'التأكد من التحديثات',
                      content: 'تأكد من تحديث التطبيق إلى أحدث إصدار من متجر التطبيقات.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // بناء نصائح حل المشكلات
  Widget _buildTroubleshootingTip({
    required String number,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}