import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:test_athkar_app/models/daily_quote_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.newFavoriteQuote});

  final HighlightItem? newFavoriteQuote;

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<HighlightItem> favoriteQuotes = []; // قائمة الاقتباسات المفضلة

  @override
  void initState() {
    super.initState();
    if (widget.newFavoriteQuote != null) {
      setState(() {
        favoriteQuotes.add(widget.newFavoriteQuote!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'المفضلة',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
        ),
        body: favoriteQuotes.isEmpty
            ? const Center(
                child: Text('لا يوجد اقتباسات مفضلة حتى الآن.'),
              )
            : ListView.builder(
                itemCount: favoriteQuotes.length,
                itemBuilder: (context, index) {
                  final quote = favoriteQuotes[index];
                  return ListTile(
                    title: Text(quote.quote),
                    subtitle: Text(quote.source),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeFromFavorites(quote),
                    ),
                  );
                },
              ),
      ),
    );
  }

  // إزالة اقتباس من المفضلة
  void _removeFromFavorites(HighlightItem quote) {
    setState(() {
      favoriteQuotes.remove(quote);
    });
  }
}