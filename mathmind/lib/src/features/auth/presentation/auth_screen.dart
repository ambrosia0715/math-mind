import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/presentation/dashboard_shell.dart';
import '../application/auth_provider.dart';
import '../../../widgets/mathmind_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        if (auth.errorMessage != null) ...[
                          _ErrorBanner(message: auth.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        if (_isSignUp) ...[
                          _buildNameField(),
                          const SizedBox(height: 16),
                        ],
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_isSignUp ? '회원가입' : '로그인'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_translate),
                          label: const Text('Google 계정으로 계속하기'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: auth.isLoading ? null : _toggleMode,
                          child: Text(
                            _isSignUp
                                ? '이미 계정이 있으신가요? 로그인'
                                : '처음 오셨나요? 회원가입',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final subtitleStyle =
        theme.textTheme.bodyMedium?.copyWith(color: subtitleColor);
    final actionLabel = _isSignUp ? '회원가입' : '로그인';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MathMindLogo(height: 40),
            const SizedBox(width: 12),
            Text(actionLabel, style: titleStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUp
              ? '아이디, 이름, 이메일을 입력하고 새 계정을 만들어 보세요.'
              : '계정에 로그인하고 맞춤형 수학 학습을 이어가세요.',
          style: subtitleStyle,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      decoration: const InputDecoration(
        labelText: '이름',
        hintText: '학습자 이름',
      ),
      validator: (value) {
        if (!_isSignUp) {
          return null;
        }
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return '이름을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: '이메일',
        hintText: 'example@email.com',
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return '이메일을 입력해주세요.';
        }
        final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!pattern.hasMatch(trimmed)) {
          return '올바른 이메일 형식을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return TextFormField(
          controller: _passwordController,
          textInputAction: TextInputAction.done,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: '비밀번호',
            hintText: '6자 이상 입력',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          onEditingComplete: auth.isLoading ? null : _submit,
          validator: (value) {
            final password = value ?? '';
            if (password.isEmpty) {
              return '비밀번호를 입력해주세요.';
            }
            if (password.length < 6) {
              return '비밀번호는 6자 이상이어야 합니다.';
            }
            return null;
          },
        );
      },
    );
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      if (_isSignUp) {
        await auth.registerWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      auth.clearError();
      if (!mounted) return;
      _navigateToDashboard();
    } on AuthFailure catch (error) {
      _showError(error.message);
    } catch (error) {
      debugPrint('Unexpected auth error: $error');
      _showError('인증 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();

    try {
      await auth.signInWithGoogle();
      auth.clearError();
      if (!mounted) return;
      _navigateToDashboard();
    } on AuthFailure catch (error) {
      _showError(error.message);
    } catch (error) {
      debugPrint('Unexpected Google auth error: $error');
      _showError('Google 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardShell.routeName,
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
