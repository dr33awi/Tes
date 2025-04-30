import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import '../home_screen/home_screen.dart';

class OnBoardingScreenWrapper extends StatelessWidget {
  const OnBoardingScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: OnBoardingSlider(
        finishButtonText: 'ابدأ',
        finishButtonStyle: FinishButtonStyle(
          backgroundColor: const Color(0xFF447055),
        ),
        // ✅ زر "تخطي" أعلى يمين
        onFinish: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
        skipTextButton: const Text(
          'تخطي',
          style: TextStyle(
            color: Color(0xFF447055),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        controllerColor: const Color(0xFF447055),
        totalPage: 3,
        headerBackgroundColor: const Color(0xFFE7E8E3),
        pageBackgroundColor: const Color(0xFFE7E8E3),
        background: const [
          SizedBox(),
          SizedBox(),
          SizedBox(),
        ],
        speed: 1.8,
        pageBodies: [
          _buildPage(
            imagePath: 'assets/images/onboarding1.png',
            title: 'أذكار المسلم',
            description: 'تطبيق شامل لجميع الأذكار اليومية للمسلم',
          ),
          _buildPage(
            imagePath: 'assets/images/onboarding2.png',
            title: 'إشعارات تذكيرية',
            description: 'احصل على تذكير منتظم بالأذكار في أوقاتها',
          ),
          _buildPage(
            imagePath: 'assets/images/onboarding3.png',
            title: 'سهل الاستخدام',
            description: 'واجهة بسيطة وسهلة الاستخدام',
          ),
        ],
      ),
    );
  }

  Widget _buildPage({required String imagePath, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // تغيير من center إلى start لرفع المحتوى
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 20), // تقليل المسافة من الأعلى من 40 إلى 20
          // تنسيق موحد للصور في جميع الصفحات
          Container(
            width: 350,
            height: 350,
            alignment: Alignment.center,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              width: 350,
              height: 350,
            ),
          ),
          const SizedBox(height: 40), // مسافة موحدة بين الصورة والنص
          // تنسيق موحد للعناوين
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF447055),
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15), // مسافة موحدة بين العنوان والوصف
          // تنسيق موحد للوصف
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 18.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}