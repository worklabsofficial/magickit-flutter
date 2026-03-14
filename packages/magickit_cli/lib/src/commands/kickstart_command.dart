// ignore_for_file: unnecessary_brace_in_string_interps
import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/page_generator.dart';
import '../generators/route_generator.dart';
import '../utils/di_utils.dart';
import '../utils/init_guard.dart';
import '../utils/logger.dart';

class KickstartCommand extends Command<void> {
  @override
  String get name => 'kickstart';

  @override
  String get description =>
      'Generate starter app: splash, onboarding, login, main navigation.';

  @override
  String get invocation => 'magickit kickstart';

  @override
  Future<void> run() async {
    logger.info('');
    logger.info('MagicKit Kickstart!');
    logger.info('');

    // ── Prerequisite check ────────────────────────────────────────────────────
    logger.info('Checking prerequisites...');
    requireMagickitInit(requireInjector: true);
    logger.info('  magickit init detected');
    logger.info('');

    // ── Create feature route groups ───────────────────────────────────────────
    logger.info('Creating features...');
    final routeGen = RouteGenerator();
    final pageGen = PageGenerator();

    for (final feature in ['startup', 'auth', 'main']) {
      final featureFiles = routeGen.generateFeatureRouteFiles(feature);
      for (final entry in featureFiles.entries) {
        final file = File(entry.key);
        if (file.existsSync()) continue;
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(entry.value);
      }
      routeGen.updateCoreForFeature(feature);
    }

    // ── Create pages using the same generators as `magickit page` ────────────
    final pages = [
      ('startup', 'splash'),
      ('startup', 'onboarding'),
      ('auth', 'login'),
      ('main', 'main_navigation'),
      ('main', 'home'),
      ('main', 'profile'),
    ];

    for (final (feature, page) in pages) {
      await pageGen.generate(
        name: page,
        outputDir: 'lib/features/$feature',
      );
      // main_navigation acts as shell wrapper, not a standalone route
      if (!(feature == 'main' && page == 'main_navigation')) {
        routeGen.updateRouteFilesForPage(feature, page, const [], const []);
      }
      logger.info('  Page: $feature/$page');
    }

    // ── Register all pages in injector.dart ──────────────────────────────────
    _updateAllInjections(pages.map((e) => (e.$1, e.$2)).toList());

    // ── Overwrite with customized implementations ─────────────────────────────
    logger.info('');
    logger.info('Customizing template...');

    _writeMainRoutes();
    _updateInitialRoute();

    _writeSplashCubit();
    _writeSplashState();
    _writeSplashPage();

    _writeOnboardingCubit();
    _writeOnboardingState();
    _writeOnboardingPage();

    _writeLoginCubit();
    _writeLoginState();
    _writeLoginPage();

    _writeMainNavigationCubit();
    _writeMainNavigationState();
    _writeMainNavigationPage();

    _writeHomeCubit();
    _writeHomeState();
    _writeHomePage();

    _writeProfileCubit();
    _writeProfileState();
    _writeProfilePage();

    _writeMainDart();

    logger.success('main.dart updated');
    logger.success('Splash → auto navigate');
    logger.success('Onboarding → 3 slides');
    logger.success('Login → form with validation');
    logger.success('Main → bottom navigation (home + profile)');
    logger.success('Profile → logout with dialog');

    logger.info('');
    logger.success('Your app is ready to run!');
    logger.info('   → flutter run');
    logger.info('   → Demo login: test@mail.com / 123456');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _writeFile(String path, String content) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  void _updateAllInjections(List<(String, String)> pages) {
    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (!injectorFile.existsSync()) return;

    final content = injectorFile.readAsStringSync();
    if (!content.contains('// MAGICKIT:INJECTOR') ||
        !content.contains('// MAGICKIT:IMPORT')) {
      logger.warn(
        'injector.dart tidak memiliki marker MAGICKIT. Skip auto DI update.',
      );
      return;
    }

    final appName = DiUtils.readAppName();
    if (appName == null) {
      logger.warn('pubspec.yaml tidak ditemukan atau gagal dibaca.');
      return;
    }

    final features = <String>{};
    var updated = false;

    for (final (feature, page) in pages) {
      features.add(feature);
      final featureUpdated =
          DiUtils.updateFeatureInjector(feature: feature, page: page);
      if (featureUpdated) updated = true;
    }

    for (final feature in features) {
      final globalUpdated =
          DiUtils.updateGlobalInjector(appName: appName, feature: feature);
      if (globalUpdated) updated = true;
    }

    if (updated) {
      logger.info('DI updated for features: ${features.join(', ')}');
    }
  }

  // ── Feature Route Files ───────────────────────────────────────────────────

  void _writeMainRoutes() {
    _writeFile(
      'lib/features/main/routes/main_routes.dart',
      '''// GENERATED BY MAGICKIT CLI

import 'package:go_router/go_router.dart';
import 'main_route_names.dart';
import '../main_navigation/presentation/pages/main_navigation_page.dart';
import '../home/presentation/pages/home_page.dart';
import '../profile/presentation/pages/profile_page.dart';

final mainRoutes = <RouteBase>[
  ShellRoute(
    builder: (context, state, child) => MainNavigationPage(child: child),
    routes: [
      GoRoute(
        name: MainRouteName.home,
        path: MainRoutePath.homePath,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: MainRouteName.profile,
        path: MainRoutePath.profilePath,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  ),
];
''',
    );
  }

  void _updateInitialRoute() {
    final file = File('lib/core/routes/route_config.dart');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    content = _ensureImport(
      content,
      "import '../../features/startup/routes/startup_route_names.dart';",
    );

    final initialReg = RegExp(r"initialLocation:\\s*'[^']*'");
    if (initialReg.hasMatch(content)) {
      content = content.replaceFirst(
        initialReg,
        'initialLocation: StartupRoutePath.splashPath',
      );
    }

    file.writeAsStringSync(content);
  }

  String _ensureImport(String content, String importLine) {
    if (content.contains(importLine)) return content;
    final reg = RegExp("^import\\s+['\"][^'\"]+['\"];\\s*", multiLine: true);
    final matches = reg.allMatches(content).toList();
    if (matches.isEmpty) {
      return '$importLine\n$content';
    }
    final last = matches.last;
    return '${content.substring(0, last.end)}\n$importLine${content.substring(last.end)}';
  }

  // ── Splash ────────────────────────────────────────────────────────────────

  void _writeSplashState() {
    _writeFile(
      'lib/features/startup/splash/presentation/cubit/splash_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class SplashStateCubit {
  const SplashStateCubit();
}
''',
    );
  }

  void _writeSplashCubit() {
    _writeFile(
      'lib/features/startup/splash/presentation/cubit/splash_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import '../../../../auth/routes/auth_route_names.dart';
import '../../../../main/routes/main_route_names.dart';
import '../../../routes/startup_route_names.dart';
import 'splash_state.dart';

class SplashCubit extends MagicCubit<SplashStateCubit> {
  SplashCubit() : super(const SplashStateCubit());

  void Function(String path)? _onNavigate;

  void setOnNavigate(void Function(String path) callback) {
    _onNavigate = callback;
  }

  @override
  void onReady() {
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Cek dari local storage
    const hasSeenOnboarding = false;
    const isLoggedIn = false;

    if (!hasSeenOnboarding) {
      _onNavigate?.call(StartupRoutePath.onboardingPath);
    } else if (!isLoggedIn) {
      _onNavigate?.call(AuthRoutePath.loginPath);
    } else {
      _onNavigate?.call(MainRoutePath.homePath);
    }
  }
}
''',
    );
  }

