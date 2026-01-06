import 'package:flutter/material.dart';
import 'package:reader_flutter/models/book.dart';
import 'package:reader_flutter/ui/screens/detail_screen.dart';

class RankingCard extends StatelessWidget {
  final String title;
  final List<Book> books;

  const RankingCard({
    super.key,
    required this.title,
    required this.books,
  });

  void _goToBookDetail(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.redAccent, Colors.orange, Colors.amber];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(books.take(10).length, (index) {
              final book = books[index];
              return InkWell(
                onTap: () => _goToBookDetail(context, book),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: index < 3 ? colors[index] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(book.author, style: TextStyle(fontSize: 13, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
