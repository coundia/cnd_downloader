import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      'Java',
      'Spring Boot',
      'Angular',
      'PHP 8',
      'Laravel',
      'Flutter',
      'Swift',
      'CQRS',
      'DDD',
      'RabbitMQ',
      'PostgreSQL',
      'MySQL',
      'Docker',
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white10,
                  child: Text(
                    'SEN IPTV',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Papa Coundia',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Developer',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),

                Card(
                  color: const Color(0xFF111111),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _kv('Email pro', 'contact@pcoundia.com'),
                        _kv('Web', 'pcoundia.com'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '© ${DateTime.now().year} Coundia',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              v,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
