/// Kayıt akışının e-posta OTP ekranı.
///
/// Kod buraya gelmeden ÖNCE çağıran tarafından gönderilir. Doğrulama
/// başarılıysa ekran `true` ile kapanır; aksi hâlde kullanıcı yeniden dener
/// ya da **5 dakikalık** süre dolunca kodu tekrar ister (web ile aynı süre).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../common/widgets/login_signup/auth_notice.dart';
import '../../../../common/widgets/login_signup/otp_code_field.dart';
import '../../../../data/repositories/authentication/api_auth.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  static const int _cooldown = 5 * 60; // 5 dakika, saniye cinsinden

  String _code = '';
  String? _error;
  bool _verifying = false;
  bool _resending = false;

  int _secondsLeft = _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _cooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  String get _formattedTime {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get _expired => _secondsLeft <= 0;

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    final res = await ApiAuth.verifyRegistrationOtp(contact: widget.email, code: _code);

    if (!mounted) return;
    if (res['success'] == true) {
      _timer?.cancel();
      Get.back(result: true);
    } else {
      setState(() {
        _verifying = false;
        _error = (res['message']?.toString().isNotEmpty == true)
            ? res['message'].toString()
            : 'Wrong code. Please try again.';
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });

    final res = await ApiAuth.resendRegistrationOtp(contact: widget.email);

    if (!mounted) return;
    setState(() => _resending = false);
    if (res['success'] == true) {
      _startTimer();
    } else {
      setState(() => _error = (res['message']?.toString().isNotEmpty == true)
          ? res['message'].toString()
          : 'Could not resend the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace, vertical: TSizes.defaultSpace),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Back button
                TRoundedContainer(
                  padding: EdgeInsets.zero,
                  radius: TSizes.borderRadiusMd,
                  backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
                  child: IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// Title
                Center(
                  child: Text('Email Verification'.tr,
                      style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                /// Subtitle
                Text(
                  '${'A verification code was sent to'.tr} ${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// OTP field — otomatik ilerleme, geri silme, yapıştırma.
                TOtpCodeField(
                  length: 6,
                  hasError: _error != null,
                  onChanged: (code) => _code = code,
                  onCompleted: (code) => _code = code,
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                /// Countdown / expired
                Center(
                  child: Text(
                    _expired ? 'Code expired'.tr : '${'Code expires in'.tr} $_formattedTime',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _expired ? TColors.error : TColors.darkGrey,
                        ),
                  ),
                ),

                /// Hata — metin yoksa kutu hiç çizilmez.
                const SizedBox(height: TSizes.spaceBtwItems),
                TAuthNotice(message: _error, tone: TAuthNoticeTone.error),

                const SizedBox(height: TSizes.spaceBtwSections * 2),

                /// Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    child: Text(_verifying ? '${'Verifying'.tr}...' : 'Verify'.tr),
                  ),
                ),

                const SizedBox(height: TSizes.spaceBtwItems),

                /// Resend — yalnız süre dolunca etkinleşir.
                Center(
                  child: TextButton(
                    onPressed: (_expired && !_resending) ? _resend : null,
                    child: Text(
                      _resending
                          ? '${'Sending'.tr}...'
                          : _expired
                              ? 'Resend code'.tr
                              : '${'Resend code'.tr} ($_formattedTime)',
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
}
