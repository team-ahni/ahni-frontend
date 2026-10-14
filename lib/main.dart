import 'package:ahni_mobile/app/ahni_app.dart';
import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/core/config/app_environment.dart';
import 'package:ahni_mobile/core/network/student_api.dart';
import 'package:ahni_mobile/features/grade/application/course_catalog_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_edit_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_list_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_registration_controller.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/data/course_api.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/inquiry/application/inquiry_controller.dart';
import 'package:ahni_mobile/features/inquiry/data/inquiry_api.dart';
import 'package:ahni_mobile/features/timetable/application/timetable_controller.dart';
import 'package:ahni_mobile/features/timetable/data/timetable_api.dart';
import 'package:ahni_mobile/features/onboarding/application/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/data/graduation_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const configuredEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  final missingConfiguration = <String>[
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    if (apiBaseUrl.isEmpty) 'API_BASE_URL',
  ];

  if (missingConfiguration.isNotEmpty) {
    runApp(_ConfigurationErrorApp(missing: missingConfiguration));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSupabaseStorage(),
    ),
  );

  final auth = SupabaseAuthGateway(Supabase.instance.client);
  final httpClient = http.Client();
  final apiBaseUri = Uri.parse(apiBaseUrl);
  final gradeApi = HttpGradeApi(baseUri: apiBaseUri, client: httpClient);
  runApp(
    AhniApp(
      environment: AppEnvironment.parse(configuredEnvironment),
      controller: OnboardingController(
        auth: auth,
        api: HttpStudentApi(baseUri: apiBaseUri, client: httpClient),
      ),
      gradeController: GradeListController(auth: auth, api: gradeApi),
      gradeSimulationController: GradeSimulationController(
        auth: auth,
        api: gradeApi,
      ),
      graduationController: GraduationController(
        auth: auth,
        api: HttpGraduationApi(baseUri: apiBaseUri, client: httpClient),
      ),
      courseController: CourseCatalogController(
        auth: auth,
        api: HttpCourseApi(baseUri: apiBaseUri, client: httpClient),
      ),
      gradeRegistrationController: GradeRegistrationController(
        auth: auth,
        api: gradeApi,
      ),
      gradeEditController: GradeEditController(auth: auth, api: gradeApi),
      inquiryController: InquiryController(
        auth: auth,
        api: HttpInquiryApi(baseUri: apiBaseUri, client: httpClient),
      ),
      timetableController: TimetableController(
        auth: auth,
        api: HttpTimetableApi(baseUri: apiBaseUri, client: httpClient),
      ),
    ),
  );
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp({required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '앱 설정을 확인해 주세요.\n'
                '누락된 실행 설정: ${missing.join(', ')}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
