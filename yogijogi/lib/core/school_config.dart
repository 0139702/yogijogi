abstract final class SchoolConfig {
  static const name = '성신여자대학교';
  static const emailDomain = 'sungshin.ac.kr';

  static bool isSchoolEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final at = normalized.lastIndexOf('@');
    return at > 0 && normalized.substring(at + 1) == emailDomain;
  }
}
