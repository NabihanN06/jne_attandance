import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../onboarding/onboarding1.dart';
import '../home/home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscureLogin = true;
  bool _loginLoading = false;

  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPhoneCtrl = TextEditingController();
  final _regNikCtrl = TextEditingController();
  final _regDeptCtrl = TextEditingController();
  final _regPosCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  bool _obscureReg = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _doRegister() {
    final provider = context.read<AppProvider>();
    if (_regNameCtrl.text.isEmpty || _regEmailCtrl.text.isEmpty ||
        _regNikCtrl.text.isEmpty || _regPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mohon lengkapi semua field wajib'),
        backgroundColor: Color(0xFFB71C1C),
      ));
      return;
    }
    final user = UserModel(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: _regNameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      phone: _regPhoneCtrl.text.trim(),
      nik: _regNikCtrl.text.trim(),
      role: 'user',
      department: _regDeptCtrl.text.trim().isEmpty ? 'Belum diisi' : _regDeptCtrl.text.trim(),
      position: _regPosCtrl.text.trim().isEmpty ? 'Pegawai' : _regPosCtrl.text.trim(),
    );
    provider.register(user);
    provider.addNotification('Akun Baru', '${user.name} baru mendaftar. NIK: ${user.nik}', targetUserId: 'admin_001');
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Onboarding1()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('JNE Attendance App'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE31E24),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF90A4AE),
          tabs: const [Tab(text: 'Login'), Tab(text: 'Daftar Akun')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [_buildLogin(), _buildRegister()]),
    );
  }

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selamat Datang!\nAyo, Masuk ke Akun Kamu',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
            const SizedBox(height: 6),
            const Text('JNE Martapura Attendance App', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
            const SizedBox(height: 20),
            _label('EMAIL'),
            _field(_loginEmailCtrl, 'email@contoh.com', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _label('PASSWORD'),
            _field(_loginPassCtrl, '••••••••', obscure: _obscureLogin,
                suffix: IconButton(
                  icon: Icon(_obscureLogin ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF90A4AE), size: 18),
                  onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                )),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(width: 18, height: 18, child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: const Color(0xFFE31E24),
                side: const BorderSide(color: Color(0xFF90A4AE)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
              )),
              const SizedBox(width: 8),
              const Text('Ingat saya (Pada perangkat ini)', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 46,
                child: ElevatedButton(
                  onPressed: _loginLoading ? null : _doLogin,
                  child: _loginLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Log In'),
                )),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _tabController.animateTo(1),
          child: RichText(text: const TextSpan(
            text: 'Belum punya akun? ',
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13),
            children: [TextSpan(text: 'Daftar di sini', style: TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.w600))],
          )),
        ),
      ]),
    );
  }

  Widget _buildRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Buat Akun Baru', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Isi data diri kamu untuk mendaftar', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
          const SizedBox(height: 20),
          _label('NAMA LENGKAP *'), _field(_regNameCtrl, 'Nama lengkap'),
          const SizedBox(height: 12),
          _label('EMAIL *'), _field(_regEmailCtrl, 'email@contoh.com', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _label('NO. TELEPON'), _field(_regPhoneCtrl, '+62 xxx', keyboard: TextInputType.phone),
          const SizedBox(height: 12),
          _label('NIK (ID Karyawan) *'), _field(_regNikCtrl, 'Nomor Induk Karyawan'),
          const SizedBox(height: 12),
          _label('DEPARTEMEN'), _field(_regDeptCtrl, 'Dept. Logistik'),
          const SizedBox(height: 12),
          _label('JABATAN'), _field(_regPosCtrl, 'Staff Operasional'),
          const SizedBox(height: 12),
          _label('PASSWORD *'),
          _field(_regPassCtrl, '••••••••', obscure: _obscureReg,
              suffix: IconButton(
                icon: Icon(_obscureReg ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF90A4AE), size: 18),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              )),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton(onPressed: _doRegister, child: const Text('Daftar & Mulai Onboarding'))),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
  );

  Widget _field(TextEditingController ctrl, String hint, {
    bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl, obscureText: obscure, keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFF4A6080)),
        filled: true, fillColor: const Color(0xFF162440),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        suffixIcon: suffix,
      ),
    );
  }
}