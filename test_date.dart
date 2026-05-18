void main() {
  var d1 = DateTime.now();
  var str = d1.toIso8601String();
  var d2 = DateTime.tryParse(str);
  var str2 = d2!.toIso8601String();
  print("d1: $d1");
  print("str: $str");
  print("d2: $d2");
  print("str2: $str2");
  print("Match: ${str == str2}");
}
