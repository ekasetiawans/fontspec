library fontspec;

import 'dart:io';

void main() {
  final dir = Directory(Directory.current.path + "/fonts");
  if (!dir.existsSync()) {
    print("no fonts directory found");
    return;
  }

  final files = dir.listSync();
  final fontFiles = <FontFile>[];
  for (var file in files) {
    fontFiles.add(FontFile(file.path));
  }

  fontFiles.sort((a, b) {
    final x = a.family.compareTo(b.family);
    if (x == 0) {
      return a.weight.compareTo(b.weight);
    }
    return x;
  });

  Set<String> families = fontFiles.fold<List<String>>([],
      (previousValue, element) => previousValue..add(element.family)).toSet();

  List<String> result = ["  fonts:"];
  for (var family in families) {
    result.add("    - family: $family");
    result.add("      fonts:");
    for (var asset in fontFiles.where((element) => element.family == family)) {
      result.add("      - asset: fonts/${asset.name}");
      result.add("        weight: ${asset.weight}");
      if (asset.style != null) {
        result.add("        style: ${asset.style}");
      }
    }
  }

  final content = replaceFonts(result);
  final file = File("pubspec.yaml");
  file.writeAsStringSync(content, mode: FileMode.write, flush: true);
}

List<String> getPubspec() {
  final file = File("pubspec.yaml");
  return file.readAsLinesSync();
}

String replaceFonts(List<String> fonts) {
  final pubs = getPubspec();

  int flutterIndex = -1;
  int fontsIndexStart = -1;
  int fontsIndexEnd = -1;
  for (var i = 0; i < pubs.length; i++) {
    final line = pubs[i];
    if (line.trim().startsWith("flutter:")) {
      flutterIndex = i;
      continue;
    }

    if (flutterIndex > -1 &&
        fontsIndexStart == -1 &&
        line.trim().startsWith("fonts:")) {
      fontsIndexStart = i;
      continue;
    }

    if (fontsIndexStart > -1 && fontsIndexEnd == -1) {
      if (!line.startsWith(" ") || line.trim().startsWith("#")) {
        fontsIndexEnd = i;
        continue;
      }
    }
  }

  if (fontsIndexStart == -1) {
    fontsIndexStart = pubs.length;
  }

  if (fontsIndexEnd == -1) {
    fontsIndexEnd = pubs.length;
  }

  final newPubs = <String>[
    ...pubs.getRange(0, fontsIndexStart),
    ...fonts,
    ...pubs.getRange(fontsIndexEnd, pubs.length)
  ];

  final result = newPubs.fold<String>(
      "", (previousValue, element) => previousValue += element + "\n");
  return result.trim();
}

final weights = <int, List<String>>{
  100: ["Thin", "ThinItalic"],
  200: ["ExtraLight", "ExtraLightItalic"],
  300: ["Light", "LightItalic"],
  400: ["Regular", "Italic"],
  500: ["Medium", "MediumItalic"],
  600: ["SemiBold", "SemiBoldItalic"],
  700: ["Bold", "BoldItalic"],
  800: ["ExtraBold", "ExtraBoldItalic"],
  900: ["Black", "BlackItalic"],
};

class FontFile {
  final String name;
  FontFile(String path) : name = path.substring(path.lastIndexOf("/") + 1);
  String get family => name.substring(0, name.indexOf("-"));

  int get weight {
    final x = name.substring(name.indexOf("-") + 1, name.lastIndexOf("."));
    for (var val in weights.keys) {
      final ws = weights[val];
      if (ws.contains(x)) {
        return val;
      }
    }

    return 400;
  }

  String get style => name.contains("Italic") ? "italic" : null;
}
