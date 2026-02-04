import 'dart:math';

class BeatlyMessages {
  static final Random _random = Random();

  static final List<String> _messages = [
    "🎧 Your ears have great taste.",
    "🔥 This track? Absolute masterpiece.",
    "⚠️ Warning: This song is highly addictive.",
    "😌 Vibe check: Passed. This playlist is elite.",
    "🎶 Turn it up. You know you want to.",

    "🔥 Wait, who gave you permission to have such a fire taste in music?",
    "🌙 This playlist is officially a mood.",
    "🎯 Your shuffle never misses. Seriously.",
    "🎬 If your life was a movie, this would be the hit single.",
    "🎛️ You’re definitely the person everyone wants holding the AUX cable.",

    "💫 Every note of this sounds better with you listening.",
    "😌 Close your eyes. Let the sound take over.",
    "🔊 This bass was made for your speakers.",
    "⏳ Wait for the drop... it's worth it.",
    "💎 Pure sonic gold. Don't stop the flow.",
    "☕ Monday morning vs. this song? This song wins every time.",

    "🚗 Perfect song for a long drive and zero destination.",
    "🧹 Cleaning the house or a private concert? Let’s go with concert.",
    "🌌 The sun is down, the volume is up. This is the sweet spot.",
    "🎥 Found: The perfect track for your 'Main Character' moment.",
    "🔁 On the 5th repeat? Don't worry, we're not judging.",

    "🧠 This song is living rent-free in your head today.",
    "🔂 One more time? Yeah, one more time.",
    "⚠️ Warning: Side effects include humming this for the next 48 hours.",
    "🔇 The silence is loud. Let’s fix that.",
    "🏙️ Ghost town in here... drop a beat!",
    "💃 Your ears are lonely. Give them something to dance to.",
  ];

  /// Returns a random message different from the last one
  static String random({String? exclude}) {
    if (_messages.length <= 1) return _messages.first;

    String next;
    do {
      next = _messages[_random.nextInt(_messages.length)];
    } while (next == exclude);

    return next;
  }
}
