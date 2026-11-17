import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../data/student_repository.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _updatingTheme = false;

  Future<void> _toggleTheme(StudentRepository repository, bool darkMode) async {
    setState(() => _updatingTheme = true);
    try {
      await repository.updateThemeMode(darkMode ? 'dark' : 'light');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme preference could not be saved: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingTheme = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final repository = StudentRepository(user.uid);
    final name = user.displayName ?? user.email?.split('@').first ?? 'Student';
    final isGoogleUser = user.providerData.any(
      (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    final supportsPasswordChange = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );

    return StreamBuilder(
      stream: repository.watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data() ?? const <String, dynamic>{};
        final photoUrl = user.photoURL;
        final darkMode = profile['themeMode'] == 'dark';
        final ImageProvider<Object>? photoProvider = photoUrl == null
            ? null
            : NetworkImage(photoUrl);

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snapshot.hasError)
                  const Card(
                    color: Color(0xFFFFF3E0),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        'Unable to load saved profile settings from Firebase.',
                      ),
                    ),
                  ),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFE7F0F3),
                          backgroundImage: photoProvider,
                          child: photoProvider == null
                              ? const Icon(
                                  Icons.person,
                                  size: 52,
                                  color: Color(0xFF536872),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No email address',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 18),
                        _ProfileInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Account Type',
                          value: isGoogleUser ? 'Google' : 'Email',
                        ),
                        if (user.metadata.creationTime != null) ...[
                          const Divider(height: 20),
                          _ProfileInfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Joined',
                            value: _formatDate(user.metadata.creationTime!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white,
                  child: Column(
                    children: [
                      if (supportsPasswordChange)
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordPage(),
                            ),
                          ),
                        ),
                      if (supportsPasswordChange) const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          darkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode,
                        ),
                        title: const Text('Dark Theme'),
                        subtitle: Text(darkMode ? 'Dark' : 'Light'),
                        value: darkMode,
                        onChanged: _updatingTheme
                            ? null
                            : (value) => _toggleTheme(repository, value),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Color(0xFFB3261E),
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Color(0xFFB3261E)),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.toLocal().month}/${date.toLocal().day}/${date.toLocal().year}';
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with email to change password.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassword.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassword.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        final message = switch (error.code) {
          'wrong-password' ||
          'invalid-credential' => 'Current password is incorrect.',
          'requires-recent-login' =>
            'Please sign in again before changing your password.',
          _ => error.message ?? 'Password update failed.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Keep your account secure by using a strong password.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _passwordField(
                    _currentPassword,
                    'Current Password',
                    obscureText: _obscureCurrentPassword,
                    onToggleVisibility: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    _newPassword,
                    'New Password',
                    obscureText: _obscureNewPassword,
                    onToggleVisibility: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Use at least 6 characters';
                      }
                      if (value == _currentPassword.text) {
                        return 'Choose a password different from your current one';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    _confirmPassword,
                    'Confirm New Password',
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    validator: (value) => value != _newPassword.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading ? null : _changePassword,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(_loading ? 'Updating...' : 'Update Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show $label' : 'Hide $label',
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF087A3E)),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
