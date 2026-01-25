import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/quran_service.dart';

class MessageDetailScreen extends StatefulWidget {
  final Message message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  String _ayatText = '';
  String _ayatBosnianText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAyat();
  }

  Future<void> _loadAyat() async {
    final ayat = await QuranService.getAyat(widget.message.sura, widget.message.ajet);
    final ayatBosnian = await QuranService.getAyatBosnian(widget.message.sura, widget.message.ajet);
    setState(() {
      _ayatText = ayat;
      _ayatBosnianText = ayatBosnian;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dan ${widget.message.id}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slika
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                widget.message.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_border,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Sadržaj
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poruka
                  Text(
                    widget.message.message,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                  ),
                  
                  // Opis imena
                  if (widget.message.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        widget.message.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Ajet iz Kurana
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_ayatText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: Colors.teal.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Ajet iz Kur\'ana',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _ayatText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Arial',
                              height: 2.0,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                          if (_ayatBosnianText.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _ayatBosnianText,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.7,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Sura i ajet
                  _buildInfoCard(
                    context,
                    icon: Icons.book,
                    title: 'Kur\'an',
                    value: '${widget.message.sura}:${widget.message.ajet}',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Dan',
                    value: '${widget.message.id} od 30',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
