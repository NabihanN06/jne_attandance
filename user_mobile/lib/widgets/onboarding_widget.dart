import 'package:flutter/material.dart';

class OnboardingWidget extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  const OnboardingWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onNext,
    required this.onSkip,
    this.nextLabel = 'Lanjut →',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Icon area
              SizedBox(
                height: 120,
                child: icon,
              ),

              const Spacer(flex: 2),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE31E24),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB0BEC5),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 3),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    nextLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip
              GestureDetector(
                onTap: onSkip,
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF90A4AE),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}