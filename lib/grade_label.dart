// =============================================================================
// WHAT A GRADE IS CALLED
//   The problems are filed by grade ("9" ... "12") and, next to the grades, by
//   sections that aren't a grade ("AcadNet": the contest's problems, for every
//   high-school year). A grade reads "clasa a IX-a"; a section keeps its name.
// =============================================================================

const Map<String, String> gradeRoman = {'9': 'IX', '10': 'X', '11': 'XI', '12': 'XII'};

/// A school grade ("9"), not a section like "AcadNet".
bool isSchoolGrade(String g) => int.tryParse(g) != null;

/// "a IX-a", or the section's name.
String gradeShort(String g) => isSchoolGrade(g) ? 'a ${gradeRoman[g] ?? g}-a' : g;

/// "Clasa a IX-a", or the section's name.
String gradeTitle(String g) => isSchoolGrade(g) ? 'Clasa a ${gradeRoman[g] ?? g}-a' : g;

/// "clasa a 9-a" (as the grade is written), or the section's name.
String gradeInline(String g) => isSchoolGrade(g) ? 'clasa a $g-a' : g;
