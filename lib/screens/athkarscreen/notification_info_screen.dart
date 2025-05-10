// lib/screens/athkarscreen/notification_info_screen.dart
import 'package:flutter/material.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'حول إشعارات الأذكار',
                content: 'يقوم التطبيق بإرسال إشعارات تذكيرية في الأوقات المحددة لمساعدتك على المداومة على قراءة الأذكار في أوقاتها المناسبة.',
              ),
              
              _buildInfoCard(
                icon: Icons.timer,
                title: 'أوقات الإشعارات',
                content: 'يعتمد التطبيق على أوقات افتراضية لكل نوع من الأذكار، ويمكنك تعديل هذه الأوقات بما يناسبك من خلال شاشة إعدادات الإشعارات.',
              ),
              
              _buildInfoCard(
                icon: Icons.notification_important,
                title: 'تفعيل الإشعارات',
                content: 'لضمان وصول الإشعارات إليك، يرجى التأكد من السماح للتطبيق بإرسال الإشعارات من خلال إعدادات جهازك. بعض أجهزة الأندرويد قد تحتاج أيضاً إلى السماح للتطبيق بالعمل في الخلفية.',
              ),
              
              _buildInfoCard(
                icon: Icons.battery_alert,
                title: 'توفير البطارية',
                title2: '(خاص بأجهزة أندرويد)',
                content: 'قد تقوم بعض أجهزة أندرويد بإيقاف التطبيقات تلقائياً في الخلفية لتوفير البطارية، مما قد يؤثر على وصول الإشعارات. يمكنك إضافة تطبيق الأذكار إلى قائمة الاستثناءات من خلال إعدادات "توفير البطارية" أو "تحسين البطارية" في جهازك.',
              ),
              
              _buildInfoCard(
                icon: Icons.warning_amber,
                title: 'المنطقة الزمنية',
                content: 'يعتمد التطبيق على المنطقة الزمنية "آسيا/الرياض" كمنطقة زمنية ثابتة. إذا كنت تعيش في منطقة زمنية مختلفة، فقد تصلك الإشعارات في أوقات غير مناسبة. يمكنك تعديل الأوقات بما يناسب منطقتك الزمنية.',
              ),
              
              _buildTroubleshootingTips(),
              
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build info card
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? title2,
    required String content,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: kPrimary,
                      size: 20,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimary,
                        ),
                      ),
                      if (title2 != null)
                        Text(
                          title2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build troubleshooting tips
  Widget _buildTroubleshootingTips() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.help_outline,
                      color: kPrimary,
                      size: 20,
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
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Troubleshooting tips
            _buildTroubleshootingTip(
              number: '1',
              title: 'الإشعارات لا تصل',
              content: 'تأكد من تفعيل الإشعارات للتطبيق من إعدادات جهازك، ومن عدم تفعيل وضع "عدم الإزعاج".',
            ),
            
            _buildTroubleshootingTip(
              number: '2',
              title: 'مشكلة في التوقيت',
              content: 'قم بإعادة ضبط أوقات الإشعارات من شاشة إعدادات الإشعارات.',
            ),
            
            _buildTroubleshootingTip(
              number: '3',
              title: 'لا يوجد صوت للإشعارات',
              content: 'تأكد من عدم كتم صوت الإشعارات في إعدادات جهازك.',
            ),
            
            _buildTroubleshootingTip(
              number: '4',
              title: 'الإشعارات تتوقف بعد فترة',
              content: 'أجهزة الأندرويد تميل إلى إيقاف التطبيقات في الخلفية لتوفير البطارية. قم بإضافة التطبيق إلى قائمة الاستثناءات من إعدادات "توفير البطارية" أو "تحسين البطارية".',
            ),
            
            _buildTroubleshootingTip(
              number: '5',
              title: 'إعادة تشغيل التطبيق',
              content: 'في حال استمرار المشكلة، حاول إعادة تشغيل التطبيق أو إعادة تشغيل الجهاز.',
            ),
          ],
        ),
      ),
    );
  }
  
  // Build troubleshooting tip
  Widget _buildTroubleshootingTip({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kPrimary,
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
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}