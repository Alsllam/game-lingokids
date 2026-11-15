import 'package:equatable/equatable.dart';

/// A piece of content text in both app languages.
final class LocalizedText extends Equatable {
  const LocalizedText({required this.ar, required this.en});

  /// The same text for every language (emoji, hex colours, shape names).
  const LocalizedText.same(String value) : ar = value, en = value;

  final String ar;
  final String en;

  String of(String languageCode) => languageCode == 'ar' ? ar : en;

  @override
  List<Object?> get props => [ar, en];
}
