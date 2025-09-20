import 'package:characters/characters.dart';
import 'package:target_classic/colorcodes.dart';

class Message {
  final String message;

  Message(this.message) {
    if (!RegExp(r'^[\x00-\x7F]+$').hasMatch(message)) {
      throw ArgumentError("Message must be ascii");
    }
  }

  static String sanitize(String message) {
    if (message.isNotEmpty && message[message.length - 1] == '&')
      message = message.substring(0, message.length - 1);

    return message.replaceAllMapped(
      RegExp('[\x00-\x1F\x7F-\xFF]'),
      (match) => '?',
    );
  }

  String getSanitized() {
    return sanitize(message);
  }

  List<String> getParts({String overflowPrefix = "> "}) {
    List<String> parts = [];
    List<String> currentPart = [];
    List<String> currentWord = [];
    int currentLength = 0;
    String lastColor = "";
    String startColor = ColorCodes.white;
    bool firstPart = true;

    int getMaxPartLength(bool addPrefix) {
      return (64 - startColor.length) -
          (!addPrefix ? 0 : overflowPrefix.length);
    }

    void addWord() {
      if (currentWord.isEmpty) return;
      currentPart.add(currentWord.join(""));
      currentLength += currentWord.length + (currentPart.length == 1 ? 0 : 1);
      currentWord.clear();
    }

    void addPart(bool addPrefix) {
      if (currentPart.isEmpty) return;
      String part = currentPart.join(" ");
      if (part.isNotEmpty) {
        parts.add(
          (addPrefix ? overflowPrefix : "") + startColor + sanitize(part),
        );
      }
      currentPart.clear();
      currentLength = 0;
      firstPart = false;
      startColor = lastColor;
    }

    int i = -1;
    void checkWord(bool addPrefix) {
      if (currentLength +
              currentWord.length +
              (currentPart.length == 0 ? 0 : 1) <=
          getMaxPartLength(addPrefix)) {
        addWord();
      }
    }

    void trimColor(bool wasColor) {
      if (wasColor)
        currentWord = currentWord.sublist(0, currentWord.length - 2);
    }

    void handleSplit(String char, bool wasColor) {
      int maxPartLength = getMaxPartLength(!firstPart);
      checkWord(!firstPart && char != "\n");
      if (currentWord.length >=
          (maxPartLength = getMaxPartLength(!firstPart))) {
        // Split word
        trimColor(wasColor);
        String saveStartColor =
            startColor; // Save current color or it'll be set to the last color
        addPart(!firstPart && char != "\n");
        startColor = saveStartColor;
        maxPartLength = getMaxPartLength(!firstPart && char != "\n");
        currentPart = [currentWord.sublist(0, maxPartLength).join("")];
        currentLength += maxPartLength;
        currentWord = currentWord.sublist(maxPartLength);
        handleSplit(char, wasColor); // Recurse to handle the rest of the word
      } else if (currentLength + currentWord.length >=
              maxPartLength || // Word won't fit
          char == "\n" || // New line
          i == message.length - 1) /* Last character */ {
        trimColor(wasColor);
        addPart(!firstPart && char != "\n");
        checkWord(!firstPart && char != "\n");
        if (i == message.length - 1) addPart(!firstPart && char != "\n");
      }
    }

    for (String char in message.characters) {
      i++;
      bool wasColor = false;
      if (char == "&") {
        lastColor = "&";
      } else if (RegExp("[0-9a-fA-F]").hasMatch(char) && lastColor == "&") {
        lastColor += char;
        wasColor = true;
      }
      if (!const {" ", "\n"}.contains(char)) {
        currentWord.add(char);
      }
      if (char == " " || char == "\n" || i == message.length - 1) {
        handleSplit(char, wasColor);
      }
    }
    return parts;
  }

  @override
  bool operator ==(Object other) {
    return other is Message && this.message == other.message;
  }

  Message operator +(Object other) {
    if (other is String) {
      return Message(this.message + other);
    } else if (other is Message) {
      return Message(this.message + other.message);
    }
    throw ArgumentError("Cannot add Message and ${other.runtimeType}");
  }

  @override
  String toString() {
    return message;
  }
}
