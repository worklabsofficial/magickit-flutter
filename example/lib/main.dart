import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

void main() {
  runApp(const MagicKitExampleApp());
}

class MagicKitExampleApp extends StatelessWidget {
  const MagicKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MagicKit Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D4AF5)),
        extensions: [MagicTheme.light()],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B82F8),
          brightness: Brightness.dark,
        ),
        extensions: [MagicTheme.dark()],
      ),
      home: const ComponentShowcasePage(),
    );
  }
}

class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  bool _isLoading = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.surface,
        elevation: 0,
        title: MagicText('MagicKit Showcase', style: MagicTextStyle.h5),
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.spacing.md),
        children: [
          // --- MagicText ---
          _Section(
            title: 'MagicText',
            children: [
              MagicText('Heading 1', style: MagicTextStyle.h1),
              SizedBox(height: theme.spacing.xs),
              MagicText('Heading 2', style: MagicTextStyle.h2),
              SizedBox(height: theme.spacing.xs),
              MagicText('Heading 3', style: MagicTextStyle.h3),
              SizedBox(height: theme.spacing.xs),
              MagicText('Body Large', style: MagicTextStyle.bodyLarge),
              MagicText('Body Medium', style: MagicTextStyle.bodyMedium),
              MagicText('Caption text', style: MagicTextStyle.caption),
            ],
          ),

          // --- MagicButton ---
          _Section(
            title: 'MagicButton',
            children: [
              Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  MagicButton(
                    label: 'Primary',
                    onPressed: () {},
                  ),
                  MagicButton(
                    label: 'Secondary',
                    onPressed: () {},
                    variant: MagicButtonVariant.secondary,
                  ),
                  MagicButton(
                    label: 'Outlined',
                    onPressed: () {},
                    variant: MagicButtonVariant.outlined,
                  ),
                  MagicButton(
                    label: 'Ghost',
                    onPressed: () {},
                    variant: MagicButtonVariant.ghost,
                  ),
                  MagicButton(
                    label: 'Disabled',
                    onPressed: null,
                  ),
                  MagicButton(
                    label: 'Loading',
                    onPressed: () {},
                    isLoading: _isLoading,
                  ),
                  MagicButton(
                    label: 'With Icon',
                    onPressed: () {},
                    icon: Icons.add,
                  ),
                ],
              ),
              SizedBox(height: theme.spacing.sm),
              Row(
                children: [
                  MagicButton(
                    label: 'Small',
                    onPressed: () {},
                    size: MagicButtonSize.small,
                  ),
                  SizedBox(width: theme.spacing.sm),
                  MagicButton(
                    label: 'Medium',
                    onPressed: () {},
                  ),
                  SizedBox(width: theme.spacing.sm),
                  MagicButton(
                    label: 'Large',
                    onPressed: () {},
                    size: MagicButtonSize.large,
                  ),
                ],
              ),
              SizedBox(height: theme.spacing.sm),
              MagicButton(
                label: _isLoading ? 'Loading...' : 'Toggle Loading State',
                onPressed: () => setState(() => _isLoading = !_isLoading),
                variant: MagicButtonVariant.outlined,
              ),
            ],
          ),

          // --- MagicInput ---
          _Section(
            title: 'MagicInput',
            children: [
              MagicInput(
                label: 'Email',
                hint: 'Masukkan email kamu',
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              SizedBox(height: theme.spacing.sm),
              const MagicInput(
                label: 'Password',
                hint: 'Masukkan password',
                obscureText: true,
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              SizedBox(height: theme.spacing.sm),
              const MagicInput(
                hint: 'Input dengan error',
                errorText: 'Field ini wajib diisi',
              ),
              SizedBox(height: theme.spacing.sm),
              const MagicInput(
                hint: 'Disabled input',
                enabled: false,
              ),
            ],
          ),

          // --- MagicIcon ---
          _Section(
            title: 'MagicIcon',
            children: [
              Wrap(
                spacing: theme.spacing.md,
                children: [
                  MagicIcon(Icons.home_outlined),
                  MagicIcon(Icons.search, color: theme.colors.primary),
                  MagicIcon(Icons.favorite_outline, color: Colors.red),
                  MagicIcon(Icons.settings_outlined),
                  MagicIcon(Icons.notifications_outlined, size: 32),
                ],
              ),
            ],
          ),

          // --- MagicAvatar ---
          _Section(
            title: 'MagicAvatar',
            children: [
              Wrap(
                spacing: theme.spacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const MagicAvatar(
                    fallbackInitial: 'Y',
                    size: MagicAvatarSize.sm,
                  ),
                  const MagicAvatar(
                    fallbackInitial: 'U',
                  ),
                  const MagicAvatar(
                    fallbackInitial: 'D',
                    size: MagicAvatarSize.lg,
                  ),
                  MagicAvatar(
                    imageUrl: 'https://i.pravatar.cc/150?img=3',
                    size: MagicAvatarSize.md,
                  ),
                  const MagicAvatar(
                    imageUrl: 'https://invalid-url.xyz/broken.png',
                    fallbackInitial: 'E',
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: theme.spacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.lg),
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radius.md),
        boxShadow: theme.shadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MagicText(title, style: MagicTextStyle.h6),
          Divider(height: theme.spacing.lg, color: theme.colors.outline),
          ...children,
        ],
      ),
    );
  }
}
