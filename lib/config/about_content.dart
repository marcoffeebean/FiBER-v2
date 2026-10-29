/// Asset paths. Set a path to null to show a placeholder instead.
const aboutLogoAsset = 'lib/assets/Logo/fiber_logo.png';

/// Replace null with the path once the institutional image is added to
/// the project and listed in pubspec.yaml, for example:
/// 'lib/assets/images/cvsu_naic_logo.png'
const String? aboutInstitutionAsset = null;

class AboutPerson {
  const AboutPerson({required this.name, this.photoAsset});

  final String name;

  /// Path to the profile photo, or null to show initials.
  /// Add photos to pubspec.yaml and set the path here when available.
  final String? photoAsset;
}

const aboutPurposeText =
    'FiBER aims to make Fisheries Board Exam preparation more accessible, '
    'interactive, and effective through learning modules, mock examinations, '
    'quizzes, and performance analytics covering key fisheries competencies. '
    'It helps students strengthen their knowledge, identify learning gaps, and '
    'prepare for the Fisheries Licensure Examination while providing faculty '
    'with tools to manage learning materials and monitor student progress. As '
    'an educational and technological initiative of CvSU-Naic, FiBER also '
    'supports innovative fisheries education and serves as a foundation for '
    'future technology-driven academic projects.';

const aboutDevelopers = <AboutPerson>[
  AboutPerson(name: 'Ymanuel Marco T. Manalo'),
  AboutPerson(name: 'Princess Jed D. Javier'),
  AboutPerson(name: 'Joey Albert P. Zamora'),
];

const aboutAdviser = AboutPerson(name: 'Henry R. Balanza');

const aboutCritic = AboutPerson(name: 'Gillian Kyle Catahan');

const aboutInstitutionName = 'Cavite State University – Naic Campus';
const aboutProgramName = 'Bachelor of Science in Information Technology (BSIT)';
