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

class AboutStep {
  const AboutStep({required this.title, required this.body});

  final String title;
  final String body;
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

const aboutSteps = <AboutStep>[
  AboutStep(
    title: 'Create an Account or Log In',
    body:
        'Sign up using your CvSU email address or log in if you already have an '
        'account. For teachers, the admin or department chairperson will provide '
        'an account to access the Teacher Dashboard for managing learning '
        'materials and monitoring student progress.',
  ),
  AboutStep(
    title: 'Explore Learning Features',
    body:
        'For students, explore the learning modules, take mini quizzes and mock '
        'exams, and track your performance analytics to identify areas for '
        'improvement. For teachers, upload and manage learning materials, create '
        'quizzes and exams, and monitor student progress through your classes.',
  ),
  AboutStep(
    title: 'Join or Create a Class',
    body:
        'For students, join your teacher\'s class by entering the class code '
        'provided by your teacher. For teachers, create a class and share the '
        'class code with students so they can join.',
  ),
  AboutStep(
    title: 'Take a Study Break',
    body:
        'For a short study break, play the available mini games to relax and '
        'refresh your mind.',
  ),
];

const aboutDevelopers = <AboutPerson>[
  AboutPerson(name: 'Ymanuel Marco T. Manalo'),
  AboutPerson(name: 'Princess Jed D. Javier'),
  AboutPerson(name: 'Joey Albert P. Zamora'),
];

const aboutAdviser = AboutPerson(name: 'Henry R. Balanza');

const aboutCritic = AboutPerson(name: 'Gillian Kyle Catahan');

const aboutInstitutionName = 'Cavite State University – Naic Campus';
const aboutProgramName = 'Bachelor of Science in Information Technology (BSIT)';
