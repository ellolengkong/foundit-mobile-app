import 'package:flutter/material.dart';

import '../../data/mock/foundit_scope.dart';
import '../../widgets/primary_button.dart';

/// Screen to edit current user's profile information.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _whatsappOptIn = true;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = FoundItScope.of(context).authService.currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(
      text: user?.contact?.whatsappNumber ?? '',
    );
    _whatsappOptIn = user?.contact?.allowWhatsappContact ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final scope = FoundItScope.of(context);
    scope.authService.updateProfile(
      fullName: _nameController.text.trim(),
      whatsapp: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      allowWhatsappContact: _whatsappOptIn,
    );

    setState(() => _isSaving = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Nama Lengkap *', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Nama Anda',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Nama minimal 2 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Text('Nomor WhatsApp', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '081234567890',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                value: _whatsappOptIn,
                onChanged: (val) => setState(() => _whatsappOptIn = val),
                title: const Text('Izinkan Kontak WhatsApp'),
                subtitle: const Text(
                  'Pengguna lain dapat meminta nomor Anda untuk verifikasi barang yang dilaporkan.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Simpan Perubahan',
                loading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
