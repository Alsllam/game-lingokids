/// One-shot signals a game sends to the screen that hosts it, which answers
/// with sound and mascot animation. Cubits never touch audio or widgets.
enum GameFeedback {
  none,
  correct,
  wrong,
  finished,

  /// The game is saying or repeating its question (the mascot "talks").
  prompt,
}
