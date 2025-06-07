import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome to TaskTide!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'By registering for an account, you agree to the following terms and conditions:',
              ),
              SizedBox(height: 16),
              Text(
                '1. Account Usage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'You must provide accurate information. One user must not impersonate another.',
              ),
              SizedBox(height: 12),
              Text(
                '2. Task Assignment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Only Team Leads have the right to assign, update, or remove tasks.',
              ),
              SizedBox(height: 12),
              Text(
                '3. Privacy & Security',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Your personal data (name, email, DOB) will be stored securely. We do not share data with third parties.',
              ),
              SizedBox(height: 12),
              Text(
                '4. Misuse of Platform',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Any misuse, including attempting to bypass role restrictions or falsify task data, will result in suspension.',
              ),
              SizedBox(height: 12),
              Text(
                '5. Disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'TaskTide is provided "as-is" without warranties. We are not liable for losses due to data loss or downtime.',
              ),
              SizedBox(height: 24),
              Text('By using this app, you agree to abide by these terms.'),
            ],
          ),
        ),
      ),
    );
  }
}