  void _writeSplashPage() {
    _writeFile(
      'lib/features/startup/splash/presentation/pages/splash_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../cubit/splash_cubit.dart';
import '../cubit/splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with MagicStatePage<SplashPage, SplashCubit, SplashStateCubit> {
  @override
  SplashCubit createCubit() {
    final c = getIt<SplashCubit>();
    c.setOnNavigate((path) => context.go(path));
    return c;
  }

  @override
  Widget buildPage(BuildContext context, SplashStateCubit state) {
    final theme = MagicTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MagicImage(src: 'assets/images/logo.png', width: 120, height: 120),
            SizedBox(height: theme.spacing.lg),
            MagicText('MagicKit', style: MagicTextStyle.h1),
            SizedBox(height: theme.spacing.sm),
            MagicText(
              'Build Flutter Apps Faster',
              style: MagicTextStyle.bodyMedium,
              color: theme.colors.onBackground.withValues(alpha: 0.7),
            ),
            SizedBox(height: theme.spacing.xl),
            MagicShimmer(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(theme.radius.full),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    );
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  void _writeOnboardingState() {
    _writeFile(
      'lib/features/startup/onboarding/presentation/cubit/onboarding_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class OnboardingStateCubit {
  final int currentPage;
  const OnboardingStateCubit({this.currentPage = 0});

  OnboardingStateCubit copyWith({int? currentPage}) {
    return OnboardingStateCubit(
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
''',
    );
  }

  void _writeOnboardingCubit() {
    _writeFile(
      'lib/features/startup/onboarding/presentation/cubit/onboarding_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends MagicCubit<OnboardingStateCubit> {
  OnboardingCubit() : super(const OnboardingStateCubit());

  void setPage(int page) {
    emit(state.copyWith(currentPage: page));
  }
}
''',
    );
  }

  void _writeOnboardingPage() {
    _writeFile(
      'lib/features/startup/onboarding/presentation/pages/onboarding_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../../../../auth/routes/auth_route_names.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with MagicStatePage<OnboardingPage, OnboardingCubit, OnboardingStateCubit> {
  final _pageController = PageController();

  @override
  OnboardingCubit createCubit() => getIt();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, OnboardingStateCubit state) {
    final theme = MagicTheme.of(context);
    final slides = [
      _Slide(icon: Icons.star, title: 'Welcome', subtitle: 'Discover amazing features'),
      _Slide(icon: Icons.touch_app, title: 'Easy', subtitle: 'Simple and intuitive'),
      _Slide(icon: Icons.rocket_launch, title: 'Ready', subtitle: "Let's get started"),
    ];

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: cubit.setPage,
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: EdgeInsets.all(theme.spacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MagicIcon(
                          slide.icon,
                          size: 80,
                          color: theme.colors.primary,
                        ),
                        SizedBox(height: theme.spacing.lg),
                        MagicText(slide.title, style: MagicTextStyle.h2),
                        SizedBox(height: theme.spacing.sm),
                        MagicText(
                          slide.subtitle,
                          style: MagicTextStyle.bodyMedium,
                          color: theme.colors.onBackground.withValues(alpha: 0.7),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(theme.spacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      slides.length,
                      (i) => Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(right: theme.spacing.xs),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.currentPage == i
                              ? theme.colors.primary
                              : theme.colors.onBackground
                                  .withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  MagicButton(
                    label: state.currentPage == slides.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: () {
                      if (state.currentPage == slides.length - 1) {
                        context.go(AuthRoutePath.loginPath);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
''',
    );
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  void _writeLoginState() {
    _writeFile(
      'lib/features/auth/login/presentation/cubit/login_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class LoginStateCubit {
  final bool isLoading;
  final bool obscurePassword;
  final String? error;

  const LoginStateCubit({
    this.isLoading = false,
    this.obscurePassword = true,
    this.error,
  });

  LoginStateCubit copyWith({
    bool? isLoading,
    bool? obscurePassword,
    String? error,
  }) {
    return LoginStateCubit(
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      error: error,
    );
  }
}
''',
    );
  }

  void _writeLoginCubit() {
    _writeFile(
      'lib/features/auth/login/presentation/cubit/login_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import 'login_state.dart';

class LoginCubit extends MagicCubit<LoginStateCubit> {
  LoginCubit() : super(const LoginStateCubit());

  void Function()? _onLoginSuccess;

  void setOnLoginSuccess(void Function() callback) {
    _onLoginSuccess = callback;
  }

  void toggleObscurePassword() {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
    if (!value.contains('@')) return 'Format email tidak valid';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, error: null));
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'test@mail.com' && password == '123456') {
      emit(state.copyWith(isLoading: false));
      _onLoginSuccess?.call();
    } else {
      emit(state.copyWith(
        isLoading: false,
        error: 'Email atau password salah',
      ));
    }
  }
}
''',
    );
  }

  void _writeLoginPage() {
    _writeFile(
      'lib/features/auth/login/presentation/pages/login_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../../../../main/routes/main_route_names.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with MagicStatePage<LoginPage, LoginCubit, LoginStateCubit> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  LoginCubit createCubit() {
    final c = getIt<LoginCubit>();
    c.setOnLoginSuccess(() => context.go(MainRoutePath.homePath));
    return c;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(BuildContext context, LoginStateCubit state) {
    final theme = MagicTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.lg),
          child: MagicForm(
            formKey: _formKey,
            children: [
              const Spacer(),
              MagicText(
                'Welcome Back',
                style: MagicTextStyle.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.spacing.xs),
              MagicText(
                'Login to continue',
                style: MagicTextStyle.bodyMedium,
                color: theme.colors.onBackground.withValues(alpha: 0.7),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: theme.spacing.xxl),
              MagicFormField(
                label: 'Email',
                child: MagicInput(
                  controller: _emailController,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: cubit.validateEmail,
                ),
              ),
              SizedBox(height: theme.spacing.md),
              MagicFormField(
                label: 'Password',
                child: MagicInput(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  obscureText: state.obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    onPressed: cubit.toggleObscurePassword,
                    icon: Icon(
                      state.obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  validator: cubit.validatePassword,
                ),
              ),
              if (state.error != null) ...[
                SizedBox(height: theme.spacing.sm),
                MagicText(
                  state.error!,
                  style: MagicTextStyle.bodySmall,
                  color: theme.colors.error,
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: theme.spacing.lg),
              MagicButton(
                label: 'Login',
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          cubit.login(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                        }
                      },
                isLoading: state.isLoading,
                variant: MagicButtonVariant.primary,
                size: MagicButtonSize.large,
              ),
              SizedBox(height: theme.spacing.md),
              MagicText(
                'Demo: test@mail.com / 123456',
                style: MagicTextStyle.caption,
                color: theme.colors.onBackground.withValues(alpha: 0.7),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
''',
    );
  }

  // ── Main Navigation ───────────────────────────────────────────────────────

  void _writeMainNavigationState() {
    _writeFile(
      'lib/features/main/main_navigation/presentation/cubit/main_navigation_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class MainNavigationStateCubit {
  final int currentIndex;
  const MainNavigationStateCubit({this.currentIndex = 0});

  MainNavigationStateCubit copyWith({int? currentIndex}) {
    return MainNavigationStateCubit(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
''',
    );
  }

  void _writeMainNavigationCubit() {
    _writeFile(
      'lib/features/main/main_navigation/presentation/cubit/main_navigation_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import 'main_navigation_state.dart';

class MainNavigationCubit extends MagicCubit<MainNavigationStateCubit> {
  MainNavigationCubit() : super(const MainNavigationStateCubit());

  void setTab(int index) {
    emit(state.copyWith(currentIndex: index));
  }
}
''',
    );
  }

  void _writeMainNavigationPage() {
    _writeFile(
      'lib/features/main/main_navigation/presentation/pages/main_navigation_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../../../routes/main_route_names.dart';
import '../cubit/main_navigation_cubit.dart';
import '../cubit/main_navigation_state.dart';

class MainNavigationPage extends StatefulWidget {
  final Widget child;
  const MainNavigationPage({super.key, required this.child});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with MagicStatePage<MainNavigationPage, MainNavigationCubit,
        MainNavigationStateCubit> {
  @override
  MainNavigationCubit createCubit() => getIt();

  @override
  Widget buildPage(BuildContext context, MainNavigationStateCubit state) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: MagicNavBar(
        currentIndex: state.currentIndex,
        onTap: (index) {
          cubit.setTab(index);
          switch (index) {
            case 0:
              context.go(MainRoutePath.homePath);
            case 1:
              context.go(MainRoutePath.profilePath);
          }
        },
        items: const [
          MagicNavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          MagicNavBarItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
''',
    );
  }

  // ── Home ──────────────────────────────────────────────────────────────────

  void _writeHomeState() {
    _writeFile(
      'lib/features/main/home/presentation/cubit/home_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class HomeStateCubit {
  const HomeStateCubit();
}
''',
    );
  }

  void _writeHomeCubit() {
    _writeFile(
      'lib/features/main/home/presentation/cubit/home_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import 'home_state.dart';

class HomeCubit extends MagicCubit<HomeStateCubit> {
  HomeCubit() : super(const HomeStateCubit());
}
''',
    );
  }

  void _writeHomePage() {
    _writeFile(
      'lib/features/main/home/presentation/pages/home_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with MagicStatePage<HomePage, HomeCubit, HomeStateCubit> {
  @override
  HomeCubit createCubit() => getIt();

  @override
  Widget buildPage(BuildContext context, HomeStateCubit state) {
    final theme = MagicTheme.of(context);
    return Scaffold(
      appBar: MagicAppBar(
        title: 'Home',
        actions: [
          MagicAvatar(
            imageUrl: null,
            fallbackInitial: 'JD',
            size: MagicAvatarSize.sm,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MagicText('Welcome back!', style: MagicTextStyle.h3),
            SizedBox(height: theme.spacing.xs),
            MagicText(
              "Here's what's happening today",
              style: MagicTextStyle.bodyMedium,
              color: theme.colors.onBackground.withValues(alpha: 0.7),
            ),
            SizedBox(height: theme.spacing.lg),
            MagicCard(
              padding: EdgeInsets.all(theme.spacing.md),
              child: Row(
                children: [
                  MagicIcon(
                    Icons.analytics_outlined,
                    size: 40,
                    color: theme.colors.primary,
                  ),
                  SizedBox(width: theme.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MagicText(
                          'Quick Stats',
                          style: MagicTextStyle.bodyLarge,
                        ),
                        MagicText(
                          'Everything looks great',
                          style: MagicTextStyle.caption,
                          color: theme.colors.onBackground.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  MagicBadge(label: 'New', color: theme.colors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''',
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  void _writeProfileState() {
    _writeFile(
      'lib/features/main/profile/presentation/cubit/profile_state.dart',
      '''// GENERATED BY MAGICKIT CLI

class ProfileStateCubit {
  const ProfileStateCubit();
}
''',
    );
  }

  void _writeProfileCubit() {
    _writeFile(
      'lib/features/main/profile/presentation/cubit/profile_cubit.dart',
      '''// GENERATED BY MAGICKIT CLI

import '../../../../../core/base/magic_cubit.dart';
import 'profile_state.dart';

class ProfileCubit extends MagicCubit<ProfileStateCubit> {
  ProfileCubit() : super(const ProfileStateCubit());
}
''',
    );
  }

  void _writeProfilePage() {
    _writeFile(
      'lib/features/main/profile/presentation/pages/profile_page.dart',
      r'''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magickit/magickit.dart';
import '../../../../../core/base/magic_state_page.dart';
import '../../../../../core/dependency_injection/injector.dart';
import '../../../../auth/routes/auth_route_names.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with MagicStatePage<ProfilePage, ProfileCubit, ProfileStateCubit> {
  @override
  ProfileCubit createCubit() => getIt();

  @override
  Widget buildPage(BuildContext context, ProfileStateCubit state) {
    final theme = MagicTheme.of(context);
    return Scaffold(
      appBar: MagicAppBar(title: 'Profile'),
      body: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: Column(
          children: [
            SizedBox(height: theme.spacing.lg),
            MagicAvatar(
              imageUrl: null,
              fallbackInitial: 'JD',
              size: MagicAvatarSize.lg,
            ),
            SizedBox(height: theme.spacing.md),
            MagicText('John Doe', style: MagicTextStyle.h3),
            SizedBox(height: theme.spacing.xs),
            MagicText(
              'test@mail.com',
              style: MagicTextStyle.bodyMedium,
              color: theme.colors.onBackground.withValues(alpha: 0.7),
            ),
            SizedBox(height: theme.spacing.xl),
            MagicDivider(),
            SizedBox(height: theme.spacing.sm),
            MagicListTile(
              leading: MagicIcon(
                Icons.settings_outlined,
                color: theme.colors.onBackground,
              ),
              title: 'Settings',
              trailing: MagicIcon(
                Icons.chevron_right,
                color: theme.colors.onBackground.withValues(alpha: 0.7),
              ),
              onTap: () {},
            ),
            MagicListTile(
              leading: MagicIcon(
                Icons.help_outline,
                color: theme.colors.onBackground,
              ),
              title: 'Help & Support',
              trailing: MagicIcon(
                Icons.chevron_right,
                color: theme.colors.onBackground.withValues(alpha: 0.7),
              ),
              onTap: () {},
            ),
            MagicListTile(
              leading: MagicIcon(
                Icons.info_outline,
                color: theme.colors.onBackground,
              ),
              title: 'About',
              trailing: MagicIcon(
                Icons.chevron_right,
                color: theme.colors.onBackground.withValues(alpha: 0.7),
              ),
              onTap: () {},
            ),
            SizedBox(height: theme.spacing.md),
            MagicDivider(),
            SizedBox(height: theme.spacing.md),
            MagicButton(
              label: 'Logout',
              variant: MagicButtonVariant.outlined,
              icon: Icons.logout,
              onPressed: () {
                MagicDialog.show(
                  context,
                  title: 'Logout',
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    MagicButton(
                      label: 'Cancel',
                      variant: MagicButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                    ),
                    MagicButton(
                      label: 'Logout',
                      variant: MagicButtonVariant.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(AuthRoutePath.loginPath);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
''',
    );
  }

  // ── main.dart ─────────────────────────────────────────────────────────────

  void _writeMainDart() {
    _writeFile(
      'lib/main.dart',
      '''// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:magickit/magickit.dart';
import 'core/dependency_injection/injector.dart';
import 'core/routes/route_config.dart';
import 'core/assets/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MagicKit App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        extensions: [
          MagicTheme(
            colors: MagicColors.light(),
            typography: MagicTypography(),
            spacing: MagicSpacing(),
            radius: MagicRadius(),
            shadows: MagicShadows(),
          ),
        ],
      ),
      routerConfig: routeConfig,
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
''',
    );

    logger.info('  main.dart updated');
  }
}
