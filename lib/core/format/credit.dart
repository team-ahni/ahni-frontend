/// 학점을 화면에 쓸 때의 모양. 3.0은 `3`, 1.5는 `1.5`로 쓴다.
String formatCredit(double value) => value == value.truncateToDouble()
    ? value.toInt().toString()
    : value.toString();
